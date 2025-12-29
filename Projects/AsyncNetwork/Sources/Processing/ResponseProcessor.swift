import Foundation

public protocol ResponseProcessing: Sendable {
    func process<T: Decodable>(
        result: Result<HTTPResponse, Error>,
        decodeType: T.Type,
        request: (any APIRequest)?
    ) -> Result<T, NetworkError>
}

public protocol DataResponseProcessing: Sendable {
    func process(
        result: Result<HTTPResponse, Error>,
        request: (any APIRequest)?
    ) -> Result<Data, NetworkError>
}

public struct ResponseProcessor: ResponseProcessing {
    private let steps: [any ResponseProcessorStep]
    private let decoder: ResponseDecoder
    private let errorMapper: ErrorMapper

    public init(
        steps: [any ResponseProcessorStep] = [StatusCodeValidationStep()],
        decoder: ResponseDecoder = .default,
        errorMapper: ErrorMapper = .default
    ) {
        self.steps = steps
        self.decoder = decoder
        self.errorMapper = errorMapper
    }

    public func process<T: Decodable>(
        result: Result<HTTPResponse, Error>,
        decodeType _: T.Type,
        request: (any APIRequest)?
    ) -> Result<T, NetworkError> {
        let mappedResult = result.mapError { errorMapper.mapError($0, request: request) }
        var currentResult = mappedResult
        for step in steps {
            currentResult = currentResult.flatMap { response in
                step.process(response, request: request)
            }

            if case .failure = currentResult { break }
        }

        return currentResult.flatMap { response in
            do {
                let decoded = try decoder.decode(response, to: T.self)
                return .success(decoded)
            } catch {
                return .failure(errorMapper.mapError(error, request: request))
            }
        }
    }
}

public struct DataResponseProcessor: DataResponseProcessing {
    private let steps: [any ResponseProcessorStep]
    private let errorMapper: ErrorMapper

    public init(
        steps: [any ResponseProcessorStep] = [StatusCodeValidationStep()],
        errorMapper: ErrorMapper = .default
    ) {
        self.steps = steps
        self.errorMapper = errorMapper
    }

    public func process(
        result: Result<HTTPResponse, Error>,
        request: (any APIRequest)?
    ) -> Result<Data, NetworkError> {
        let mappedResult = result.mapError { errorMapper.mapError($0, request: request) }
        var currentResult = mappedResult
        for step in steps {
            currentResult = currentResult.flatMap { response in
                step.process(response, request: request)
            }

            if case .failure = currentResult { break }
        }

        return currentResult.map { $0.data }
    }
}

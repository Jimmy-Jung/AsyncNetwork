import Foundation

public protocol ResponseProcessing: Sendable {
    func process<T: Decodable>(
        result: Result<HTTPResponse, Error>,
        decodeType: T.Type,
        request: (any APIRequest)?
    ) -> Result<T, NetworkError>

    func validateAndExtractData(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) throws -> Data
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
        let validatedResult = validate(result: result, request: request)

        return validatedResult.flatMap { response in
            do {
                let decoded = try decoder.decode(response, to: T.self)
                return .success(decoded)
            } catch {
                return .failure(errorMapper.mapError(error, request: request))
            }
        }
    }

    public func validateAndExtractData(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) throws -> Data {
        let result = validate(result: .success(response), request: request)
        return try result.map { $0.data }.get()
    }

    // MARK: - Private Helpers

    private func validate(
        result: Result<HTTPResponse, Error>,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError> {
        let mappedResult = result.mapError { errorMapper.mapError($0, request: request) }
        var currentResult = mappedResult

        for step in steps {
            currentResult = currentResult.flatMap { response in
                step.process(response, request: request)
            }

            if case .failure = currentResult { break }
        }

        return currentResult
    }
}

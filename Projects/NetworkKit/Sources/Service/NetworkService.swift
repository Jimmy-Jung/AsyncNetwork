import Foundation

public struct NetworkService: Sendable {
    private let httpClient: HTTPClient
    private let retryPolicy: RetryPolicy
    private let configuration: NetworkConfiguration
    private let responseProcessor: any ResponseProcessing
    private let dataResponseProcessor: any DataResponseProcessing
    private let delayer: AsyncDelayer
    private let interceptors: [any RequestInterceptor]

    public init(
        httpClient: HTTPClient,
        retryPolicy: RetryPolicy,
        configuration: NetworkConfiguration,
        responseProcessor: any ResponseProcessing,
        dataResponseProcessor: any DataResponseProcessing = DataResponseProcessor(),
        interceptors: [any RequestInterceptor] = [],
        delayer: AsyncDelayer = SystemDelayer()
    ) {
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
        self.configuration = configuration
        self.responseProcessor = responseProcessor
        self.dataResponseProcessor = dataResponseProcessor
        self.interceptors = interceptors
        self.delayer = delayer
    }

    public func request<R: APIRequest, T: Decodable>(
        request: R,
        decodeType: T.Type
    ) async throws -> T {
        var urlRequest = try request.asURLRequest()
        var attempt = 1

        while true {
            do {
                let response = try await executeWithInterceptors(
                    urlRequest: &urlRequest,
                    target: request
                )

                return try responseProcessor.process(
                    result: .success(response),
                    decodeType: decodeType,
                    request: request
                ).get()
            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    public func requestData<R: APIRequest>(
        _ request: R
    ) async throws -> Data {
        var urlRequest = try request.asURLRequest()
        var attempt = 1

        while true {
            do {
                let response = try await executeWithInterceptors(
                    urlRequest: &urlRequest,
                    target: request
                )

                return try dataResponseProcessor.process(
                    result: .success(response),
                    request: request
                ).get()

            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    public func requestRaw<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        var urlRequest = try request.asURLRequest()
        var attempt = 1

        while true {
            do {
                return try await executeWithInterceptors(
                    urlRequest: &urlRequest,
                    target: request
                )
            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    private func executeWithInterceptors<R: APIRequest>(
        urlRequest: inout URLRequest,
        target: R
    ) async throws -> HTTPResponse {
        for interceptor in interceptors {
            try await interceptor.prepare(&urlRequest, target: target)
        }

        for interceptor in interceptors {
            await interceptor.willSend(urlRequest, target: target)
        }

        let response = try await httpClient.request(urlRequest)

        for interceptor in interceptors {
            await interceptor.didReceive(response, target: target)
        }

        return response
    }

    private func handleRetry(error: Error, attempt: inout Int) async throws {
        let decision = retryPolicy.shouldRetry(error: error, attempt: attempt)
        switch decision {
        case let .retry(delay):
            try await delayer.sleep(seconds: delay)
            attempt += 1
        case .stop:
            throw error
        case .retryImmediately:
            attempt += 1
        }
    }
}

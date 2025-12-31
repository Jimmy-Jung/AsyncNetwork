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

    /// 응답을 특정 타입으로 디코딩하여 반환합니다 (명시적 타입 지정)
    ///
    /// - Parameters:
    ///   - request: 실행할 API 요청
    ///   - decodeType: 디코딩할 응답 타입
    /// - Returns: 디코딩된 응답 객체
    /// - Throws: 네트워크 에러, 디코딩 에러 등
    ///
    /// **사용 예시:**
    /// ```swift
    /// // 커스텀 타입으로 디코딩
    /// let response = try await networkService.request(
    ///     request: userRequest,
    ///     decodeType: CustomUserResponse.self
    /// )
    /// ```
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

    /// 응답을 APIRequest의 associatedtype Response로 디코딩하여 반환합니다 (타입 추론)
    ///
    /// - Parameter request: 실행할 API 요청 (Response associatedtype 정의 필요)
    /// - Returns: 디코딩된 응답 객체
    /// - Throws: 네트워크 에러, 디코딩 에러 등
    ///
    /// **사용 예시:**
    /// ```swift
    /// struct LoginRequest: APIRequest {
    ///     typealias Response = LoginResponse
    ///     // ...
    /// }
    ///
    /// // 타입이 자동으로 추론됨
    /// let loginResponse = try await networkService.request(LoginRequest())
    /// ```
    public func request<R: APIRequest>(
        _ request: R
    ) async throws -> R.Response {
        try await self.request(request: request, decodeType: R.Response.self)
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

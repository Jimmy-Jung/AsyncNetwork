import Foundation

public struct NetworkService: Sendable {
    private let httpClient: any HTTPClientProtocol
    private let retryPolicy: RetryPolicy
    private let responseProcessor: any ResponseProcessing
    private let delayer: AsyncDelayer
    private let interceptors: [any RequestInterceptor]
    private let networkMonitor: (any NetworkMonitoring)?
    private let checkNetworkBeforeRequest: Bool

    public init(
        httpClient: any HTTPClientProtocol,
        retryPolicy: RetryPolicy,
        responseProcessor: any ResponseProcessing,
        interceptors: [any RequestInterceptor] = [],
        delayer: AsyncDelayer = SystemDelayer(),
        networkMonitor: (any NetworkMonitoring)? = NetworkMonitor.shared,
        checkNetworkBeforeRequest: Bool = true
    ) {
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
        self.responseProcessor = responseProcessor
        self.interceptors = interceptors
        self.delayer = delayer
        self.networkMonitor = networkMonitor
        self.checkNetworkBeforeRequest = checkNetworkBeforeRequest
    }

    /// 기본 설정으로 NetworkService를 초기화합니다
    public init(
        configuration: NetworkConfiguration = .default,
        plugins: [any RequestInterceptor]? = nil
    ) {
        let defaultPlugins: [any RequestInterceptor] = plugins ?? [
            ConsoleLoggingInterceptor(minimumLevel: .verbose)
        ]

        self.init(
            httpClient: HTTPClient(configuration: configuration),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            interceptors: defaultPlugins,
            delayer: SystemDelayer(),
            networkMonitor: NetworkMonitor.shared,
            checkNetworkBeforeRequest: true
        )
    }

    // MARK: - Network Status

    /// 현재 네트워크 연결 여부를 반환합니다
    public var isNetworkAvailable: Bool {
        networkMonitor?.isConnected ?? true
    }

    /// 현재 네트워크 연결 타입을 반환합니다
    public var connectionType: NetworkMonitor.ConnectionType {
        networkMonitor?.connectionType ?? .unknown
    }

    // MARK: - Public API

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
        // 네트워크 연결 체크
        if checkNetworkBeforeRequest, !isNetworkAvailable {
            throw NetworkError.offline
        }

        let response = try await execute(request)
        return try responseProcessor.process(
            result: .success(response),
            decodeType: decodeType,
            request: request
        ).get()
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

    /// Raw Data를 반환합니다 (디코딩 없이)
    public func requestData<R: APIRequest>(
        _ request: R
    ) async throws -> Data {
        let response = try await execute(request)
        return try responseProcessor.validateAndExtractData(response, request: request)
    }

    /// HTTPResponse를 그대로 반환합니다
    public func requestRaw<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        try await execute(request)
    }

    // MARK: - Private Helpers

    /// 핵심 실행 메서드 (재시도 로직 포함)
    private func execute<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        var urlRequest = try request.asURLRequest()
        var attempt = 1
        let maxAttempts = retryPolicy.configuration.maxRetries + 1

        while attempt <= maxAttempts {
            do {
                return try await executeWithInterceptors(
                    urlRequest: &urlRequest,
                    target: request
                )
            } catch {
                // 마지막 시도인 경우 즉시 throw
                if attempt >= maxAttempts {
                    throw error
                }
                try await handleRetry(error: error, attempt: &attempt)
            }
        }

        // 이론적으로 도달 불가하지만 컴파일러를 위해
        throw NetworkError.unknown(
            NSError(
                domain: "AsyncNetwork",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected: exceeded max attempts without throwing"]
            )
        )
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

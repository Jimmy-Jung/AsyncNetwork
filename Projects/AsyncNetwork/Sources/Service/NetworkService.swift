//
//  NetworkService.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

// MARK: - NetworkService

/// 네트워크 요청을 처리하는 서비스
///
/// ## 특징
/// - HTTPClient를 통한 네트워크 요청 실행
/// - 자동 재시도 정책
/// - Request/Response Interceptor 지원
/// - 네트워크 상태 모니터링
///
/// ## 사용 예시
/// ```swift
/// let service = NetworkService(
///     httpClient: HTTPClient(),
///     retryPolicy: RetryPolicy(configuration: .standard),
///     interceptors: [ConsoleLoggingInterceptor()]
/// )
///
/// let response = try await service.request(GetPostsRequest())
/// ```
///
/// ## Thread Safety
/// - class로 구현되어 참조 공유
/// - 내부 상태는 모두 immutable (let)
/// - Sendable 준수로 동시성 안전성 보장
public final class NetworkService: Sendable {
    private let httpClient: any HTTPClientProtocol
    private let retryPolicy: RetryPolicy
    private let responseProcessor: any ResponseProcessing
    private let delayer: AsyncDelayer
    private let interceptors: [any RequestInterceptor]
    private let networkMonitor: (any NetworkMonitoring)?
    private let checkNetworkBeforeRequest: Bool

    public init(
        httpClient: any HTTPClientProtocol = HTTPClient(),
        retryPolicy: RetryPolicy = RetryPolicy(),
        responseProcessor: any ResponseProcessing = ResponseProcessor(),
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor(minimumLevel: .verbose)],
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

    public var isNetworkAvailable: Bool {
        networkMonitor?.isConnected ?? true
    }

    public var connectionType: NetworkMonitor.ConnectionType {
        networkMonitor?.connectionType ?? .unknown
    }

    public func request<R: APIRequest, T: Decodable>(
        request: R,
        decodeType: T.Type
    ) async throws -> T {
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

    public func request<R: APIRequest>(
        _ request: R
    ) async throws -> R.Response {
        try await self.request(request: request, decodeType: R.Response.self)
    }

    public func requestData<R: APIRequest>(
        _ request: R
    ) async throws -> Data {
        let response = try await execute(request)
        return try responseProcessor.validateAndExtractData(response, request: request)
    }

    public func requestRaw<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        try await execute(request)
    }

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
                if attempt >= maxAttempts {
                    throw error
                }
                try await handleRetry(error: error, attempt: &attempt)
            }
        }

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

// MARK: - NetworkService Presets

public extension NetworkService {
    /// 일반 API 요청용 (기본값)
    ///
    /// **특징:**
    /// - Timeout: 60초 (요청), 7일 (전체)
    /// - Cache: HTTP 헤더 기반 (.useProtocolCachePolicy)
    ///   → Cache-Control, Expires 등 서버 헤더에 따라 캐싱
    ///   → ETag 자동 검증 없음
    /// - Retry: 중간 수준 (1회 재시도, 2초 간격)
    /// - Logging: Verbose
    /// - Network Check: 활성화
    ///
    /// **사용 케이스:**
    /// - REST API 호출
    /// - JSON 데이터 요청
    /// - 일반적인 HTTP 통신
    ///
    /// **사용 예시:**
    /// ```swift
    /// let service = NetworkService.default(interceptors: [loggingInterceptor])
    /// let posts = try await service.request(GetPostsRequest())
    /// ```
    static func `default`(
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor(minimumLevel: .verbose)]
    ) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(),
            retryPolicy: RetryPolicy(configuration: .patient),
            interceptors: interceptors
        )
    }

    /// 이미지 다운로드용
    ///
    /// **특징:**
    /// - Timeout: 30초 (요청), 300초 (전체, 5분)
    /// - Cache: HTTP 캐시 자동 관리
    ///   → 이미지 URL이 동일하면 캐시 사용으로 네트워크 절약
    /// - Retry: 최소 (1회 재시도, 2초 간격)
    /// - Logging: Verbose
    /// - Connection: 최대 4개 (병렬 다운로드 제한)
    ///
    /// **사용 케이스:**
    /// - 프로필 이미지 (URL이 고정)
    /// - 썸네일 이미지
    /// - 피드 이미지
    ///
    /// **주의:**
    /// - 이미지 URL에 버전/타임스탬프가 있으면 캐시 효과 제한적
    /// - 예: `/profile.jpg?v=123` (v가 바뀌면 새 URL로 인식)
    ///
    /// **사용 예시:**
    /// ```swift
    /// let imageService = NetworkService.image()
    /// let imageData = try await imageService.requestData(ImageRequest(url: url))
    /// ```
    static func image(
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor(minimumLevel: .verbose)]
    ) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(
                configuration: HTTPClientConfiguration(
                    timeoutForRequest: 30,
                    timeoutForResource: 300,
                    cachePolicy: .reloadRevalidatingCacheData, // ETag 활성화
                    maxConnectionsPerHost: 4
                )
            ),
            retryPolicy: RetryPolicy(configuration: .patient),
            interceptors: interceptors
        )
    }

    /// 파일 업로드용
    ///
    /// **특징:**
    /// - Timeout: 120초 (요청), 1800초 (전체, 30분)
    /// - Cache: 무시 (항상 서버에 전송)
    /// - Retry: 표준 (3회 재시도, 지수 백오프)
    /// - Logging: Verbose
    /// - Network Check: 활성화
    ///
    /// **사용 케이스:**
    /// - 이미지 업로드
    /// - 비디오 업로드
    /// - 파일 업로드
    ///
    /// **사용 예시:**
    /// ```swift
    /// let uploadService = NetworkService.upload(interceptors: [loggingInterceptor])
    /// let result = try await uploadService.request(UploadImageRequest(data: imageData))
    /// ```
    static func upload(
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor(minimumLevel: .verbose)]
    ) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(configuration: .upload),
            retryPolicy: RetryPolicy(configuration: .standard),
            interceptors: interceptors
        )
    }

    /// 대용량 파일 다운로드용
    ///
    /// **특징:**
    /// - Timeout: 120초 (요청), 3600초 (전체, 1시간)
    /// - Cache: 무시 (항상 새로 다운로드)
    /// - Retry: 표준 (3회 재시도)
    /// - Connectivity: 네트워크 복구 대기
    /// - Logging: Verbose
    ///
    /// **사용 케이스:**
    /// - 대용량 파일 다운로드
    /// - 비디오 다운로드
    /// - 백업 파일 다운로드
    ///
    /// **사용 예시:**
    /// ```swift
    /// let downloadService = NetworkService.download(interceptors: [loggingInterceptor])
    /// let data = try await downloadService.requestData(DownloadFileRequest(url: url))
    /// ```
    static func download(
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor(minimumLevel: .verbose)]
    ) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(configuration: .download),
            retryPolicy: RetryPolicy(configuration: .standard),
            interceptors: interceptors
        )
    }

    /// 실시간 API용 (캐시 없음, 빠른 실패)
    ///
    /// **특징:**
    /// - Timeout: 10초 (요청), 60초 (전체)
    /// - Cache: 무시 (항상 최신 데이터)
    /// - Retry: 빠름 (5회 재시도, 0.5초 간격)
    /// - Logging: 최소 (성능 최적화)
    /// - Network Check: 비활성화 (빠른 실패)
    ///
    /// **사용 케이스:**
    /// - 실시간 채팅
    /// - 주식 시세
    /// - 라이브 스코어
    /// - 위치 추적
    ///
    /// **사용 예시:**
    /// ```swift
    /// let realtimeService = NetworkService.realtime()
    /// let message = try await realtimeService.request(SendMessageRequest(text: "Hello"))
    /// ```
    static func realtime(interceptors: [any RequestInterceptor] = []) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(configuration: .realtime),
            retryPolicy: RetryPolicy(configuration: .quick),
            interceptors: interceptors,
            checkNetworkBeforeRequest: false
        )
    }

    /// 오프라인 우선 (캐시 우선)
    ///
    /// **특징:**
    /// - Timeout: 5초 (요청), 30초 (전체)
    /// - Cache: 캐시 우선, 없으면 서버 (.returnCacheDataElseLoad)
    /// - Retry: 느림 (1회 재시도, 2초 간격)
    /// - Connectivity: 대기 안 함 (빠른 실패)
    /// - Logging: 최소
    ///
    /// **사용 케이스:**
    /// - 오프라인 모드
    /// - 느린 네트워크 환경
    /// - 데이터 절약 모드
    ///
    /// **사용 예시:**
    /// ```swift
    /// let offlineService = NetworkService.offline()
    /// let posts = try await offlineService.request(GetPostsRequest())
    /// ```
    static func offline(interceptors: [any RequestInterceptor] = []) -> NetworkService {
        NetworkService(
            httpClient: HTTPClient(configuration: .offline),
            retryPolicy: RetryPolicy(configuration: .patient),
            interceptors: interceptors,
            checkNetworkBeforeRequest: false
        )
    }
}

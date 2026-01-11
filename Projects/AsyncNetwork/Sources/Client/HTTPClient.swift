//
//  HTTPClient.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

// MARK: - HTTPClientConfiguration

/// HTTPClient 커스터마이징 설정
///
/// URLSessionConfiguration의 주요 설정들을 간편하게 설정할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 기본 설정
/// let config = HTTPClientConfiguration()
///
/// // Timeout만 변경
/// let config = HTTPClientConfiguration(timeoutForRequest: 15)
///
/// // 파일 업로드용 (긴 timeout)
/// let uploadConfig = HTTPClientConfiguration(
///     timeoutForRequest: 300,
///     timeoutForResource: 300
/// )
///
/// // Wi-Fi만 사용
/// let wifiConfig = HTTPClientConfiguration(
///     allowsCellularAccess: false
/// )
///
/// // 오프라인 우선 (캐시 우선)
/// let offlineConfig = HTTPClientConfiguration(
///     cachePolicy: .returnCacheDataElseLoad,
///     waitsForConnectivity: false
/// )
/// ```
public struct HTTPClientConfiguration: Sendable {
    // MARK: - Timeout

    /// 개별 요청의 timeout (초 단위)
    ///
    /// **의미**: 데이터 전송 중 "멈춤" 감지 시간
    /// - 데이터 수신이 시작된 후, 다음 데이터 패킷을 기다리는 최대 시간
    /// - 데이터가 계속 오면 timeout 되지 않음
    ///
    /// **예시:**
    /// ```
    /// timeoutForRequest = 60초
    ///
    /// ━━ 60초 ━━
    ///   ↓   ↓   ↓   ← 계속 데이터가 오면 계속 진행 ✅
    /// 📦 📦 📦 📦
    ///
    /// ━━ 60초 ━━ ⏰
    ///   ↓   ↓
    /// 📦 📦 ❌ ❌  ← 60초간 데이터가 안 오면 실패 ❌
    /// ```
    ///
    /// **사용 케이스:**
    /// - 네트워크가 불안정할 때 빠르게 실패
    /// - 느린 서버 감지
    ///
    /// - 기본값: 60초
    public let timeoutForRequest: TimeInterval

    /// 전체 리소스의 timeout (초 단위)
    ///
    /// **의미**: 요청 시작부터 완료까지의 "총 시간" 제한
    /// - 데이터가 계속 오더라도 이 시간을 초과하면 실패
    /// - 큰 파일 다운로드 시 필요
    ///
    /// **예시:**
    /// ```
    /// timeoutForResource = 300초 (5분)
    ///
    /// ━━━━━━━ 5분 ━━━━━━━
    /// 시작                  완료
    ///  ↓                    ↓
    /// 📦📦📦...📦📦 ← 5분 내 완료 ✅
    ///
    /// ━━━━━━━ 5분 ━━━━━━━ ⏰
    /// 시작                  (진행중)
    ///  ↓
    /// 📦📦📦...📦📦📦  ← 5분 지나면 실패 ❌
    /// ```
    ///
    /// **사용 케이스:**
    /// - 일반 API: 60~300초 (1~5분)
    /// - 파일 업로드: 300~1800초 (5~30분)
    /// - 스트리밍: 3600~7200초 (1~2시간)
    ///
    /// **주의:**
    /// - Apple 기본값: 604800초 (7일) - 거의 무제한
    /// - 필요에 따라 더 짧게 설정 가능
    ///
    /// - 기본값: 604800초 (7일, Apple 기본값)
    public let timeoutForResource: TimeInterval

    // MARK: - Cache

    /// 캐시 정책
    ///
    /// - `.useProtocolCachePolicy`: HTTP 헤더를 따름 (기본값)
    /// - `.reloadIgnoringLocalCacheData`: 항상 서버에서 가져옴
    /// - `.returnCacheDataElseLoad`: 캐시 우선, 없으면 서버
    /// - `.returnCacheDataDontLoad`: 캐시만 사용, 없으면 실패
    public let cachePolicy: URLRequest.CachePolicy

    /// URLCache 인스턴스
    ///
    /// - nil이면 URLCache.shared 사용
    public let urlCache: URLCache?

    // MARK: - Network Access

    /// 셀룰러 네트워크 사용 허용 여부
    ///
    /// - `true`: Wi-Fi + 셀룰러 모두 사용 (기본값)
    /// - `false`: Wi-Fi만 사용
    public let allowsCellularAccess: Bool

    /// 고비용 네트워크 사용 허용 여부
    ///
    /// - `true`: 모든 네트워크 사용 (기본값)
    /// - `false`: 저비용 네트워크만 사용 (로밍 등 제외)
    public let allowsExpensiveNetworkAccess: Bool

    /// 제한된 네트워크 사용 허용 여부
    ///
    /// - `true`: 모든 네트워크 사용 (기본값)
    /// - `false`: 제한 없는 네트워크만 사용 (저전력 모드 등)
    public let allowsConstrainedNetworkAccess: Bool

    /// 네트워크 연결을 기다릴지 여부
    ///
    /// - `true`: 연결될 때까지 대기
    /// - `false`: 즉시 실패 (기본값)
    public let waitsForConnectivity: Bool

    // MARK: - Connection

    /// 호스트당 최대 동시 연결 수
    ///
    /// - 기본값: 6
    public let maxConnectionsPerHost: Int

    /// 추가 HTTP 헤더
    ///
    /// 모든 요청에 자동으로 추가될 헤더
    /// - 예: User-Agent, Accept-Language 등
    public let additionalHeaders: [String: String]?

    // MARK: - Initialization

    public init(
        timeoutForRequest: TimeInterval = 60.0,
        timeoutForResource: TimeInterval = 604_800.0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        urlCache: URLCache? = nil,
        allowsCellularAccess: Bool = true,
        allowsExpensiveNetworkAccess: Bool = true,
        allowsConstrainedNetworkAccess: Bool = true,
        waitsForConnectivity: Bool = false,
        maxConnectionsPerHost: Int = 6,
        additionalHeaders: [String: String]? = nil
    ) {
        self.timeoutForRequest = timeoutForRequest
        self.timeoutForResource = timeoutForResource
        self.cachePolicy = cachePolicy
        self.urlCache = urlCache
        self.allowsCellularAccess = allowsCellularAccess
        self.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        self.waitsForConnectivity = waitsForConnectivity
        self.maxConnectionsPerHost = maxConnectionsPerHost
        self.additionalHeaders = additionalHeaders
    }
}

// MARK: - HTTPClientConfiguration Presets

public extension HTTPClientConfiguration {
    /// 이미지 다운로드용
    ///
    /// **특징:**
    /// - Timeout: 30초 (요청), 300초 (전체)
    /// - 캐시: HTTP 헤더 따름
    /// - 동시 연결: 4개 (이미지는 병렬 다운로드 제한)
    ///
    /// **사용 케이스:**
    /// - 프로필 이미지
    /// - 썸네일 이미지
    /// - 피드 이미지
    ///
    /// **주의:**
    /// - 이미지 URL에 버전 쿼리 추가 권장
    /// - 예: `/profile.jpg?v=\(timestamp)`
    static var image: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 30,
            timeoutForResource: 300, // 5분
            maxConnectionsPerHost: 4
        )
    }

    /// 파일 업로드용
    ///
    /// **특징:**
    /// - Timeout: 120초 (요청), 1800초 (전체)
    /// - 캐시: 무시 (항상 서버에 전송)
    /// - 네트워크: 모든 네트워크 허용
    ///
    /// **사용 케이스:**
    /// - 이미지 업로드
    /// - 비디오 업로드
    /// - 파일 업로드
    static var upload: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 120,
            timeoutForResource: 1800, // 30분
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }

    /// 대용량 파일 다운로드용
    ///
    /// **특징:**
    /// - Timeout: 120초 (요청), 3600초 (전체)
    /// - 캐시: 무시 (항상 새로 다운로드)
    /// - 연결 대기: true (네트워크 복구 대기)
    ///
    /// **사용 케이스:**
    /// - 대용량 파일 다운로드
    /// - 비디오 다운로드
    /// - 백업 파일 다운로드
    static var download: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 120,
            timeoutForResource: 3600, // 1시간
            cachePolicy: .reloadIgnoringLocalCacheData,
            waitsForConnectivity: true
        )
    }

    /// 실시간 API용 (캐시 없음)
    ///
    /// **특징:**
    /// - Timeout: 10초 (요청), 60초 (전체)
    /// - 캐시: 무시 (항상 최신 데이터)
    /// - 빠른 실패
    ///
    /// **사용 케이스:**
    /// - 실시간 채팅
    /// - 주식 시세
    /// - 라이브 스코어
    /// - 위치 추적
    static var realtime: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 10,
            timeoutForResource: 60,
            cachePolicy: .reloadIgnoringLocalCacheData,
            waitsForConnectivity: false
        )
    }

    /// 오프라인 우선 (캐시 우선)
    ///
    /// **특징:**
    /// - Timeout: 5초 (요청), 30초 (전체)
    /// - 캐시: 캐시 우선, 없으면 서버
    /// - 빠른 실패, 캐시 의존
    ///
    /// **사용 케이스:**
    /// - 오프라인 모드
    /// - 느린 네트워크 환경
    /// - 데이터 절약 모드
    static var offline: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 5,
            timeoutForResource: 30,
            cachePolicy: .returnCacheDataElseLoad,
            waitsForConnectivity: false
        )
    }

    /// Wi-Fi 전용
    ///
    /// **특징:**
    /// - Timeout: 60초 (요청), 7일 (전체)
    /// - 캐시: HTTP 헤더 따름
    /// - 네트워크: Wi-Fi만 사용
    ///
    /// **사용 케이스:**
    /// - 대용량 데이터
    /// - 자동 백업
    /// - 비디오 스트리밍
    static var wifiOnly: HTTPClientConfiguration {
        .init(
            allowsCellularAccess: false,
            allowsExpensiveNetworkAccess: false
        )
    }

    /// 저전력 모드 (제한된 네트워크만)
    ///
    /// **특징:**
    /// - Timeout: 30초 (요청), 300초 (전체)
    /// - 캐시: 캐시 우선
    /// - 네트워크: 제한 없는 네트워크만
    ///
    /// **사용 케이스:**
    /// - 저전력 모드
    /// - 배터리 절약
    /// - 데이터 절약
    static var lowPower: HTTPClientConfiguration {
        .init(
            timeoutForRequest: 30,
            timeoutForResource: 300,
            cachePolicy: .returnCacheDataElseLoad,
            allowsExpensiveNetworkAccess: false,
            allowsConstrainedNetworkAccess: false
        )
    }
}

// MARK: - HTTPClientProtocol

///
/// 네트워크 요청을 수행하는 클라이언트의 인터페이스를 정의합니다.
/// 테스트 시 Mock 구현체를 주입하여 사용할 수 있습니다.
public protocol HTTPClientProtocol: Sendable {
    func request(_ request: any APIRequest) async throws -> HTTPResponse
    func request(_ urlRequest: URLRequest) async throws -> HTTPResponse
}

/// HTTP 통신 클라이언트
///
/// URLSession을 캡슐화하고 timeout 설정을 자체적으로 관리합니다.
///
/// ## 초기화 방식
///
/// ### 1️⃣ 기본 초기화 (URLSession.shared)
/// ```swift
/// let client = HTTPClient()
/// ```
/// - URLSession.shared (싱글톤) 사용
/// - Timeout: 75초 (기본값)
/// - 메모리 효율적
/// - 일반적인 경우 권장
///
/// ### 2️⃣ 커스텀 Timeout
/// ```swift
/// let client = HTTPClient(timeout: 15)
/// ```
/// - 새로운 URLSession 인스턴스 생성
/// - URLSessionConfiguration.default 기반
/// - Timeout: 지정한 값
/// - 특정 timeout이 필요한 경우 사용
///
/// ### 3️⃣ 완전한 커스터마이징
/// ```swift
/// let config = URLSessionConfiguration.default
/// config.timeoutIntervalForRequest = 30
/// config.requestCachePolicy = .reloadIgnoringLocalCacheData
/// let session = URLSession(configuration: config)
/// let client = HTTPClient(session: session)
/// ```
/// - 모든 설정 직접 제어
/// - 테스트용 Mock 주입 가능
/// HTTP 네트워크 요청을 수행하는 클라이언트
///
/// ## 특징
/// - URLSession 기반 네트워크 요청
/// - 타임아웃, 캐시 정책 등 세밀한 제어
/// - HTTPClientConfiguration으로 쉬운 설정
///
/// ## Thread Safety
/// - class로 구현되어 참조 공유
/// - 내부 URLSession은 thread-safe
/// - Sendable 준수로 동시성 안전성 보장
///
/// ## 사용 예시
/// ```swift
/// // 기본 HTTP 헤더 기반 캐싱
/// let client = HTTPClient()
///
/// // ETag 캐싱 활성화
/// let client = HTTPClient(configuration: .withETagCaching)
///
/// // 커스텀 설정
/// let config = HTTPClientConfiguration(
///     cachePolicy: .reloadRevalidatingCacheData,
///     timeoutForRequest: 30.0
/// )
/// let client = HTTPClient(configuration: config)
/// ```
public final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession

    // MARK: - Initialization

    /// 기본 HTTPClient 생성 (HTTP 헤더 기반 캐싱)
    ///
    /// **기본 설정:**
    /// - Timeout: 60초 (요청), 7일 (전체)
    /// - Cache Policy: `.useProtocolCachePolicy` (HTTP 헤더 따름)
    ///   → Cache-Control, Expires 등 서버 헤더에 따라 캐싱
    ///   → 304 응답 시 URLCache 자동 사용
    /// - URLCache.shared 사용
    ///
    /// **중요: ETag 캐싱은 자동으로 활성화되지 않습니다**
    /// - If-None-Match 헤더는 자동으로 추가되지 않음
    /// - ETag 캐싱을 사용하려면 ETagInterceptor 필수
    ///
    /// **사용 예시:**
    /// ```swift
    /// // 일반 API 요청 (HTTP 헤더 기반 캐싱)
    /// let client = HTTPClient()
    /// ```
    ///
    /// **ETag 캐싱 활성화가 필요한 경우:**
    /// ```swift
    /// let etagInterceptor = ETagInterceptor()
    /// let client = HTTPClient(configuration: .withETagCaching)
    /// let service = NetworkService(
    ///     httpClient: client,
    ///     interceptors: [etagInterceptor]  // 필수!
    /// )
    /// ```
    public init(urlCache: URLCache? = nil) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 604_800.0
        config.urlCache = urlCache ?? .shared
        session = URLSession(configuration: config)
    }

    /// 커스텀 URLSession을 사용하는 초기화
    ///
    /// - Parameter session: 사용할 URLSession
    ///
    /// **주의:**
    /// - URLSession의 configuration이 이미 설정되어 있어야 함
    /// - 테스트용 Mock URLSession 주입 시 사용
    ///
    /// **사용 예시:**
    /// ```swift
    /// // 테스트용 Mock Session
    /// let mockSession = MockURLSession()
    /// let client = HTTPClient(session: mockSession)
    /// ```
    public init(session: URLSession) {
        self.session = session
    }

    /// 상세한 커스터마이징을 위한 HTTPClient 생성
    ///
    /// - Parameter configuration: 네트워크 설정
    ///
    /// **캐싱 정책:**
    /// - `.useProtocolCachePolicy`: HTTP 헤더 기반 캐싱 (Cache-Control, Expires)
    /// - 304 응답 시 URLCache 자동 사용
    /// - URLCache.shared 자동 사용
    ///
    /// **ETag 캐싱 주의사항:**
    /// - Cache Policy만으로는 If-None-Match 헤더가 추가되지 않습니다
    /// - ETag 캐싱을 사용하려면 **ETagInterceptor 필수**
    ///
    /// **사용 예시:**
    /// ```swift
    /// // HTTP 헤더 기반 캐싱 (기본값)
    /// let client = HTTPClient()
    ///
    /// // ETag 캐싱 준비 (ETagInterceptor와 함께 사용)
    /// let etagInterceptor = ETagInterceptor()
    /// let client = HTTPClient(configuration: .withETagCaching)
    /// let service = NetworkService(
    ///     httpClient: client,
    ///     interceptors: [etagInterceptor]  // If-None-Match 헤더 추가
    /// )
    /// ```
    public init(configuration: HTTPClientConfiguration) {
        let sessionConfig = URLSessionConfiguration.default

        // Timeout 설정
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutForRequest
        sessionConfig.timeoutIntervalForResource = configuration.timeoutForResource

        // Cache 정책
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        sessionConfig.urlCache = configuration.urlCache ?? .shared

        // Network Access 제어
        sessionConfig.allowsCellularAccess = configuration.allowsCellularAccess
        sessionConfig.allowsExpensiveNetworkAccess = configuration.allowsExpensiveNetworkAccess
        sessionConfig.allowsConstrainedNetworkAccess = configuration.allowsConstrainedNetworkAccess
        sessionConfig.waitsForConnectivity = configuration.waitsForConnectivity

        // Connection 설정
        sessionConfig.httpMaximumConnectionsPerHost = configuration.maxConnectionsPerHost

        // 추가 헤더
        if let headers = configuration.additionalHeaders {
            sessionConfig.httpAdditionalHeaders = headers
        }

        session = URLSession(configuration: sessionConfig)
    }

    // MARK: - Request

    public func request(_ request: any APIRequest) async throws -> HTTPResponse {
        let urlRequest = try request.asURLRequest()
        return try await self.request(urlRequest)
    }

    public func request(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: urlRequest)
        return try HTTPResponse.from(data: data, response: response, request: urlRequest)
    }
}

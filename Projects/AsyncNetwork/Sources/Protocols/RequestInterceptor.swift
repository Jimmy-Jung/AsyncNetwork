//
//  RequestInterceptor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - RequestInterceptor Protocol

/// 네트워크 요청/응답을 가로채서 전처리 또는 후처리를 수행하는 프로토콜
///
/// RequestInterceptor는 세 가지 라이프사이클 훅을 제공합니다:
/// 1. `prepare(_:target:)` - 요청 전송 전 URLRequest 수정 (인증 토큰 주입 등)
/// 2. `willSend(_:target:)` - 요청 직전 옵저버 훅 (로깅, Analytics 등)
/// 3. `didReceive(_:target:)` - 응답 수신 후 옵저버 훅 (로깅, 메트릭 수집 등)
///
/// ## 주요 용도
///
/// - ✅ 인증 토큰(OAuth, JWT) 자동 주입
/// - ✅ 공통 HTTP 헤더 추가 (User-Agent, Device-ID, API-Key 등)
/// - ✅ 요청/응답 로깅 및 Analytics 전송
/// - ✅ 성능 메트릭 수집 (요청 시간, 응답 크기 등)
/// - ✅ 디버깅 정보 추가 (Request-ID, Trace-ID 등)
///
/// ## 사용 예시
///
/// ### 1. 인증 토큰 자동 주입
///
/// ```swift
/// struct AuthInterceptor: RequestInterceptor {
///     private let tokenProvider: TokenProvider
///
///     func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
///         // 토큰 발급 (비동기)
///         let token = try await tokenProvider.getAccessToken()
///         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
///     }
///
///     func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
///         print("🚀 Sending: \(request.url?.absoluteString ?? "")")
///     }
///
///     func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
///         print("✅ Received: \(response.statusCode)")
///     }
/// }
/// ```
///
/// ### 2. 공통 헤더 추가
///
/// ```swift
/// struct CommonHeadersInterceptor: RequestInterceptor {
///     func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
///         request.setValue("AsyncNetwork/1.0.0", forHTTPHeaderField: "User-Agent")
///         request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
///         request.setValue(Locale.current.identifier, forHTTPHeaderField: "Accept-Language")
///     }
/// }
/// ```
///
/// ### 3. Analytics 통합
///
/// ```swift
/// struct AnalyticsInterceptor: RequestInterceptor {
///     func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
///         Analytics.track("API Request Started", properties: [
///             "url": request.url?.absoluteString ?? "",
///             "method": request.httpMethod ?? ""
///         ])
///     }
///
///     func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
///         Analytics.track("API Request Completed", properties: [
///             "url": response.url.absoluteString,
///             "statusCode": response.statusCode,
///             "duration": response.metrics?.taskInterval.duration ?? 0
///         ])
///     }
/// }
/// ```
///
/// ## 여러 Interceptor 체이닝
///
/// ```swift
/// let interceptors: [RequestInterceptor] = [
///     AuthInterceptor(tokenProvider: tokenProvider),
///     CommonHeadersInterceptor(),
///     AnalyticsInterceptor()
/// ]
///
/// // HTTPClient에 체이닝된 interceptor 적용
/// for interceptor in interceptors {
///     try await interceptor.prepare(&request, target: target)
/// }
/// ```
///
/// ## 주의사항
///
/// - `prepare` 메서드는 `inout` 파라미터로 URLRequest를 직접 수정합니다
/// - `willSend`와 `didReceive`는 옵저버 패턴으로 동작하며 요청/응답을 수정하지 않습니다
/// - 모든 메서드는 `async`이므로 비동기 작업 수행 가능 (토큰 갱신, DB 조회 등)
/// - `Sendable` 프로토콜을 준수하므로 Swift 6.0 Strict Concurrency 환경에서 안전합니다
///
public protocol RequestInterceptor: Sendable {
    /// 요청을 전송하기 전에 URLRequest를 수정합니다
    ///
    /// 이 메서드는 HTTPClient가 URLSession에 요청을 전달하기 직전에 호출됩니다.
    /// 주로 인증 토큰, 공통 헤더, 디버깅 정보 등을 추가하는 데 사용됩니다.
    ///
    /// - Parameters:
    ///   - request: 수정할 URLRequest (inout 파라미터)
    ///   - target: 요청의 원본 APIRequest (선택 사항)
    /// - Throws: 수정 중 발생한 에러 (예: 토큰 발급 실패, 네트워크 에러)
    ///
    /// ## 예시
    ///
    /// ```swift
    /// func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
    ///     // 인증 토큰 추가
    ///     let token = try await TokenManager.shared.getToken()
    ///     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    ///
    ///     // 공통 헤더 추가
    ///     request.setValue("iOS/17.0", forHTTPHeaderField: "X-Platform")
    ///     request.setValue("NetworkKit/1.0.0", forHTTPHeaderField: "User-Agent")
    /// }
    /// ```
    func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws

    /// 요청이 전송되기 직전에 호출됩니다 (옵저버 훅)
    ///
    /// 이 메서드는 URLRequest를 수정하지 않으며, 로깅, Analytics, 디버깅 등의
    /// 옵저버 역할만 수행합니다.
    ///
    /// - Parameters:
    ///   - request: 전송될 URLRequest (읽기 전용)
    ///   - target: 요청의 원본 APIRequest (선택 사항)
    ///
    /// ## 예시
    ///
    /// ```swift
    /// func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
    ///     print("🚀 Sending: \(request.url?.absoluteString ?? "")")
    ///
    ///     // Analytics 전송
    ///     Analytics.track("API Request", properties: [
    ///         "url": request.url?.absoluteString ?? "",
    ///         "method": request.httpMethod ?? ""
    ///     ])
    /// }
    /// ```
    func willSend(_ request: URLRequest, target: (any APIRequest)?) async

    /// 응답을 수신한 직후에 호출됩니다 (옵저버 훅)
    ///
    /// 이 메서드는 HTTPResponse를 수정하지 않으며, 로깅, 성능 메트릭 수집,
    /// Analytics 등의 옵저버 역할만 수행합니다.
    ///
    /// - Parameters:
    ///   - response: 수신된 HTTPResponse (읽기 전용)
    ///   - target: 요청의 원본 APIRequest (선택 사항)
    ///
    /// ## 예시
    ///
    /// ```swift
    /// func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
    ///     print("✅ Received: \(response.statusCode)")
    ///
    ///     // 성능 메트릭 수집
    ///     if let duration = response.metrics?.taskInterval.duration {
    ///         PerformanceMonitor.record(duration: duration, for: response.url)
    ///     }
    ///
    ///     // 에러 응답 추적
    ///     if response.statusCode >= 400 {
    ///         ErrorTracker.log(statusCode: response.statusCode, url: response.url)
    ///     }
    /// }
    /// ```
    func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async
}

// MARK: - Default Implementations

public extension RequestInterceptor {
    /// 기본 구현: 아무 작업도 수행하지 않음
    func prepare(_: inout URLRequest, target _: (any APIRequest)?) async throws {
        // 기본 구현은 비어 있음 (필요 시 오버라이드)
    }

    /// 기본 구현: 아무 작업도 수행하지 않음
    func willSend(_: URLRequest, target _: (any APIRequest)?) async {
        // 기본 구현은 비어 있음 (필요 시 오버라이드)
    }

    /// 기본 구현: 아무 작업도 수행하지 않음
    func didReceive(_: HTTPResponse, target _: (any APIRequest)?) async {
        // 기본 구현은 비어 있음 (필요 시 오버라이드)
    }
}

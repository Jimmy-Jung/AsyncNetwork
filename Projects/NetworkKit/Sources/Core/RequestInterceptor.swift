//
//  RequestInterceptor.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - RequestInterceptor Protocol

/// 네트워크 요청을 가로채서 수정하거나 전처리를 수행하는 프로토콜
///
/// **주요 용도:**
/// - 인증 토큰(OAuth) 주입
/// - 공통 HTTP 헤더 추가 (User-Agent, Device-ID 등)
/// - 요청 로깅 또는 트래킹 심기
///
/// **사용 예시:**
/// ```swift
/// struct AuthInterceptor: RequestInterceptor {
///     let tokenProvider: TokenProvider
///
///     func adapt(_ request: URLRequest) async throws -> URLRequest {
///         var request = request
///         let token = await tokenProvider.accessToken
///         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
///         return request
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {
    /// 요청을 전송하기 전에 수정합니다.
    /// - Parameter request: 원본 URLRequest
    /// - Returns: 수정된 URLRequest
    /// - Throws: 수정 중 발생한 에러 (예: 토큰 발급 실패)
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

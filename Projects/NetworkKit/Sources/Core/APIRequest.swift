//
//  APIRequest.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - APIRequest Protocol

/// API 요청을 나타내는 프로토콜
///
/// **설계 원칙:**
/// - 구현체는 사용처에서 정의 (NetworkKit은 프로토콜만 제공)
/// - 순수 Foundation 타입만 사용
/// - Sendable 지원
///
/// **사용 예시:**
/// ```swift
/// struct LoginRequest: APIRequest {
///     let baseURL: URL = URL(string: "https://api.example.com")!
///     let path: String = "/auth/login"
///     let method: HTTPMethod = .post
///     let task: HTTPTask = .requestJSONEncodable(LoginBody(username: "user", password: "pass"))
///     let headers: [String: String]? = ["Content-Type": "application/json"]
/// }
/// ```
public protocol APIRequest: Sendable {
    /// 베이스 URL
    var baseURL: URL { get }

    /// 엔드포인트 경로
    var path: String { get }

    /// HTTP 메서드
    var method: HTTPMethod { get }

    /// HTTP 태스크 (바디, 파라미터 등)
    var task: HTTPTask { get }

    /// HTTP 헤더
    var headers: [String: String]? { get }

    /// 타임아웃 (초)
    var timeout: TimeInterval { get }
}

// MARK: - Default Implementation

public extension APIRequest {
    /// 기본 타임아웃: 30초
    var timeout: TimeInterval { 30.0 }

    /// 기본 헤더: nil
    var headers: [String: String]? { nil }
}

// MARK: - URLRequest Conversion

extension APIRequest {
    /// APIRequest를 URLRequest로 변환
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        // 헤더 추가
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Task 적용
        try task.apply(to: &request)

        return request
    }
}

// MARK: - APIResponse Protocol

/// API 응답을 나타내는 프로토콜
///
/// **설계 원칙:**
/// - 사용처에서 Codable 구조체로 구현
/// - NetworkKit은 프로토콜만 제공
///
/// **사용 예시:**
/// ```swift
/// struct LoginResponse: APIResponse {
///     let token: String
///     let userId: String
///     let expiresAt: Date
/// }
/// ```
public protocol APIResponse: Codable, Sendable {}

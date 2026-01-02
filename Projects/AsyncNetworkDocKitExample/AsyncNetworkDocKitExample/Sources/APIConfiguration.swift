//
//  APIConfiguration.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/02.
//

import Foundation

/// API 전역 설정
///
/// 여러 서버의 baseURL을 중앙에서 관리합니다.
///
/// **사용법:**
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: APIConfiguration.jsonPlaceholder,  // 명시적으로 지정
///     path: "/posts",
///     method: "get"
/// )
/// struct GetPostsRequest {}
///
/// @APIRequest(
///     response: User.self,
///     baseURL: APIConfiguration.auth,  // 다른 서버 사용
///     path: "/users",
///     method: "get"
/// )
/// struct GetUsersRequest {}
/// ```
///
/// **장점:**
/// - 여러 서버의 baseURL을 한 곳에서 관리
/// - 각 API가 명시적으로 어느 서버를 사용하는지 명확
/// - 환경별(dev/staging/prod) 전환 용이
/// - 타입 안전성 (문자열 오타 방지)
enum APIConfiguration {
    // MARK: - Base URLs

    /// JSONPlaceholder API 서버
    static let jsonPlaceholder = "https://jsonplaceholder.typicode.com"

    /// 인증 서버 (예시)
    static let auth = "https://auth.example.com"

    /// 파일 서버 (예시)
    static let files = "https://files.example.com"

    // MARK: - Environment Management

    /// 환경별 설정
    enum Environment {
        case development
        case staging
        case production

        /// 환경별 JSONPlaceholder baseURL
        var jsonPlaceholder: String {
            switch self {
            case .development:
                return "https://dev.jsonplaceholder.typicode.com"
            case .staging:
                return "https://staging.jsonplaceholder.typicode.com"
            case .production:
                return "https://jsonplaceholder.typicode.com"
            }
        }

        /// 환경별 Auth baseURL
        var auth: String {
            switch self {
            case .development:
                return "https://dev-auth.example.com"
            case .staging:
                return "https://staging-auth.example.com"
            case .production:
                return "https://auth.example.com"
            }
        }

        /// 환경별 Files baseURL
        var files: String {
            switch self {
            case .development:
                return "https://dev-files.example.com"
            case .staging:
                return "https://staging-files.example.com"
            case .production:
                return "https://files.example.com"
            }
        }
    }

    /// 현재 환경 (기본값: production)
    ///
    /// App 시작 시 빌드 설정에 따라 변경:
    /// ```swift
    /// #if DEBUG
    /// APIConfiguration.currentEnvironment = .development
    /// #elseif STAGING
    /// APIConfiguration.currentEnvironment = .staging
    /// #else
    /// APIConfiguration.currentEnvironment = .production
    /// #endif
    /// ```
    static var currentEnvironment: Environment = .production

    /// 현재 환경에 맞는 baseURL 반환
    ///
    /// 환경별 baseURL을 동적으로 사용하고 싶을 때:
    /// ```swift
    /// @APIRequest(
    ///     response: [Post].self,
    ///     baseURL: APIConfiguration.url(for: .jsonPlaceholder),
    ///     path: "/posts",
    ///     method: "get"
    /// )
    /// ```
    static func url(for server: ServerType) -> String {
        switch server {
        case .jsonPlaceholder:
            return currentEnvironment.jsonPlaceholder
        case .auth:
            return currentEnvironment.auth
        case .files:
            return currentEnvironment.files
        }
    }

    /// 서버 타입
    enum ServerType {
        case jsonPlaceholder
        case auth
        case files
    }
}

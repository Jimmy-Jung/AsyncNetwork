import Foundation

/// API 요청을 나타내는 프로토콜
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
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: [String: String]? { get }
    var timeout: TimeInterval { get }
}

public extension APIRequest {
    var timeout: TimeInterval { 30.0 }
    var headers: [String: String]? { nil }
}

extension APIRequest {
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

/// API 응답을 나타내는 프로토콜
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

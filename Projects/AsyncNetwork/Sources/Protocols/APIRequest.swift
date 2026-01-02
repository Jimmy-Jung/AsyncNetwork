import Foundation

/// API 요청을 나타내는 프로토콜
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(
///     response: LoginResponse.self,
///     title: "사용자 로그인",
///     baseURL: "https://api.example.com",
///     path: "/auth/login",
///     method: .post
/// )
/// struct LoginRequest {
///     @RequestBody var body: LoginBody
/// }
///
/// // 사용
/// let request = LoginRequest(body: LoginBody(username: "user", password: "pass"))
/// let response: LoginResponse = try await networkService.request(request)
/// ```
public protocol APIRequest: Sendable {
    /// 응답 타입 정의
    /// - Note: 빈 응답의 경우 `EmptyResponse`를 사용하세요
    associatedtype Response: Decodable = EmptyResponse

    var baseURLString: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var timeout: TimeInterval { get }
}

public extension APIRequest {
    var timeout: TimeInterval { 30.0 }
    var headers: [String: String]? { nil }

    /// String을 URL로 변환
    var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            preconditionFailure("Invalid baseURL: \(baseURLString)")
        }
        return url
    }
}

public extension APIRequest {
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        // 정적 헤더 추가
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Property Wrapper들을 리플렉션으로 찾아서 적용
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }

            // Property Wrapper의 실제 이름 추출 (_를 제거)
            let propertyName = label.hasPrefix("_") ? String(label.dropFirst()) : label

            // RequestParameter 프로토콜을 채택한 Property Wrapper 찾기
            if let param = child.value as? RequestParameter {
                try param.apply(to: &request, key: propertyName)
            }
        }

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

/// 빈 응답을 나타내는 타입
///
/// **사용 예시:**
/// ```swift
/// struct LogoutRequest: APIRequest {
///     typealias Response = EmptyResponse
///     // ...
/// }
/// ```
public struct EmptyResponse: Codable, Sendable {
    public init() {}
}

import Foundation

/// 서버 응답을 감싸는 제네릭 래퍼
///
/// **사용 예시:**
/// ```swift
/// struct LoginResponse: APIResponse {
///     let result: String
///     let msg: String?
///     let data: LoginData?
/// }
///
/// struct LoginData: Codable {
///     let token: String
///     let userId: String
/// }
/// ```
public struct ServerResponse<T: Codable & Sendable>: APIResponse {
    public let result: String
    public let msg: String?
    public let data: T?

    public init(result: String, msg: String? = nil, data: T? = nil) {
        self.result = result
        self.msg = msg
        self.data = data
    }
}

public struct EmptyResponseDto: APIResponse {
    public init() {}
}

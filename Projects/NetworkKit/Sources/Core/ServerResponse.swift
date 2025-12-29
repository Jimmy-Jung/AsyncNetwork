//
//  ServerResponse.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - ServerResponse

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

// MARK: - EmptyResponseDto

/// 빈 응답을 나타내는 DTO
public struct EmptyResponseDto: APIResponse {
    public init() {}
}

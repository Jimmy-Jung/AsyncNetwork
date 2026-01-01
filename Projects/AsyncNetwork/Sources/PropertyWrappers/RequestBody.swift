//
//  RequestBody.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// Request body를 자동으로 JSON 인코딩
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(...)
/// struct CreatePostRequest {
///     @RequestBody var body: PostBody
/// }
///
/// struct PostBody: Codable, Sendable {
///     let title: String
///     let content: String
///     let userId: Int
/// }
///
/// let request = CreatePostRequest(body: PostBody(...))
/// // Content-Type: application/json 자동 설정
/// // body가 JSON으로 인코딩되어 httpBody에 설정됨
/// ```
@propertyWrapper
public struct RequestBody<Value: Encodable & Sendable>: RequestParameter {
    public var wrappedValue: Value?
    
    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    public func apply(to request: inout URLRequest, key: String) throws {
        guard let value = wrappedValue else { return }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(value)
        
        // Content-Type이 설정되지 않은 경우에만 설정
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}


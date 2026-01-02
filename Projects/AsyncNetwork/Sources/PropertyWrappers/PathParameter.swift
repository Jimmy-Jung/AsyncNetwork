//
//  PathParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// Path parameter를 자동으로 치환
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(
///     path: "/posts/{id}",
///     ...
/// )
/// struct GetPostByIdRequest {
///     @PathParameter var id: Int
/// }
///
/// let request = GetPostByIdRequest(id: 123)
/// // URL: /posts/123
/// ```
@propertyWrapper
public struct PathParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public func apply(to request: inout URLRequest, key: String) throws {
        guard let url = request.url else { return }

        let placeholder = "{\(key)}"
        let replaced = url.absoluteString.replacingOccurrences(
            of: placeholder,
            with: "\(wrappedValue)"
        )

        if let newURL = URL(string: replaced) {
            request.url = newURL
        }
    }
}

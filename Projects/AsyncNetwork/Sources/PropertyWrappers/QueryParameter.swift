//
//  QueryParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// Query string parameter를 자동으로 URLRequest에 추가
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(...)
/// struct GetPostsRequest {
///     @QueryParameter var userId: Int?
///     @QueryParameter var page: Int?
///     @QueryParameter(key: "_limit") var limit: Int?  // 커스텀 키 사용
/// }
///
/// let request = GetPostsRequest(userId: 1, page: 2, limit: 10)
/// // URL: /posts?userId=1&page=2&_limit=10
/// ```
@propertyWrapper
public struct QueryParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value?
    private let customKey: String?

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
        customKey = nil
    }

    public init(wrappedValue: Value? = nil, key: String) {
        self.wrappedValue = wrappedValue
        customKey = key
    }

    public func apply(to request: inout URLRequest, key: String) throws {
        guard let value = wrappedValue else { return }

        guard var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) else {
            return
        }

        var queryItems = components.queryItems ?? []
        let parameterKey = customKey ?? key
        queryItems.append(URLQueryItem(name: parameterKey, value: "\(value)"))
        components.queryItems = queryItems

        if let url = components.url {
            request.url = url
        }
    }
}

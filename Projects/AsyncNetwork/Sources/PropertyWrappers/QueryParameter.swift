//
//  QueryParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Query string parameter를 자동으로 URLRequest에 추가
///
/// Optional과 non-optional 값을 모두 지원합니다.
/// - Optional 타입: nil일 때 query string에 추가되지 않음
/// - Non-optional 타입: 항상 query string에 추가됨
///
/// ## 사용 예시
/// ```swift
/// @APIRequest(...)
/// struct GetUserPostsRequest {
///     @QueryParameter var userId: Int      // 필수 파라미터 (항상 추가)
///     @QueryParameter var page: Int?        // 옵셔널 파라미터 (nil이면 생략)
/// }
/// ```
@propertyWrapper
public struct QueryParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value?
    private let customKey: String?

    /// Optional 값을 받는 초기화자
    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
        customKey = nil
    }

    /// Optional 값을 받고 커스텀 키를 사용하는 초기화자
    public init(wrappedValue: Value? = nil, key: String) {
        self.wrappedValue = wrappedValue
        customKey = key
    }

    /// Non-optional 값을 받는 초기화자 (필수 파라미터용)
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        customKey = nil
    }

    /// Non-optional 값을 받고 커스텀 키를 사용하는 초기화자 (필수 파라미터용)
    public init(wrappedValue: Value, key: String) {
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

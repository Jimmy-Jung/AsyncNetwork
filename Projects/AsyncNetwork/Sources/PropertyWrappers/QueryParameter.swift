//
//  QueryParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Query string parameter를 자동으로 URLRequest에 추가
///
/// 타입 레벨에서 필수/비필수 파라미터를 구분합니다.
/// - Non-optional 타입: 필수 파라미터 (항상 query string에 추가)
/// - Optional 타입: 비필수 파라미터 (nil일 때 query string에 추가되지 않음)
///
/// ## 사용 예시
/// ```swift
/// @APIRequest(...)
/// struct GetUserPostsRequest {
///     @QueryParameter var userId: Int      // 필수 파라미터 (항상 추가)
///     @QueryParameter var page: Int?        // 비필수 파라미터 (nil이면 생략)
/// }
/// ```
@propertyWrapper
public struct QueryParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value
    private let customKey: String?

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
        // Optional인지 확인하고, Optional이면 nil 체크 및 값 추출
        let mirror = Mirror(reflecting: wrappedValue)
        let valueToAppend: String

        if mirror.displayStyle == .optional {
            // Optional 타입이고 nil인 경우 무시
            guard let firstChild = mirror.children.first else {
                return
            }
            // Optional의 래핑된 값 사용
            valueToAppend = "\(firstChild.value)"
        } else {
            // Non-optional 값 직접 사용
            valueToAppend = "\(wrappedValue)"
        }

        guard var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) else {
            return
        }

        var queryItems = components.queryItems ?? []
        let parameterKey = customKey ?? key
        queryItems.append(URLQueryItem(name: parameterKey, value: valueToAppend))
        components.queryItems = queryItems

        if let url = components.url {
            request.url = url
        }
    }
}

// MARK: - Optional Support

/// Optional 타입 전용 extension (비필수 파라미터용)
public extension QueryParameter {
    /// Optional 값을 받는 초기화자 (비필수 파라미터용)
    init<Wrapped>(wrappedValue: Wrapped? = nil) where Value == Wrapped? {
        self.wrappedValue = wrappedValue
        customKey = nil
    }

    /// Optional 값을 받고 커스텀 키를 사용하는 초기화자 (비필수 파라미터용)
    init<Wrapped>(wrappedValue: Wrapped? = nil, key: String) where Value == Wrapped? {
        self.wrappedValue = wrappedValue
        customKey = key
    }
}

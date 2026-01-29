//
//  HeaderField.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

// MARK: - HeaderField

/// HTTPHeaders.HeaderKey를 활용한 타입 안전한 헤더 관리
///
/// 타입 레벨에서 필수/비필수 헤더를 구분합니다.
/// - Non-optional 타입: 필수 헤더 (항상 추가)
/// - Optional 타입: 비필수 헤더 (nil일 때 추가되지 않음)
///
/// ## 사용 예시
/// ```swift
/// @APIRequest(...)
/// struct CreatePostRequest {
///     @HeaderField(key: .authorization) var authorization: String?     // 비필수 헤더
///     @HeaderField(key: .contentType) var contentType: String = "application/json"  // 필수 헤더 + 기본값
///
///     init(authorization: String?, contentType: String = "application/json") {
///         self.authorization = authorization
///         self.contentType = contentType
///     }
/// }
/// ```
@propertyWrapper
public struct HeaderField<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value
    public var projectedValue: HeaderField<Value> { self }
    private let key: HTTPHeaders.HeaderKey

    /// Non-optional 값을 받는 초기화자 (필수 헤더용)
    public init(wrappedValue: Value, key: HTTPHeaders.HeaderKey) {
        self.wrappedValue = wrappedValue
        self.key = key
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        // Optional인지 확인하고, Optional이면 nil 체크 및 값 추출
        let mirror = Mirror(reflecting: wrappedValue)

        if mirror.displayStyle == .optional {
            // Optional 타입이고 nil인 경우 무시
            guard let firstChild = mirror.children.first else {
                return
            }
            // Optional의 래핑된 값 사용
            request.setValue("\(firstChild.value)", forHTTPHeaderField: key.rawValue)
        } else {
            // Non-optional 값 직접 사용
            request.setValue("\(wrappedValue)", forHTTPHeaderField: key.rawValue)
        }
    }
}

// MARK: - Optional Support

/// Optional 타입 전용 extension (비필수 헤더용)
public extension HeaderField {
    /// Optional 값을 받는 초기화자 (비필수 헤더용)
    init<Wrapped>(wrappedValue: Wrapped? = nil, key: HTTPHeaders.HeaderKey) where Value == Wrapped? {
        self.wrappedValue = wrappedValue
        self.key = key
    }
}

// MARK: - CustomHeader

/// 커스텀 헤더용 (HTTPHeaders.HeaderKey에 없는 경우)
///
/// ## 사용 예시
/// ```swift
/// @APIRequest(...)
/// struct CustomRequest {
///     @CustomHeader("X-Custom-Header") var customValue: String?
///     @CustomHeader("X-API-Version") var apiVersion: String = "1.0"
///
///     init(customValue: String?, apiVersion: String = "1.0") {
///         self.customValue = customValue
///         self.apiVersion = apiVersion
///     }
/// }
/// ```
@propertyWrapper
public struct CustomHeader<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value
    public var projectedValue: CustomHeader<Value> { self }
    private let headerName: String

    /// Non-optional 값을 받는 초기화자 (필수 헤더용)
    public init(wrappedValue: Value, _ headerName: String) {
        self.wrappedValue = wrappedValue
        self.headerName = headerName
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        // Optional인지 확인하고, Optional이면 nil 체크 및 값 추출
        let mirror = Mirror(reflecting: wrappedValue)

        if mirror.displayStyle == .optional {
            // Optional 타입이고 nil인 경우 무시
            guard let firstChild = mirror.children.first else {
                return
            }
            // Optional의 래핑된 값 사용
            request.setValue("\(firstChild.value)", forHTTPHeaderField: headerName)
        } else {
            // Non-optional 값 직접 사용
            request.setValue("\(wrappedValue)", forHTTPHeaderField: headerName)
        }
    }
}

// MARK: - Optional Support

/// Optional 타입 전용 extension (비필수 헤더용)
public extension CustomHeader {
    /// Optional 값을 받는 초기화자 (비필수 헤더용)
    init<Wrapped>(wrappedValue: Wrapped? = nil, _ headerName: String) where Value == Wrapped? {
        self.wrappedValue = wrappedValue
        self.headerName = headerName
    }
}

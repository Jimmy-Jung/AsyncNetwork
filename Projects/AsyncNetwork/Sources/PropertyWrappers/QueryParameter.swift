//
//  QueryParameter.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

// MARK: - DefaultInitializable Protocol

/// Property wrapper 초기화 시 기본값을 제공하는 프로토콜
///
/// 커스텀 타입을 `@QueryParameter(key: "...")`로 사용하려면 이 프로토콜을 구현하세요.
///
/// ## 커스텀 타입 예시
/// ```swift
/// enum Status: String, Sendable, DefaultInitializable {
///     case active
///     case inactive
///
///     static var defaultValue: Status { .active }
/// }
///
/// struct Request: APIRequest {
///     @QueryParameter(key: "status") var status: Status
/// }
/// ```
public protocol DefaultInitializable {
    /// 타입의 기본값 (property 선언에서 key만 지정할 때 사용)
    static var defaultValue: Self { get }
}

extension Int: DefaultInitializable {
    public static var defaultValue: Int { 0 }
}

extension String: DefaultInitializable {
    public static var defaultValue: String { "" }
}

extension Bool: DefaultInitializable {
    public static var defaultValue: Bool { false }
}

extension Double: DefaultInitializable {
    public static var defaultValue: Double { 0.0 }
}

extension Float: DefaultInitializable {
    public static var defaultValue: Float { 0.0 }
}

extension Int8: DefaultInitializable {
    public static var defaultValue: Int8 { 0 }
}

extension Int16: DefaultInitializable {
    public static var defaultValue: Int16 { 0 }
}

extension Int32: DefaultInitializable {
    public static var defaultValue: Int32 { 0 }
}

extension Int64: DefaultInitializable {
    public static var defaultValue: Int64 { 0 }
}

extension UInt: DefaultInitializable {
    public static var defaultValue: UInt { 0 }
}

extension UInt8: DefaultInitializable {
    public static var defaultValue: UInt8 { 0 }
}

extension UInt16: DefaultInitializable {
    public static var defaultValue: UInt16 { 0 }
}

extension UInt32: DefaultInitializable {
    public static var defaultValue: UInt32 { 0 }
}

extension UInt64: DefaultInitializable {
    public static var defaultValue: UInt64 { 0 }
}

// MARK: - QueryParameter

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
///     @QueryParameter var userId: Int                     // 필수 파라미터 (항상 추가)
///     @QueryParameter var page: Int?                      // 비필수 파라미터 (nil이면 생략)
///     @QueryParameter(key: "_limit") var limit: Int?      // Optional + 커스텀 키
///     @QueryParameter(key: "user_id") var id: Int         // Non-optional + 커스텀 키
///
///     init(userId: Int, page: Int? = nil, limit: Int? = nil, id: Int) {
///         self.userId = userId
///         self.page = page
///         self.limit = limit
///         self.id = id
///     }
/// }
/// ```
///
/// ## 커스텀 키 사용 방법
/// ### 1. Optional 타입: Property 선언에서 지정 가능
/// ```swift
/// @QueryParameter(key: "per_page") var itemsPerPage: Int?
/// ```
///
/// ### 2. Non-optional 타입: Property 선언에서 지정 가능 (기본값 자동 설정)
/// ```swift
/// @QueryParameter(key: "user_id") var userId: Int
///
/// init(userId: Int) {
///     self.userId = userId  // 기본값(0)에서 실제 값으로 업데이트
/// }
/// ```
///
/// ### 3. 커스텀 타입 지원: `DefaultInitializable` 프로토콜 구현
/// ```swift
/// enum SortOrder: String, Sendable, DefaultInitializable {
///     case asc, desc
///     static var defaultValue: SortOrder { .asc }
/// }
///
/// struct Request: APIRequest {
///     @QueryParameter(key: "sort") var sortOrder: SortOrder
///
///     init(sortOrder: SortOrder) {
///         self.sortOrder = sortOrder
///     }
/// }
/// ```
///
/// ### 4. 복잡한 타입: Initializer에서 직접 설정 (fallback)
/// ```swift
/// struct CustomType: Sendable { /* ... */ }
///
/// struct Request: APIRequest {
///     @QueryParameter var custom: CustomType
///
///     init(custom: CustomType) {
///         // Property wrapper를 직접 초기화
///         self._custom = QueryParameter(wrappedValue: custom, key: "custom_key")
///     }
/// }
/// ```
///
/// - Note: 기본 지원 타입: Int, String, Bool, Double, Float 및 모든 정수 타입 (Int8, Int16, Int32, Int64, UInt 등)
@propertyWrapper
public struct QueryParameter<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value
    public var projectedValue: QueryParameter<Value> { self }
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

    /// Property 선언에서 커스텀 키만 지정하는 초기화자 (Non-optional 타입용)
    /// @QueryParameter(key: "user_id") var userId: Int 형태로 사용 가능
    /// - Note: DefaultInitializable 프로토콜을 준수하는 타입만 사용 가능 (Int, String, Bool 등)
    public init(key: String) where Value: DefaultInitializable {
        wrappedValue = Value.defaultValue
        customKey = key
    }

    public func apply(to request: inout URLRequest, key: String) throws {
        guard var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) else {
            return
        }

        var queryItems = components.queryItems ?? []
        let parameterKey = customKey ?? key

        // Optional인지 확인하고, Optional이면 nil 체크 및 값 추출
        let mirror = Mirror(reflecting: wrappedValue)

        if mirror.displayStyle == .optional {
            // Optional 타입이고 nil인 경우 무시
            guard let firstChild = mirror.children.first else {
                return
            }

            // Optional의 래핑된 값 확인
            let unwrappedValue = firstChild.value
            let unwrappedMirror = Mirror(reflecting: unwrappedValue)

            // 배열인지 확인
            if unwrappedMirror.displayStyle == .collection {
                // 배열의 각 요소를 개별 쿼리 파라미터로 추가
                for child in unwrappedMirror.children {
                    let elementValue = "\(child.value)"
                    queryItems.append(URLQueryItem(name: parameterKey, value: elementValue))
                }
            } else {
                // 배열이 아닌 경우 기존 로직
                let valueToAppend = "\(unwrappedValue)"
                queryItems.append(URLQueryItem(name: parameterKey, value: valueToAppend))
            }
        } else {
            // Non-optional 값 처리
            let nonOptionalMirror = Mirror(reflecting: wrappedValue)

            // 배열인지 확인
            if nonOptionalMirror.displayStyle == .collection {
                // 배열의 각 요소를 개별 쿼리 파라미터로 추가
                for child in nonOptionalMirror.children {
                    let elementValue = "\(child.value)"
                    queryItems.append(URLQueryItem(name: parameterKey, value: elementValue))
                }
            } else {
                // 배열이 아닌 경우 기존 로직
                let valueToAppend = "\(wrappedValue)"
                queryItems.append(URLQueryItem(name: parameterKey, value: valueToAppend))
            }
        }

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

    /// Property 선언에서 커스텀 키만 지정하는 초기화자
    /// @QueryParameter(key: "_limit") var limit: Int? 형태로 사용 가능
    init<Wrapped>(key: String) where Value == Wrapped? {
        wrappedValue = nil
        customKey = key
    }
}

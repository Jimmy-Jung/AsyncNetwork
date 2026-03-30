//
//  RequestBody.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// Request body를 자동으로 JSON 인코딩
///
/// 타입 레벨에서 필수/비필수 body를 구분합니다.
/// - Non-optional 타입: 필수 body (항상 인코딩)
/// - Optional 타입: 비필수 body (nil일 때 httpBody를 설정하지 않음)
///
/// ## 사용 예시
/// ```swift
/// @APIRequest(...)
/// struct UpdateUserRequest {
///     @RequestBody var body: UserBody       // 필수 body (항상 인코딩)
/// }
///
/// @APIRequest(...)
/// struct OptionalUpdateRequest {
///     @RequestBody var body: UserBody?      // 비필수 body (nil이면 생략)
/// }
/// ```
@propertyWrapper
public struct RequestBody<Value: Encodable & Sendable>: RequestParameter {
    public var wrappedValue: Value

    /// Non-optional 값을 받는 초기화자 (필수 body용)
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        // Mirror를 사용하여 Optional 타입 체크
        let mirror = Mirror(reflecting: wrappedValue)

        if mirror.displayStyle == .optional {
            // Optional 타입이고 nil인 경우 무시
            guard mirror.children.first != nil else {
                return
            }
        }

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(wrappedValue)

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

// MARK: - Optional Support

/// Optional 타입 전용 extension (비필수 body용)
public extension RequestBody {
    /// Optional 값을 받는 초기화자 (비필수 body용)
    init<Wrapped>(wrappedValue: Wrapped? = nil) where Value == Wrapped?, Wrapped: Encodable & Sendable {
        self.wrappedValue = wrappedValue
    }
}

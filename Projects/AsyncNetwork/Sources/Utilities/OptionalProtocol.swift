//
//  OptionalProtocol.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/07.
//

import Foundation

/// Optional 타입을 감지하고 nil 여부를 확인하기 위한 프로토콜
///
/// Property Wrapper에서 제네릭 타입이 Optional인지 확인하고
/// nil 값을 처리할 때 사용됩니다.
///
/// ## 사용 예시
/// ```swift
/// func process<T>(_ value: T) {
///     if let optional = value as? (any OptionalProtocol),
///        optional.isNil {
///         // nil 처리
///         return
///     }
///     // non-nil 처리
/// }
/// ```
public protocol OptionalProtocol {
    /// Optional 값이 nil인지 확인
    var isNil: Bool { get }
    
    /// Optional의 wrapped value를 Any로 반환
    var wrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
    public var isNil: Bool {
        self == nil
    }
    
    public var wrappedValue: Any? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped
        }
    }
}


//
//  TestHelpers.swift
//  AsyncNetwork Tests
//
//  Created by jimmy on 2026/01/13.
//

import Foundation

// MARK: - Sendable Helpers

/// Sendable-safe mutable container for test scenarios
///
/// 테스트에서 동기 클로저 내에서 비동기 값을 안전하게 캡처하기 위해 사용합니다.
///
/// ## 사용 예시
/// ```swift
/// let countBox = Box(value: 0)
/// Task {
///     countBox.value = await someAsyncOperation()
/// }
/// ```
public final class Box<T>: @unchecked Sendable {
    public var value: T

    public init(value: T) {
        self.value = value
    }
}

//
//  ValueGenerationStrategy.swift
//  AsyncNetworkCore
//
//  Created by jimmy on 2026/02/03.
//

import Foundation

/// 값 생성 전략 프로토콜
///
/// 테스트 데이터 생성 시 사용되는 전략을 정의합니다.
/// 랜덤 생성, 고정값(Fixture) 생성 등 다양한 전략을 구현할 수 있습니다.
public protocol ValueGenerationStrategy {
    mutating func generateInt(range: ClosedRange<Int>) -> Int
    mutating func generateInt8(range: ClosedRange<Int8>) -> Int8
    mutating func generateInt16(range: ClosedRange<Int16>) -> Int16
    mutating func generateInt32(range: ClosedRange<Int32>) -> Int32
    mutating func generateInt64(range: ClosedRange<Int64>) -> Int64
    mutating func generateUInt(range: ClosedRange<UInt>) -> UInt
    mutating func generateUInt8(range: ClosedRange<UInt8>) -> UInt8
    mutating func generateUInt16(range: ClosedRange<UInt16>) -> UInt16
    mutating func generateUInt32(range: ClosedRange<UInt32>) -> UInt32
    mutating func generateUInt64(range: ClosedRange<UInt64>) -> UInt64
    mutating func generateDouble(range: ClosedRange<Double>) -> Double
    mutating func generateFloat(range: ClosedRange<Float>) -> Float
    mutating func generateBool() -> Bool
    mutating func generateDate() -> Date
    mutating func generateUUID() -> UUID
    mutating func generateString(prefix: String) -> String
}

extension ValueGenerationStrategy {
    // 기본 구현 제공 (필요 시 오버라이드)
    public mutating func generateString(prefix: String) -> String {
        "\(prefix) \(generateUUID().uuidString.prefix(8))"
    }
}

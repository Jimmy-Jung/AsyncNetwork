//
//  FixtureStrategy.swift
//  AsyncNetworkCore
//
//  Created by jimmy on 2026/02/03.
//

import Foundation

/// 고정값(Fixture) 생성 전략
///
/// 항상 동일한 값을 반환하는 전략입니다.
/// 테스트 데이터의 일관성을 보장하며, 예측 가능한 값이 필요한 경우 사용합니다.
public struct FixtureStrategy: ValueGenerationStrategy {
    /// 옵셔널 처리 전략
    public enum OptionalStrategy {
        case alwaysPresent  // 항상 값 생성
        case alwaysNil      // 항상 nil
    }
    
    /// Enum 처리 전략
    public enum EnumStrategy {
        case firstCase   // 첫 번째 케이스 선택
        case lastCase    // 마지막 케이스 선택
    }
    
    private let optionalStrategy: OptionalStrategy
    private let enumStrategy: EnumStrategy
    
    /// 초기화
    /// - Parameters:
    ///   - optionalStrategy: 옵셔널 필드 처리 전략
    ///   - enumStrategy: Enum 타입 처리 전략
    public init(
        optionalStrategy: OptionalStrategy = .alwaysPresent,
        enumStrategy: EnumStrategy = .firstCase
    ) {
        self.optionalStrategy = optionalStrategy
        self.enumStrategy = enumStrategy
    }
    
    // MARK: - Fixed Values
    
    public mutating func generateInt(range: ClosedRange<Int>) -> Int {
        range.lowerBound
    }
    
    public mutating func generateInt8(range: ClosedRange<Int8>) -> Int8 {
        range.lowerBound
    }
    
    public mutating func generateInt16(range: ClosedRange<Int16>) -> Int16 {
        range.lowerBound
    }
    
    public mutating func generateInt32(range: ClosedRange<Int32>) -> Int32 {
        range.lowerBound
    }
    
    public mutating func generateInt64(range: ClosedRange<Int64>) -> Int64 {
        range.lowerBound
    }
    
    public mutating func generateUInt(range: ClosedRange<UInt>) -> UInt {
        range.lowerBound
    }
    
    public mutating func generateUInt8(range: ClosedRange<UInt8>) -> UInt8 {
        range.lowerBound
    }
    
    public mutating func generateUInt16(range: ClosedRange<UInt16>) -> UInt16 {
        range.lowerBound
    }
    
    public mutating func generateUInt32(range: ClosedRange<UInt32>) -> UInt32 {
        range.lowerBound
    }
    
    public mutating func generateUInt64(range: ClosedRange<UInt64>) -> UInt64 {
        range.lowerBound
    }
    
    public mutating func generateDouble(range: ClosedRange<Double>) -> Double {
        range.lowerBound
    }
    
    public mutating func generateFloat(range: ClosedRange<Float>) -> Float {
        range.lowerBound
    }
    
    public mutating func generateBool() -> Bool {
        true
    }
    
    public mutating func generateDate() -> Date {
        // 고정된 날짜: 2024-01-01 00:00:00 UTC
        Date(timeIntervalSince1970: 1704067200)
    }
    
    public mutating func generateUUID() -> UUID {
        // 고정된 UUID (테스트용)
        UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
    }
    
    public mutating func generateString(prefix: String) -> String {
        "\(prefix)_fixture"
    }
}

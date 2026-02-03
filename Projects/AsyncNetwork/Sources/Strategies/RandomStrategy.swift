//
//  RandomStrategy.swift
//  AsyncNetworkCore
//
//  Created by jimmy on 2026/02/03.
//

import Foundation

/// 랜덤 값 생성 전략
///
/// 시드(Seed)를 지원하여 결정론적(Deterministic) 랜덤 생성을 지원합니다.
public struct RandomStrategy: ValueGenerationStrategy {
    private var generator: AnyRandomNumberGenerator
    
    /// 시드 기반 초기화
    /// - Parameter seed: 랜덤 시드 값 (옵셔널). nil이면 시스템 랜덤 사용.
    public init(seed: Int? = nil) {
        if let seed = seed {
            self.generator = AnyRandomNumberGenerator(SeededRandomNumberGenerator(seed: seed))
        } else {
            self.generator = AnyRandomNumberGenerator(SystemRandomNumberGenerator())
        }
    }
    
    public mutating func generateInt(range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }
    
    public mutating func generateInt8(range: ClosedRange<Int8>) -> Int8 {
        Int8.random(in: range, using: &generator)
    }
    
    public mutating func generateInt16(range: ClosedRange<Int16>) -> Int16 {
        Int16.random(in: range, using: &generator)
    }
    
    public mutating func generateInt32(range: ClosedRange<Int32>) -> Int32 {
        Int32.random(in: range, using: &generator)
    }
    
    public mutating func generateInt64(range: ClosedRange<Int64>) -> Int64 {
        Int64.random(in: range, using: &generator)
    }
    
    public mutating func generateUInt(range: ClosedRange<UInt>) -> UInt {
        UInt.random(in: range, using: &generator)
    }
    
    public mutating func generateUInt8(range: ClosedRange<UInt8>) -> UInt8 {
        UInt8.random(in: range, using: &generator)
    }
    
    public mutating func generateUInt16(range: ClosedRange<UInt16>) -> UInt16 {
        UInt16.random(in: range, using: &generator)
    }
    
    public mutating func generateUInt32(range: ClosedRange<UInt32>) -> UInt32 {
        UInt32.random(in: range, using: &generator)
    }
    
    public mutating func generateUInt64(range: ClosedRange<UInt64>) -> UInt64 {
        UInt64.random(in: range, using: &generator)
    }
    
    public mutating func generateDouble(range: ClosedRange<Double>) -> Double {
        Double.random(in: range, using: &generator)
    }
    
    public mutating func generateFloat(range: ClosedRange<Float>) -> Float {
        Float.random(in: range, using: &generator)
    }
    
    public mutating func generateBool() -> Bool {
        Bool.random(using: &generator)
    }
    
    public mutating func generateDate() -> Date {
        Date(timeIntervalSince1970: Double.random(in: 0...1_700_000_000, using: &generator))
    }
    
    public mutating func generateUUID() -> UUID {
        // UUID는 RandomNumberGenerator를 직접 지원하지 않으므로,
        // 난수 생성기에서 128비트를 추출하여 UUID 생성
        let byte1 = UInt64.random(in: UInt64.min...UInt64.max, using: &generator)
        let byte2 = UInt64.random(in: UInt64.min...UInt64.max, using: &generator)
        
        // UUID v4 format adjustments
        // Set version to 4
        let uuid1 = (byte1 & 0xFFFFFFFFFFFF0FFF) | 0x0000000000004000
        // Set variant to 10xx
        let uuid2 = (byte2 & 0x3FFFFFFFFFFFFFFF) | 0x8000000000000000
        
        let uuidString = String(format: "%016X%016X", uuid1, uuid2)
        // Insert hyphens: 8-4-4-4-12
        let p1 = uuidString.prefix(8)
        let p2 = uuidString.dropFirst(8).prefix(4)
        let p3 = uuidString.dropFirst(12).prefix(4)
        let p4 = uuidString.dropFirst(16).prefix(4)
        let p5 = uuidString.dropFirst(20)
        
        return UUID(uuidString: "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)") ?? UUID()
    }
}

/// Type Eraser for RandomNumberGenerator
private struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private var _next: () -> UInt64
    
    init<G: RandomNumberGenerator>(_ generator: G) {
        var generator = generator
        _next = { generator.next() }
    }
    
    mutating func next() -> UInt64 {
        _next()
    }
}

//
//  FixtureStrategyTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/02/03.
//

import Testing
import Foundation
@testable import AsyncNetworkCore

@Suite("FixtureStrategy 테스트")
struct FixtureStrategyTests {
    
    @Test("고정된 정수 값 생성")
    func testGenerateInt() {
        var strategy = FixtureStrategy()
        
        let value1 = strategy.generateInt(range: 0...100)
        let value2 = strategy.generateInt(range: 0...100)
        
        // 항상 lowerBound 반환
        #expect(value1 == 0)
        #expect(value2 == 0)
        #expect(value1 == value2)
    }
    
    @Test("고정된 Bool 값 생성")
    func testGenerateBool() {
        var strategy = FixtureStrategy()
        
        let value1 = strategy.generateBool()
        let value2 = strategy.generateBool()
        
        // 항상 true 반환
        #expect(value1 == true)
        #expect(value2 == true)
    }
    
    @Test("고정된 Date 값 생성")
    func testGenerateDate() {
        var strategy = FixtureStrategy()
        
        let date1 = strategy.generateDate()
        let date2 = strategy.generateDate()
        
        // 항상 동일한 날짜 반환 (2024-01-01 00:00:00 UTC)
        #expect(date1 == date2)
        #expect(date1.timeIntervalSince1970 == 1704067200)
    }
    
    @Test("고정된 UUID 값 생성")
    func testGenerateUUID() {
        var strategy = FixtureStrategy()
        
        let uuid1 = strategy.generateUUID()
        let uuid2 = strategy.generateUUID()
        
        // 항상 동일한 UUID 반환
        #expect(uuid1 == uuid2)
        #expect(uuid1.uuidString == "00000000-0000-0000-0000-000000000000")
    }
    
    @Test("고정된 String 값 생성")
    func testGenerateString() {
        var strategy = FixtureStrategy()
        
        let string1 = strategy.generateString(prefix: "test")
        let string2 = strategy.generateString(prefix: "test")
        
        // 항상 동일한 문자열 반환
        #expect(string1 == string2)
        #expect(string1 == "test_fixture")
    }
    
    @Test("고정된 Double 값 생성")
    func testGenerateDouble() {
        var strategy = FixtureStrategy()
        
        let value1 = strategy.generateDouble(range: 0.0...100.0)
        let value2 = strategy.generateDouble(range: 0.0...100.0)
        
        // 항상 lowerBound 반환
        #expect(value1 == 0.0)
        #expect(value2 == 0.0)
    }
    
    @Test("고정된 Float 값 생성")
    func testGenerateFloat() {
        var strategy = FixtureStrategy()
        
        let value1 = strategy.generateFloat(range: 0.0...100.0)
        let value2 = strategy.generateFloat(range: 0.0...100.0)
        
        // 항상 lowerBound 반환
        #expect(value1 == 0.0)
        #expect(value2 == 0.0)
    }
    
    @Test("다양한 정수 타입 고정값 생성")
    func testGenerateIntegerTypes() {
        var strategy = FixtureStrategy()
        
        #expect(strategy.generateInt8(range: 0...127) == 0)
        #expect(strategy.generateInt16(range: 0...1000) == 0)
        #expect(strategy.generateInt32(range: 0...100000) == 0)
        #expect(strategy.generateInt64(range: 0...1000000) == 0)
        
        #expect(strategy.generateUInt(range: 0...100) == 0)
        #expect(strategy.generateUInt8(range: 0...255) == 0)
        #expect(strategy.generateUInt16(range: 0...1000) == 0)
        #expect(strategy.generateUInt32(range: 0...100000) == 0)
        #expect(strategy.generateUInt64(range: 0...1000000) == 0)
    }
    
    @Test("범위가 다른 경우에도 lowerBound 반환")
    func testDifferentRanges() {
        var strategy = FixtureStrategy()
        
        #expect(strategy.generateInt(range: 10...20) == 10)
        #expect(strategy.generateInt(range: 100...200) == 100)
        #expect(strategy.generateInt(range: -50...50) == -50)
        
        #expect(strategy.generateDouble(range: 5.0...10.0) == 5.0)
        #expect(strategy.generateDouble(range: -10.0...10.0) == -10.0)
    }
}

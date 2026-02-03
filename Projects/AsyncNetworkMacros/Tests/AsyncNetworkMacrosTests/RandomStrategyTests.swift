//
//  RandomStrategyTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/02/03.
//

import Testing
import Foundation
@testable import AsyncNetworkCore

@Suite("RandomStrategy 테스트 - 결정론적 랜덤 생성")
struct RandomStrategyTests {
    
    @Test("동일한 시드로 동일한 정수 생성")
    func testDeterministicIntGeneration() {
        var strategy1 = RandomStrategy(seed: 42)
        var strategy2 = RandomStrategy(seed: 42)
        
        let value1 = strategy1.generateInt(range: 0...100)
        let value2 = strategy2.generateInt(range: 0...100)
        
        #expect(value1 == value2, "동일한 시드에서는 동일한 값이 생성되어야 합니다")
    }
    
    @Test("다른 시드로 다른 정수 생성")
    func testDifferentSeedsDifferentValues() {
        var strategy1 = RandomStrategy(seed: 42)
        var strategy2 = RandomStrategy(seed: 999)
        
        let value1 = strategy1.generateInt(range: 0...100)
        let value2 = strategy2.generateInt(range: 0...100)
        
        // 대부분의 경우 다른 값이 생성되어야 함
        #expect(value1 != value2, "다른 시드에서는 다른 값이 생성되어야 합니다")
    }
    
    @Test("동일한 시드로 동일한 시퀀스 생성")
    func testDeterministicSequence() {
        var strategy1 = RandomStrategy(seed: 12345)
        var strategy2 = RandomStrategy(seed: 12345)
        
        // 10개의 값 시퀀스 생성
        var sequence1: [Int] = []
        var sequence2: [Int] = []
        
        for _ in 0..<10 {
            sequence1.append(strategy1.generateInt(range: 0...1000))
            sequence2.append(strategy2.generateInt(range: 0...1000))
        }
        
        #expect(sequence1 == sequence2, "동일한 시드는 동일한 시퀀스를 생성해야 합니다")
    }
    
    @Test("동일한 시드로 동일한 Bool 생성")
    func testDeterministicBoolGeneration() {
        var strategy1 = RandomStrategy(seed: 777)
        var strategy2 = RandomStrategy(seed: 777)
        
        var bools1: [Bool] = []
        var bools2: [Bool] = []
        
        for _ in 0..<20 {
            bools1.append(strategy1.generateBool())
            bools2.append(strategy2.generateBool())
        }
        
        #expect(bools1 == bools2, "동일한 시드는 동일한 Bool 시퀀스를 생성해야 합니다")
    }
    
    @Test("동일한 시드로 동일한 Date 생성")
    func testDeterministicDateGeneration() {
        var strategy1 = RandomStrategy(seed: 555)
        var strategy2 = RandomStrategy(seed: 555)
        
        let date1 = strategy1.generateDate()
        let date2 = strategy2.generateDate()
        
        #expect(date1 == date2, "동일한 시드는 동일한 Date를 생성해야 합니다")
    }
    
    @Test("동일한 시드로 동일한 UUID 생성")
    func testDeterministicUUIDGeneration() {
        var strategy1 = RandomStrategy(seed: 888)
        var strategy2 = RandomStrategy(seed: 888)
        
        let uuid1 = strategy1.generateUUID()
        let uuid2 = strategy2.generateUUID()
        
        #expect(uuid1 == uuid2, "동일한 시드는 동일한 UUID를 생성해야 합니다")
    }
    
    @Test("동일한 시드로 동일한 String 생성")
    func testDeterministicStringGeneration() {
        var strategy1 = RandomStrategy(seed: 333)
        var strategy2 = RandomStrategy(seed: 333)
        
        let string1 = strategy1.generateString(prefix: "test")
        let string2 = strategy2.generateString(prefix: "test")
        
        #expect(string1 == string2, "동일한 시드는 동일한 String을 생성해야 합니다")
    }
    
    @Test("시드 없이 사용 시 시스템 랜덤 사용")
    func testSystemRandomWithoutSeed() {
        var strategy1 = RandomStrategy()
        var strategy2 = RandomStrategy()
        
        var sequence1: [Int] = []
        var sequence2: [Int] = []
        
        for _ in 0..<10 {
            sequence1.append(strategy1.generateInt(range: 0...1000))
            sequence2.append(strategy2.generateInt(range: 0...1000))
        }
        
        // 시드가 없으면 대부분의 경우 다른 시퀀스가 생성됨
        let allEqual = sequence1 == sequence2
        #expect(!allEqual, "시드 없이는 다른 시퀀스가 생성되어야 합니다 (확률적)")
    }
    
    @Test("다양한 정수 타입의 결정론적 생성")
    func testDeterministicIntegerTypes() {
        var strategy1 = RandomStrategy(seed: 111)
        var strategy2 = RandomStrategy(seed: 111)
        
        #expect(strategy1.generateInt8(range: 0...127) == strategy2.generateInt8(range: 0...127))
        #expect(strategy1.generateInt16(range: 0...1000) == strategy2.generateInt16(range: 0...1000))
        #expect(strategy1.generateInt32(range: 0...100000) == strategy2.generateInt32(range: 0...100000))
        #expect(strategy1.generateInt64(range: 0...1000000) == strategy2.generateInt64(range: 0...1000000))
        
        #expect(strategy1.generateUInt(range: 0...100) == strategy2.generateUInt(range: 0...100))
        #expect(strategy1.generateUInt8(range: 0...255) == strategy2.generateUInt8(range: 0...255))
        #expect(strategy1.generateUInt16(range: 0...1000) == strategy2.generateUInt16(range: 0...1000))
        #expect(strategy1.generateUInt32(range: 0...100000) == strategy2.generateUInt32(range: 0...100000))
        #expect(strategy1.generateUInt64(range: 0...1000000) == strategy2.generateUInt64(range: 0...1000000))
    }
    
    @Test("Double과 Float의 결정론적 생성")
    func testDeterministicFloatingPointTypes() {
        var strategy1 = RandomStrategy(seed: 222)
        var strategy2 = RandomStrategy(seed: 222)
        
        let double1 = strategy1.generateDouble(range: 0.0...100.0)
        let double2 = strategy2.generateDouble(range: 0.0...100.0)
        #expect(double1 == double2)
        
        let float1 = strategy1.generateFloat(range: 0.0...100.0)
        let float2 = strategy2.generateFloat(range: 0.0...100.0)
        #expect(float1 == float2)
    }
    
    @Test("범위 내 값 생성 검증")
    func testValuesWithinRange() {
        var strategy = RandomStrategy(seed: 999)
        
        // 100번 생성하여 모두 범위 내인지 확인
        for _ in 0..<100 {
            let value = strategy.generateInt(range: 10...20)
            #expect(value >= 10 && value <= 20, "생성된 값이 범위 내에 있어야 합니다")
        }
        
        for _ in 0..<100 {
            let value = strategy.generateDouble(range: 0.0...1.0)
            #expect(value >= 0.0 && value <= 1.0, "생성된 값이 범위 내에 있어야 합니다")
        }
    }
    
    @Test("음수 범위 처리")
    func testNegativeRange() {
        var strategy1 = RandomStrategy(seed: 444)
        var strategy2 = RandomStrategy(seed: 444)
        
        let value1 = strategy1.generateInt(range: -100...100)
        let value2 = strategy2.generateInt(range: -100...100)
        
        #expect(value1 == value2)
        #expect(value1 >= -100 && value1 <= 100)
    }
    
    @Test("복합 시나리오: DTO 생성 시뮬레이션")
    func testComplexDTOSimulation() {
        var strategy1 = RandomStrategy(seed: 12345)
        var strategy2 = RandomStrategy(seed: 12345)
        
        // UserDTO를 시뮬레이션
        struct SimulatedUser {
            let id: Int
            let name: String
            let age: Int
            let isActive: Bool
            let createdAt: Date
            let uuid: UUID
        }
        
        func generateUser(using strategy: inout RandomStrategy) -> SimulatedUser {
            SimulatedUser(
                id: strategy.generateInt(range: 1...1000),
                name: strategy.generateString(prefix: "User"),
                age: strategy.generateInt(range: 18...80),
                isActive: strategy.generateBool(),
                createdAt: strategy.generateDate(),
                uuid: strategy.generateUUID()
            )
        }
        
        let user1 = generateUser(using: &strategy1)
        let user2 = generateUser(using: &strategy2)
        
        #expect(user1.id == user2.id)
        #expect(user1.name == user2.name)
        #expect(user1.age == user2.age)
        #expect(user1.isActive == user2.isActive)
        #expect(user1.createdAt == user2.createdAt)
        #expect(user1.uuid == user2.uuid)
    }
}

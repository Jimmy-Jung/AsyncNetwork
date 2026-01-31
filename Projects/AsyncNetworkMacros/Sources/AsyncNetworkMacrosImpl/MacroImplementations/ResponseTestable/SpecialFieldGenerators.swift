//
//  SpecialFieldGenerators.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/02/01.
//  Strategy 패턴을 사용한 특수 필드 값 생성기
//

import Foundation

// MARK: - Protocol

/// 특수 필드에 대한 Mock/Fixture 값 생성 전략
protocol SpecialFieldGenerator {
    /// 이 Generator가 특정 필드에 적용 가능한지 확인
    func matches(propertyName: String, type: String) -> Bool
    
    /// Mock 값 생성 (랜덤)
    func generateMockValue() -> String
    
    /// Fixture 값 생성 (고정)
    func generateFixtureValue() -> String
}

// MARK: - Email Field Generator

struct EmailFieldGenerator: SpecialFieldGenerator {
    private let mockDomain: String
    private let mockRange: ClosedRange<Int>
    private let fixtureEmail: String
    
    init(
        mockDomain: String = "example.com",
        mockRange: ClosedRange<Int> = 1...999,
        fixtureEmail: String = "test@example.com"
    ) {
        self.mockDomain = mockDomain
        self.mockRange = mockRange
        self.fixtureEmail = fixtureEmail
    }
    
    func matches(propertyName: String, type: String) -> Bool {
        type == "String" && propertyName.lowercased().contains("email")
    }
    
    func generateMockValue() -> String {
        "\"mock\\(Int.random(in: \(mockRange)))@\(mockDomain)\""
    }
    
    func generateFixtureValue() -> String {
        "\"\(fixtureEmail)\""
    }
}

// MARK: - URL Field Generator

struct URLFieldGenerator: SpecialFieldGenerator {
    private let mockDomain: String
    private let fixtureURL: String
    
    init(
        mockDomain: String = "example.com",
        fixtureURL: String = "https://example.com/fixture"
    ) {
        self.mockDomain = mockDomain
        self.fixtureURL = fixtureURL
    }
    
    func matches(propertyName: String, type: String) -> Bool {
        type == "String" && propertyName.lowercased().contains("url")
    }
    
    func generateMockValue() -> String {
        "\"https://\(mockDomain)/\\(UUID().uuidString.prefix(8))\""
    }
    
    func generateFixtureValue() -> String {
        "\"\(fixtureURL)\""
    }
}

// MARK: - ID Field Generator

struct IDFieldGenerator: SpecialFieldGenerator {
    func matches(propertyName: String, type: String) -> Bool {
        propertyName.lowercased().contains("id") &&
        ["Int", "Int8", "Int16", "Int32", "Int64"].contains(type)
    }
    
    func generateMockValue() -> String {
        // ID는 일반 Int와 동일하게 처리
        ""  // 빈 문자열 반환 시 기본 로직 사용
    }
    
    func generateFixtureValue() -> String {
        ""  // 빈 문자열 반환 시 기본 로직 사용
    }
}

// MARK: - Special Field Generator Registry

struct SpecialFieldGeneratorRegistry {
    private let generators: [SpecialFieldGenerator]
    
    init() {
        // 순서 중요: 더 구체적인 Generator를 먼저 등록
        self.generators = [
            EmailFieldGenerator(),
            URLFieldGenerator(),
            IDFieldGenerator()
        ]
    }
    
    /// 특정 필드에 적용 가능한 Generator 찾기
    func findGenerator(for propertyName: String, type: String) -> SpecialFieldGenerator? {
        generators.first { $0.matches(propertyName: propertyName, type: type) }
    }
    
    /// Mock 값 생성 (특수 필드가 아니면 nil 반환)
    func generateMockValue(for propertyName: String, type: String) -> String? {
        guard let generator = findGenerator(for: propertyName, type: type) else {
            return nil
        }
        let value = generator.generateMockValue()
        return value.isEmpty ? nil : value
    }
    
    /// Fixture 값 생성 (특수 필드가 아니면 nil 반환)
    func generateFixtureValue(for propertyName: String, type: String) -> String? {
        guard let generator = findGenerator(for: propertyName, type: type) else {
            return nil
        }
        let value = generator.generateFixtureValue()
        return value.isEmpty ? nil : value
    }
}

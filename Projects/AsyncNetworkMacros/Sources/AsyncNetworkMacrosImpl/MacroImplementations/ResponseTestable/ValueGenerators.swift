//
//  ValueGenerators.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//  Extracted from ResponseTestableMacroImpl.swift for better organization
//

import Foundation
import SwiftSyntax

// MARK: - Constants

extension ResponseTestableMacroImpl {
    /// Mock 값 생성 시 사용되는 상수
    private enum MockConstants {
        static let intRange = 1 ... 1000
        static let int8Range = Int8(-128) ... 127 // Int8의 전체 범위
        static let uintRange = UInt(0) ... 1000 // UInt는 0부터 시작
        static let uint8Range = UInt8(0) ... 255 // UInt8도 0부터 시작
        static let floatRange = 0.0 ... 100.0
        static let emailRange = 1 ... 999
        static let arrayCountRange = 2 ... 5
        static let exampleDomain = "example.com"
    }

    /// Fixture 값 생성 시 사용되는 상수 (고정값)
    private enum FixtureConstants {
        static let intValue = 1
        static let stringValue = "Test String"
        static let boolValue = true
        static let floatValue = 0.0
        static let referenceTimestamp: TimeInterval = 1_704_556_800 // 2024-01-06
        static let referenceUUID = "00000000-0000-0000-0000-000000000001"
        static let exampleURL = "https://example.com"
        static let fixtureURL = "https://example.com/fixture"
        static let testEmail = "test@example.com"
    }

    // MARK: - Helper Methods

    /// 타입명에서 Optional 표시(?)와 공백을 제거하여 정규화된 타입명 반환
    private static func cleanTypeName(_ type: String) -> String {
        type.replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

extension ResponseTestableMacroImpl {
    /// 특수 필드 Generator Registry (싱글톤 패턴)
    private static let specialFieldRegistry = SpecialFieldGeneratorRegistry()

    /// Mock 값 생성
    static func generateMockValue(
        for type: String,
        isOptional: Bool,
        propertyName: String = "",
        structName: String = ""
    ) -> String {
        let cleanType = cleanTypeName(type)

        // 특수 필드 Generator 시도
        if let specialValue = specialFieldRegistry.generateMockValue(for: propertyName, type: cleanType) {
            return isOptional ? "Bool.random() ? \(specialValue) : nil" : specialValue
        }

        var mockValue: String

        switch cleanType {
        case "Int":
            mockValue = "Int.random(in: \(MockConstants.intRange))"
        case "Int8":
            mockValue = "Int8.random(in: \(MockConstants.int8Range))"
        case "Int16":
            mockValue = "Int16.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "Int32":
            mockValue = "Int32.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "Int64":
            mockValue = "Int64.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "UInt":
            mockValue = "UInt.random(in: \(MockConstants.uintRange))"
        case "UInt8":
            mockValue = "UInt8.random(in: \(MockConstants.uint8Range))"
        case "UInt16":
            mockValue = "UInt16.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "UInt32":
            mockValue = "UInt32.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "UInt64":
            mockValue = "UInt64.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound))"
        case "String":
            // 기본 String 값 (특수 필드가 아닌 경우)
            mockValue = "\"Mock \\(UUID().uuidString.prefix(8))\""
        case "Bool":
            mockValue = "Bool.random()"
        case "Double":
            mockValue = "Double.random(in: \(MockConstants.floatRange))"
        case "Float":
            mockValue = "Float.random(in: \(MockConstants.floatRange))"
        case "CGFloat":
            mockValue = "CGFloat.random(in: \(MockConstants.floatRange))"
        case "Date":
            mockValue = "Date()"
        case "UUID":
            mockValue = "UUID()"
        case "URL":
            mockValue = "URL(string: \"\(FixtureConstants.exampleURL)\")!"
        case "Decimal":
            mockValue = "Decimal(Double.random(in: \(MockConstants.floatRange)))"
        case "Data":
            mockValue = "Data()"
        default:
            // 컬렉션 타입 파싱
            let collectionType = CollectionType.parse(cleanType)

            switch collectionType {
            case let .array(elementType):
                let randomCount = "Int.random(in: \(MockConstants.arrayCountRange))"
                let elementMockValue = generateMockValue(for: elementType, isOptional: false, propertyName: "", structName: structName)
                mockValue = "(0..<\(randomCount)).map { _ in \(elementMockValue) }"

            case .dictionary:
                mockValue = "[:]"

            case let .set(elementType):
                let randomCount = "Int.random(in: \(MockConstants.arrayCountRange))"
                let elementMockValue = generateMockValue(for: elementType, isOptional: false, propertyName: "", structName: structName)
                mockValue = "Set((0..<\(randomCount)).map { _ in \(elementMockValue) })"

            case .none:
                // 커스텀 타입 - mock() 재귀 호출
                mockValue = "\(cleanType).mock()"
            }
        }

        if isOptional {
            return "Bool.random() ? \(mockValue) : nil"
        } else {
            return mockValue
        }
    }

    /// Fixture 값 생성 (고정값)
    static func generateFixtureValue(
        for type: String,
        isOptional: Bool,
        propertyName: String = "",
        structName: String = "",
        defaultArrayCount: Int = 1
    ) -> String {
        let cleanType = cleanTypeName(type)

        // 특수 필드 Generator 시도
        if let specialValue = specialFieldRegistry.generateFixtureValue(for: propertyName, type: cleanType) {
            return isOptional ? "nil" : specialValue
        }

        var fixtureValue: String

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            fixtureValue = "\(FixtureConstants.intValue)"
        case "String":
            // 기본 String 값 (특수 필드가 아닌 경우)
            fixtureValue = "\"\(FixtureConstants.stringValue)\""
        case "Bool":
            fixtureValue = "\(FixtureConstants.boolValue)"
        case "Double", "Float":
            fixtureValue = "\(FixtureConstants.floatValue)"
        case "CGFloat":
            fixtureValue = "CGFloat(\(FixtureConstants.floatValue))"
        case "Date":
            fixtureValue = "Date(timeIntervalSince1970: \(FixtureConstants.referenceTimestamp))"
        case "UUID":
            fixtureValue = "UUID(uuidString: \"\(FixtureConstants.referenceUUID)\")!"
        case "URL":
            fixtureValue = "URL(string: \"\(FixtureConstants.exampleURL)\")!"
        case "Decimal":
            fixtureValue = "Decimal(\(FixtureConstants.intValue))"
        case "Data":
            fixtureValue = "Data()"
        default:
            // 컬렉션 타입 파싱
            let collectionType = CollectionType.parse(cleanType)

            switch collectionType {
            case let .array(elementType):
                let elementFixtureValue = generateFixtureValue(
                    for: elementType,
                    isOptional: false,
                    propertyName: "",
                    structName: structName,
                    defaultArrayCount: defaultArrayCount
                )
                fixtureValue = "(0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) }"

            case .dictionary:
                fixtureValue = "[:]"

            case let .set(elementType):
                let elementFixtureValue = generateFixtureValue(
                    for: elementType,
                    isOptional: false,
                    propertyName: "",
                    structName: structName,
                    defaultArrayCount: defaultArrayCount
                )
                fixtureValue = "Set((0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) })"

            case .none:
                // 커스텀 타입 - mock()으로 고정값 생성
                // - struct 타입: builder()와 mock() 모두 제공
                // - enum 타입: mock()만 제공 (builder()는 지원하지 않음)
                // 따라서 모든 커스텀 타입에 대해 mock()을 사용하는 것이 안전
                fixtureValue = "\(cleanType).mock()"
            }
        }

        if isOptional {
            return "nil"
        } else {
            return fixtureValue
        }
    }

    /// 검증 로직 생성
    static func generateValidation(for prop: PropertyInfo) -> String? {
        let cleanType = cleanTypeName(prop.type)

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64":
            if prop.name.lowercased().contains("id") {
                if prop.isOptional {
                    return """
                    if let \(prop.name) = \(prop.name) {
                            assert(
                                \(prop.name) > 0,
                                "\(prop.name) must be positive"
                            )
                        }
                    """
                } else {
                    return """
                    assert(\(prop.name) > 0, "\(prop.name) must be positive")
                    """
                }
            }
        case "String":
            if prop.name.lowercased().contains("email") {
                if prop.isOptional {
                    return """
                    if let \(prop.name) = \(prop.name) {
                            assert(
                                \(prop.name).contains("@") && \(prop.name).contains("."),
                                "\(prop.name) must be valid email"
                            )
                            assert(
                                !\(prop.name).starts(with: "@") && !\(prop.name).starts(with: "."),
                                "\(prop.name) format invalid"
                            )
                        }
                    """
                } else {
                    return """
                    assert(
                        \(prop.name).contains("@") && \(prop.name).contains("."),
                        "\(prop.name) must be valid email"
                    )
                        assert(
                            !\(prop.name).starts(with: "@") && !\(prop.name).starts(with: "."),
                            "\(prop.name) format invalid"
                        )
                    """
                }
            } else if !prop.name.lowercased().contains("optional") {
                if !prop.isOptional {
                    return "assert(!\(prop.name).isEmpty, \"\(prop.name) must not be empty\")"
                }
            }
        default:
            break
        }

        return nil
    }
}

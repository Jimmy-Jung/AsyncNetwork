//
//  ValueGenerators.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/02/03.
//  Refactored for better organization
//

import Foundation
import SwiftSyntax

// MARK: - Constants

extension ResponseTestableMacroImpl {
    /// Random 값 생성 시 사용되는 상수
    private enum MockConstants {
        static let intRange = 1...1000
        static let int8Range = Int8(-128)...127
        static let uintRange = UInt(0)...1000
        static let uint8Range = UInt8(0)...255
        static let floatRange = 0.0...100.0
        static let arrayCountRange = 2...5
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
    }

    // MARK: - Helper Methods

    /// 타입명에서 Optional 표시(?)와 공백을 제거하여 정규화된 타입명 반환
    private static func cleanTypeName(_ type: String) -> String {
        type.replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// 커스텀 타입인지 확인 (기본 타입이 아닌 경우)
    private static func isCustomType(_ type: String) -> Bool {
        let basicTypes: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "String", "Bool", "Double", "Float", "CGFloat",
            "Date", "UUID", "URL", "Decimal", "Data"
        ]
        return !basicTypes.contains(type)
    }
}

// MARK: - Value Generation

extension ResponseTestableMacroImpl {
    /// 특수 필드 Generator Registry (싱글톤 패턴)
    private static let specialFieldRegistry = SpecialFieldGeneratorRegistry()

    /// Random 값 생성
    static func generateRandomValue(
        for type: String,
        isOptional: Bool,
        propertyName: String = "",
        structName: String = "",
        generatorName: String = "generator"
    ) -> String {
        let cleanType = cleanTypeName(type)

        // 특수 필드 Generator 시도
        if let specialValue = specialFieldRegistry.generateRandomValue(for: propertyName, type: cleanType) {
            if isOptional {
                return "depth > 10 ? nil : (Bool.random(using: &\(generatorName)) ? \(specialValue) : nil)"
            } else {
                return specialValue
            }
        }

        let randomValue = generateRandomValueForType(
            cleanType: cleanType,
            propertyName: propertyName,
            structName: structName,
            generatorName: generatorName
        )

        if isOptional {
            return "depth > 10 ? nil : (Bool.random(using: &\(generatorName)) ? \(randomValue) : nil)"
        } else {
            return randomValue
        }
    }
    
    private static func generateRandomValueForType(
        cleanType: String,
        propertyName: String,
        structName: String,
        generatorName: String
    ) -> String {
        switch cleanType {
        case "Int":
            return "Int.random(in: \(MockConstants.intRange), using: &\(generatorName))"
        case "Int8":
            return "Int8.random(in: \(MockConstants.int8Range), using: &\(generatorName))"
        case "Int16":
            return "Int16.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "Int32":
            return "Int32.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "Int64":
            return "Int64.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "UInt":
            return "UInt.random(in: \(MockConstants.uintRange), using: &\(generatorName))"
        case "UInt8":
            return "UInt8.random(in: \(MockConstants.uint8Range), using: &\(generatorName))"
        case "UInt16":
            return "UInt16.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "UInt32":
            return "UInt32.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "UInt64":
            return "UInt64.random(in: \(MockConstants.intRange.lowerBound)...\(MockConstants.intRange.upperBound), using: &\(generatorName))"
        case "String":
            return "\"Mock \\(UUID().uuidString.prefix(8))\""
        case "Bool":
            return "Bool.random(using: &\(generatorName))"
        case "Double":
            return "Double.random(in: \(MockConstants.floatRange), using: &\(generatorName))"
        case "Float":
            return "Float.random(in: \(MockConstants.floatRange), using: &\(generatorName))"
        case "CGFloat":
            return "CGFloat.random(in: \(MockConstants.floatRange), using: &\(generatorName))"
        case "Date":
            return "Date()"
        case "UUID":
            return "UUID()"
        case "URL":
            return "URL(string: \"\(FixtureConstants.exampleURL)\")!"
        case "Decimal":
            return "Decimal(Double.random(in: \(MockConstants.floatRange), using: &\(generatorName)))"
        case "Data":
            return "Data()"
        default:
            return generateRandomValueForCollectionOrCustomType(
                cleanType: cleanType,
                propertyName: propertyName,
                structName: structName,
                generatorName: generatorName
            )
        }
    }
    
    private static func generateRandomValueForCollectionOrCustomType(
        cleanType: String,
        propertyName: String,
        structName: String,
        generatorName: String
    ) -> String {
        let collectionType = CollectionType.parse(cleanType)

        switch collectionType {
        case let .array(elementType):
            return generateRandomArrayValue(
                elementType: elementType,
                structName: structName,
                generatorName: generatorName
            )
            
        case .dictionary:
            return "[:]"
            
        case let .set(elementType):
            return generateRandomSetValue(
                elementType: elementType,
                structName: structName,
                generatorName: generatorName
            )
            
        case .none:
            // 커스텀 타입
            return "\(cleanType).random(seed: seed, depth: depth + 1)"
        }
    }
    
    private static func generateRandomArrayValue(
        elementType: String,
        structName: String,
        generatorName: String
    ) -> String {
        let cleanElementType = cleanTypeName(elementType)
        let nestedCollectionType = CollectionType.parse(cleanElementType)
        let randomCount = "Int.random(in: \(MockConstants.arrayCountRange), using: &\(generatorName))"
        
        if nestedCollectionType != .none {
            // 중첩 컬렉션
            let elementRandomValue = generateRandomValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                generatorName: generatorName
            )
            return "(0..<\(randomCount)).map { _ in \(elementRandomValue) }"
        } else if isCustomType(cleanElementType) {
            // 커스텀 타입 - defaultArrayCount 사용
            return "\(cleanElementType).randomArray(seed: seed)"
        } else {
            // 기본 타입
            let elementRandomValue = generateRandomValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                generatorName: generatorName
            )
            return "(0..<\(randomCount)).map { _ in \(elementRandomValue) }"
        }
    }
    
    private static func generateRandomSetValue(
        elementType: String,
        structName: String,
        generatorName: String
    ) -> String {
        let cleanElementType = cleanTypeName(elementType)
        let nestedCollectionType = CollectionType.parse(cleanElementType)
        let randomCount = "Int.random(in: \(MockConstants.arrayCountRange), using: &\(generatorName))"
        
        if nestedCollectionType != .none {
            // 중첩 컬렉션
            let elementRandomValue = generateRandomValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                generatorName: generatorName
            )
            return "Set((0..<\(randomCount)).map { _ in \(elementRandomValue) })"
        } else if isCustomType(cleanElementType) {
            // 커스텀 타입 - defaultArrayCount 사용
            return "Set(\(cleanElementType).randomArray(seed: seed))"
        } else {
            // 기본 타입
            let elementRandomValue = generateRandomValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                generatorName: generatorName
            )
            return "Set((0..<\(randomCount)).map { _ in \(elementRandomValue) })"
        }
    }

    /// Fixture 값 생성 (고정값)
    static func generateFixtureValue(
        for type: String,
        isOptional: Bool,
        propertyName: String = "",
        structName: String = "",
        defaultArrayCount: Int = 1,
        enumStrategy: String = "firstCase"
    ) -> String {
        let cleanType = cleanTypeName(type)

        // 특수 필드 Generator 시도
        if let specialValue = specialFieldRegistry.generateFixtureValue(for: propertyName, type: cleanType) {
            return isOptional ? "nil" : specialValue
        }

        if isOptional {
            return "nil"
        }

        return generateFixtureValueForType(
            cleanType: cleanType,
            propertyName: propertyName,
            structName: structName,
            defaultArrayCount: defaultArrayCount
        )
    }
    
    private static func generateFixtureValueForType(
        cleanType: String,
        propertyName: String,
        structName: String,
        defaultArrayCount: Int
    ) -> String {
        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return "\(FixtureConstants.intValue)"
        case "String":
            return "\"\(FixtureConstants.stringValue)\""
        case "Bool":
            return "\(FixtureConstants.boolValue)"
        case "Double", "Float":
            return "\(FixtureConstants.floatValue)"
        case "CGFloat":
            return "CGFloat(\(FixtureConstants.floatValue))"
        case "Date":
            return "Date(timeIntervalSince1970: \(FixtureConstants.referenceTimestamp))"
        case "UUID":
            return "UUID(uuidString: \"\(FixtureConstants.referenceUUID)\")!"
        case "URL":
            return "URL(string: \"\(FixtureConstants.exampleURL)\")!"
        case "Decimal":
            return "Decimal(\(FixtureConstants.intValue))"
        case "Data":
            return "Data()"
        default:
            return generateFixtureValueForCollectionOrCustomType(
                cleanType: cleanType,
                propertyName: propertyName,
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
        }
    }
    
    private static func generateFixtureValueForCollectionOrCustomType(
        cleanType: String,
        propertyName: String,
        structName: String,
        defaultArrayCount: Int
    ) -> String {
        let collectionType = CollectionType.parse(cleanType)

        switch collectionType {
        case let .array(elementType):
            return generateFixtureArrayValue(
                elementType: elementType,
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            
        case .dictionary:
            return "[:]"
            
        case let .set(elementType):
            return generateFixtureSetValue(
                elementType: elementType,
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            
        case .none:
            // 커스텀 타입
            return "\(cleanType).fixtureValue()"
        }
    }
    
    private static func generateFixtureArrayValue(
        elementType: String,
        structName: String,
        defaultArrayCount: Int
    ) -> String {
        let cleanElementType = cleanTypeName(elementType)
        let nestedCollectionType = CollectionType.parse(cleanElementType)
        
        if nestedCollectionType != .none {
            // 중첩 컬렉션
            let elementFixtureValue = generateFixtureValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            return "(0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) }"
        } else if isCustomType(cleanElementType) {
            // 커스텀 타입
            return "\(cleanElementType).randomArray()"
        } else {
            // 기본 타입
            let elementFixtureValue = generateFixtureValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            return "(0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) }"
        }
    }
    
    private static func generateFixtureSetValue(
        elementType: String,
        structName: String,
        defaultArrayCount: Int
    ) -> String {
        let cleanElementType = cleanTypeName(elementType)
        let nestedCollectionType = CollectionType.parse(cleanElementType)
        
        if nestedCollectionType != .none {
            // 중첩 컬렉션
            let elementFixtureValue = generateFixtureValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            return "Set((0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) })"
        } else if isCustomType(cleanElementType) {
            // 커스텀 타입
            return "Set(\(cleanElementType).randomArray())"
        } else {
            // 기본 타입
            let elementFixtureValue = generateFixtureValue(
                for: elementType,
                isOptional: false,
                propertyName: "",
                structName: structName,
                defaultArrayCount: defaultArrayCount
            )
            return "Set((0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) })"
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

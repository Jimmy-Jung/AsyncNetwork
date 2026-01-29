//
//  ValueGenerators.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//  Extracted from ResponseTestableMacroImpl.swift for better organization
//

import Foundation
import SwiftSyntax

extension ResponseTestableMacroImpl {
    /// Mock 값 생성
    static func generateMockValue(
        for type: String,
        isOptional: Bool,
        propertyName: String = ""
    ) -> String {
        let cleanType = type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)

        var mockValue: String

        switch cleanType {
        case "Int":
            mockValue = "Int.random(in: 1...1000)"
        case "Int8":
            mockValue = "Int8.random(in: 1...127)"
        case "Int16":
            mockValue = "Int16.random(in: 1...1000)"
        case "Int32":
            mockValue = "Int32.random(in: 1...1000)"
        case "Int64":
            mockValue = "Int64.random(in: 1...1000)"
        case "UInt":
            mockValue = "UInt.random(in: 1...1000)"
        case "UInt8":
            mockValue = "UInt8.random(in: 1...255)"
        case "UInt16":
            mockValue = "UInt16.random(in: 1...1000)"
        case "UInt32":
            mockValue = "UInt32.random(in: 1...1000)"
        case "UInt64":
            mockValue = "UInt64.random(in: 1...1000)"
        case "String":
            // 특수 필드명 처리
            if propertyName.lowercased().contains("email") {
                mockValue = "\"mock\\(Int.random(in: 1...999))@example.com\""
            } else if propertyName.lowercased().contains("url") {
                mockValue = "\"https://example.com/\\(UUID().uuidString.prefix(8))\""
            } else {
                mockValue = "\"Mock \\(UUID().uuidString.prefix(8))\""
            }
        case "Bool":
            mockValue = "Bool.random()"
        case "Double":
            mockValue = "Double.random(in: 0...100)"
        case "Float":
            mockValue = "Float.random(in: 0...100)"
        case "CGFloat":
            mockValue = "CGFloat.random(in: 0...100)"
        case "Date":
            mockValue = "Date()"
        case "UUID":
            mockValue = "UUID()"
        case "URL":
            mockValue = "URL(string: \"https://example.com\")!"
        case "Decimal":
            mockValue = "Decimal(Double.random(in: 0...100))"
        case "Data":
            mockValue = "Data()"
        default:
            if cleanType.hasPrefix("["), cleanType.hasSuffix("]"), !cleanType.contains(":") {
                // 배열 타입 (딕셔너리 제외)
                let elementType = String(cleanType.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)

                // 빈 배열이 아닌지 확인
                if !elementType.isEmpty {
                    let randomCount = "Int.random(in: 2...5)"
                    let elementMockValue = generateMockValue(for: elementType, isOptional: false, propertyName: "")
                    mockValue = "(0..<\(randomCount)).map { _ in \(elementMockValue) }"
                } else {
                    mockValue = "[]"
                }
            } else if cleanType.hasPrefix("["), cleanType.contains(":"), cleanType.hasSuffix("]") {
                // 딕셔너리 타입
                mockValue = "[:]"
            } else if cleanType.hasPrefix("Set<"), cleanType.hasSuffix(">") {
                // Set 타입
                let elementType = String(cleanType.dropFirst(4).dropLast()).trimmingCharacters(in: .whitespaces)
                if !elementType.isEmpty {
                    let randomCount = "Int.random(in: 2...5)"
                    let elementMockValue = generateMockValue(for: elementType, isOptional: false, propertyName: "")
                    mockValue = "Set((0..<\(randomCount)).map { _ in \(elementMockValue) })"
                } else {
                    mockValue = "Set()"
                }
            } else {
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

    /// Fixture 값 생성
    static func generateFixtureValue(
        for type: String,
        isOptional: Bool,
        defaultArrayCount: Int = 1
    ) -> String {
        let cleanType = type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)

        var fixtureValue: String

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            fixtureValue = "1"
        case "String":
            fixtureValue = "\"Test String\""
        case "Bool":
            fixtureValue = "true"
        case "Double", "Float":
            fixtureValue = "0.0"
        case "CGFloat":
            fixtureValue = "CGFloat(0.0)"
        case "Date":
            fixtureValue = "Date(timeIntervalSince1970: 1704556800)" // 2024-01-06
        case "UUID":
            fixtureValue = "UUID()"
        case "URL":
            fixtureValue = "URL(string: \"https://example.com\")!"
        case "Decimal":
            fixtureValue = "Decimal(0)"
        case "Data":
            fixtureValue = "Data()"
        default:
            if cleanType.hasPrefix("["), cleanType.hasSuffix("]") {
                // 배열 타입: defaultArrayCount만큼 fixture()를 사용하여 고정값 생성
                let elementType = String(cleanType.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                if !elementType.isEmpty {
                    let elementFixtureValue = generateFixtureValue(for: elementType, isOptional: false, defaultArrayCount: defaultArrayCount)
                    fixtureValue = "(0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) }"
                } else {
                    fixtureValue = "[]"
                }
            } else if cleanType.hasPrefix("Set<"), cleanType.hasSuffix(">") {
                let elementType = String(cleanType.dropFirst(4).dropLast()).trimmingCharacters(in: .whitespaces)
                if !elementType.isEmpty {
                    let elementFixtureValue = generateFixtureValue(for: elementType, isOptional: false, defaultArrayCount: defaultArrayCount)
                    fixtureValue = "Set((0..<\(defaultArrayCount)).map { _ in \(elementFixtureValue) })"
                } else {
                    fixtureValue = "Set()"
                }
            } else {
                fixtureValue = "\(cleanType).fixture()"
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
        let cleanType = prop.type
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: CharacterSet.whitespaces)

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

//
//  ResponseTestableMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/12.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @ResponseTestable 매크로 구현
///
/// Codable DTO의 테스트 데이터 생성 및 검증 로직을 자동 생성합니다.
public struct ResponseTestableMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. struct 검증
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw TestableDTOMacroError.notAStruct
        }

        let typeName = structDecl.name.text

        // 2. 매크로 인자 파싱
        let args = try parseTestableDTOArguments(from: node)

        // 3. @ResponseDocument에서 fixtureJSON 추출 (있으면)
        let documentFixtureJSON = extractFixtureJSONFromResponseDocument(structDecl: structDecl)

        // ResponseTestable의 fixtureJSON이 없으면 ResponseDocument의 것을 사용
        let fixtureJSON = args.fixtureJSON ?? documentFixtureJSON

        // 4. 프로퍼티 추출
        let properties = extractProperties(from: structDecl)

        // 5. 멤버 생성
        var members: [DeclSyntax] = []

        // mock() 메서드
        members.append(generateMockMethod(typeName: typeName, properties: properties, strategy: args.mockStrategy))

        // fixture() 메서드
        members.append(generateFixtureMethod(typeName: typeName, properties: properties, fixtureJSON: fixtureJSON))

        // mockArray() 메서드
        members.append(generateMockArrayMethod(defaultCount: args.defaultArrayCount))

        // assertValid() 메서드
        members.append(generateAssertValidMethod(properties: properties))

        // builder() 메서드 및 Builder 타입 (옵션)
        if args.includeBuilder {
            members.append(generateBuilderMethod(typeName: typeName))
            members.append(generateBuilderType(typeName: typeName, properties: properties))
        }

        return members
    }

    // MARK: - ExtensionMacro Implementation

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // TestableDTO 프로토콜 채택
        let ext: DeclSyntax = """
        extension \(type.trimmed): TestableDTO {
        }
        """

        return [ext.cast(ExtensionDeclSyntax.self)]
    }

    // MARK: - Helper Methods

    /// mock() 메서드 생성
    private static func generateMockMethod(
        typeName: String,
        properties: [PropertyInfo],
        strategy _: String
    ) -> DeclSyntax {
        var initParams: [String] = []

        for prop in properties {
            let mockValue = generateMockValue(for: prop.type, isOptional: prop.isOptional, propertyName: prop.name)
            initParams.append("\(prop.name): \(mockValue)")
        }

        let initCode = initParams.joined(separator: ",\n            ")

        return """
        /// 랜덤 값으로 테스트 데이터 생성
        ///
        /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
        /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
        /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
        /// - builder(): fixture() 기반으로 일부만 커스터마이징
        public static func mock() -> \(raw: typeName) {
            \(raw: typeName)(
                \(raw: initCode)
            )
        }
        """
    }

    /// fixture() 메서드 생성
    private static func generateFixtureMethod(
        typeName: String,
        properties: [PropertyInfo],
        fixtureJSON: String?
    ) -> DeclSyntax {
        if let json = fixtureJSON {
            // JSON을 올바르게 escape
            let escaped = json
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")

            return """
            /// 고정 값으로 테스트 데이터 생성
            public static func fixture() -> \(raw: typeName) {
                let json = \"\(raw: escaped)\"
                return try! JSONDecoder().decode(\(raw: typeName).self, from: Data(json.utf8))
            }
            """
        } else {
            // 기본값 사용
            var initParams: [String] = []
            for prop in properties {
                let fixtureValue = generateFixtureValue(for: prop.type, isOptional: prop.isOptional)
                initParams.append("\(prop.name): \(fixtureValue)")
            }

            let initCode = initParams.joined(separator: ",\n            ")

            return """
            /// 고정 값으로 테스트 데이터 생성
            public static func fixture() -> \(raw: typeName) {
                \(raw: typeName)(
                    \(raw: initCode)
                )
            }
            """
        }
    }

    /// mockArray() 메서드 생성
    private static func generateMockArrayMethod(defaultCount: Int) -> DeclSyntax {
        return """
        /// 여러 개의 Mock 데이터 생성
        public static func mockArray(count: Int = \(raw: String(defaultCount))) -> [Self] {
            (0..<count).map { _ in mock() }
        }
        """
    }

    /// assertValid() 메서드 생성
    private static func generateAssertValidMethod(properties: [PropertyInfo]) -> DeclSyntax {
        var validations: [String] = []

        for prop in properties {
            if let validation = generateValidation(for: prop) {
                validations.append(validation)
            }
        }

        let validationCode = validations.isEmpty ? "// No validation rules" : validations.joined(separator: "\n        ")

        return """
        /// 데이터 검증
        public func assertValid() {
            \(raw: validationCode)
        }
        """
    }

    /// builder() 메서드 생성
    private static func generateBuilderMethod(typeName: String) -> DeclSyntax {
        return """
        /// Builder 패턴으로 유연한 데이터 생성
        ///
        /// Builder는 fixture() 값을 기본값으로 사용합니다.
        /// - 주입하지 않은 값은 fixture()의 고정값을 사용 (예측 가능한 테스트)
        /// - 랜덤 값이 필요하면 mock() 메서드를 사용하세요
        ///
        /// Example:
        /// ```swift
        /// let dto = DTO.builder()
        ///     .with(id: 999)
        ///     .with(name: "Custom")
        ///     .build()
        /// // id와 name만 커스텀, 나머지는 fixture() 값 사용
        /// ```
        public static func builder() -> \(raw: typeName)Builder {
            \(raw: typeName)Builder()
        }
        """
    }

    /// Builder 타입 생성
    private static func generateBuilderType(typeName: String, properties: [PropertyInfo]) -> DeclSyntax {
        var builderProperties: [String] = []
        var withMethods: [String] = []
        var buildParams: [String] = []

        for prop in properties {
            let fixtureValue = generateFixtureValue(for: prop.type, isOptional: prop.isOptional)
            builderProperties.append("private var \(prop.name): \(prop.type) = \(fixtureValue)")

            withMethods.append("""
            public func with(\(prop.name): \(prop.type)) -> Self {
                    var copy = self
                    copy.\(prop.name) = \(prop.name)
                    return copy
                }
            """)

            buildParams.append("\(prop.name): \(prop.name)")
        }

        let propertiesCode = builderProperties.joined(separator: "\n    ")
        let methodsCode = withMethods.joined(separator: "\n    \n    ")
        let buildCode = buildParams.joined(separator: ",\n                ")

        return """
        /// Builder 패턴
        ///
        /// 모든 프로퍼티는 fixture() 값으로 초기화됩니다.
        /// - fixtureJSON이 있으면 해당 값 사용
        /// - fixtureJSON이 없으면 타입별 기본값 사용 (Int: 1, String: "Test String" 등)
        /// - with() 메서드로 원하는 값만 커스터마이징 가능
        /// - 예측 가능한 고정값으로 안정적인 테스트 작성
        public struct \(raw: typeName)Builder {
            \(raw: propertiesCode)

            \(raw: methodsCode)

            /// Builder로 설정된 값들로 인스턴스 생성
            public func build() -> \(raw: typeName) {
                \(raw: typeName)(
                    \(raw: buildCode)
                )
            }
        }
        """
    }

    /// Mock 값 생성
    private static func generateMockValue(for type: String, isOptional: Bool, propertyName: String = "") -> String {
        let cleanType = type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)

        var mockValue: String

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64":
            mockValue = "Int.random(in: 1...1000)"
        case "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            mockValue = "UInt.random(in: 1...1000)"
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
        case "Float", "CGFloat":
            mockValue = "Float.random(in: 0...100)"
        case "Date":
            mockValue = "Date()"
        case "UUID":
            mockValue = "UUID()"
        case "URL":
            mockValue = "URL(string: \"https://example.com\")!"
        default:
            if cleanType.hasPrefix("[") && cleanType.hasSuffix("]") {
                // 배열 타입
                mockValue = "[]"
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
    private static func generateFixtureValue(for type: String, isOptional: Bool) -> String {
        let cleanType = type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)

        var fixtureValue: String

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            fixtureValue = "1"
        case "String":
            fixtureValue = "\"Test String\""
        case "Bool":
            fixtureValue = "true"
        case "Double", "Float", "CGFloat":
            fixtureValue = "0.0"
        case "Date":
            fixtureValue = "Date(timeIntervalSince1970: 1704556800)" // 2024-01-06
        case "UUID":
            fixtureValue = "UUID(uuidString: \"00000000-0000-0000-0000-000000000001\")!"
        case "URL":
            fixtureValue = "URL(string: \"https://example.com\")!"
        default:
            if cleanType.hasPrefix("[") && cleanType.hasSuffix("]") {
                fixtureValue = "[]"
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
    private static func generateValidation(for prop: PropertyInfo) -> String? {
        let cleanType = prop.type.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: CharacterSet.whitespaces)

        switch cleanType {
        case "Int", "Int8", "Int16", "Int32", "Int64":
            if prop.name.lowercased().contains("id") {
                return "assert(\(prop.name) > 0, \"\(prop.name) must be positive\")"
            }
        case "String":
            if prop.name.lowercased().contains("email") {
                if prop.isOptional {
                    return """
                    if let \(prop.name) = \(prop.name) {
                            assert(\(prop.name).contains("@"), "\(prop.name) must contain @")
                        }
                    """
                } else {
                    return """
                    assert(\(prop.name).contains("@"), "\(prop.name) must contain @")
                        assert(\(prop.name).contains("."), "\(prop.name) must contain .")
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

    /// 프로퍼티 추출
    private static func extractProperties(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in structDecl.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                          let typeAnnotation = binding.typeAnnotation
                    else { continue }

                    let name = pattern.identifier.text
                    let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)
                    let isOptional = type.contains("?")

                    properties.append(PropertyInfo(
                        name: name,
                        type: type,
                        isOptional: isOptional
                    ))
                }
            }
        }

        return properties
    }
}

// MARK: - Supporting Types

struct TestableDTOArguments {
    let mockStrategy: String
    let fixtureJSON: String?
    let includeBuilder: Bool
    let defaultArrayCount: Int
}

// MARK: - Argument Parsing

func parseTestableDTOArguments(from node: AttributeSyntax) throws -> TestableDTOArguments {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        // 기본값 사용
        return TestableDTOArguments(
            mockStrategy: "random",
            fixtureJSON: nil,
            includeBuilder: true,
            defaultArrayCount: 5
        )
    }

    var mockStrategy = "random"
    var fixtureJSON: String?
    var includeBuilder = true
    var defaultArrayCount = 5

    for argument in arguments {
        let label = argument.label?.text ?? ""
        let expr = argument.expression

        switch label {
        case "mockStrategy":
            if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                mockStrategy = memberAccess.declName.baseName.text
            }
        case "fixtureJSON":
            fixtureJSON = extractStringLiteralLocal(from: expr)
        case "includeBuilder":
            if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                includeBuilder = boolLiteral.literal.text == "true"
            }
        case "defaultArrayCount":
            if let intLiteral = expr.as(IntegerLiteralExprSyntax.self) {
                defaultArrayCount = Int(intLiteral.literal.text) ?? 5
            }
        default:
            break
        }
    }

    return TestableDTOArguments(
        mockStrategy: mockStrategy,
        fixtureJSON: fixtureJSON,
        includeBuilder: includeBuilder,
        defaultArrayCount: defaultArrayCount
    )
}

// Local string extraction helper (to avoid dependency on ArgumentParser.swift)
private func extractStringLiteralLocal(from expr: ExprSyntax) -> String? {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
        var result = ""
        for segment in stringLiteral.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result += stringSegment.content.text
            }
        }
        return result.isEmpty ? nil : result
    }
    return nil
}

/// @ResponseDocument 속성에서 fixtureJSON을 추출합니다
private func extractFixtureJSONFromResponseDocument(structDecl: StructDeclSyntax) -> String? {
    for attribute in structDecl.attributes {
        guard let customAttribute = attribute.as(AttributeSyntax.self) else {
            continue
        }

        let attributeName = customAttribute.attributeName.trimmedDescription

        // @ResponseDocument 찾기
        if attributeName == "ResponseDocument" {
            guard let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }

            // fixtureJSON 인자 찾기
            for argument in arguments {
                if argument.label?.text == "fixtureJSON" {
                    return extractStringLiteralLocal(from: argument.expression)
                }
            }
        }
    }

    return nil
}

// MARK: - Errors

enum TestableDTOMacroError: Error, CustomStringConvertible {
    case notAStruct
    case notCodable
    case invalidFixtureJSON

    var description: String {
        switch self {
        case .notAStruct:
            return "@ResponseTestable can only be applied to struct declarations"
        case .notCodable:
            return "@ResponseTestable requires the type to conform to Codable"
        case .invalidFixtureJSON:
            return "fixtureJSON must be a valid JSON string"
        }
    }
}

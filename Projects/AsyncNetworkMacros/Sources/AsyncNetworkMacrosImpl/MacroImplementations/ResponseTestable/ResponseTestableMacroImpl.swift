import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ResponseTestableMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw TestableDTOMacroError.notAStruct
        }

        let typeName = structDecl.name.text
        let parser = TestableDTOArgumentParser()
        let args = try parser.parse(from: node)

        let extractor = FixtureJSONExtractor()
        let documentFixtureJSON = extractor.extract(from: structDecl)
        let fixtureJSON = args.fixtureJSON ?? documentFixtureJSON
        let properties = extractProperties(from: structDecl)

        var members: [DeclSyntax] = []

        members.append(generateMockMethod(typeName: typeName, properties: properties))
        members.append(generateFixtureMethod(typeName: typeName, properties: properties, fixtureJSON: fixtureJSON))
        members.append(generateMockArrayMethod(defaultCount: args.defaultArrayCount))

        // assertValid() 메서드
        members.append(generateAssertValidMethod(properties: properties))

        // jsonSample 프로퍼티 (generateDocumentation: true인 경우)
        if args.generateDocumentation, let json = fixtureJSON {
            members.append(generateJSONSampleProperty(json: json))
        }

        // builder() 메서드 및 Builder 타입 (옵션)
        if args.includeBuilder {
            members.append(generateBuilderMethod(typeName: typeName))
            members.append(
                generateBuilderType(
                    typeName: typeName,
                    properties: properties,
                    defaultArrayCount: args.defaultArrayCount
                )
            )
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

    /// mock() 메서드 생성 (항상 랜덤 값)
    private static func generateMockMethod(
        typeName: String,
        properties: [PropertyInfo]
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
            // JSON을 올바르게 escape (순서 중요: \\ 먼저!)
            let escaped = json
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
                .replacingOccurrences(of: "\u{0008}", with: "\\b")
                .replacingOccurrences(of: "\u{000C}", with: "\\f")

            return """
            /// 고정 값으로 테스트 데이터 생성
            public static func fixture() -> \(raw: typeName) {
                let json = \"\(raw: escaped)\"
                do {
                    return try JSONDecoder().decode(\(raw: typeName).self, from: Data(json.utf8))
                } catch {
                    fatalError("[ResponseTestable] Invalid fixtureJSON for \(raw: typeName): \\(error)")
                }
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

        let validationCode = validations.isEmpty
            ? "// No validation rules"
            : validations.joined(separator: "\n        ")

        return """
        /// 데이터 검증
        public func assertValid() {
            \(raw: validationCode)
        }
        """
    }

    /// jsonSample 프로퍼티 생성 (OpenAPI 문서화용)
    private static func generateJSONSampleProperty(json: String) -> DeclSyntax {
        // 들여쓰기 추가 (빈 줄 제외)
        let indented = json
            .components(separatedBy: .newlines)
            .map { $0.isEmpty ? $0 : "    " + $0 }
            .joined(separator: "\n")

        return """
        /// JSON 샘플 문자열
        ///
        /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
        /// fixtureJSON과 동일한 내용을 포함합니다.
        public static var jsonSample: String {
            \"\"\"
        \(raw: indented)
            \"\"\"
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
    private static func generateBuilderType(
        typeName: String,
        properties: [PropertyInfo],
        defaultArrayCount _: Int
    ) -> DeclSyntax {
        var builderProperties: [String] = []
        var withMethods: [String] = []
        var buildParams: [String] = []

        for prop in properties {
            builderProperties.append("private var \(prop.name): \(prop.type)")

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
        public struct \(raw: typeName)Builder: Sendable {
            \(raw: propertiesCode)

            public init() {
                let fixture = \(raw: typeName).fixture()
                \(raw: properties.map { "self.\($0.name) = fixture.\($0.name)" }.joined(separator: "\n        "))
            }

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

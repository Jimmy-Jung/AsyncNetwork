import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ResponseTestableMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let parser = TestableDTOArgumentParser()
        let args = try parser.parse(from: node)
        
        // Struct 또는 Enum 처리
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expandForStruct(
                structDecl: structDecl,
                args: args
            )
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try expandForEnum(
                enumDecl: enumDecl,
                args: args
            )
        } else {
            throw TestableDTOMacroError.notAStructOrEnum
        }
    }
    
    // MARK: - Struct Expansion
    
    private static func expandForStruct(
        structDecl: StructDeclSyntax,
        args: TestableDTOArguments
    ) throws -> [DeclSyntax] {
        let typeName = structDecl.name.text
        let properties = extractProperties(from: structDecl)

        var members: [DeclSyntax] = []

        // mock() 메서드
        members.append(generateMockMethod(typeName: typeName, properties: properties))
        
        // mockArray() 메서드
        members.append(generateMockArrayMethod(defaultCount: args.defaultArrayCount))

        // assertValid() 메서드
        members.append(generateAssertValidMethod(properties: properties))

        // builder() 메서드 및 Builder 타입 (항상 생성)
        members.append(generateBuilderMethod(typeName: typeName))
        members.append(
            generateBuilderType(
                typeName: typeName,
                properties: properties,
                defaultArrayCount: args.defaultArrayCount
            )
        )

        return members
    }
    
    // MARK: - Enum Expansion
    
    private static func expandForEnum(
        enumDecl: EnumDeclSyntax,
        args: TestableDTOArguments
    ) throws -> [DeclSyntax] {
        let typeName = enumDecl.name.text
        let cases = extractEnumCases(from: enumDecl)

        var members: [DeclSyntax] = []

        // mock() 메서드 (enum용)
        members.append(generateEnumMockMethod(typeName: typeName, cases: cases))
        
        // mockArray() 메서드
        members.append(generateMockArrayMethod(defaultCount: args.defaultArrayCount))

        // assertValid() 메서드 (enum용)
        members.append(generateEnumAssertValidMethod(typeName: typeName, cases: cases))

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

    /// mock() 메서드 생성 (항상 랜덤 값, 단 특수 필드는 고정 값)
    private static func generateMockMethod(
        typeName: String,
        properties: [PropertyInfo]
    ) -> DeclSyntax {
        var initParams: [String] = []

        for prop in properties {
            let mockValue = generateMockValue(
                for: prop.type,
                isOptional: prop.isOptional,
                propertyName: prop.name,
                structName: typeName
            )
            initParams.append("\(prop.name): \(mockValue)")
        }

        let initCode = initParams.joined(separator: ",\n            ")

        return """
        /// 랜덤 값으로 테스트 데이터 생성
        ///
        /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
        /// - 테스트 시 특정 필드만 고정하려면 builder()를 사용하세요
        /// - builder(): fixture 고정 값 기반으로 일부만 커스터마이징
        public static func mock() -> \(raw: typeName) {
            \(raw: typeName)(
                \(raw: initCode)
            )
        }
        """
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

    /// builder() 메서드 생성
    private static func generateBuilderMethod(typeName: String) -> DeclSyntax {
        return """
        /// Builder 패턴으로 유연한 데이터 생성
        ///
        /// Builder는 고정된 fixture 값을 기본값으로 사용합니다.
        /// - 주입하지 않은 값은 일관된 fixture 값을 사용
        /// - 특정 필드만 커스터마이징하고 나머지는 고정 값 사용
        ///
        /// Example:
        /// ```swift
        /// let dto = DTO.builder()
        ///     .with(id: 999)
        ///     .with(name: "Custom")
        ///     .build()
        /// // id와 name만 고정, 나머지는 fixture 값 사용
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
        defaultArrayCount: Int
    ) -> DeclSyntax {
        let builderComponents = generateBuilderComponents(
            typeName: typeName,
            properties: properties,
            defaultArrayCount: defaultArrayCount
        )
        
        return composeBuilderType(
            typeName: typeName,
            components: builderComponents
        )
    }
    
    // MARK: - Builder Component Generation
    
    /// Builder 구성 요소 생성
    private static func generateBuilderComponents(
        typeName: String,
        properties: [PropertyInfo],
        defaultArrayCount: Int
    ) -> BuilderComponents {
        var builderProperties: [String] = []
        var withMethods: [String] = []
        var buildParams: [String] = []
        var initAssignments: [String] = []

        for prop in properties {
            builderProperties.append(generateBuilderProperty(for: prop))
            withMethods.append(generateWithMethod(for: prop))
            buildParams.append(generateBuildParameter(for: prop))
            
            let fixtureValue = generateFixtureValue(
                for: prop.type,
                isOptional: prop.isOptional,
                propertyName: prop.name,
                structName: typeName,
                defaultArrayCount: defaultArrayCount
            )
            initAssignments.append("self.\(prop.name) = \(fixtureValue)")
        }

        return BuilderComponents(
            properties: builderProperties,
            withMethods: withMethods,
            buildParams: buildParams,
            initAssignments: initAssignments
        )
    }
    
    /// Builder 프로퍼티 생성
    private static func generateBuilderProperty(for prop: PropertyInfo) -> String {
        "private var \(prop.name): \(prop.type)"
    }
    
    /// with() 메서드 생성
    private static func generateWithMethod(for prop: PropertyInfo) -> String {
        """
        public func with(\(prop.name): \(prop.type)) -> Self {
                var copy = self
                copy.\(prop.name) = \(prop.name)
                return copy
            }
        """
    }
    
    /// build() 메서드의 파라미터 생성
    private static func generateBuildParameter(for prop: PropertyInfo) -> String {
        "\(prop.name): \(prop.name)"
    }
    
    /// Builder 타입 조립
    private static func composeBuilderType(
        typeName: String,
        components: BuilderComponents
    ) -> DeclSyntax {
        let propertiesCode = components.properties.joined(separator: "\n    ")
        let methodsCode = components.withMethods.joined(separator: "\n    \n    ")
        let buildCode = components.buildParams.joined(separator: ",\n                ")
        let initCode = components.initAssignments.joined(separator: "\n        ")

        return """
        /// Builder 패턴
        ///
        /// 모든 프로퍼티는 고정된 fixture 값으로 초기화됩니다.
        /// - 일관된 고정 값으로 시작하여 원하는 필드만 커스터마이징
        /// - with() 메서드로 원하는 값만 커스터마이징 가능
        /// - 테스트 시나리오별로 특정 필드만 제어할 때 유용
        public struct \(raw: typeName)Builder: Sendable {
            \(raw: propertiesCode)

            public init() {
                \(raw: initCode)
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
    
    // MARK: - Helper Types
    
    /// Builder 구성 요소를 담는 구조체
    private struct BuilderComponents {
        let properties: [String]
        let withMethods: [String]
        let buildParams: [String]
        let initAssignments: [String]
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
    
    // MARK: - Enum Helpers
    
    /// Enum case 정보
    private struct EnumCaseInfo {
        let name: String
        let associatedValueType: String?
    }
    
    /// Enum case 추출
    private static func extractEnumCases(from enumDecl: EnumDeclSyntax) -> [EnumCaseInfo] {
        var cases: [EnumCaseInfo] = []
        
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    
                    // Associated value 타입 추출
                    let associatedValueType: String?
                    if let parameterClause = element.parameterClause {
                        // 첫 번째 파라미터의 타입만 추출 (단순화)
                        if let firstParam = parameterClause.parameters.first {
                            associatedValueType = firstParam.type.description.trimmingCharacters(in: .whitespaces)
                        } else {
                            associatedValueType = nil
                        }
                    } else {
                        associatedValueType = nil
                    }
                    
                    cases.append(EnumCaseInfo(
                        name: caseName,
                        associatedValueType: associatedValueType
                    ))
                }
            }
        }
        
        return cases
    }
    
    /// Enum용 mock() 메서드 생성
    private static func generateEnumMockMethod(
        typeName: String,
        cases: [EnumCaseInfo]
    ) -> DeclSyntax {
        guard !cases.isEmpty else {
            return """
            /// 랜덤 값으로 테스트 데이터 생성
            public static func mock() -> \(raw: typeName) {
                fatalError("Enum에 case가 없습니다")
            }
            """
        }
        
        var switchCases: [String] = []
        for (index, caseInfo) in cases.enumerated() {
            if let associatedType = caseInfo.associatedValueType {
                // Associated value가 있는 경우
                switchCases.append("""
                case \(index):
                        return .\(caseInfo.name)(\(associatedType).mock())
                """)
            } else {
                // Associated value가 없는 경우
                switchCases.append("""
                case \(index):
                        return .\(caseInfo.name)
                """)
            }
        }
        
        let switchCode = switchCases.joined(separator: "\n            ")
        
        return """
        /// 랜덤 값으로 테스트 데이터 생성
        ///
        /// 랜덤하게 enum case 중 하나를 선택하여 생성합니다.
        /// Associated value가 있는 경우 해당 타입의 mock()을 호출합니다.
        public static func mock() -> \(raw: typeName) {
            let randomCase = Int.random(in: 0...\(raw: String(cases.count - 1)))
            switch randomCase {
            \(raw: switchCode)
            default:
                return .\(raw: cases[0].name)\(raw: cases[0].associatedValueType != nil ? "(\(cases[0].associatedValueType!).mock())" : "")
            }
        }
        """
    }
    
    /// Enum용 assertValid() 메서드 생성
    private static func generateEnumAssertValidMethod(
        typeName: String,
        cases: [EnumCaseInfo]
    ) -> DeclSyntax {
        guard !cases.isEmpty else {
            return """
            /// 데이터 검증
            public func assertValid() {
                // No validation rules
            }
            """
        }
        
        var switchCases: [String] = []
        for caseInfo in cases {
            if let associatedType = caseInfo.associatedValueType {
                // Associated value가 있는 경우 검증
                switchCases.append("""
                case let .\(caseInfo.name)(value):
                        try value.assertValid()
                """)
            } else {
                // Associated value가 없는 경우
                switchCases.append("""
                case .\(caseInfo.name):
                        break
                """)
            }
        }
        
        let switchCode = switchCases.joined(separator: "\n            ")
        
        return """
        /// 데이터 검증
        public func assertValid() throws {
            switch self {
            \(raw: switchCode)
            }
        }
        """
    }
}

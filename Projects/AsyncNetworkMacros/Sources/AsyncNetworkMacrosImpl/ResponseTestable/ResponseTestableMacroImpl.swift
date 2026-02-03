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

        // random() 메서드
        members.append(generateRandomMethod(typeName: typeName, properties: properties))
        
        // randomArray() 메서드
        members.append(generateRandomArrayMethod(defaultCount: args.defaultArrayCount))

        // assertValid() 메서드
        members.append(generateAssertValidMethod(properties: properties))

        // fixture() 메서드 및 FixtureBuilder 타입 (항상 생성)
        members.append(generateFixtureMethod(typeName: typeName))
        members.append(
            generateFixtureBuilderType(
                typeName: typeName,
                properties: properties,
                defaultArrayCount: args.defaultArrayCount,
                enumStrategy: args.enumStrategy
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

        // random() 메서드 (enum용)
        members.append(generateEnumRandomMethod(typeName: typeName, cases: cases))
        
        // randomArray() 메서드
        members.append(generateRandomArrayMethod(defaultCount: args.defaultArrayCount))

        // fixture() 메서드 (enum용)
        members.append(generateEnumFixtureMethod(typeName: typeName, cases: cases, strategy: args.enumStrategy))

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

    /// random() 메서드 생성 (항상 랜덤 값, 단 특수 필드는 고정 값)
    private static func generateRandomMethod(
        typeName: String,
        properties: [PropertyInfo]
    ) -> DeclSyntax {
        var initParams: [String] = []

        for prop in properties {
            let randomValue = generateRandomValue(
                for: prop.type,
                isOptional: prop.isOptional,
                propertyName: prop.name,
                structName: typeName,
                generatorName: "generator"
            )
            initParams.append("\(prop.name): \(randomValue)")
        }

        let initCode = initParams.joined(separator: ",\n            ")

        return """
        /// 랜덤 값으로 테스트 데이터 생성 (내부 구현)
        public static func random(seed: Int? = nil, depth: Int = 0) -> \(raw: typeName) {
            if depth > 10 { // 순환 참조 방지 (최대 깊이 10)
                // Optional이면 nil 반환, Non-Optional이면 어쩔 수 없이 진행 (단, ValueGenerator에서 Optional 처리)
                // 여기서는 타입 정보를 모르므로, ValueGenerator에서 depth를 활용하도록 위임
            }
            
            var generator: RandomNumberGenerator = seed != nil ? SeededRandomNumberGenerator(seed: seed!) : SystemRandomNumberGenerator()
            
            return \(raw: typeName)(
                \(raw: initCode)
            )
        }
        
        /// 랜덤 값으로 테스트 데이터 생성 (공개 인터페이스)
        public static func random(seed: Int? = nil) -> \(raw: typeName) {
            random(seed: seed, depth: 0)
        }
        """
    }

    /// randomArray() 메서드 생성
    private static func generateRandomArrayMethod(defaultCount: Int) -> DeclSyntax {
        return """
        /// 여러 개의 Random 데이터 생성
        public static func randomArray(count: Int = \(raw: String(defaultCount)), seed: Int? = nil) -> [Self] {
            var generator: RandomNumberGenerator = seed != nil ? SeededRandomNumberGenerator(seed: seed!) : SystemRandomNumberGenerator()
            // 시드가 있으면 예측 가능한 난수 시퀀스를 위해 시드를 조금씩 변경하거나, 생성기를 공유해야 함.
            // 여기서는 단순화를 위해 시드를 증가시키는 방식 사용
            return (0..<count).map { i in 
                let itemSeed = seed.map { $0 + i }
                return random(seed: itemSeed) 
            }
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

    /// fixture() 메서드 생성
    private static func generateFixtureMethod(typeName: String) -> DeclSyntax {
        return """
        /// Builder 패턴으로 유연한 데이터 생성
        ///
        /// Builder는 고정된 fixture 값을 기본값으로 사용합니다.
        /// - 주입하지 않은 값은 일관된 fixture 값을 사용
        /// - 특정 필드만 커스터마이징하고 나머지는 고정 값 사용
        ///
        /// Example:
        /// ```swift
        /// let dto = DTO.fixture()
        ///     .with(id: 999)
        ///     .with(name: "Custom")
        ///     .build()
        /// // id와 name만 고정, 나머지는 fixture 값 사용
        /// ```
        public static func fixture() -> \(raw: typeName)FixtureBuilder {
            \(raw: typeName)FixtureBuilder()
        }
        
        /// 고정 값으로 테스트 데이터 생성 (내부용)
        public static func fixtureValue() -> \(raw: typeName) {
            fixture().build()
        }
        """
    }

    /// FixtureBuilder 타입 생성
    private static func generateFixtureBuilderType(
        typeName: String,
        properties: [PropertyInfo],
        defaultArrayCount: Int,
        enumStrategy: String
    ) -> DeclSyntax {
        let builderComponents = generateBuilderComponents(
            typeName: typeName,
            properties: properties,
            defaultArrayCount: defaultArrayCount,
            enumStrategy: enumStrategy
        )
        
        return composeFixtureBuilderType(
            typeName: typeName,
            components: builderComponents
        )
    }
    
    // MARK: - Builder Component Generation
    
    /// Builder 구성 요소 생성
    private static func generateBuilderComponents(
        typeName: String,
        properties: [PropertyInfo],
        defaultArrayCount: Int,
        enumStrategy: String
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
                defaultArrayCount: defaultArrayCount,
                enumStrategy: enumStrategy
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
    
    /// FixtureBuilder 타입 조립
    private static func composeFixtureBuilderType(
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
        public struct \(raw: typeName)FixtureBuilder: Sendable {
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
    
    /// Enum용 random() 메서드 생성
    private static func generateEnumRandomMethod(
        typeName: String,
        cases: [EnumCaseInfo]
    ) -> DeclSyntax {
        guard !cases.isEmpty else {
            return """
            /// 랜덤 값으로 테스트 데이터 생성
            public static func random(seed: Int? = nil) -> \(raw: typeName) {
                fatalError("Enum에 case가 없습니다")
            }
            """
        }
        
        var switchCases: [String] = []
        for (index, caseInfo) in cases.enumerated() {
            if let associatedType = caseInfo.associatedValueType {
                // Associated value가 있는 경우
                // 연관 값 생성 시에도 동일한 시드 패턴을 유지하거나, 생성기를 공유해야 함.
                // 여기서는 시드를 전달하는 방식으로 처리
                switchCases.append("""
                case \(index):
                        return .\(caseInfo.name)(\(associatedType).random(seed: seed, depth: depth + 1))
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
        /// 랜덤 값으로 테스트 데이터 생성 (내부 구현)
        public static func random(seed: Int? = nil, depth: Int = 0) -> \(raw: typeName) {
            var generator: RandomNumberGenerator = seed != nil ? SeededRandomNumberGenerator(seed: seed!) : SystemRandomNumberGenerator()
            let randomCase = Int.random(in: 0...\(raw: String(cases.count - 1)), using: &generator)
            switch randomCase {
            \(raw: switchCode)
            default:
                return .\(raw: cases[0].name)\(raw: cases[0].associatedValueType != nil ? "(\(cases[0].associatedValueType!).random(seed: seed, depth: depth + 1))" : "")
            }
        }
        
        /// 랜덤 값으로 테스트 데이터 생성 (공개 인터페이스)
        public static func random(seed: Int? = nil) -> \(raw: typeName) {
            random(seed: seed, depth: 0)
        }
        """
    }
    
    /// Enum용 fixture() 메서드 생성
    private static func generateEnumFixtureMethod(
        typeName: String,
        cases: [EnumCaseInfo],
        strategy: String
    ) -> DeclSyntax {
        guard !cases.isEmpty else {
            return """
            /// 고정 값으로 테스트 데이터 생성
            public static func fixture() -> \(raw: typeName) {
                fatalError("Enum에 case가 없습니다")
            }
            """
        }
        
        // 전략에 따른 케이스 선택
        let selectedCase: EnumCaseInfo
        if strategy == "random" {
            // 랜덤 전략이지만 fixture()는 고정값을 반환해야 하므로
            // 여기서는 첫 번째 케이스를 반환하는 것이 맞음.
            // 하지만 사용자가 명시적으로 random을 원했다면?
            // fixture()의 의미는 "예측 가능한 고정값"이므로 random 전략은 적합하지 않음.
            // 따라서 fixture()는 항상 첫 번째 케이스를 반환하거나,
            // 별도의 로직이 필요함.
            // 여기서는 "firstCase"와 동일하게 처리
            selectedCase = cases[0]
        } else {
            // "firstCase"
            selectedCase = cases[0]
        }
        
        let returnValue: String
        if let associatedType = selectedCase.associatedValueType {
            // 연관 값이 있는 경우 해당 타입의 fixture() 호출
            // Struct에도 fixtureValue() -> Self를 추가했으므로 그것을 호출
            returnValue = ".\(selectedCase.name)(\(associatedType).fixtureValue())"
        } else {
            returnValue = ".\(selectedCase.name)"
        }
        
        return """
        /// 고정 값으로 테스트 데이터 생성
        ///
        /// Enum의 경우 첫 번째 case를 기본값으로 사용합니다.
        public static func fixture() -> \(raw: typeName) {
            return \(raw: returnValue)
        }
        
        /// 고정 값으로 테스트 데이터 생성 (내부용)
        public static func fixtureValue() -> \(raw: typeName) {
            return fixture()
        }
        """
    }
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

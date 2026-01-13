//
//  APIRequestMacroFacade.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// @APIRequest 매크로 Facade
///
/// 이 클래스는 매크로 확장 로직을 다음과 같이 조율합니다:
/// 1. 검증 (Validator)
/// 2. 인자 파싱 (Parser)
/// 3. 코드 생성 (Generators)
///
/// ## 사용 예시
/// ```swift
/// let facade = APIRequestMacroFacade(
///     validator: MacroValidator(),
///     argumentParser: APIRequestArgumentParser(...),
///     pathParser: PathParser()
/// )
///
/// let declarations = try facade.expand(
///     node: node,
///     declaration: declaration,
///     context: context
/// )
/// ```
public struct APIRequestMacroFacade {
    // MARK: - Dependencies

    private let pathParser: PathParser
    private let expressionParser: ExpressionParser

    // MARK: - Initialization

    public init() {
        pathParser = PathParser()
        expressionParser = ExpressionParser()
    }

    // MARK: - Public Methods

    /// 매크로 확장 수행
    ///
    /// - Parameters:
    ///   - node: 매크로 어트리뷰트 노드
    ///   - declaration: 매크로가 적용된 선언
    ///   - context: 매크로 확장 컨텍스트
    /// - Returns: 생성된 멤버 선언 배열
    /// - Throws: 검증 또는 파싱 오류
    public func expand(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. MacroContext 생성
        let macroContext = MacroContext(
            node: node,
            declaration: declaration,
            expansionContext: context
        )

        // 2. 구조체 검증
        guard let structDecl = macroContext.structDecl else {
            throw MacroError.onlyApplicableToStruct
        }

        // 3. 매크로 인자 파싱
        let argumentParser = APIRequestArgumentParser(
            context: macroContext,
            expressionParser: expressionParser,
            pathParser: pathParser
        )

        let args = try argumentParser.parse()

        // 4. 프로퍼티 수집
        let properties = collectProperties(from: structDecl)

        // 5. PropertyWrapper 검증 및 제안
        let validator = PropertyWrapperValidator(
            context: macroContext,
            args: args,
            pathParser: pathParser
        )

        let suggestions = validator.validateAndSuggest()

        // 진단 메시지 발행
        for suggestion in suggestions {
            let diagnostic = suggestion.toDiagnostic(node: structDecl)
            context.diagnose(diagnostic)
        }

        // 6. Generator 실행
        var declarations: [DeclSyntax] = []

        // PropertyGenerator
        let propertyGenerator = PropertyGenerator(args: args)
        declarations.append(contentsOf: propertyGenerator.generate())

        // PathGenerator
        let pathGenerator = PathGenerator(
            args: args,
            pathParser: pathParser,
            properties: properties
        )
        declarations.append(contentsOf: pathGenerator.generate())

        // @APIDocument가 없으면 MetadataGenerator 실행
        if !hasAPIDocumentAttribute(declaration: declaration) {
            let metadataGenerator = MetadataGenerator(
                args: args,
                properties: properties
            )
            declarations.append(contentsOf: metadataGenerator.generate())
        }

        return declarations
    }

    // MARK: - Private Methods

    /// 구조체의 프로퍼티 정보 수집
    private func collectProperties(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for variableDecl in structDecl.variableDeclarations {
            guard let propertyName = variableDecl.firstPropertyName,
                  let typeAnnotation = variableDecl.firstTypeAnnotation
            else {
                continue
            }

            let wrapperType = variableDecl.propertyWrapperType
            let isRequired = !typeAnnotation.isOptional
            let defaultValue = variableDecl.firstInitializer?.value.trimmedDescription

            // HeaderField의 경우 헤더 키 추출
            var headerKey: String?
            if let wrapperAttribute = variableDecl.propertyWrapperAttribute,
               let wrapperName = wrapperAttribute.name,
               wrapperName == "HeaderField" || wrapperName == "CustomHeader",
               let keyArg = wrapperAttribute.argument(labeled: "key") {
                // 문자열 리터럴 시도
                if let literal = try? expressionParser.extractString(from: keyArg) {
                    headerKey = literal
                }
                // Enum case 시도
                else if let enumCase = try? expressionParser.extractEnumCase(from: keyArg) {
                    headerKey = enumCase
                }
            }

            properties.append(PropertyInfo(
                name: propertyName,
                type: typeAnnotation.trimmedDescription,
                wrapperType: wrapperType,
                isRequired: isRequired,
                headerKey: headerKey,
                defaultValue: defaultValue
            ))
        }

        return properties
    }

    /// @APIDocument 어트리뷰트 존재 여부 확인
    private func hasAPIDocumentAttribute(declaration: some DeclGroupSyntax) -> Bool {
        return declaration.findAttribute(named: "APIDocument") != nil
    }
}

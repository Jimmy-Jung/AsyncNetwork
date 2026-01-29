//
//  PropertyWrapperScanner.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax

/// Property Wrapper를 스캔하여 파라미터 정보를 수집하는 유틸리티
struct PropertyWrapperScanner {
    /// Property Wrapper를 스캔하여 파라미터 정보를 수집합니다.
    ///
    /// struct의 모든 멤버를 순회하면서 Property Wrapper 어트리뷰트를 찾고,
    /// 각 프로퍼티의 이름, 타입, 헤더 키, 기본값 등을 추출합니다.
    ///
    /// - Parameter structDecl: 스캔할 struct 선언
    /// - Returns: 추출된 Property Wrapper 정보 배열
    func scan(from structDecl: StructDeclSyntax) -> [PropertyWrapperInfo] {
        var parameters: [PropertyWrapperInfo] = []

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            for attribute in variableDecl.attributes {
                guard let customAttribute = attribute.as(AttributeSyntax.self),
                      let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                else {
                    continue
                }

                let wrapperType = identifier
                let validTypes = [
                    "PathParameter", "QueryParameter",
                    "HeaderParameter", "HeaderField", "CustomHeader",
                    "RequestBody",
                ]
                guard validTypes.contains(wrapperType) else {
                    continue
                }

                // 프로퍼티 이름 추출
                guard let binding = variableDecl.bindings.first,
                      let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
                else {
                    continue
                }
                let propertyName = pattern.identifier.text

                // 타입 추출
                let propertyType = extractPropertyType(from: binding) ?? "String"

                // 옵셔널 여부 확인
                let isOptional = propertyType.hasSuffix("?")

                // HeaderField, CustomHeader의 경우 헤더 키 추출
                var headerKey: String?
                var defaultValue: String?

                if wrapperType == "HeaderField" || wrapperType == "CustomHeader" {
                    // @HeaderField(.authorization) 또는 @CustomHeader("X-Custom-Header")에서 인자 추출
                    if let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self) {
                        let expressionParser = ExpressionParser()
                        for argument in arguments {
                            let expr = argument.expression
                            // HeaderField(.authorization) - enum case
                            if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                                let caseName = memberAccess.declName.baseName.text
                                // HTTPHeaders.HeaderKey enum case를 실제 헤더 이름으로 매핑
                                headerKey = HeaderKeyMapper.map(caseName)
                            }
                            // CustomHeader("X-Custom-Header") - string literal
                            else if let stringLiteral = try? expressionParser.extractString(from: expr) {
                                headerKey = stringLiteral
                            }
                        }
                    }

                    // 기본값 추출 (var userAgent: String? = "MyApp/1.0.0")
                    if let initializer = binding.initializer {
                        let expressionParser = ExpressionParser()
                        if let stringLiteral = try? expressionParser.extractString(from: initializer.value) {
                            defaultValue = stringLiteral
                        } else if initializer.value.is(FunctionCallExprSyntax.self) {
                            // UUID().uuidString 같은 함수 호출은 "UUID()"로 표시
                            defaultValue = initializer.value.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }

                parameters.append(PropertyWrapperInfo(
                    name: propertyName,
                    type: propertyType,
                    wrapperType: wrapperType,
                    isRequired: !isOptional,
                    headerKey: headerKey,
                    defaultValue: defaultValue
                ))
            }
        }

        return parameters
    }

    /// Property의 타입을 추출합니다.
    private func extractPropertyType(from binding: PatternBindingSyntax) -> String? {
        guard let typeAnnotation = binding.typeAnnotation else {
            return nil
        }
        return typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

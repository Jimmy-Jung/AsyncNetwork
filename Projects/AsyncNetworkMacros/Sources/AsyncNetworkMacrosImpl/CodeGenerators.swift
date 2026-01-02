//
//  CodeGenerators.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/02.
//

import Foundation
import SwiftSyntax

// MARK: - Property Wrapper Scanning

/// Property Wrapper를 스캔하여 파라미터 정보를 수집합니다.
func scanPropertyWrappers( // swiftlint:disable:this function_body_length cyclomatic_complexity
    from structDecl: StructDeclSyntax
) -> [PropertyWrapperInfo] {
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
                    for argument in arguments {
                        let expr = argument.expression
                        // HeaderField(.authorization) - enum case
                        if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                            let caseName = memberAccess.declName.baseName.text
                            // HTTPHeaders.HeaderKey enum case를 실제 헤더 이름으로 매핑
                            headerKey = mapHeaderKeyToString(caseName)
                        }
                        // CustomHeader("X-Custom-Header") - string literal
                        else if let stringLiteral = extractStringLiteral(from: expr) {
                            headerKey = stringLiteral
                        }
                    }
                }

                // 기본값 추출 (var userAgent: String? = "MyApp/1.0.0")
                if let initializer = binding.initializer {
                    if let stringLiteral = extractStringLiteral(from: initializer.value) {
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

/// HTTPHeaders.HeaderKey enum case를 실제 HTTP 헤더 이름으로 매핑합니다.
private func mapHeaderKeyToString(_ key: String) -> String {
    let mapping: [String: String] = [
        "contentType": "Content-Type",
        "accept": "Accept",
        "authorization": "Authorization",
        "userAgent": "User-Agent",
        "acceptLanguage": "Accept-Language",
        "appVersion": "X-App-Version",
        "deviceModel": "X-Device-Model",
        "osVersion": "X-OS-Version",
        "bundleId": "X-Bundle-Id",
        "requestId": "X-Request-Id",
        "timestamp": "X-Timestamp",
        "sessionId": "X-Session-Id",
        "clientVersion": "X-Client-Version",
        "platform": "X-Platform",
    ]
    return mapping[key] ?? key
}

// MARK: - Code Generation

/// PropertyWrapperInfo 배열을 ParameterInfo 배열 리터럴로 변환합니다.
/// HeaderField, CustomHeader, RequestBody는 제외합니다 (별도 섹션에서 처리됨)
func generateParametersArray(_ parameters: [PropertyWrapperInfo]) -> String {
    // HeaderField, CustomHeader, RequestBody는 파라미터가 아니므로 제외
    let filteredParameters = parameters.filter {
        !["HeaderField", "CustomHeader", "RequestBody"].contains($0.wrapperType)
    }

    if filteredParameters.isEmpty {
        return "[]"
    }

    let parameterStrings = filteredParameters.map { param in
        let location: String
        switch param.wrapperType {
        case "PathParameter":
            location = ".path"
        case "QueryParameter":
            location = ".query"
        case "HeaderParameter":
            location = ".header"
        case "RequestBody":
            location = ".body"
        default:
            location = ".query"
        }

        return """
        ParameterInfo(
                    id: "\(param.name)",
                    name: "\(param.name)",
                    type: "\(param.type)",
                    location: \(location),
                    isRequired: \(param.isRequired)
                )
        """
    }

    return """
    [
                \(parameterStrings.joined(separator: ",\n                "))
            ]
    """
}

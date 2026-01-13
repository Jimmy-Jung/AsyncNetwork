//
//  SyntaxExtensions.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

// MARK: - StructDeclSyntax Extensions

public extension StructDeclSyntax {
    /// 구조체의 모든 변수 선언 수집
    var variableDeclarations: [VariableDeclSyntax] {
        memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }
    }

    /// 구조체의 모든 프로퍼티 이름 수집
    var propertyNames: Set<String> {
        var names: Set<String> = []

        for member in memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        names.insert(identifier.identifier.text)
                    }
                }
            }

            if let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self) {
                names.insert(typealiasDecl.name.text)
            }
        }

        return names
    }

    /// 특정 이름의 프로퍼티가 존재하는지 확인
    func hasProperty(named name: String) -> Bool {
        propertyNames.contains(name)
    }

    /// initializer가 존재하는지 확인
    var hasInitializer: Bool {
        memberBlock.members.contains { member in
            member.decl.is(InitializerDeclSyntax.self)
        }
    }
}

// MARK: - VariableDeclSyntax Extensions

public extension VariableDeclSyntax {
    /// Property Wrapper 어트리뷰트 찾기
    var propertyWrapperAttribute: AttributeSyntax? {
        let validWrappers = [
            "PathParameter", "QueryParameter",
            "HeaderField", "CustomHeader",
            "RequestBody", "FormData"
        ]

        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                  validWrappers.contains(identifier)
            else {
                continue
            }
            return customAttribute
        }

        return nil
    }

    /// Property Wrapper 타입 이름
    var propertyWrapperType: String? {
        propertyWrapperAttribute?.attributeName.trimmedDescription
    }

    /// 첫 번째 바인딩의 프로퍼티 이름
    var firstPropertyName: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    /// 첫 번째 바인딩의 타입 어노테이션
    var firstTypeAnnotation: TypeAnnotationSyntax? {
        bindings.first?.typeAnnotation
    }

    /// 첫 번째 바인딩의 초기화 표현식
    var firstInitializer: InitializerClauseSyntax? {
        bindings.first?.initializer
    }
}

// MARK: - AttributeSyntax Extensions

public extension AttributeSyntax {
    /// 어트리뷰트 이름
    var name: String? {
        attributeName.as(IdentifierTypeSyntax.self)?.name.text
    }

    /// 레이블된 인자 목록
    var labeledArguments: LabeledExprListSyntax? {
        arguments?.as(LabeledExprListSyntax.self)
    }

    /// 특정 레이블의 인자 표현식 찾기
    func argument(labeled label: String) -> ExprSyntax? {
        guard let arguments = labeledArguments else { return nil }

        for argument in arguments {
            if argument.label?.text == label {
                return argument.expression
            }
        }

        return nil
    }
}

// MARK: - DeclGroupSyntax Extensions

public extension DeclGroupSyntax {
    /// 특정 이름의 어트리뷰트 찾기
    func findAttribute(named name: String) -> AttributeSyntax? {
        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  customAttribute.name == name
            else {
                continue
            }
            return customAttribute
        }
        return nil
    }

    /// 여러 이름의 어트리뷰트 찾기
    func findAttributes(named names: [String]) -> [AttributeSyntax] {
        var result: [AttributeSyntax] = []

        for attribute in attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  let attrName = customAttribute.name,
                  names.contains(attrName)
            else {
                continue
            }
            result.append(customAttribute)
        }

        return result
    }
}

// MARK: - TypeAnnotationSyntax Extensions

public extension TypeAnnotationSyntax {
    /// 타입이 옵셔널인지 확인
    var isOptional: Bool {
        type.trimmedDescription.hasSuffix("?")
    }

    /// 타입 이름 (옵셔널 제거)
    var baseTypeName: String {
        type.trimmedDescription.replacingOccurrences(of: "?", with: "")
    }
}

// MARK: - PatternBindingSyntax Extensions

public extension PatternBindingSyntax {
    /// 프로퍼티 이름
    var propertyName: String? {
        pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    /// 기본값 (초기화 표현식의 값)
    var defaultValue: String? {
        initializer?.value.trimmedDescription
    }
}

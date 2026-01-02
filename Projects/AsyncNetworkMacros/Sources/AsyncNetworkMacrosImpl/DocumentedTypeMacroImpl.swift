//
//  DocumentedTypeMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/02.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - DocumentedTypeMacroError

/// DocumentedType 매크로 에러 타입
public enum DocumentedTypeMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStructOrClass

    public var description: String {
        switch self {
        case .onlyApplicableToStructOrClass:
            return "@DocumentedType can only be applied to a struct or class"
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "DocumentedTypeMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - DocumentedTypeMacroImpl

/// @DocumentedType 매크로 구현
///
/// 타입의 저장 프로퍼티를 스캔하여 타입 구조를 문자열로 생성합니다.
public struct DocumentedTypeMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // struct 또는 class에만 적용 가능
        let typeName: String
        let isStruct: Bool

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
            isStruct = true
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
            isStruct = false
        } else {
            let diagnostic = Diagnostic(
                node: node,
                message: DocumentedTypeMacroError.onlyApplicableToStructOrClass
            )
            context.diagnose(diagnostic)
            return []
        }

        // 저장 프로퍼티 수집
        let properties = collectStoredProperties(from: declaration)

        // 타입 구조 문자열 생성
        let typeKeyword = isStruct ? "struct" : "class"
        let propertiesString = properties.map { prop in
            "    \(prop.keyword) \(prop.name): \(prop.type)"
        }.joined(separator: "\n")

        let typeStructure = """
        \(typeKeyword) \(typeName) {
        \(propertiesString)
        }
        """

        // 이스케이프 처리
        let escapedStructure = typeStructure
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        // relatedTypeNames 프로퍼티 생성 (중첩 타입 이름들)
        let nestedTypeNames = extractNestedTypeNames(from: properties)
        let nestedTypeNamesArray = nestedTypeNames.isEmpty
            ? "[]"
            : "[\(nestedTypeNames.map { "\"\($0)\"" }.joined(separator: ", "))]"

        // typeStructure 프로퍼티 생성
        let structureMember: DeclSyntax =
            """
            public static var typeStructure: String {
                _ = _register  // 등록 강제 실행
                return "\(raw: escapedStructure)"
            }
            """

        // relatedTypeNames 프로퍼티 생성
        let relatedTypesMember: DeclSyntax =
            """
            public static var relatedTypeNames: [String] {
                _ = _register  // 등록 강제 실행
                return \(raw: nestedTypeNamesArray)
            }
            """

        // 자동 등록을 위한 static initializer 생성
        let registrationMember: DeclSyntax =
            """
            private static let _register: Void = {
                TypeRegistry.shared.register(\(raw: typeName).self)
            }()
            """

        return [structureMember, relatedTypesMember, registrationMember]
    }

    // MARK: - ExtensionMacro Implementation

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // TypeStructureProvider 프로토콜 채택
        let ext: DeclSyntax =
            """
            extension \(type.trimmed): TypeStructureProvider {}
            """

        guard let extensionDeclSyntax = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Helper Types

    private struct PropertyInfo {
        let keyword: String // let, var
        let name: String
        let type: String
    }

    /// 저장 프로퍼티를 수집합니다
    private static func collectStoredProperties(
        from declaration: some DeclGroupSyntax
    ) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in declaration.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // 계산 프로퍼티는 제외 (getter가 있으면 계산 프로퍼티)
            let hasGetter = variableDecl.bindings.contains { binding in
                binding.accessorBlock != nil
            }
            if hasGetter {
                continue
            }

            // 프로퍼티 키워드 (let/var)
            let keyword = variableDecl.bindingSpecifier.text

            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation
                else {
                    continue
                }

                let name = pattern.identifier.text
                let type = typeAnnotation.type.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                properties.append(PropertyInfo(
                    keyword: keyword,
                    name: name,
                    type: type
                ))
            }
        }

        return properties
    }

    /// 프로퍼티들로부터 중첩된 커스텀 타입 이름들을 추출합니다
    private static func extractNestedTypeNames(from properties: [PropertyInfo]) -> [String] {
        var typeNames = Set<String>()

        for property in properties {
            let type = property.type

            // 옵셔널 제거
            let typeWithoutOptional = type.hasSuffix("?") ? String(type.dropLast()) : type

            // 배열 체크
            let baseType: String
            if typeWithoutOptional.hasPrefix("["), typeWithoutOptional.hasSuffix("]") {
                baseType = String(typeWithoutOptional.dropFirst().dropLast())
            } else {
                baseType = typeWithoutOptional
            }

            // 프리미티브 타입이 아닌 경우만 추가
            if !isPrimitiveType(baseType) {
                typeNames.insert(baseType)
            }
        }

        return Array(typeNames).sorted()
    }

    /// 프리미티브 타입인지 확인
    private static func isPrimitiveType(_ type: String) -> Bool {
        let primitives = ["Int", "String", "Double", "Bool", "Float", "Int64", "Int32", "UInt", "Date", "Data", "URL"]
        return primitives.contains(type)
    }
}

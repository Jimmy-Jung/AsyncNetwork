//
//  MacroContext.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// 매크로 확장에 필요한 모든 컨텍스트를 담는 컨테이너
///
/// 이 타입은 매크로 관련 모든 정보를 하나의 객체로 관리하여
/// 파라미터 전달을 간소화하고 일관성을 보장합니다.
public struct MacroContext {
    /// 매크로 어트리뷰트 노드
    public let node: AttributeSyntax

    /// 매크로가 적용된 선언
    public let declaration: DeclGroupSyntax

    /// 매크로 확장 컨텍스트
    public let expansionContext: any MacroExpansionContext

    // MARK: - 편의 접근자

    /// 구조체 선언 (매크로가 struct에 적용된 경우)
    public var structDecl: StructDeclSyntax? {
        declaration.as(StructDeclSyntax.self)
    }

    /// 매크로 인자 목록
    public var arguments: LabeledExprListSyntax? {
        node.arguments?.as(LabeledExprListSyntax.self)
    }

    /// 선언의 이름 (예: "GetPostRequest")
    public var declarationName: String? {
        if let structDecl = structDecl {
            return structDecl.name.text
        }
        return nil
    }

    // MARK: - 진단 헬퍼

    /// 에러 진단 발행
    public func diagnoseError(_ message: some DiagnosticMessage) {
        let diagnostic = Diagnostic(node: node, message: message)
        expansionContext.diagnose(diagnostic)
    }

    /// 경고 진단 발행
    public func diagnoseWarning(
        on node: SyntaxProtocol,
        message: some DiagnosticMessage
    ) {
        let diagnostic = Diagnostic(node: node, message: message)
        expansionContext.diagnose(diagnostic)
    }
}

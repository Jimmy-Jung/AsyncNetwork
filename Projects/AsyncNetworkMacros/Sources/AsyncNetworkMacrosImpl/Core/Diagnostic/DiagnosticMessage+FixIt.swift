import SwiftDiagnostics
import SwiftSyntax

/// DiagnosticMessage에 Fix-it 제안을 추가하는 확장
public extension MacroError {
    /// 에러에 대한 Fix-it 제안을 생성합니다
    ///
    /// - Parameters:
    ///   - node: 에러가 발생한 노드
    ///   - replacement: 대체할 코드 (nil이면 Fix-it 없음)
    /// - Returns: Fix-it이 포함된 Diagnostic
    func diagnostic(
        node: some SyntaxProtocol,
        fixIt: FixIt? = nil
    ) -> Diagnostic {
        if let fixIt = fixIt {
            return Diagnostic(
                node: Syntax(node),
                message: self,
                fixIts: [fixIt]
            )
        } else {
            return Diagnostic(
                node: Syntax(node),
                message: self
            )
        }
    }
}

/// Fix-it 생성 헬퍼
public enum FixItBuilder {
    /// struct가 아닌 선언을 struct로 변경하는 Fix-it
    public static func changeToStruct(
        from declaration: some DeclGroupSyntax
    ) -> FixIt? {
        // class, enum, actor 등을 struct로 변경
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            let newDecl = classDecl.with(\.classKeyword, .keyword(.struct))
            return FixIt(
                message: MacroFixItMessage.changeToStruct,
                changes: [
                    .replace(
                        oldNode: Syntax(classDecl.classKeyword),
                        newNode: Syntax(newDecl.classKeyword)
                    )
                ]
            )
        }

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let newDecl = enumDecl.with(\.enumKeyword, .keyword(.struct))
            return FixIt(
                message: MacroFixItMessage.changeToStruct,
                changes: [
                    .replace(
                        oldNode: Syntax(enumDecl.enumKeyword),
                        newNode: Syntax(newDecl.enumKeyword)
                    )
                ]
            )
        }

        if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            let newDecl = actorDecl.with(\.actorKeyword, .keyword(.struct))
            return FixIt(
                message: MacroFixItMessage.changeToStruct,
                changes: [
                    .replace(
                        oldNode: Syntax(actorDecl.actorKeyword),
                        newNode: Syntax(newDecl.actorKeyword)
                    )
                ]
            )
        }

        return nil
    }

    /// 누락된 인자를 추가하는 Fix-it
    ///
    /// ⚠️ 이 메서드는 복잡도와 실용성을 고려하여 더 이상 사용되지 않습니다.
    /// SwiftSyntax의 불변성으로 인해 AttributeSyntax 전체를 재구성해야 하며,
    /// 사용자가 4개의 필수 인자를 모두 작성해야 하므로 부분적인 Fix-it의 가치가 낮습니다.
    ///
    /// 대신 MacroError 메시지에서 상세한 수동 수정 가이드를 제공합니다.
    @available(*, deprecated, message: "Fix-it 복잡도 대비 실용성이 낮아 제거됨. MacroError 메시지 개선으로 대체.")
    public static func addMissingArgument(
        attribute _: AttributeSyntax,
        argumentName _: String,
        defaultValue _: String
    ) -> FixIt? {
        // 더 이상 Fix-it을 제공하지 않음
        return nil
    }

    /// 잘못된 타입의 인자를 수정하는 Fix-it
    public static func correctArgumentType(
        argument: LabeledExprSyntax,
        expectedType: String,
        suggestion: String
    ) -> FixIt {
        // StringLiteralExprSyntax 또는 MemberAccessExprSyntax로 새 노드 생성
        let newExpression: ExprSyntax = "\(raw: suggestion)"

        return FixIt(
            message: MacroFixItMessage.correctType(expectedType),
            changes: [
                .replace(
                    oldNode: Syntax(argument.expression),
                    newNode: Syntax(newExpression)
                )
            ]
        )
    }
}

/// Fix-it 메시지
public enum MacroFixItMessage: FixItMessage {
    case changeToStruct
    @available(*, deprecated, message: "addArgument Fix-it 제거됨")
    case addArgument(String, String)
    case correctType(String)

    public var message: String {
        switch self {
        case .changeToStruct:
            return "struct로 변경"
        case let .addArgument(name, value):
            // Deprecated: 더 이상 사용되지 않지만 기존 코드 호환성을 위해 유지
            return "'\(name)' 인자 추가: \(value)"
        case let .correctType(type):
            return "타입을 \(type)으로 수정"
        }
    }

    public var fixItID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "FixIt")
    }
}

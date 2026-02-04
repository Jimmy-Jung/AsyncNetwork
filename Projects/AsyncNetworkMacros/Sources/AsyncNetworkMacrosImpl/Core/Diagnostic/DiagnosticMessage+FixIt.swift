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
    case correctType(String)

    public var message: String {
        switch self {
        case .changeToStruct:
            return "struct로 변경"
        case let .correctType(type):
            return "타입을 \(type)으로 수정"
        }
    }

    public var fixItID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "FixIt")
    }
}

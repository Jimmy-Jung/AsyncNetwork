import SwiftDiagnostics
import SwiftSyntax

/// 진단 메시지를 쉽게 생성하는 빌더
///
/// 이 타입은 에러, 경고, 정보 메시지를 일관된 방식으로 생성합니다.
///
/// ## 사용 예시
/// ```swift
/// let builder = DiagnosticBuilder()
///
/// // 에러 생성
/// let error = builder.error(
///     on: node,
///     message: "Invalid argument"
/// )
///
/// // 경고 생성
/// let warning = builder.warning(
///     on: node,
///     message: "Consider using @PathParameter"
/// )
/// ```
public struct DiagnosticBuilder {
    public init() {}

    // MARK: - Error

    /// 에러 진단 생성
    ///
    /// - Parameters:
    ///   - node: 에러가 발생한 노드
    ///   - message: 에러 메시지
    ///   - domain: 진단 도메인 (기본값: "AsyncNetworkMacros")
    ///   - id: 진단 ID (기본값: "Error")
    /// - Returns: Diagnostic 객체
    public func error(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Error"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .error,
                domain: domain,
                id: id
            )
        )
    }

    /// 에러 진단 생성 (DiagnosticMessage 사용)
    ///
    /// - Parameters:
    ///   - node: 에러가 발생한 노드
    ///   - diagnosticMessage: DiagnosticMessage 프로토콜 준수 타입
    /// - Returns: Diagnostic 객체
    public func error(
        on node: some SyntaxProtocol,
        diagnosticMessage: some SwiftDiagnostics.DiagnosticMessage
    ) -> Diagnostic {
        Diagnostic(node: node, message: diagnosticMessage)
    }

    // MARK: - Warning

    /// 경고 진단 생성
    ///
    /// - Parameters:
    ///   - node: 경고가 발생한 노드
    ///   - message: 경고 메시지
    ///   - domain: 진단 도메인 (기본값: "AsyncNetworkMacros")
    ///   - id: 진단 ID (기본값: "Warning")
    /// - Returns: Diagnostic 객체
    public func warning(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Warning"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .warning,
                domain: domain,
                id: id
            )
        )
    }

    // MARK: - Note

    /// 정보 진단 생성
    ///
    /// - Parameters:
    ///   - node: 정보를 표시할 노드
    ///   - message: 정보 메시지
    ///   - domain: 진단 도메인 (기본값: "AsyncNetworkMacros")
    ///   - id: 진단 ID (기본값: "Note")
    /// - Returns: Diagnostic 객체
    public func note(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Note"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .note,
                domain: domain,
                id: id
            )
        )
    }
}

// MARK: - DiagnosticMessage

extension DiagnosticBuilder {
    /// 간단한 진단 메시지
    struct DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {
        let message: String
        let severity: DiagnosticSeverity
        let domain: String
        let id: String

        var diagnosticID: MessageID {
            MessageID(domain: domain, id: id)
        }
    }
}

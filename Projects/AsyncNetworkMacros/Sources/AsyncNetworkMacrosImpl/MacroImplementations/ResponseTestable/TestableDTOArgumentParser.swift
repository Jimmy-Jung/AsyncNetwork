//
//  TestableDTOArgumentParser.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax

/// @ResponseTestable 매크로 인자 파서
struct TestableDTOArgumentParser {
    /// 매크로 인자를 파싱하여 TestableDTOArguments로 변환
    ///
    /// - Parameter node: @ResponseTestable 어트리뷰트 노드
    /// - Returns: 파싱된 인자 (인자가 없으면 기본값 반환)
    func parse(from node: AttributeSyntax) throws -> TestableDTOArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // 기본값 사용
            return TestableDTOArguments(
                mockStrategy: "random",
                fixtureJSON: nil,
                includeBuilder: true,
                defaultArrayCount: 5
            )
        }

        var mockStrategy = "random"
        var fixtureJSON: String?
        var includeBuilder = true
        var defaultArrayCount = 5

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "mockStrategy":
                if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                    mockStrategy = memberAccess.declName.baseName.text
                }
            case "fixtureJSON":
                fixtureJSON = try? ExpressionParser().extractString(from: expr)
            case "includeBuilder":
                if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                    includeBuilder = boolLiteral.literal.text == "true"
                }
            case "defaultArrayCount":
                if let intLiteral = expr.as(IntegerLiteralExprSyntax.self) {
                    defaultArrayCount = Int(intLiteral.literal.text) ?? 5
                }
            default:
                break
            }
        }

        return TestableDTOArguments(
            mockStrategy: mockStrategy,
            fixtureJSON: fixtureJSON,
            includeBuilder: includeBuilder,
            defaultArrayCount: defaultArrayCount
        )
    }
}

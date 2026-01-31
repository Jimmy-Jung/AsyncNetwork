import SwiftSyntax

struct TestableDTOArgumentParser {
    func parse(from node: AttributeSyntax) throws -> TestableDTOArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return TestableDTOArguments(
                defaultArrayCount: 5
            )
        }

        var defaultArrayCount = 5

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "defaultArrayCount":
                if let intLiteral = expr.as(IntegerLiteralExprSyntax.self) {
                    defaultArrayCount = Int(intLiteral.literal.text) ?? 5
                }
            default:
                break
            }
        }

        return TestableDTOArguments(
            defaultArrayCount: defaultArrayCount
        )
    }
}

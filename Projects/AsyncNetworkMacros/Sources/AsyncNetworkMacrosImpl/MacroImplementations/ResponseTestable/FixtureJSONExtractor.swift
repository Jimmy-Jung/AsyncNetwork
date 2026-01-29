import SwiftSyntax

/// @ResponseDocument 속성에서 fixtureJSON을 추출하는 유틸리티
struct FixtureJSONExtractor {
    /// @ResponseDocument 속성에서 fixtureJSON을 추출합니다
    ///
    /// - Parameter structDecl: struct 선언
    /// - Returns: fixtureJSON 문자열 (없으면 nil)
    func extract(from structDecl: StructDeclSyntax) -> String? {
        let expressionParser = ExpressionParser()

        for attribute in structDecl.attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self) else {
                continue
            }

            let attributeName = customAttribute.attributeName.trimmedDescription

            // @ResponseDocument 찾기
            if attributeName == "ResponseDocument" {
                guard let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self) else {
                    continue
                }

                // fixtureJSON 인자 찾기
                for argument in arguments where argument.label?.text == "fixtureJSON" {
                    return try? expressionParser.extractString(from: argument.expression)
                }
            }
        }

        return nil
    }
}

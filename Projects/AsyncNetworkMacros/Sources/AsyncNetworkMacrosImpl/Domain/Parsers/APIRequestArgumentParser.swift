import SwiftSyntax

public struct APIRequestArgumentParser {
    public let context: MacroContext
    public let expressionParser: ExpressionParser
    public let pathParser: PathParser

    public init(
        context: MacroContext,
        expressionParser: ExpressionParser,
        pathParser: PathParser
    ) {
        self.context = context
        self.expressionParser = expressionParser
        self.pathParser = pathParser
    }

    public func parse() throws -> MacroArguments {
        guard let arguments = context.arguments else {
            throw MacroError.missingArguments
        }

        let responseType = try parseResponseType(from: arguments)
        let baseURL = try parseBaseURL(from: arguments)
        let path = try parsePath(from: arguments)
        let method = try parseMethod(from: arguments)

        let title = parseTitle(from: arguments)
        let description = parseDescription(from: arguments)
        let tags = parseTags(from: arguments)

        let testScenarios = parseTestScenarios(from: arguments)
        let errorExamples = parseErrorExamples(from: arguments)
        let includeRetryTests = parseIncludeRetryTests(from: arguments)
        let includePerformanceTests = parseIncludePerformanceTests(from: arguments)

        let optionalPathParameters = pathParser.extractOptionalParameters(from: path)

        return MacroArguments(
            responseType: responseType,
            title: title,
            description: description,
            baseURL: baseURL.value,
            isBaseURLLiteral: baseURL.isLiteral,
            path: path,
            method: method,
            tags: tags,
            optionalPathParameters: optionalPathParameters,
            testScenarios: testScenarios,
            errorExamples: errorExamples,
            includeRetryTests: includeRetryTests,
            includePerformanceTests: includePerformanceTests
        )
    }

    private func parseResponseType(from arguments: LabeledExprListSyntax) throws -> String {
        guard let expr = findArgument(labeled: "response", in: arguments) else {
            throw MacroError.missingRequiredArgument("response")
        }

        do {
            return try expressionParser.extractTypeName(from: expr)
        } catch {
            throw MacroError.invalidArgument("response: \(error.localizedDescription)")
        }
    }

    private func parseBaseURL(from arguments: LabeledExprListSyntax) throws -> (value: String, isLiteral: Bool) {
        guard let expr = findArgument(labeled: "baseURL", in: arguments) else {
            throw MacroError.missingRequiredArgument("baseURL")
        }

        if let literal = try? expressionParser.extractString(from: expr) {
            return (literal, true)
        }

        let expression = expressionParser.extractStringOrExpression(from: expr)
        return (expression, false)
    }

    private func parsePath(from arguments: LabeledExprListSyntax) throws -> String {
        guard let expr = findArgument(labeled: "path", in: arguments) else {
            throw MacroError.missingRequiredArgument("path")
        }

        do {
            return try expressionParser.extractString(from: expr)
        } catch {
            throw MacroError.invalidArgument("path: \(error.localizedDescription)")
        }
    }

    private func parseMethod(from arguments: LabeledExprListSyntax) throws -> String {
        guard let expr = findArgument(labeled: "method", in: arguments) else {
            throw MacroError.missingRequiredArgument("method")
        }

        do {
            return try expressionParser.extractEnumCase(from: expr)
        } catch {
            throw MacroError.invalidArgument("method: \(error.localizedDescription)")
        }
    }

    private func parseTitle(from arguments: LabeledExprListSyntax) -> String {
        guard let expr = findArgument(labeled: "title", in: arguments),
              let title = try? expressionParser.extractString(from: expr)
        else {
            return ""
        }
        return title
    }

    private func parseDescription(from arguments: LabeledExprListSyntax) -> String {
        guard let expr = findArgument(labeled: "description", in: arguments),
              let description = try? expressionParser.extractString(from: expr)
        else {
            return ""
        }
        return description
    }

    private func parseTags(from arguments: LabeledExprListSyntax) -> [String] {
        guard let expr = findArgument(labeled: "tags", in: arguments) else {
            return []
        }
        return expressionParser.extractStringArray(from: expr)
    }

    private func parseTestScenarios(from arguments: LabeledExprListSyntax) -> [String] {
        guard let expr = findArgument(labeled: "testScenarios", in: arguments) else {
            return []
        }
        return expressionParser.extractEnumCaseArray(from: expr)
    }

    private func parseErrorExamples(from arguments: LabeledExprListSyntax) -> [String: String] {
        guard let expr = findArgument(labeled: "errorExamples", in: arguments) else {
            return [:]
        }
        return expressionParser.extractStringDictionary(from: expr)
    }

    private func parseIncludeRetryTests(from arguments: LabeledExprListSyntax) -> Bool {
        guard let expr = findArgument(labeled: "includeRetryTests", in: arguments),
              let value = try? expressionParser.extractBoolean(from: expr)
        else {
            return true
        }
        return value
    }

    private func parseIncludePerformanceTests(from arguments: LabeledExprListSyntax) -> Bool {
        guard let expr = findArgument(labeled: "includePerformanceTests", in: arguments),
              let value = try? expressionParser.extractBoolean(from: expr)
        else {
            return false
        }
        return value
    }

    private func findArgument(
        labeled label: String,
        in arguments: LabeledExprListSyntax
    ) -> ExprSyntax? {
        for argument in arguments where argument.label?.text == label {
            return argument.expression
        }
        return nil
    }
}

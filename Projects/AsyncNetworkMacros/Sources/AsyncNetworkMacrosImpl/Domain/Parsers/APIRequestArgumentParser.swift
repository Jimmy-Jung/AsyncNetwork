//
//  APIRequestArgumentParser.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// @APIRequest 매크로 인자 파서
///
/// ExpressionParser를 사용하여 매크로 인자를 타입 안전하게 파싱하고
/// MacroArguments 도메인 모델로 변환합니다.
///
/// ## 사용 예시
/// ```swift
/// let parser = APIRequestArgumentParser(
///     context: macroContext,
///     expressionParser: ExpressionParser(),
///     pathParser: PathParser()
/// )
///
/// let args = try parser.parse()
/// // args.responseType == "Post"
/// // args.baseURL == "https://api.example.com"
/// ```
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

    // MARK: - Parse

    /// 매크로 인자를 파싱하여 MacroArguments로 변환
    ///
    /// - Returns: 파싱된 MacroArguments
    /// - Throws: 필수 인자가 없거나 잘못된 형식인 경우
    public func parse() throws -> MacroArguments {
        guard let arguments = context.arguments else {
            throw MacroError.missingArguments
        }

        // 1. 필수 인자 파싱
        let responseType = try parseResponseType(from: arguments)
        let baseURL = try parseBaseURL(from: arguments)
        let path = try parsePath(from: arguments)
        let method = try parseMethod(from: arguments)

        // 2. 선택적 인자 파싱
        let title = parseTitle(from: arguments)
        let description = parseDescription(from: arguments)
        let tags = parseTags(from: arguments)

        // 3. 테스트 관련 인자 파싱
        let testScenarios = parseTestScenarios(from: arguments)
        let errorExamples = parseErrorExamples(from: arguments)
        let includeRetryTests = parseIncludeRetryTests(from: arguments)
        let includePerformanceTests = parseIncludePerformanceTests(from: arguments)

        // 4. 경로에서 선택적 파라미터 추출
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

    // MARK: - Required Arguments

    /// response 타입 파싱
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

    /// baseURL 파싱 (문자열 리터럴 또는 표현식)
    private func parseBaseURL(from arguments: LabeledExprListSyntax) throws -> (value: String, isLiteral: Bool) {
        guard let expr = findArgument(labeled: "baseURL", in: arguments) else {
            throw MacroError.missingRequiredArgument("baseURL")
        }

        // 문자열 리터럴 시도
        if let literal = try? expressionParser.extractString(from: expr) {
            return (literal, true)
        }

        // 표현식으로 처리
        let expression = expressionParser.extractStringOrExpression(from: expr)
        return (expression, false)
    }

    /// path 파싱
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

    /// method 파싱
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

    // MARK: - Optional Arguments

    /// title 파싱 (기본값: 빈 문자열)
    private func parseTitle(from arguments: LabeledExprListSyntax) -> String {
        guard let expr = findArgument(labeled: "title", in: arguments),
              let title = try? expressionParser.extractString(from: expr)
        else {
            return ""
        }
        return title
    }

    /// description 파싱 (기본값: 빈 문자열)
    private func parseDescription(from arguments: LabeledExprListSyntax) -> String {
        guard let expr = findArgument(labeled: "description", in: arguments),
              let description = try? expressionParser.extractString(from: expr)
        else {
            return ""
        }
        return description
    }

    /// tags 파싱 (기본값: 빈 배열)
    private func parseTags(from arguments: LabeledExprListSyntax) -> [String] {
        guard let expr = findArgument(labeled: "tags", in: arguments) else {
            return []
        }
        return expressionParser.extractStringArray(from: expr)
    }

    // MARK: - Test Arguments

    /// testScenarios 파싱 (기본값: 빈 배열)
    private func parseTestScenarios(from arguments: LabeledExprListSyntax) -> [String] {
        guard let expr = findArgument(labeled: "testScenarios", in: arguments) else {
            return []
        }
        return expressionParser.extractEnumCaseArray(from: expr)
    }

    /// errorExamples 파싱 (기본값: 빈 딕셔너리)
    private func parseErrorExamples(from arguments: LabeledExprListSyntax) -> [String: String] {
        guard let expr = findArgument(labeled: "errorExamples", in: arguments) else {
            return [:]
        }
        return expressionParser.extractStringDictionary(from: expr)
    }

    /// includeRetryTests 파싱 (기본값: true)
    private func parseIncludeRetryTests(from arguments: LabeledExprListSyntax) -> Bool {
        guard let expr = findArgument(labeled: "includeRetryTests", in: arguments),
              let value = try? expressionParser.extractBoolean(from: expr)
        else {
            return true
        }
        return value
    }

    /// includePerformanceTests 파싱 (기본값: false)
    private func parseIncludePerformanceTests(from arguments: LabeledExprListSyntax) -> Bool {
        guard let expr = findArgument(labeled: "includePerformanceTests", in: arguments),
              let value = try? expressionParser.extractBoolean(from: expr)
        else {
            return false
        }
        return value
    }

    // MARK: - Helper

    /// 특정 레이블의 인자 찾기
    private func findArgument(
        labeled label: String,
        in arguments: LabeledExprListSyntax
    ) -> ExprSyntax? {
        for argument in arguments {
            if argument.label?.text == label {
                return argument.expression
            }
        }
        return nil
    }
}

//
//  ExpressionParserTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftParser
    import SwiftSyntax
    import Testing

    @Suite("ExpressionParser Tests")
    struct ExpressionParserTests {
        let parser = ExpressionParser()

        // MARK: - Helper Methods

        /// 소스 코드에서 ExprSyntax 추출
        private func parseExpression(_ code: String) -> ExprSyntax? {
            let source = "let value = \(code)"
            let syntax = Parser.parse(source: source)

            // VariableDecl 찾기
            for item in syntax.statements {
                if let variableDecl = item.item.as(VariableDeclSyntax.self),
                   let binding = variableDecl.bindings.first,
                   let initializer = binding.initializer {
                    return initializer.value
                }
            }

            return nil
        }

        // MARK: - extractTypeName Tests

        @Test("타입 이름 추출 - 단일 타입")
        func testExtractTypeName() throws {
            guard let expr = parseExpression("Post.self") else {
                Issue.record("Failed to parse expression")
                return
            }

            let typeName = try parser.extractTypeName(from: expr)
            #expect(typeName == "Post")
        }

        @Test("타입 이름 추출 - 배열 타입")
        func extractArrayTypeName() throws {
            guard let expr = parseExpression("[Post].self") else {
                Issue.record("Failed to parse expression")
                return
            }

            let typeName = try parser.extractTypeName(from: expr)
            #expect(typeName == "[Post]")
        }

        @Test("타입 이름 추출 - 제네릭 타입")
        func extractGenericTypeName() throws {
            guard let expr = parseExpression("Result<Post, Error>.self") else {
                Issue.record("Failed to parse expression")
                return
            }

            let typeName = try parser.extractTypeName(from: expr)
            #expect(typeName == "Result<Post, Error>")
        }

        // MARK: - extractString Tests

        @Test("문자열 추출 - 단순 리터럴")
        func testExtractString() throws {
            guard let expr = parseExpression("\"hello\"") else {
                Issue.record("Failed to parse expression")
                return
            }

            let string = try parser.extractString(from: expr)
            #expect(string == "hello")
        }

        @Test("문자열 추출 - URL")
        func extractURLString() throws {
            guard let expr = parseExpression("\"https://api.example.com\"") else {
                Issue.record("Failed to parse expression")
                return
            }

            let string = try parser.extractString(from: expr)
            #expect(string == "https://api.example.com")
        }

        @Test("문자열 추출 - 경로")
        func extractPathString() throws {
            guard let expr = parseExpression("\"/posts/{id}\"") else {
                Issue.record("Failed to parse expression")
                return
            }

            let string = try parser.extractString(from: expr)
            #expect(string == "/posts/{id}")
        }

        @Test("문자열 추출 - 빈 문자열 에러")
        func extractEmptyStringThrows() throws {
            guard let expr = parseExpression("\"\"") else {
                Issue.record("Failed to parse expression")
                return
            }

            #expect(throws: ExpressionParserError.self) {
                try parser.extractString(from: expr)
            }
        }

        // MARK: - extractEnumCase Tests

        @Test("Enum case 추출 - GET")
        func extractEnumCaseGet() throws {
            guard let expr = parseExpression(".get") else {
                Issue.record("Failed to parse expression")
                return
            }

            let enumCase = try parser.extractEnumCase(from: expr)
            #expect(enumCase == "get")
        }

        @Test("Enum case 추출 - POST")
        func extractEnumCasePost() throws {
            guard let expr = parseExpression(".post") else {
                Issue.record("Failed to parse expression")
                return
            }

            let enumCase = try parser.extractEnumCase(from: expr)
            #expect(enumCase == "post")
        }

        // MARK: - extractStringArray Tests

        @Test("문자열 배열 추출 - 빈 배열")
        func extractEmptyArray() {
            guard let expr = parseExpression("[]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let array = parser.extractStringArray(from: expr)
            #expect(array.isEmpty)
        }

        @Test("문자열 배열 추출 - 단일 요소")
        func extractSingleElementArray() {
            guard let expr = parseExpression("[\"tag1\"]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let array = parser.extractStringArray(from: expr)
            #expect(array == ["tag1"])
        }

        @Test("문자열 배열 추출 - 다중 요소")
        func extractMultipleElementsArray() {
            guard let expr = parseExpression("[\"tag1\", \"tag2\", \"tag3\"]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let array = parser.extractStringArray(from: expr)
            #expect(array == ["tag1", "tag2", "tag3"])
        }

        // MARK: - extractEnumCaseArray Tests

        @Test("Enum case 배열 추출")
        func testExtractEnumCaseArray() {
            guard let expr = parseExpression("[.success, .notFound, .serverError]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let array = parser.extractEnumCaseArray(from: expr)
            #expect(array == ["success", "notFound", "serverError"])
        }

        // MARK: - extractStringDictionary Tests

        @Test("딕셔너리 추출 - 빈 딕셔너리")
        func extractEmptyDictionary() {
            guard let expr = parseExpression("[:]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let dict = parser.extractStringDictionary(from: expr)
            #expect(dict.isEmpty)
        }

        @Test("딕셔너리 추출 - 단일 요소")
        func extractSingleElementDictionary() {
            guard let expr = parseExpression("[\"404\": \"Not found\"]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let dict = parser.extractStringDictionary(from: expr)
            #expect(dict == ["404": "Not found"])
        }

        @Test("딕셔너리 추출 - 다중 요소")
        func extractMultipleElementsDictionary() {
            guard let expr = parseExpression("[\"404\": \"Not found\", \"500\": \"Server error\"]") else {
                Issue.record("Failed to parse expression")
                return
            }

            let dict = parser.extractStringDictionary(from: expr)
            #expect(dict == ["404": "Not found", "500": "Server error"])
        }

        // MARK: - extractBoolean Tests

        @Test("Boolean 추출 - true")
        func extractTrue() throws {
            guard let expr = parseExpression("true") else {
                Issue.record("Failed to parse expression")
                return
            }

            let value = try parser.extractBoolean(from: expr)
            #expect(value == true)
        }

        @Test("Boolean 추출 - false")
        func extractFalse() throws {
            guard let expr = parseExpression("false") else {
                Issue.record("Failed to parse expression")
                return
            }

            let value = try parser.extractBoolean(from: expr)
            #expect(value == false)
        }

        // MARK: - extractStringOrExpression Tests

        @Test("문자열 또는 표현식 - 리터럴")
        func extractStringOrExpressionLiteral() {
            guard let expr = parseExpression("\"https://api.com\"") else {
                Issue.record("Failed to parse expression")
                return
            }

            let value = parser.extractStringOrExpression(from: expr)
            #expect(value == "https://api.com")
        }

        @Test("문자열 또는 표현식 - 표현식")
        func extractStringOrExpressionExpression() {
            guard let expr = parseExpression("APIConfiguration.baseURL") else {
                Issue.record("Failed to parse expression")
                return
            }

            let value = parser.extractStringOrExpression(from: expr)
            #expect(value == "APIConfiguration.baseURL")
        }
    }

#endif // os(macOS)

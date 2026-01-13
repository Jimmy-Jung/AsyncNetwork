//
//  APIRequestArgumentParserTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftDiagnostics
    import SwiftParser
    import SwiftSyntax
    import SwiftSyntaxMacros
    import Testing

    @Suite("APIRequestArgumentParser Tests")
    struct APIRequestArgumentParserTests {
        // MARK: - Helper Methods

        /// 매크로 코드에서 MacroContext 생성
        private func makeMacroContext(_ macroCode: String) -> MacroContext? {
            let source = """
            \(macroCode)
            struct TestRequest {}
            """

            let syntax = Parser.parse(source: source)

            // StructDeclSyntax 찾기
            for item in syntax.statements {
                if let structDecl = item.item.as(StructDeclSyntax.self) {
                    // AttributeSyntax 찾기
                    for attribute in structDecl.attributes {
                        if let customAttribute = attribute.as(AttributeSyntax.self) {
                            return MacroContext(
                                node: customAttribute,
                                declaration: structDecl,
                                expansionContext: MockMacroExpansionContext()
                            )
                        }
                    }
                }
            }

            return nil
        }

        // MARK: - Required Arguments Tests

        @Test("필수 인자 파싱 - 모두 제공")
        func parseAllRequiredArguments() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.responseType == "Post")
            #expect(args.baseURL == "https://api.example.com")
            #expect(args.isBaseURLLiteral == true)
            #expect(args.path == "/posts")
            #expect(args.method == "get")
        }

        @Test("필수 인자 누락 - response")
        func missingResponseArgument() throws {
            let macroCode = """
            @APIRequest(
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            #expect(throws: MacroError.self) {
                try parser.parse()
            }
        }

        @Test("필수 인자 누락 - baseURL")
        func missingBaseURLArgument() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            #expect(throws: MacroError.self) {
                try parser.parse()
            }
        }

        // MARK: - Optional Arguments Tests

        @Test("선택적 인자 - title, description, tags")
        func optionalArguments() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                title: "Get posts",
                description: "Retrieve all posts",
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get,
                tags: ["Posts", "Read"]
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.title == "Get posts")
            #expect(args.description == "Retrieve all posts")
            #expect(args.tags == ["Posts", "Read"])
        }

        @Test("선택적 인자 생략 - 기본값")
        func optionalArgumentsDefaultValues() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.title == "")
            #expect(args.description == "")
            #expect(args.tags.isEmpty)
            #expect(args.testScenarios.isEmpty)
            #expect(args.errorExamples.isEmpty)
            #expect(args.includeRetryTests == true)
            #expect(args.includePerformanceTests == false)
        }

        // MARK: - BaseURL Tests

        @Test("baseURL - 문자열 리터럴")
        func baseURLLiteral() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.baseURL == "https://api.example.com")
            #expect(args.isBaseURLLiteral == true)
        }

        @Test("baseURL - 표현식")
        func baseURLExpression() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: APIConfiguration.baseURL,
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.baseURL == "APIConfiguration.baseURL")
            #expect(args.isBaseURLLiteral == false)
        }

        // MARK: - Path Tests

        @Test("path - 정적 경로")
        func staticPath() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.path == "/posts")
            #expect(args.optionalPathParameters.isEmpty)
        }

        @Test("path - 동적 경로")
        func dynamicPath() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts/{id}",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.path == "/posts/{id}")
            #expect(args.optionalPathParameters.isEmpty)
        }

        @Test("path - 선택적 파라미터")
        func optionalPathParameter() throws {
            let macroCode = """
            @APIRequest(
                response: Resource.self,
                baseURL: "https://api.example.com",
                path: "/api/{version?}/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.path == "/api/{version?}/posts")
            #expect(args.optionalPathParameters == ["version"])
        }

        // MARK: - Method Tests

        @Test("method - GET")
        func methodGet() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .get
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()
            #expect(args.method == "get")
        }

        @Test("method - POST")
        func methodPost() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts",
                method: .post
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()
            #expect(args.method == "post")
        }

        // MARK: - Test Arguments Tests

        @Test("테스트 인자 - testScenarios, errorExamples")
        func arguments() throws {
            let macroCode = """
            @APIRequest(
                response: Post.self,
                baseURL: "https://api.example.com",
                path: "/posts/{id}",
                method: .get,
                testScenarios: [.success, .notFound],
                errorExamples: ["404": "Not found"]
            )
            """

            guard let context = makeMacroContext(macroCode) else {
                Issue.record("Failed to create MacroContext")
                return
            }

            let parser = APIRequestArgumentParser(
                context: context,
                expressionParser: ExpressionParser(),
                pathParser: PathParser()
            )

            let args = try parser.parse()

            #expect(args.testScenarios == ["success", "notFound"])
            #expect(args.errorExamples == ["404": "Not found"])
        }
    }

    // MARK: - Mock MacroExpansionContext

    private final class MockMacroExpansionContext: MacroExpansionContext {
        func makeUniqueName(_ name: String) -> SwiftSyntax.TokenSyntax {
            TokenSyntax.identifier(name)
        }

        func diagnose(_: SwiftDiagnostics.Diagnostic) {}

        var lexicalContext: [SwiftSyntax.Syntax] {
            []
        }

        func location<Node>(
            of _: Node,
            at _: PositionInSyntaxNode,
            filePathMode _: SourceLocationFilePathMode
        ) -> AbstractSourceLocation? where Node: SwiftSyntax.SyntaxProtocol {
            nil
        }
    }

#endif // os(macOS)

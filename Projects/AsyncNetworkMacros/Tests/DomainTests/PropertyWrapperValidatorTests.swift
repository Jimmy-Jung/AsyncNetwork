//
//  PropertyWrapperValidatorTests.swift
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

    @Suite("PropertyWrapperValidator Tests")
    struct PropertyWrapperValidatorTests {
        // MARK: - Helper Methods

        private func makeMacroContext(_ code: String) -> MacroContext? {
            let syntax = Parser.parse(source: code)

            for item in syntax.statements {
                if let structDecl = item.item.as(StructDeclSyntax.self) {
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

        // MARK: - PathParameter Validation Tests

        @Test("PathParameter 검증 - 정상")
        func validPathParameter() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts/{id}", method: .get)
            struct GetPostRequest {
                @PathParameter var id: Int
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.isEmpty)
        }

        @Test("PathParameter 검증 - 경로에 없음")
        func pathParameterNotInPath() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .get)
            struct GetPostsRequest {
                @PathParameter var id: Int
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(!suggestions.isEmpty)
        }

        @Test("PathParameter 검증 - 이름 불일치 (유사)")
        func pathParameterNameMismatchSimilar() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts/{postId}", method: .get)
            struct GetPostRequest {
                @PathParameter var PostId: Int
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{postId}",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].suggestedWrapper.contains("key"))
        }

        @Test("PathParameter 검증 - 옵셔널 불일치")
        func pathParameterOptionalMismatch() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts/{id}", method: .get)
            struct GetPostRequest {
                @PathParameter var id: Int?
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].reason.contains("필수값"))
        }

        // MARK: - QueryParameter Validation Tests

        @Test("QueryParameter 검증 - 정상")
        func validQueryParameter() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .get)
            struct GetPostsRequest {
                @QueryParameter var page: Int
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.isEmpty)
        }

        @Test("QueryParameter 검증 - body 키워드 (POST)")
        func queryParameterWithBodyKeyword() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .post)
            struct CreatePostRequest {
                @QueryParameter var body: PostBody
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].suggestedWrapper.contains("RequestBody"))
        }

        // MARK: - RequestBody Validation Tests

        @Test("RequestBody 검증 - 정상 (POST)")
        func validRequestBody() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .post)
            struct CreatePostRequest {
                @RequestBody var body: PostBody
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.isEmpty)
        }

        @Test("RequestBody 검증 - GET 메서드")
        func requestBodyInGetMethod() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .get)
            struct GetPostsRequest {
                @RequestBody var filter: FilterBody
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].reason.contains("GET"))
        }

        // MARK: - Suggestion Tests

        @Test("제안 - PathParameter 누락")
        func suggestPathParameter() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts/{id}", method: .get)
            struct GetPostRequest {
                var id: Int
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].suggestedWrapper.contains("PathParameter"))
        }

        @Test("제안 - QueryParameter 누락 (GET)")
        func suggestQueryParameter() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .get)
            struct GetPostsRequest {
                var page: Int?
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].suggestedWrapper.contains("QueryParameter"))
        }

        @Test("제안 - HeaderField 누락")
        func suggestHeaderField() {
            let code = """
            @APIRequest(response: Post.self, baseURL: "https://api.com", path: "/posts", method: .get)
            struct GetPostsRequest {
                var authorization: String?
            }
            """

            guard let context = makeMacroContext(code) else {
                Issue.record("Failed to create context")
                return
            }

            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let validator = PropertyWrapperValidator(
                context: context,
                args: args,
                pathParser: PathParser()
            )

            let suggestions = validator.validateAndSuggest()
            #expect(suggestions.count == 1)
            #expect(suggestions[0].suggestedWrapper.contains("HeaderField"))
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

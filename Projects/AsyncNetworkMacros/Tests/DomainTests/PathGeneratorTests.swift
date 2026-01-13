//
//  PathGeneratorTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftSyntax
    import Testing

    @Suite("PathGenerator Tests")
    struct PathGeneratorTests {
        @Test("정적 경로 생성")
        func generateStaticPath() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let generator = PathGenerator(
                args: args,
                pathParser: PathParser(),
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let pathDecl = declarations[0].description
            #expect(pathDecl.contains("var path: String"))
            #expect(pathDecl.contains("\"/posts\""))
        }

        @Test("동적 경로 생성 - 단일 플레이스홀더")
        func generateDynamicPathSinglePlaceholder() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "get"
            )

            let generator = PathGenerator(
                args: args,
                pathParser: PathParser(),
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let pathDecl = declarations[0].description
            #expect(pathDecl.contains("var path: String"))
            #expect(pathDecl.contains("/posts/\\(id)"))
        }

        @Test("동적 경로 생성 - 다중 플레이스홀더")
        func generateDynamicPathMultiplePlaceholders() {
            let args = MacroArguments(
                responseType: "Comment",
                baseURL: "https://api.com",
                path: "/posts/{postId}/comments/{commentId}",
                method: "get"
            )

            let generator = PathGenerator(
                args: args,
                pathParser: PathParser(),
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let pathDecl = declarations[0].description
            #expect(pathDecl.contains("var path: String"))
            #expect(pathDecl.contains("/posts/\\(postId)/comments/\\(commentId)"))
        }

        @Test("동적 경로 생성 - 선택적 파라미터")
        func generateDynamicPathOptionalParameter() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id?}",
                method: "get"
            )

            let generator = PathGenerator(
                args: args,
                pathParser: PathParser(),
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let pathDecl = declarations[0].description
            #expect(pathDecl.contains("var path: String"))
            // 정규화되어 {id?} -> {id}로 변환되고, 다시 \(id)로 변환됨
            #expect(pathDecl.contains("/posts/\\(id)"))
        }

        @Test("복잡한 경로 생성")
        func generateComplexPath() {
            let args = MacroArguments(
                responseType: "Resource",
                baseURL: "https://api.com",
                path: "/api/v1/users/{userId}/posts/{postId}/comments",
                method: "get"
            )

            let generator = PathGenerator(
                args: args,
                pathParser: PathParser(),
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let pathDecl = declarations[0].description
            #expect(pathDecl.contains("/api/v1/users/\\(userId)/posts/\\(postId)/comments"))
        }
    }

#endif // os(macOS)

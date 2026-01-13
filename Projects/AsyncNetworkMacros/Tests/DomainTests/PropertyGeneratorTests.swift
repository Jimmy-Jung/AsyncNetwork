//
//  PropertyGeneratorTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftSyntax
    import Testing

    @Suite("PropertyGenerator Tests")
    struct PropertyGeneratorTests {
        @Test("Response typealias 생성")
        func generateResponseTypealias() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let generator = PropertyGenerator(args: args)
            let declarations = generator.generate()

            #expect(declarations.count == 3)

            let typealiasDecl = declarations[0].description
            #expect(typealiasDecl.contains("typealias Response = Post"))
        }

        @Test("baseURLString 생성 - 문자열 리터럴")
        func generateBaseURLStringLiteral() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.example.com",
                isBaseURLLiteral: true,
                path: "/posts",
                method: "get"
            )

            let generator = PropertyGenerator(args: args)
            let declarations = generator.generate()

            let baseURLDecl = declarations[1].description
            #expect(baseURLDecl.contains("var baseURLString: String"))
            #expect(baseURLDecl.contains("\"https://api.example.com\""))
        }

        @Test("baseURLString 생성 - 표현식")
        func generateBaseURLStringExpression() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "APIConfiguration.baseURL",
                isBaseURLLiteral: false,
                path: "/posts",
                method: "get"
            )

            let generator = PropertyGenerator(args: args)
            let declarations = generator.generate()

            let baseURLDecl = declarations[1].description
            #expect(baseURLDecl.contains("var baseURLString: String"))
            #expect(baseURLDecl.contains("APIConfiguration.baseURL"))
            #expect(!baseURLDecl.contains("\"APIConfiguration.baseURL\""))
        }

        @Test("method 생성")
        func generateMethod() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let generator = PropertyGenerator(args: args)
            let declarations = generator.generate()

            let methodDecl = declarations[2].description
            #expect(methodDecl.contains("var method: HTTPMethod"))
            #expect(methodDecl.contains(".post"))
        }

        @Test("모든 프로퍼티 생성")
        func generateAllProperties() {
            let args = MacroArguments(
                responseType: "[User]",
                baseURL: "https://jsonplaceholder.typicode.com",
                path: "/users",
                method: "get"
            )

            let generator = PropertyGenerator(args: args)
            let declarations = generator.generate()

            #expect(declarations.count == 3)

            // Response typealias
            #expect(declarations[0].description.contains("typealias Response = [User]"))

            // baseURLString
            #expect(declarations[1].description.contains("var baseURLString: String"))

            // method
            #expect(declarations[2].description.contains("var method: HTTPMethod"))
            #expect(declarations[2].description.contains(".get"))
        }
    }

#endif // os(macOS)

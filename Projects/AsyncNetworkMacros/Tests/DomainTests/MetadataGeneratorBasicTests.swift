//
//  MetadataGeneratorBasicTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//  Split from MetadataGeneratorTests.swift - Basic metadata generation tests
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftSyntax
    import Testing

    @Suite("MetadataGenerator Basic Tests")
    struct MetadataGeneratorBasicTests {
        @Test("기본 메타데이터 생성")
        func generateBasicMetadata() {
            let args = MacroArguments(
                responseType: "Post",
                title: "Get Posts",
                description: "Retrieve all posts",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get",
                tags: ["Posts", "Read"]
            )

            let generator = MetadataGenerator(
                typeName: "GetPostsRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()

            #expect(declarations.count == 1)

            let metadataDecl = declarations[0].description
            #expect(metadataDecl.contains("var metadata: EndpointMetadata"))
            #expect(metadataDecl.contains("title: \"Get Posts\""))
            #expect(metadataDecl.contains("description: \"Retrieve all posts\""))
            #expect(metadataDecl.contains("method: \"GET\""))
            #expect(metadataDecl.contains("path: \"/posts\""))
            #expect(metadataDecl.contains("\"Posts\", \"Read\""))
        }

        @Test("PathParameter 포함 메타데이터")
        func generateMetadataWithPathParameter() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "get"
            )

            let properties = [
                PropertyInfo(
                    name: "id",
                    type: "Int",
                    wrapperType: "PathParameter",
                    isRequired: true
                )
            ]

            let generator = MetadataGenerator(
                typeName: "GetPostRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()

            let metadataDecl = declarations[0].description
            #expect(metadataDecl.contains("parameters: [\"id\"]"))
        }

        @Test("QueryParameter 포함 메타데이터")
        func generateMetadataWithQueryParameter() {
            let args = MacroArguments(
                responseType: "[Post]",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let properties = [
                PropertyInfo(
                    name: "page",
                    type: "Int?",
                    wrapperType: "QueryParameter",
                    isRequired: false
                ),
                PropertyInfo(
                    name: "limit",
                    type: "Int?",
                    wrapperType: "QueryParameter",
                    isRequired: false
                )
            ]

            let generator = MetadataGenerator(
                typeName: "GetPostsRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()

            let metadataDecl = declarations[0].description
            #expect(metadataDecl.contains("parameters: [\"page\", \"limit\"]"))
        }

        @Test("RequestBody 포함 메타데이터")
        func generateMetadataWithRequestBody() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let properties = [
                PropertyInfo(
                    name: "body",
                    type: "PostBody",
                    wrapperType: "RequestBody",
                    isRequired: true
                )
            ]

            let generator = MetadataGenerator(
                typeName: "CreatePostRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()

            let metadataDecl = declarations[0].description
            // RequestBody는 parameters 배열에 포함되지 않음
            #expect(metadataDecl.contains("parameters: [String]()") || metadataDecl.contains("parameters: []"))
        }

        @Test("HeaderField 포함 메타데이터")
        func generateMetadataWithHeaderField() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let properties = [
                PropertyInfo(
                    name: "authorization",
                    type: "String",
                    wrapperType: "HeaderField",
                    isRequired: true,
                    headerKey: "Authorization"
                )
            ]

            let generator = MetadataGenerator(
                typeName: "GetPostsRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()

            let metadataDecl = declarations[0].description
            // HeaderField는 parameters 배열에 포함되지 않음
            #expect(metadataDecl.contains("parameters: [String]()") || metadataDecl.contains("parameters: []"))
        }

        @Test("모든 파라미터 타입 포함 메타데이터")
        func generateMetadataWithAllParameterTypes() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "put"
            )

            let properties = [
                PropertyInfo(
                    name: "id",
                    type: "Int",
                    wrapperType: "PathParameter",
                    isRequired: true
                ),
                PropertyInfo(
                    name: "page",
                    type: "Int?",
                    wrapperType: "QueryParameter",
                    isRequired: false
                ),
                PropertyInfo(
                    name: "authorization",
                    type: "String",
                    wrapperType: "HeaderField",
                    isRequired: true,
                    headerKey: "Authorization"
                ),
                PropertyInfo(
                    name: "body",
                    type: "PostBody",
                    wrapperType: "RequestBody",
                    isRequired: true
                )
            ]

            let generator = MetadataGenerator(
                typeName: "UpdatePostRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()

            let metadataDecl = declarations[0].description
            // PathParameter와 QueryParameter만 parameters 배열에 포함됨
            #expect(metadataDecl.contains("parameters: [\"id\", \"page\"]"))
        }
    }

#endif // os(macOS)

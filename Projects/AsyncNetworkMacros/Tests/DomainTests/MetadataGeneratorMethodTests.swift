//
//  MetadataGeneratorMethodTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//  Split from MetadataGeneratorTests.swift - HTTP method and advanced tests
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftSyntax
    import Testing

    @Suite("MetadataGenerator Method Tests")
    struct MetadataGeneratorMethodTests {
        @Test("HTTP 메서드는 항상 대문자로 생성 - GET")
        func httpMethodAlwaysUppercaseGet() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let generator = MetadataGenerator(
                typeName: "GetPostsRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("method: \"GET\""))
            #expect(!metadataDecl.contains("method: \"get\""))
        }

        @Test("HTTP 메서드는 항상 대문자로 생성 - POST")
        func httpMethodAlwaysUppercasePost() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let generator = MetadataGenerator(
                typeName: "CreatePostRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("method: \"POST\""))
            #expect(!metadataDecl.contains("method: \"post\""))
        }

        @Test("HTTP 메서드는 항상 대문자로 생성 - PATCH")
        func httpMethodAlwaysUppercasePatch() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "patch"
            )

            let generator = MetadataGenerator(
                typeName: "UpdatePostRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("method: \"PATCH\""))
            #expect(!metadataDecl.contains("method: \"patch\""))
        }

        @Test("HTTP 메서드는 항상 대문자로 생성 - DELETE")
        func httpMethodAlwaysUppercaseDelete() {
            let args = MacroArguments(
                responseType: "EmptyResponse",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "delete"
            )

            let generator = MetadataGenerator(
                typeName: "DeletePostRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("method: \"DELETE\""))
            #expect(!metadataDecl.contains("method: \"delete\""))
        }

        @Test("HTTP 메서드는 항상 대문자로 생성 - PUT")
        func httpMethodAlwaysUppercasePut() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts/{id}",
                method: "put"
            )

            let generator = MetadataGenerator(
                typeName: "ReplacePostRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("method: \"PUT\""))
            #expect(!metadataDecl.contains("method: \"put\""))
        }

        @Test("헤더 기본값이 메타데이터에 포함")
        func headerDefaultValuesInMetadata() {
            let args = MacroArguments(
                responseType: "Post",
                baseURL: "https://api.com",
                path: "/posts",
                method: "post"
            )

            let properties = [
                PropertyInfo(
                    name: "contentType",
                    type: "String?",
                    wrapperType: "HeaderField",
                    isRequired: false,
                    headerKey: "Content-Type",
                    defaultValue: "application/json"
                ),
                PropertyInfo(
                    name: "authorization",
                    type: "String?",
                    wrapperType: "HeaderField",
                    isRequired: false,
                    headerKey: "Authorization",
                    defaultValue: nil
                )
            ]

            let generator = MetadataGenerator(
                typeName: "CreatePostRequest",
                args: args,
                properties: properties
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            // 기본값이 있는 헤더만 메타데이터에 포함
            #expect(metadataDecl.contains("\"Content-Type\": \"application/json\""))
            #expect(!metadataDecl.contains("\"Authorization\""))
        }

        @Test("특수문자가 포함된 description은 escape 처리")
        func descriptionWithSpecialCharactersEscaped() {
            let args = MacroArguments(
                responseType: "Post",
                title: "Get Posts",
                description: "Retrieve posts with quotes",
                baseURL: "https://api.com",
                path: "/posts",
                method: "get"
            )

            let generator = MetadataGenerator(
                typeName: "GetPostsRequest",
                args: args,
                properties: []
            )

            let declarations = generator.generate()
            let metadataDecl = declarations[0].description

            #expect(metadataDecl.contains("title: \"Get Posts\""))
            #expect(metadataDecl.contains("description: \"Retrieve posts with quotes\""))
            #expect(metadataDecl.contains("method: \"GET\""))
        }
    }

#endif // os(macOS)

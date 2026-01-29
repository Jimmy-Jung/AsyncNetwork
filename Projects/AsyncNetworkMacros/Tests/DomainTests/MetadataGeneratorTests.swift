//
//  MetadataGeneratorTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    @testable import AsyncNetworkMacrosImpl
    import SwiftSyntax
    import Testing

    @Suite("MetadataGenerator Tests")
    struct MetadataGeneratorTests {
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
            #expect(metadataDecl.contains("parameters: []"))
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
            #expect(metadataDecl.contains("parameters: []"))
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

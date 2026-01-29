//
//  MetadataGeneratorEscapeTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax
import Testing

@testable import AsyncNetworkMacrosImpl

@Suite("MetadataGenerator Escape 처리 테스트")
struct MetadataGeneratorEscapeTests {
    
    // MARK: - 기본 Escape 처리
    
    @Test("백슬래시를 올바르게 escape 처리")
    func testBackslashEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Path\\to\\file",
            description: "C:\\Users\\test",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Path\\\\to\\\\file"))
        #expect(code.contains("C:\\\\Users\\\\test"))
    }
    
    @Test("따옴표를 올바르게 escape 처리")
    func testQuoteEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get \"Post\" by ID",
            description: "Retrieve a \"post\" resource",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Get \\\"Post\\\" by ID"))
        #expect(code.contains("Retrieve a \\\"post\\\" resource"))
    }
    
    @Test("줄바꿈을 올바르게 escape 처리")
    func testNewlineEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get Post",
            description: "Retrieve a post\nWith multiple lines\nAnd more content",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Retrieve a post\\nWith multiple lines\\nAnd more content"))
    }
    
    @Test("탭 문자를 올바르게 escape 처리")
    func testTabEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get\tPost",
            description: "Tab\tseparated\tvalues",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Get\\tPost"))
        #expect(code.contains("Tab\\tseparated\\tvalues"))
    }
    
    @Test("캐리지 리턴을 올바르게 escape 처리")
    func testCarriageReturnEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get\rPost",
            description: "With\rcarriage\rreturn",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Get\\rPost"))
        #expect(code.contains("With\\rcarriage\\rreturn"))
    }
    
    // MARK: - 복합 Escape 처리
    
    @Test("여러 특수 문자를 동시에 escape 처리")
    func testMultipleEscapes() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get \"Post\"\nwith\\backslash",
            description: "Complex\ttext\n\"with\"\rspecial\\chars",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("Get \\\"Post\\\"\\nwith\\\\backslash"))
        #expect(code.contains("Complex\\ttext\\n\\\"with\\\"\\rspecial\\\\chars"))
    }
    
    @Test("JSON 형식 문자열을 올바르게 escape 처리")
    func testJSONStringEscape() {
        let args = MacroArguments(
            responseType: "Post",
            title: "API Endpoint",
            description: "{\"type\": \"post\",\n\"id\": 123}",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("{\\\"type\\\": \\\"post\\\",\\n\\\"id\\\": 123}"))
    }
    
    // MARK: - 빈 문자열 및 기본값
    
    @Test("빈 문자열도 안전하게 처리")
    func testEmptyStrings() {
        let args = MacroArguments(
            responseType: "Post",
            title: "",
            description: "",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("title: \"\""))
        #expect(code.contains("description: \"\""))
    }
    
    // MARK: - 실제 사용 시나리오
    
    @Test("다국어 문자열 처리")
    func testMultilingualStrings() {
        let args = MacroArguments(
            responseType: "Post",
            title: "포스트 조회",
            description: "게시글을 조회합니다\n投稿を取得します\n取得帖子",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("포스트 조회"))
        #expect(code.contains("게시글을 조회합니다\\n投稿を取得します\\n取得帖子"))
    }
    
    @Test("코드 스니펫 포함 설명")
    func testCodeSnippetInDescription() {
        let args = MacroArguments(
            responseType: "Post",
            title: "Get Post",
            description: """
            Example:
            ```swift
            let post = try await service.getPost(id: 1)
            print("Title: \\(post.title)")
            ```
            """,
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        // 백슬래시와 줄바꿈이 모두 escape 처리되어야 함
        #expect(code.contains("\\\\(post.title)"))
        #expect(code.contains("\\n"))
    }
    
    // MARK: - 엣지 케이스
    
    @Test("연속된 특수 문자 처리")
    func testConsecutiveSpecialChars() {
        let args = MacroArguments(
            responseType: "Post",
            title: "\\\\\\",
            description: "\"\"\"",
            baseURL: "https://api.example.com",
            path: "/posts",
            method: "get"
        )
        
        let generator = MetadataGenerator(
            typeName: "TestRequest",
            args: args,
            properties: []
        )
        
        let result = generator.generate()
        #expect(result.count == 1)
        
        let code = result[0].description
        #expect(code.contains("\\\\\\\\\\\\"))  // 6개의 백슬래시 (원본 3개 * 2)
        #expect(code.contains("\\\"\\\"\\\""))  // 6개의 문자 (원본 3개 * 2)
    }
}

//
//  PathParserValidationTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//

import Testing

@testable import AsyncNetworkMacrosImpl

@Suite("PathParser 플레이스홀더 검증 테스트")
struct PathParserValidationTests {
    
    let parser = PathParser()
    
    // MARK: - 유효한 플레이스홀더
    
    @Test("유효한 플레이스홀더 패턴을 올바르게 인식")
    func testValidPlaceholders() {
        let testCases: [(path: String, expected: [String])] = [
            // 기본 패턴
            ("/posts/{id}", ["id"]),
            ("/users/{userId}", ["userId"]),
            ("/api/{user_id}", ["user_id"]),
            
            // 다중 플레이스홀더
            ("/posts/{postId}/comments/{commentId}", ["postId", "commentId"]),
            
            // 선택적 파라미터
            ("/posts/{id?}", ["id"]),
            ("/api/{version?}/users", ["version"]),
            
            // 언더스코어 시작
            ("/items/{_id}", ["_id"]),
            ("/data/{__internal}", ["__internal"])
        ]
        
        for (path, expected) in testCases {
            let result = parser.extractPlaceholders(from: path)
            #expect(result == expected, "Path: \(path) - Expected: \(expected), Got: \(result)")
        }
    }
    
    // MARK: - 무효한 플레이스홀더
    
    @Test("무효한 플레이스홀더 패턴을 무시")
    func testInvalidPlaceholdersIgnored() {
        let testCases: [(path: String, expected: [String])] = [
            // 빈 플레이스홀더
            ("/posts/{}", []),
            
            // 숫자로 시작
            ("/items/{123}", []),
            ("/data/{1id}", []),
            
            // 특수 문자 포함
            ("/posts/{my-id}", []),
            ("/users/{user.id}", []),
            ("/api/{id@user}", []),
            
            // 공백 포함
            ("/items/{my id}", []),
            
            // 혼합 (유효한 것만 반환)
            ("/posts/{id}/users/{123}", ["id"]),
            ("/api/{valid}/{my-invalid}", ["valid"])
        ]
        
        for (path, expected) in testCases {
            let result = parser.extractPlaceholders(from: path)
            #expect(result == expected, "Path: \(path) - Expected: \(expected), Got: \(result)")
        }
    }
    
    // MARK: - 엣지 케이스
    
    @Test("플레이스홀더 없는 경로")
    func testPathWithoutPlaceholders() {
        let paths = [
            "/posts",
            "/api/v1/users",
            "/health/check"
        ]
        
        for path in paths {
            let result = parser.extractPlaceholders(from: path)
            #expect(result.isEmpty, "Path: \(path) should have no placeholders")
        }
    }
    
    @Test("잘못된 중괄호 패턴")
    func testMalformedBracePatterns() {
        let testCases: [(path: String, expected: [String])] = [
            // 닫는 중괄호 없음
            ("/posts/{id", []),
            
            // 여는 중괄호 없음
            ("/posts/id}", []),
            
            // 역순 중괄호
            ("/posts/}id{", []),
            
            // 중첩 중괄호 (외부만 인식)
            ("/posts/{{id}}", ["id"]),
            
            // 연속된 중괄호
            ("/posts/{}}", []),
            ("/posts/{{}}", [])
        ]
        
        for (path, expected) in testCases {
            let result = parser.extractPlaceholders(from: path)
            #expect(result == expected, "Path: \(path) - Expected: \(expected), Got: \(result)")
        }
    }
    
    @Test("복잡한 경로 패턴")
    func testComplexPathPatterns() {
        let testCases: [(path: String, expected: [String])] = [
            // URL 인코딩 문자 (유효)
            ("/posts/{id}/tags/{tagName}", ["id", "tagName"]),
            
            // 긴 경로
            ("/api/v1/organizations/{orgId}/projects/{projectId}/issues/{issueId}", 
             ["orgId", "projectId", "issueId"]),
            
            // 쿼리 파라미터 포함 (쿼리 파라미터의 플레이스홀더도 추출됨 - URL 경로 이후의 { }도 인식)
            // Note: 실제 사용에서는 쿼리 파라미터는 @QueryParameter로 처리하므로 경로에 포함하지 않음
            ("/posts/{id}?page={pageNum}", ["id", "pageNum"]),
            
            // 파일 확장자
            ("/files/{filename}.json", ["filename"])
        ]
        
        for (path, expected) in testCases {
            let result = parser.extractPlaceholders(from: path)
            #expect(result == expected, "Path: \(path) - Expected: \(expected), Got: \(result)")
        }
    }
    
    // MARK: - 선택적 파라미터 추출
    
    @Test("선택적 파라미터를 올바르게 추출")
    func testOptionalParameterExtraction() {
        let testCases: [(path: String, expected: Set<String>)] = [
            ("/api/{version?}/posts", ["version"]),
            ("/posts/{id}/comments/{commentId?}", ["commentId"]),
            ("/api/{v?}/users/{userId?}", ["v", "userId"]),
            ("/posts/{id}", []) // 선택적 파라미터 없음
        ]
        
        for (path, expected) in testCases {
            let result = parser.extractOptionalParameters(from: path)
            #expect(result == expected, "Path: \(path) - Expected: \(expected), Got: \(result)")
        }
    }
    
    // MARK: - 경로 정규화
    
    @Test("경로 정규화가 ? 를 올바르게 제거")
    func testPathNormalization() {
        let testCases: [(input: String, expected: String)] = [
            ("/api/{version?}/posts", "/api/{version}/posts"),
            ("/posts/{id?}", "/posts/{id}"),
            ("/users/{userId?}/posts/{postId?}", "/users/{userId}/posts/{postId}"),
            ("/posts/{id}", "/posts/{id}") // 변경 없음
        ]
        
        for (input, expected) in testCases {
            let result = parser.normalize(input)
            #expect(result == expected, "Input: \(input) - Expected: \(expected), Got: \(result)")
        }
    }
    
    // MARK: - 이름 유사도
    
    @Test("유사한 이름을 올바르게 판단")
    func testSimilarNames() {
        let similarPairs = [
            ("id", "id"),           // 정확히 일치
            ("userId", "UserID"),   // 대소문자 차이
            ("id", "ids"),          // 복수형
            ("user", "users"),      // 복수형
            ("user_id", "userId"),  // 언더스코어 vs 캐멀케이스
            ("post_id", "postId")   // 언더스코어 vs 캐멀케이스
        ]
        
        for (name1, name2) in similarPairs {
            let result = parser.areSimilar(name1, name2)
            #expect(result, "\(name1) and \(name2) should be similar")
        }
    }
    
    @Test("다른 이름을 올바르게 판단")
    func testDifferentNames() {
        let differentPairs = [
            ("id", "postId"),
            ("userId", "commentId"),
            ("page", "pageSize"),
            ("start", "end")
        ]
        
        for (name1, name2) in differentPairs {
            let result = parser.areSimilar(name1, name2)
            #expect(!result, "\(name1) and \(name2) should be different")
        }
    }
}

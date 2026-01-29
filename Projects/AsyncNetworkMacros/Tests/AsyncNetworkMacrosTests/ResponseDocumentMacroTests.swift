//
//  ResponseDocumentMacroTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

@Suite("@ResponseDocument Macro Tests")
struct ResponseDocumentMacroTests {
    
    // MARK: - 기본 동작 테스트
    
    @Test("@ResponseDocument가 jsonSample 프로퍼티를 생성하는지 확인")
    func testBasicJSONSampleGeneration() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "id": 1,
              "name": "Test"
            }
            \"""
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """
        
        // When & Then
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct UserDTO: Codable, Sendable {
                    let id: Int
                    let name: String
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "id": 1,
                          "name": "Test"
                        }
                        \"""
                    }
                }
                """,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - 복잡한 JSON 테스트
    
    @Test("@ResponseDocument가 중첩된 객체와 배열을 처리하는지 확인")
    func testComplexJSONHandling() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "user": {
                "id": 42,
                "profile": {
                  "name": "John",
                  "email": "john@example.com"
                }
              },
              "posts": [
                {
                  "id": 1,
                  "title": "First Post"
                }
              ]
            }
            \"""
        )
        struct ComplexDTO: Codable, Sendable {
            let user: User
            let posts: [Post]
        }
        """
        
        // When & Then
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct ComplexDTO: Codable, Sendable {
                    let user: User
                    let posts: [Post]
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "user": {
                            "id": 42,
                            "profile": {
                              "name": "John",
                              "email": "john@example.com"
                            }
                          },
                          "posts": [
                            {
                              "id": 1,
                              "title": "First Post"
                            }
                          ]
                        }
                        \"""
                    }
                }
                """,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - 특수 문자 처리 테스트
    
    @Test("@ResponseDocument가 특수 문자를 올바르게 escape 하는지 확인")
    func testSpecialCharacterEscaping() throws {
        // Given
        let source = #"""
        @ResponseDocument(
            fixtureJSON: """
            {
              "message": "Line 1\nLine 2",
              "path": "C:\\Users\\Test",
              "quote": "He said \"Hello\""
            }
            """
        )
        struct MessageDTO: Codable, Sendable {
            let message: String
            let path: String
            let quote: String
        }
        """#
        
        // When & Then - escape 처리는 내부적으로 이루어지므로 정확한 검증은 통합 테스트에서
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: #"""
                struct MessageDTO: Codable, Sendable {
                    let message: String
                    let path: String
                    let quote: String
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        """
                        {
                          "message": "Line 1\nLine 2",
                          "path": "C:\\Users\\Test",
                          "quote": "He said \"Hello\""
                        }
                        """
                    }
                }
                """#,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - 에러 케이스 테스트
    
    @Test("@ResponseDocument가 struct가 아닌 타입에 적용되면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenAppliedToNonStruct() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {"id": 1}
            \"""
        )
        class UserClass {
            let id: Int
        }
        """
        
        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            class UserClass {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ResponseDocument can only be applied to a struct",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    @Test("@ResponseDocument에 fixtureJSON 파라미터가 없으면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenMissingFixtureJSON() throws {
        // Given
        let source = """
        @ResponseDocument
        struct UserDTO: Codable, Sendable {
            let id: Int
        }
        """
        
        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ResponseDocument requires 'fixtureJSON' parameter",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    @Test("@ResponseDocument에 빈 fixtureJSON이 전달되면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenEmptyFixtureJSON() throws {
        // Given
        let source = """
        @ResponseDocument(fixtureJSON: "")
        struct UserDTO: Codable, Sendable {
            let id: Int
        }
        """
        
        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "fixtureJSON parameter cannot be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    @Test("@ResponseDocument에 공백만 있는 fixtureJSON이 전달되면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenWhitespaceOnlyFixtureJSON() throws {
        // Given
        let source = """
        @ResponseDocument(fixtureJSON: "   \\n\\t  ")
        struct UserDTO: Codable, Sendable {
            let id: Int
        }
        """
        
        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "fixtureJSON parameter cannot be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    @Test("@ResponseDocument에 잘못된 JSON이 전달되면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenInvalidJSON() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "id": 1,
              "name": "Test"
            \"""
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
        }
        """
        
        // When & Then - JSON 파싱 에러 메시지는 플랫폼마다 다를 수 있으므로 시작 부분만 확인
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid JSON in fixtureJSON parameter",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    @Test("@ResponseDocument에 중괄호 없는 잘못된 JSON이 전달되면 진단 메시지를 생성하는지 확인")
    func testDiagnosticWhenInvalidJSONNoBrace() throws {
        // Given
        let source = """
        @ResponseDocument(fixtureJSON: "not a json")
        struct UserDTO: Codable, Sendable {
            let id: Int
        }
        """
        
        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid JSON in fixtureJSON parameter",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: [
                "ResponseDocument": ResponseDocumentMacroImpl.self
            ]
        )
    }
    
    // MARK: - 공백 처리 테스트
    
    @Test("@ResponseDocument가 빈 줄의 들여쓰기를 올바르게 처리하는지 확인")
    func testEmptyLineIndentation() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "id": 1,

              "name": "Test"
            }
            \"""
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """
        
        // When & Then
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct UserDTO: Codable, Sendable {
                    let id: Int
                    let name: String
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "id": 1,
                
                          "name": "Test"
                        }
                        \"""
                    }
                }
                """,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - 실제 사용 사례 테스트
    
    @Test("@ResponseDocument가 실제 API 응답 형태의 JSON을 처리하는지 확인")
    func testRealWorldAPIResponse() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "data": {
                "id": 12345,
                "type": "course",
                "attributes": {
                  "title": "Swift Programming",
                  "duration": 3600,
                  "enrolled": true,
                  "tags": ["swift", "ios", "mobile"]
                },
                "relationships": {
                  "instructor": {
                    "data": {
                      "id": 999,
                      "type": "user"
                    }
                  }
                }
              },
              "meta": {
                "timestamp": "2026-01-29T10:00:00Z",
                "version": "1.0"
              }
            }
            \"""
        )
        struct CourseResponseDTO: Codable, Sendable {
            let data: CourseData
            let meta: Meta
        }
        """
        
        // When & Then
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct CourseResponseDTO: Codable, Sendable {
                    let data: CourseData
                    let meta: Meta
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "data": {
                            "id": 12345,
                            "type": "course",
                            "attributes": {
                              "title": "Swift Programming",
                              "duration": 3600,
                              "enrolled": true,
                              "tags": ["swift", "ios", "mobile"]
                            },
                            "relationships": {
                              "instructor": {
                                "data": {
                                  "id": 999,
                                  "type": "user"
                                }
                              }
                            }
                          },
                          "meta": {
                            "timestamp": "2026-01-29T10:00:00Z",
                            "version": "1.0"
                          }
                        }
                        \"""
                    }
                }
                """,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - ResponseTestable과의 통합 테스트
    
    @Test("@ResponseDocument와 @ResponseTestable이 함께 동작하는지 확인")
    func testIntegrationWithResponseTestable() throws {
        // Given
        let source = """
        @ResponseTestable(includeBuilder: false)
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "id": 100,
              "title": "Test Course"
            }
            \"""
        )
        struct CourseDTO: Codable, Sendable {
            let id: Int
            let title: String
        }
        """
        
        // When & Then - ResponseTestable이 fixtureJSON을 올바르게 사용하는지 확인
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct CourseDTO: Codable, Sendable {
                    let id: Int
                    let title: String
                
                    /// 랜덤 값으로 테스트 데이터 생성
                    ///
                    /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                    /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                    /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                    /// - builder(): fixture() 기반으로 일부만 커스터마이징
                    public static func mock() -> CourseDTO {
                        CourseDTO(
                            id: Int.random(in: 1...1000),
                            title: "Mock \\(UUID().uuidString.prefix(8))"
                        )
                    }
                
                    /// 고정 값으로 테스트 데이터 생성
                    public static func fixture() -> CourseDTO {
                        let json = "{\\n  \\"id\\": 100,\\n  \\"title\\": \\"Test Course\\"\\n}"
                        return try! JSONDecoder().decode(CourseDTO.self, from: Data(json.utf8))
                    }
                
                    /// 여러 개의 Mock 데이터 생성
                    public static func mockArray(count: Int = 5) -> [Self] {
                        (0..<count).map { _ in mock() }
                    }
                
                    /// 데이터 검증
                    public func assertValid() {
                        assert(id > 0, "id must be positive")
                        assert(!title.isEmpty, "title must not be empty")
                    }
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "id": 100,
                          "title": "Test Course"
                        }
                        \"""
                    }
                }
                
                extension CourseDTO: TestableDTO {
                }
                """,
                macros: [
                    "ResponseTestable": ResponseTestableMacroImpl.self,
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
    
    // MARK: - 한글 문자열 처리 테스트
    
    @Test("@ResponseDocument가 한글 문자열을 올바르게 처리하는지 확인")
    func testKoreanStringHandling() throws {
        // Given
        let source = """
        @ResponseDocument(
            fixtureJSON: \"""
            {
              "name": "김철수",
              "description": "안녕하세요"
            }
            \"""
        )
        struct UserDTO: Codable, Sendable {
            let name: String
            let description: String
        }
        """
        
        // When & Then
        #expect(throws: Never.self) {
            assertMacroExpansion(
                source,
                expandedSource: """
                struct UserDTO: Codable, Sendable {
                    let name: String
                    let description: String
                
                    /// JSON 샘플 문자열
                    ///
                    /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                    public static var jsonSample: String {
                        \"""
                        {
                          "name": "김철수",
                          "description": "안녕하세요"
                        }
                        \"""
                    }
                }
                """,
                macros: [
                    "ResponseDocument": ResponseDocumentMacroImpl.self
                ]
            )
        }
    }
}

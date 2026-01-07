//
//  OptionalPathParameterTests.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/03.
//

// Swift Macro는 macOS에서만 빌드 가능하므로 테스트도 macOS 전용
#if os(macOS)

    import SwiftSyntax
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacrosImpl

    // MARK: - OptionalPathParameterTests

    @Suite("APIRequest Macro - Optional PathParameter Tests")
    struct OptionalPathParameterTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("선택적 PathParameter - 기본 사용법")
        func optionalPathParameterBasic() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete post(s)",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id?}",
                    method: .delete
                )
                struct DeletePostRequest {
                    @PathParameter var id: Int?
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var id: Int?

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        var result = ""
                        result += "/posts"
                        if let id = self.id {
                            result += "/\\(id)"
                        }
                        return result
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("선택적 PathParameter - 경고 없음")
        func optionalPathParameterNoWarning() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    description: "포스트를 삭제합니다.",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id?}",
                    method: .delete,
                    tags: ["Posts", "Write"]
                )
                struct DeletePostRequest {
                    @PathParameter var id: Int?
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var id: Int?

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        var result = ""
                        result += "/posts"
                        if let id = self.id {
                            result += "/\\(id)"
                        }
                        return result
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("선택적 PathParameter - 복수 파라미터")
        func optionalPathParameterMultiple() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Comment.self,
                    title: "Get comment",
                    baseURL: "https://api.example.com",
                    path: "/posts/{postId}/comments/{commentId?}",
                    method: .get
                )
                struct GetCommentRequest {
                    @PathParameter var postId: Int
                    @PathParameter var commentId: Int?
                }
                """,
                expandedSource: """
                struct GetCommentRequest {
                    @PathParameter var postId: Int
                    @PathParameter var commentId: Int?

                    typealias Response = Comment

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        var result = ""
                        result += "/posts"
                        result += "/\\(self.postId)"
                        result += "/comments"
                        if let commentId = self.commentId {
                            result += "/\\(commentId)"
                        }
                        return result
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetCommentRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("선택적 PathParameter - 필수로 표시했으나 경로는 선택적 (경고)")
        func optionalPathParameterRequiredTypeWarning() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id?}",
                    method: .delete
                )
                struct DeletePostRequest {
                    @PathParameter var id: Int
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var id: Int

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        var result = ""
                        result += "/posts"
                        if let id = self.id {
                            result += "/\\(id)"
                        }
                        return result
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("일반 PathParameter - 옵셔널 타입 사용 시 경고")
        func regularPathParameterOptionalWarning() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .get
                )
                struct GetPostRequest {
                    @PathParameter var id: Int?
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var id: Int?

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter' for 'id': PathParameter는 필수값이어야 합니다. 타입을 'Int'로 변경하거나 경로를 '/.../{id?}'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

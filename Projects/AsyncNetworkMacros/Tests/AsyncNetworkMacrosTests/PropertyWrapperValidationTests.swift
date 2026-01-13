//
//  PropertyWrapperValidationTests.swift
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

    // MARK: - PropertyWrapperValidationTests

    @Suite("APIRequest Macro - PropertyWrapper Validation Tests")
    struct PropertyWrapperValidationTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("PathParameter 검증 - 옵셔널 타입 경고")
        func pathParameterOptionalWarning() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
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
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter' for 'id': PathParameter는 필수값이어야 합니다. 타입을 'Int'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PathParameter 검증 - 이름 불일치 (복수형)")
        func pathParameterNameMismatchPlural() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .delete
                )
                struct DeletePostRequest {
                    @PathParameter var ids: Int
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var ids: Int

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter(key: \"id\")' for 'ids': 경로에 {id}가 있습니다. @PathParameter(key: \"id\")를 사용하거나 프로퍼티 이름을 'id'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PathParameter 검증 - 복수형 + 옵셔널")
        func pathParameterPluralAndOptional() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    description: "포스트를 삭제합니다.",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .delete,
                    tags: ["Posts", "Write"]
                )
                struct DeletePostRequest {
                    @PathParameter var ids: Int?
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var ids: Int?

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter' for 'ids': PathParameter는 필수값이어야 합니다. 타입을 'Int'로 변경하세요",
                        line: 10,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PathParameter 검증 - 완전히 다른 이름")
        func pathParameterCompletelyDifferentName() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{postId}",
                    method: .get
                )
                struct GetPostRequest {
                    @PathParameter var userId: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var userId: Int

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{postId}"
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
                        message: "Consider using '@PathParameter' for 'userId': 경로의 플레이스홀더[postId]와 프로퍼티 이름이 일치하지 않습니다",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("RequestBody 검증 - GET 메서드에서 사용")
        func requestBodyInGetMethod() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [Post].self,
                    title: "Get posts",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    @RequestBody var body: SearchCriteria
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @RequestBody var body: SearchCriteria

                    typealias Response = [Post]

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@QueryParameter' for 'body': GET 메서드에서는 RequestBody를 사용할 수 없습니다",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("QueryParameter 검증 - POST 메서드의 body 키워드")
        func queryParameterWithBodyKeywordInPost() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Create post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                struct CreatePostRequest {
                    @QueryParameter var bodyData: PostBody?
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @QueryParameter var bodyData: PostBody?

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .post
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@RequestBody' for 'bodyData': 'bodyData'는 요청 바디로 보입니다. @RequestBody 사용을 고려하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PathParameter 정상 사용 - 경고 없음")
        func pathParameterValidUsage() {
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
                    @PathParameter var id: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var id: Int

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
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

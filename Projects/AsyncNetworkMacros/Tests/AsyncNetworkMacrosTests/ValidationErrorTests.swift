//
//  ValidationErrorTests.swift
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

    // MARK: - ValidationErrorTests

    @Suite("APIRequest Macro - Validation Error Tests")
    struct ValidationErrorTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("빈 baseURL 문자열")
        func emptyBaseURL() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        ""
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
                macros: testMacros
            )
        }

        @Test("슬래시 없는 경로")
        func pathWithoutLeadingSlash() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("PathParameter 없이 경로 플레이스홀더 사용")
        func pathPlaceholderWithoutPropertyWrapper() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .get
                )
                struct GetPostRequest {
                    var id: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    var id: Int

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
                        message: "Consider using '@PathParameter' for 'id': 경로에 {id}가 있으므로 @PathParameter를 사용하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("QueryParameter 없이 쿼리 관련 프로퍼티 사용")
        func queryPropertyWithoutWrapper() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    var page: Int
                    var limit: Int
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    var page: Int
                    var limit: Int

                    typealias Response = Post

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
                        message: "Consider using '@QueryParameter' for 'page': GET 메서드에서 쿼리 파라미터로 사용될 수 있습니다",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                    DiagnosticSpec(
                        message: "Consider using '@QueryParameter' for 'limit': GET 메서드에서 쿼리 파라미터로 사용될 수 있습니다",
                        line: 9,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("HeaderField 없이 헤더 관련 프로퍼티 사용")
        func headerPropertyWithoutWrapper() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    var authorization: String
                    var contentType: String
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    var authorization: String
                    var contentType: String

                    typealias Response = Post

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
                        message: "Consider using '@HeaderField' for 'authorization': HTTP 헤더로 사용될 수 있습니다 (@HeaderField(key: .authorization) 사용 권장)",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                    DiagnosticSpec(
                        message: "Consider using '@HeaderField' for 'contentType': HTTP 헤더로 사용될 수 있습니다 (@HeaderField(key: .contentType) 사용 권장)",
                        line: 9,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("RequestBody 없이 POST에서 body 프로퍼티 사용")
        func bodyPropertyWithoutWrapperInPost() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                struct CreatePostRequest {
                    var body: PostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    var body: PostBody

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
                        message: "Consider using '@RequestBody' for 'body': 요청 바디로 사용될 수 있습니다",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PathParameter 이름 대소문자 불일치")
        func pathParameterCaseMismatch() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{postId}",
                    method: .get
                )
                struct GetPostRequest {
                    @PathParameter var PostId: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var PostId: Int

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
                        message: "Consider using '@PathParameter(key: \"postId\")' for 'PostId': 경로에 {postId}가 있습니다. @PathParameter(key: \"postId\")를 사용하거나 프로퍼티 이름을 'postId'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("중복된 PathParameter 정의")
        func duplicatePathParameters() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .get
                )
                struct GetPostRequest {
                    @PathParameter var id: Int
                    @PathParameter var id2: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var id: Int
                    @PathParameter var id2: Int

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
                        message: "Consider using '@PathParameter(key: \"id\")' for 'id2': 경로에 {id}가 있습니다. @PathParameter(key: \"id\")를 사용하거나 프로퍼티 이름을 'id'로 변경하세요",
                        line: 9,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("여러 RequestBody 정의")
        func multipleRequestBodies() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                struct CreatePostRequest {
                    @RequestBody var body1: PostBody
                    @RequestBody var body2: PostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @RequestBody var body1: PostBody
                    @RequestBody var body2: PostBody

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
                macros: testMacros
            )
        }

        @Test("GET 메서드에서 RequestBody 사용 - 이미 검증되는 경우")
        func requestBodyInGetAlreadyValidated() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    @RequestBody var filter: FilterBody
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @RequestBody var filter: FilterBody

                    typealias Response = Post

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
                        message: "Consider using '@RequestBody' for 'filter': GET 또는 DELETE 메서드에서는 일반적으로 RequestBody를 사용하지 않습니다.",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("경로에 없는 PathParameter")
        func pathParameterNotInPath() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    @PathParameter var id: Int
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @PathParameter var id: Int

                    typealias Response = Post

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
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

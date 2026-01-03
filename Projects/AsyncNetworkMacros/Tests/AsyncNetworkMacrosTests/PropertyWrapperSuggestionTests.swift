//
//  PropertyWrapperSuggestionTests.swift
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

    // MARK: - PropertyWrapperSuggestionTests

    @Suite("APIRequest Macro - PropertyWrapper Suggestion Tests")
    struct PropertyWrapperSuggestionTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("PropertyWrapper 제안 - QueryParameter")
        func suggestQueryParameter() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get posts",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                    var userId: Int?
                    var page: Int?
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    var userId: Int?
                    var page: Int?

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
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "",
                            method: "get",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "Post"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@QueryParameter' for 'userId': GET 메서드의 옵셔널 파라미터는 @QueryParameter를 사용하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                    DiagnosticSpec(
                        message: "Consider using '@QueryParameter' for 'page': GET 메서드의 옵셔널 파라미터는 @QueryParameter를 사용하세요",
                        line: 9,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PropertyWrapper 제안 - PathParameter")
        func suggestPathParameter() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get post by ID",
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
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostRequest",
                            title: "Get post by ID",
                            description: "",
                            method: "get",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "Post"
                        )
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

        @Test("PropertyWrapper 제안 - HeaderField")
        func suggestHeaderField() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Get current user",
                    baseURL: "https://api.example.com",
                    path: "/user/me",
                    method: .get
                )
                struct GetCurrentUserRequest {
                    var authorization: String?
                }
                """,
                expandedSource: """
                struct GetCurrentUserRequest {
                    var authorization: String?

                    typealias Response = User

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/user/me"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetCurrentUserRequest",
                            title: "Get current user",
                            description: "",
                            method: "get",
                            path: "/user/me",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "User"
                        )
                    }
                }

                extension GetCurrentUserRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@HeaderField(key: .authorization) or @CustomHeader(\"authorization\")' for 'authorization': HTTP 헤더는 @HeaderField 또는 @CustomHeader를 사용하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PropertyWrapper 제안 - RequestBody")
        func suggestRequestBody() {
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
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create post",
                            description: "",
                            method: "post",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "Post"
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@RequestBody' for 'body': 요청 바디는 @RequestBody를 사용하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PropertyWrapper 제안 - PathParameter 복수형")
        func suggestPathParameterPlural() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .delete
                )
                struct DeletePostRequest {
                    var ids: Int
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    var ids: Int

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
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "DeletePostRequest",
                            title: "Delete post",
                            description: "",
                            method: "delete",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "EmptyResponse"
                        )
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

        @Test("PropertyWrapper 제안 - PathParameter 오타")
        func suggestPathParameterTypo() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Get user",
                    baseURL: "https://api.example.com",
                    path: "/users/{userId}",
                    method: .get
                )
                struct GetUserRequest {
                    var userld: Int
                }
                """,
                expandedSource: """
                struct GetUserRequest {
                    var userld: Int

                    typealias Response = User

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/users/{userId}"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetUserRequest",
                            title: "Get user",
                            description: "",
                            method: "get",
                            path: "/users/{userId}",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "User"
                        )
                    }
                }

                extension GetUserRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter(key: \"userId\")' for 'userld': 경로에 {userId}가 있습니다. @PathParameter(key: \"userId\")를 사용하거나 프로퍼티 이름을 'userId'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("PropertyWrapper 제안 - PathParameter snake_case")
        func suggestPathParameterSnakeCase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Comment.self,
                    title: "Get comment",
                    baseURL: "https://api.example.com",
                    path: "/posts/{post_id}/comments/{commentId}",
                    method: .get
                )
                struct GetCommentRequest {
                    var postId: Int
                    var commentId: Int
                }
                """,
                expandedSource: """
                struct GetCommentRequest {
                    var postId: Int
                    var commentId: Int

                    typealias Response = Comment

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{post_id}/comments/{commentId}"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetCommentRequest",
                            title: "Get comment",
                            description: "",
                            method: "get",
                            path: "/posts/{post_id}/comments/{commentId}",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "Comment"
                        )
                    }
                }

                extension GetCommentRequest: APIRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter(key: \"post_id\")' for 'postId': 경로에 {post_id}가 있습니다. @PathParameter(key: \"post_id\")를 사용하거나 프로퍼티 이름을 'post_id'로 변경하세요",
                        line: 8,
                        column: 5,
                        severity: .warning
                    ),
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter' for 'commentId': 경로에 {commentId}가 있으므로 @PathParameter를 사용하세요",
                        line: 9,
                        column: 5,
                        severity: .warning
                    ),
                ],
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

//
//  AdvancedExpansionTests.swift
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

    // MARK: - AdvancedExpansionTests

    @Suite("APIRequest Macro - Advanced Expansion Tests")
    struct AdvancedExpansionTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        // MARK: - baseURL Tests

        @Test("baseURL - 표현식 사용 (상수 참조)")
        func baseURLExpression() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    baseURL: APIConfiguration.jsonPlaceholder,
                    path: "/posts/1",
                    method: .get
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        APIConfiguration.jsonPlaceholder
                    }

                    var path: String {
                        "/posts/1"
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

        @Test("baseURL - nil (metadata에 기본값 사용)")
        func baseURLNil() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    path: "/posts/1",
                    method: .get
                )
                struct GetPostRequest {
                    var baseURLString: String {
                        Environment.current.baseURL
                    }
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    var baseURLString: String {
                        Environment.current.baseURL
                    }

                    typealias Response = Post

                    var path: String {
                        "/posts/1"
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

        // MARK: - RequestBody Tests

        @Test("RequestBody PropertyWrapper 사용")
        func requestBodyPropertyWrapper() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Create a post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                struct CreatePostRequest {
                    @RequestBody var body: PostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @RequestBody var body: PostBody

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

        @Test("RequestBody PropertyWrapper + requestBodyExample")
        func requestBodyPropertyWrapperWithExample() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Create a post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post,
                    requestBodyExample: "{\\"title\\": \\"My Post\\", \\"content\\": \\"Hello\\"}"
                )
                struct CreatePostRequest {
                    @RequestBody var body: PostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @RequestBody var body: PostBody

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

        @Test("RequestBody - 옵셔널 타입")
        func requestBodyOptional() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Update a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .patch
                )
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @RequestBody var body: PostBody?
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @RequestBody var body: PostBody?

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .patch
                    }
                }

                extension UpdatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("RequestBody 없이 requestBodyExample만 사용 (레거시)")
        func requestBodyExampleOnly() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Create a post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post,
                    requestBodyExample: "{\\"title\\": \\"My Post\\"}"
                )
                struct CreatePostRequest {
                }
                """,
                expandedSource: """
                struct CreatePostRequest {

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

        // MARK: - Response Tests

        @Test("responseExample 포함")
        func withResponseExample() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/1",
                    method: .get,
                    responseExample: "{\\"id\\": 1, \\"title\\": \\"Hello\\"}"
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/1"
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

        // MARK: - Header Tests

        @Test("CustomHeader 사용")
        func customHeader() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Get user",
                    baseURL: "https://api.example.com",
                    path: "/user",
                    method: .get
                )
                struct GetUserRequest {
                    @CustomHeader("X-API-Key") var apiKey: String = "secret123"
                }
                """,
                expandedSource: """
                struct GetUserRequest {
                    @CustomHeader("X-API-Key") var apiKey: String = "secret123"

                    typealias Response = User

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/user"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetUserRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("HeaderField + CustomHeader 혼합 사용")
        func mixedHeaders() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Get user",
                    baseURL: "https://api.example.com",
                    path: "/user",
                    method: .get
                )
                struct GetUserRequest {
                    @HeaderField(key: .contentType) var contentType: String = "application/json"
                    @CustomHeader("X-API-Key") var apiKey: String = "secret123"
                    @HeaderField(key: .authorization) var auth: String?
                }
                """,
                expandedSource: """
                struct GetUserRequest {
                    @HeaderField(key: .contentType) var contentType: String = "application/json"
                    @CustomHeader("X-API-Key") var apiKey: String = "secret123"
                    @HeaderField(key: .authorization) var auth: String?

                    typealias Response = User

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/user"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetUserRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("HeaderField - 런타임 함수 호출 제외 (UUID)")
        func headerRuntimeFunctionExcluded() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Get user",
                    baseURL: "https://api.example.com",
                    path: "/user",
                    method: .get
                )
                struct GetUserRequest {
                    @HeaderField(key: .requestId) var requestId: String = UUID().uuidString
                    @HeaderField(key: .contentType) var contentType: String = "application/json"
                }
                """,
                expandedSource: """
                struct GetUserRequest {
                    @HeaderField(key: .requestId) var requestId: String = UUID().uuidString
                    @HeaderField(key: .contentType) var contentType: String = "application/json"

                    typealias Response = User

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/user"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetUserRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - PropertyWrapper Scanning Tests

        @Test("PathParameter + QueryParameter 스캔")
        func scanPathAndQueryParameters() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [Post].self,
                    title: "Get user posts",
                    baseURL: "https://api.example.com",
                    path: "/users/{userId}/posts",
                    method: .get
                )
                struct GetUserPostsRequest {
                    @PathParameter var userId: Int
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?
                }
                """,
                expandedSource: """
                struct GetUserPostsRequest {
                    @PathParameter var userId: Int
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?

                    typealias Response = [Post]

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/users/{userId}/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetUserPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("모든 PropertyWrapper 타입 스캔")
        func scanAllPropertyWrapperTypes() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Complex request",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .put
                )
                struct ComplexRequest {
                    @PathParameter var id: Int
                    @QueryParameter var validate: Bool?
                    @HeaderField(key: .authorization) var auth: String
                    @CustomHeader("X-Custom") var custom: String = "value"
                    @RequestBody var body: PostBody
                }
                """,
                expandedSource: """
                struct ComplexRequest {
                    @PathParameter var id: Int
                    @QueryParameter var validate: Bool?
                    @HeaderField(key: .authorization) var auth: String
                    @CustomHeader("X-Custom") var custom: String = "value"
                    @RequestBody var body: PostBody

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .put
                    }
                }

                extension ComplexRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

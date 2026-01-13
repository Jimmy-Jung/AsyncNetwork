//
//  UtilityFunctionTests.swift
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

    // MARK: - UtilityFunctionTests

    @Suite("Utility Function Tests")
    struct UtilityFunctionTests {
        // MARK: - extractArray Tests

        @Test("extractArray - tags 배열 파싱")
        func extractArrayTags() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get posts",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get,
                    tags: ["Posts", "Read", "Public"]
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
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("extractArray - 빈 tags 배열")
        func extractArrayEmpty() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get posts",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get,
                    tags: []
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
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        // MARK: - extractTypeName Tests

        @Test("extractTypeName - 배열 타입")
        func extractArrayType() {
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
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

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
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("extractTypeName - 복잡한 배열 타입")
        func extractComplexArrayType() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [User.Profile].self,
                    title: "Get user profiles",
                    baseURL: "https://api.example.com",
                    path: "/profiles",
                    method: .get
                )
                struct GetProfilesRequest {
                }
                """,
                expandedSource: """
                struct GetProfilesRequest {

                    typealias Response = [User.Profile]

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/profiles"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetProfilesRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        // MARK: - JSON Escape Tests

        @Test("escapeJSONString - 특수문자 처리")
        func jsonEscapeSpecialCharacters() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Create post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post,
                    requestBodyExample: "{\\"title\\": \\"Line1\\\\nLine2\\", \\"quote\\": \\"He said \\\\\\"Hello\\\\\\"\\"}"
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
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("escapeJSONString - 멀티라인 JSON")
        func jsonEscapeMultiline() {
            assertMacroExpansion(
                #"""
                @APIRequest(
                    response: Post.self,
                    title: "Create post",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post,
                    requestBodyExample: """
                    {
                        "title": "My Post",
                        "content": "Hello World"
                    }
                    """
                )
                struct CreatePostRequest {
                }
                """#,
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
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("escapeJSONString - responseExample 특수문자")
        func responseJsonEscape() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get post",
                    baseURL: "https://api.example.com",
                    path: "/posts/1",
                    method: .get,
                    responseExample: "{\\"id\\": 1, \\"title\\": \\"Hello\\\\nWorld\\"}"
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
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        // MARK: - Complex Scenarios

        @Test("복합 시나리오 - 모든 기능 통합")
        func complexIntegration() {
            assertMacroExpansion(
                #"""
                @APIRequest(
                    response: [Post].self,
                    title: "Create multiple posts",
                    description: "Batch create posts with tags",
                    baseURL: APIConfig.baseURL,
                    path: "/posts/batch",
                    method: .post,
                    tags: ["Posts", "Write", "Batch"],
                    requestBodyExample: """
                    {
                        "posts": [
                            {"title": "Post 1"},
                            {"title": "Post 2"}
                        ]
                    }
                    """,
                    responseExample: "[{\\"id\\": 1}, {\\"id\\": 2}]"
                )
                struct BatchCreatePostsRequest {
                    @HeaderField(key: .contentType) var contentType: String = "application/json"
                    @CustomHeader("X-Batch-Size") var batchSize: String = "2"
                    @QueryParameter var validate: Bool?
                    @RequestBody var body: BatchPostBody
                }
                """#,
                expandedSource: """
                struct BatchCreatePostsRequest {
                    @HeaderField(key: .contentType) var contentType: String = "application/json"
                    @CustomHeader("X-Batch-Size") var batchSize: String = "2"
                    @QueryParameter var validate: Bool?
                    @RequestBody var body: BatchPostBody

                    typealias Response = [Post]

                    var baseURLString: String {
                        APIConfig.baseURL
                    }

                    var path: String {
                        "/posts/batch"
                    }

                    var method: HTTPMethod {
                        .post
                    }
                }

                extension BatchCreatePostsRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("description 파라미터 처리")
        func descriptionParameter() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    description: "Retrieves a single post by ID. Returns 404 if not found.",
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
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("다양한 타입의 PathParameter")
        func variousPathParameterTypes() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Resource.self,
                    title: "Get resource",
                    baseURL: "https://api.example.com",
                    path: "/resources/{id}/{version}",
                    method: .get
                )
                struct GetResourceRequest {
                    @PathParameter var id: String
                    @PathParameter var version: Int
                }
                """,
                expandedSource: """
                struct GetResourceRequest {
                    @PathParameter var id: String
                    @PathParameter var version: Int

                    typealias Response = Resource

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/resources/{id}/{version}"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetResourceRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }

        @Test("다양한 타입의 QueryParameter")
        func variousQueryParameterTypes() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [Post].self,
                    title: "Search posts",
                    baseURL: "https://api.example.com",
                    path: "/posts/search",
                    method: .get
                )
                struct SearchPostsRequest {
                    @QueryParameter var query: String?
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?
                    @QueryParameter var published: Bool?
                    @QueryParameter var minRating: Double?
                }
                """,
                expandedSource: """
                struct SearchPostsRequest {
                    @QueryParameter var query: String?
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?
                    @QueryParameter var published: Bool?
                    @QueryParameter var minRating: Double?

                    typealias Response = [Post]

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/search"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension SearchPostsRequest: APIRequest {
                }
                """,
                macros: [
                    "APIRequest": APIRequestMacroImpl.self,
                ]
            )
        }
    }

#endif // os(macOS)

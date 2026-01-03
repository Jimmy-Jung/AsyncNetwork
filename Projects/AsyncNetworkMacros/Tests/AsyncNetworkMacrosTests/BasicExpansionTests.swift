//
//  BasicExpansionTests.swift
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

    // MARK: - BasicExpansionTests

    @Suite("APIRequest Macro - Basic Expansion Tests")
    struct BasicExpansionTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self
        ]

        @Test("기본 매크로 확장 - 모든 프로퍼티 생성")
        func basicExpansion() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    baseURL: "https://api.example.com",
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
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/1"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostRequest",
                            title: "Get a post",
                            description: "",
                            method: "get",
                            path: "/posts/1",
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
                macros: testMacros
            )
        }

        @Test("모든 파라미터를 포함한 전체 확장")
        func fullExpansion() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [Post].self,
                    title: "Get all posts",
                    description: "Retrieve a list of all posts",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts",
                    method: .get,
                    tags: ["Posts", "Read"],
                    responseExample: "[{\\"id\\": 1}]"
                )
                struct GetPostsRequest {
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"

                    typealias Response = [Post]

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
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
                            title: "Get all posts",
                            description: "Retrieve a list of all posts",
                            method: "get",
                            path: "/posts",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: ["Content-Type": "application/json"],
                            tags: ["Posts", "Read"],
                            parameters: [],
                            requestBodyExample: nil,
                            responseExample: \"""
                [{"id": 1}]
                \""",
                            responseTypeName: "[Post]"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("baseURL 없이 확장 (동적 baseURL용)")
        func expansionWithoutBaseURL() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    path: "/posts/1",
                    method: .get
                )
                struct GetPostRequest {
                    let environment: Environment

                    var baseURLString: String {
                        environment.baseURL
                    }
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    let environment: Environment

                    var baseURLString: String {
                        environment.baseURL
                    }

                    typealias Response = Post

                    var path: String {
                        "/posts/1"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostRequest",
                            title: "Get a post",
                            description: "",
                            method: "get",
                            path: "/posts/1",
                            baseURLString: "https://example.com",
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
                macros: testMacros
            )
        }

        @Test("이미 선언된 프로퍼티는 건너뛰기")
        func skipExistingProperties() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Update a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .put
                )
                struct UpdatePostRequest {
                    let id: Int

                    var path: String {
                        "/posts/\\(id)"
                    }
                    let body: PostBody
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {
                    let id: Int

                    var path: String {
                        "/posts/\\(id)"
                    }
                    let body: PostBody

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var method: HTTPMethod {
                        .put
                    }

                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "UpdatePostRequest",
                            title: "Update a post",
                            description: "",
                            method: "put",
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

                extension UpdatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("Property Wrappers와 함께 사용")
        func withPropertyWrappers() {
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
                    @QueryParameter var userId: Int?
                    @QueryParameter var page: Int?
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @QueryParameter var userId: Int?
                    @QueryParameter var page: Int?

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
                            responseTypeName: "[Post]"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("Request Body 예시 포함")
        func withRequestBody() {
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
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create a post",
                            description: "",
                            method: "post",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: \"""
                {"title": "My Post"}
                \""",
                            responseExample: nil,
                            responseTypeName: "Post"
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("다양한 HTTP 메서드 테스트 - POST")
        func postMethod() {
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
                macros: testMacros
            )
        }

        @Test("다양한 HTTP 메서드 테스트 - DELETE")
        func deleteMethod() {
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
                }
                """,
                expandedSource: """
                struct DeletePostRequest {

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
                macros: testMacros
            )
        }
    }

#endif // os(macOS)


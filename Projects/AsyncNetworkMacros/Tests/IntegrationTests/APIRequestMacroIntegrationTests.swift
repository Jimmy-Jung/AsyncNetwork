//
//  APIRequestMacroIntegrationTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacros
    @testable import AsyncNetworkMacrosImpl

    @Suite("APIRequestMacro Integration Tests")
    struct APIRequestMacroIntegrationTests {
        // MARK: - Basic Integration Tests

        @Test("기본 GET 요청 - 전체 확장 테스트")
        func basicGetRequest() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/posts",
                            tags: [],
                            parameters: []
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("동적 경로 - PathParameter 포함")
        func dynamicPathWithPathParameter() {
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
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var id: Int

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://api.example.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts/\\(id)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/posts/{id}",
                            tags: [],
                            parameters: [
                                .path(name: "id", type: "Int", required: true)
                            ]
                        )
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("POST 요청 - RequestBody 포함")
        func postRequestWithBody() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
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

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://api.example.com"
                    }

                    public var method: HTTPMethod {
                        .post
                    }

                    public var path: String {
                        "/posts"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "",
                            description: "",
                            method: "POST",
                            path: "/posts",
                            tags: [],
                            parameters: [
                                .body(type: "PostBody")
                            ]
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("복잡한 요청 - 모든 Property Wrapper 포함")
        func complexRequestWithAllWrappers() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Update User",
                    description: "Update user profile",
                    baseURL: "https://api.example.com",
                    path: "/users/{id}",
                    method: .put,
                    tags: ["Users", "Profile"]
                )
                struct UpdateUserRequest {
                    @PathParameter var id: Int
                    @QueryParameter var notify: Bool?
                    @HeaderField(.authorization) var token: String
                    @RequestBody var body: UserUpdateBody
                }
                """,
                expandedSource: """
                struct UpdateUserRequest {
                    @PathParameter var id: Int
                    @QueryParameter var notify: Bool?
                    @HeaderField(.authorization) var token: String
                    @RequestBody var body: UserUpdateBody

                    public typealias Response = User

                    public var baseURLString: String {
                        "https://api.example.com"
                    }

                    public var method: HTTPMethod {
                        .put
                    }

                    public var path: String {
                        "/users/\\(id)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Update User",
                            description: "Update user profile",
                            method: "PUT",
                            path: "/users/{id}",
                            tags: ["Users", "Profile"],
                            parameters: [
                                .path(name: "id", type: "Int", required: true),
                                .query(name: "notify", type: "Bool", required: false),
                                .header(name: "authorization", type: "String", required: true),
                                .body(type: "UserUpdateBody")
                            ]
                        )
                    }
                }

                extension UpdateUserRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("선택적 경로 파라미터")
        func optionalPathParameter() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Item.self,
                    baseURL: "https://api.example.com",
                    path: "/items/{category?}/{id}",
                    method: .get
                )
                struct GetItemRequest {
                    @PathParameter var category: String?
                    @PathParameter var id: Int
                }
                """,
                expandedSource: """
                struct GetItemRequest {
                    @PathParameter var category: String?
                    @PathParameter var id: Int

                    public typealias Response = Item

                    public var baseURLString: String {
                        "https://api.example.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/items/\\(category)/\\(id)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/items/{category?}/{id}",
                            tags: [],
                            parameters: [
                                .path(name: "category", type: "String", required: false),
                                .path(name: "id", type: "Int", required: true)
                            ]
                        )
                    }
                }

                extension GetItemRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("baseURL 표현식")
        func baseURLExpression() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: APIConfiguration.baseURL,
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    public typealias Response = Post

                    public var baseURLString: String {
                        APIConfiguration.baseURL
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/posts",
                            tags: [],
                            parameters: []
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }
    }

#endif // os(macOS)

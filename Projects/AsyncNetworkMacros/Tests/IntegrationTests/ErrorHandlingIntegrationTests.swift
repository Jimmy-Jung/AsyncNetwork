//
//  ErrorHandlingIntegrationTests.swift
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

    @Suite("Error Handling Integration Tests")
    struct ErrorHandlingIntegrationTests {
        @Test("class에 적용 시 에러")
        func appliedToClass() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    path: "/posts"
                    method: .get
                )
                class GetPostsRequest {
                }
                """
                expandedSource: """
                class GetPostsRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest can only be applied to a struct"
                        line: 1
                        column: 1
                        severity: .error
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("필수 인자 누락 - response")
        func missingResponseArgument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    baseURL: "https://api.com"
                    path: "/posts"
                    method: .get
                )
                struct GetPostsRequest {
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Missing required argument: 'response'."
                        line: 1
                        column: 1
                        severity: .error
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("필수 인자 누락 - baseURL")
        func missingBaseURLArgument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    path: "/posts"
                    method: .get
                )
                struct GetPostsRequest {
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Missing required argument: 'baseURL'."
                        line: 1
                        column: 1
                        severity: .error
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("필수 인자 누락 - path")
        func missingPathArgument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    method: .get
                )
                struct GetPostsRequest {
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Missing required argument: 'path'."
                        line: 1
                        column: 1
                        severity: .error
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("필수 인자 누락 - method")
        func missingMethodArgument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    path: "/posts"
                )
                struct GetPostsRequest {
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Missing required argument: 'method'."
                        line: 1
                        column: 1
                        severity: .error
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("PathParameter가 경로에 없음")
        func pathParameterNotInPath() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    path: "/posts"
                    method: .get
                )
                struct GetPostsRequest {
                    @PathParameter var id: Int
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                    @PathParameter var id: Int

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://api.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: ""
                            description: ""
                            method: "GET"
                            path: "/posts"
                            tags: []
                            parameters: [
                                .path(name: "id", type: "Int", required: true)
                            ]
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter' for 'id': 경로의 플레이스홀더[]와 프로퍼티 이름이 일치하지 않습니다"
                        line: 8
                        column: 5
                        severity: .warning
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("PathParameter 이름 불일치")
        func pathParameterNameMismatch() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    path: "/posts/{postId}"
                    method: .get
                )
                struct GetPostRequest {
                    @PathParameter var PostId: Int
                }
                """
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var PostId: Int

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://api.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts/\\(PostId)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: ""
                            description: ""
                            method: "GET"
                            path: "/posts/{postId}"
                            tags: []
                            parameters: [
                                .path(name: "PostId", type: "Int", required: true)
                            ]
                        )
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@PathParameter(key: \"postId\")' for 'PostId': 경로에 {postId}가 있습니다. @PathParameter(key: \"postId\")를 사용하거나 프로퍼티 이름을 'postId'로 변경하세요"
                        line: 8
                        column: 5
                        severity: .warning
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("RequestBody in GET method")
        func requestBodyInGetMethod() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self
                    baseURL: "https://api.com"
                    path: "/posts"
                    method: .get
                )
                struct GetPostsRequest {
                    @RequestBody var filter: FilterBody
                }
                """
                expandedSource: """
                struct GetPostsRequest {
                    @RequestBody var filter: FilterBody

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://api.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: ""
                            description: ""
                            method: "GET"
                            path: "/posts"
                            tags: []
                            parameters: [
                                .body(type: "FilterBody")
                            ]
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """
                diagnostics: [
                    DiagnosticSpec(
                        message: "Consider using '@QueryParameter' for 'filter': GET 메서드에서는 RequestBody를 사용할 수 없습니다"
                        line: 8
                        column: 5
                        severity: .warning
                    )
                ]
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }
    }

#endif // os(macOS)

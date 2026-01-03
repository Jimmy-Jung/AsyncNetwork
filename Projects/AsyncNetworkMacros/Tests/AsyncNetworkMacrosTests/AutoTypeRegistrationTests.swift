//
//  AutoTypeRegistrationTests.swift
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

    // MARK: - AutoTypeRegistrationTests

    @Suite("자동 타입 등록 테스트")
    struct AutoTypeRegistrationTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
            "DocumentedType": DocumentedTypeMacroImpl.self,
        ]

        @Test("@APIRequest metadata에 Response 타입 자동 등록 코드 포함")
        func metadataIncludesResponseTypeRegistration() {
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
                        // Response 타입 자동 등록
                        _ = Post.typeStructure
                        return EndpointMetadata(
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
                            requestBodyStructure: nil,
                            requestBodyRelatedTypes: nil,
                            responseStructure: resolveTypeStructure(for: Post.self),
                            responseExample: nil,
                            responseTypeName: "Post",
                            relatedTypes: collectRelatedTypes(for: Post.self)
                        )
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIRequest metadata에 RequestBody 타입 자동 등록 코드 포함")
        func metadataIncludesRequestBodyTypeRegistration() {
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
                    static var metadata: EndpointMetadata {
                        // Response 타입 자동 등록
                        _ = Post.typeStructure
                        // RequestBody 타입 자동 등록
                        _ = PostBody.typeStructure
                        return EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create a post",
                            description: "",
                            method: "post",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            requestBodyStructure: resolveTypeStructure(for: PostBody.self),
                            requestBodyRelatedTypes: collectRelatedTypes(for: PostBody.self),
                            responseStructure: resolveTypeStructure(for: Post.self),
                            responseExample: nil,
                            responseTypeName: "Post",
                            relatedTypes: collectRelatedTypes(for: Post.self)
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@DocumentedType가 자기 자신을 자동 등록")
        func documentedTypeAutoRegistersItself() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct User {
                    let id: Int
                    let name: String
                    let address: Address
                    let company: Company
                }
                """,
                expandedSource: """
                struct User {
                    let id: Int
                    let name: String
                    let address: Address
                    let company: Company

                    public static var typeStructure: String {
                        _ = _register
                        return "struct User {\\n    let id: Int\\n    let name: String\\n    let address: Address\\n    let company: Company\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register
                        return ["Address", "Company"]
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(User.self)
                    }()
                }

                extension User: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("배열 Response 타입은 요소 타입만 등록")
        func arrayResponseTypeRegistersElementType() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [Post].self,
                    title: "Get all posts",
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetAllPostsRequest {
                }
                """,
                expandedSource: """
                struct GetAllPostsRequest {

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
                        // Response 타입 자동 등록
                        _ = Post.typeStructure
                        return EndpointMetadata(
                            id: "GetAllPostsRequest",
                            title: "Get all posts",
                            description: "",
                            method: "get",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            requestBodyStructure: nil,
                            requestBodyRelatedTypes: nil,
                            responseStructure: resolveTypeStructure(for: [Post].self),
                            responseExample: nil,
                            responseTypeName: "[Post]",
                            relatedTypes: collectRelatedTypes(for: [Post].self)
                        )
                    }
                }

                extension GetAllPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("EmptyResponse 타입은 등록 코드 생성 안함")
        func emptyResponseTypeDoesNotGenerateRegistration() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    baseURL: "https://api.example.com",
                    path: "/posts/1",
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
                        "/posts/1"
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                    static var metadata: EndpointMetadata {
                        return EndpointMetadata(
                            id: "DeletePostRequest",
                            title: "Delete a post",
                            description: "",
                            method: "delete",
                            path: "/posts/1",
                            baseURLString: "https://api.example.com",
                            headers: nil,
                            tags: [],
                            parameters: [],
                            requestBodyExample: nil,
                            requestBodyStructure: nil,
                            requestBodyRelatedTypes: nil,
                            responseStructure: resolveTypeStructure(for: EmptyResponse.self),
                            responseExample: nil,
                            responseTypeName: "EmptyResponse",
                            relatedTypes: collectRelatedTypes(for: EmptyResponse.self)
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

#endif

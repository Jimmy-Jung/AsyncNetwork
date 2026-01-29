//
//  APIDocumentMacroTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/28.
//

#if os(macOS)

    import SwiftSyntax
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacrosImpl

    @Suite("@APIDocument 매크로 테스트")
    struct APIDocumentMacroTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
            "APIDocument": APIDocumentMacroImpl.self,
        ]

        @Test("@APIDocument 없이 @APIRequest만 사용하면 기본 메타데이터 생성")
        func apiRequestWithoutDocument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: [],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument와 함께 사용하면 문서화 메타데이터가 포함")
        func apiDocumentWithMetadata() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get all posts",
                    description: "Retrieve a list of all posts",
                    tags: ["Posts", "Read"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get all posts",
                            description: "Retrieve a list of all posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts", "Read"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - GET 메서드는 대문자로 생성")
        func apiDocumentGetMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: "Retrieve posts",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - POST 메서드는 대문자로 생성")
        func apiDocumentPostMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                @APIDocument(
                    title: "Create post",
                    description: "Create a new post",
                    tags: ["Posts"]
                )
                struct CreatePostRequest {
                }
                """,
                expandedSource: """
                struct CreatePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .post
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create post",
                            description: "Create a new post",
                            method: "POST",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }

                extension CreatePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - PATCH 메서드는 대문자로 생성")
        func apiDocumentPatchMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .patch
                )
                @APIDocument(
                    title: "Update post",
                    description: "Partially update a post",
                    tags: ["Posts"]
                )
                struct UpdatePostRequest {
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .patch
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "UpdatePostRequest",
                            title: "Update post",
                            description: "Partially update a post",
                            method: "PATCH",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension UpdatePostRequest: APIRequest {
                }

                extension UpdatePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - DELETE 메서드는 대문자로 생성")
        func apiDocumentDeleteMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .delete
                )
                @APIDocument(
                    title: "Delete post",
                    description: "Delete a post by ID",
                    tags: ["Posts"]
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

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "DeletePostRequest",
                            title: "Delete post",
                            description: "Delete a post by ID",
                            method: "DELETE",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "EmptyResponse"
                        )
                    }
                }

                extension DeletePostRequest: APIRequest {
                }

                extension DeletePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - PUT 메서드는 대문자로 생성")
        func apiDocumentPutMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .put
                )
                @APIDocument(
                    title: "Replace post",
                    description: "Replace a post completely",
                    tags: ["Posts"]
                )
                struct ReplacePostRequest {
                }
                """,
                expandedSource: """
                struct ReplacePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .put
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "ReplacePostRequest",
                            title: "Replace post",
                            description: "Replace a post completely",
                            method: "PUT",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension ReplacePostRequest: APIRequest {
                }

                extension ReplacePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - 여러 태그 지원")
        func apiDocumentWithMultipleTags() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: "Retrieve posts",
                    tags: ["Posts", "Read", "Public", "v1"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts", "Read", "Public", "v1"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - 긴 description 지원")
        func apiDocumentWithLongDescription() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: \"\"\"
                    Retrieve a list of all posts from the database.
                    
                    This endpoint supports pagination and filtering.
                    Results are sorted by creation date in descending order.
                    \"\"\",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve a list of all posts from the database.\\n\\nThis endpoint supports pagination and filtering.\\nResults are sorted by creation date in descending order.",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Special Characters Tests

        @Test("@APIDocument - tags에 따옴표가 포함된 경우")
        func apiDocumentWithQuotesInTags() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: "Retrieve posts",
                    tags: ["Posts", "Read", "Test\\"Tag", "Category"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts", "Read", "Test\\"Tag", "Category"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - tags에 백슬래시가 포함된 경우")
        func apiDocumentWithBackslashInTags() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: "Retrieve posts",
                    tags: ["Category\\\\Path", "Test"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Category\\\\Path", "Test"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - title과 description에 특수문자가 포함된 경우")
        func apiDocumentWithSpecialCharsInTitleAndDescription() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get \\"all\\" posts",
                    description: "Retrieve posts\\nWith line break and \\"quotes\\"",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get \\"all\\" posts",
                            description: "Retrieve posts\\nWith line break and \\"quotes\\"",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - baseURL에 특수문자가 포함된 경우")
        func apiDocumentWithSpecialCharsInBaseURL() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.test.com/\\"endpoint\\"",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get posts",
                    description: "Retrieve posts",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.test.com/\\"endpoint\\""
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get posts",
                            description: "Retrieve posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.test.com/\\"endpoint\\"",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - path에 특수문자가 포함된 경우")
        func apiDocumentWithSpecialCharsInPath() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}/comments\\"test",
                    method: .get
                )
                @APIDocument(
                    title: "Get comments",
                    description: "Retrieve comments",
                    tags: ["Comments"]
                )
                struct GetCommentsRequest {
                }
                """,
                expandedSource: """
                struct GetCommentsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}/comments\\"test"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetCommentsRequest",
                            title: "Get comments",
                            description: "Retrieve comments",
                            method: "GET",
                            path: "/posts/{id}/comments\\"test",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Comments"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetCommentsRequest: APIRequest {
                }

                extension GetCommentsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - 탭과 캐리지 리턴이 포함된 경우")
        func apiDocumentWithTabsAndCarriageReturns() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get\\tposts",
                    description: "Line1\\r\\nLine2\\tTabbed",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get\\tposts",
                            description: "Line1\\r\\nLine2\\tTabbed",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("@APIDocument - 여러 특수문자가 동시에 포함된 복잡한 경우")
        func apiDocumentWithMultipleSpecialChars() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get \\"all\\" posts\\nwith\\tspecial chars",
                    description: "Complex\\nstring\\twith\\"quotes\\"and\\\\backslashes",
                    tags: ["Posts\\\\Path", "Test\\"Tag", "Normal"]
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get \\"all\\" posts\\nwith\\tspecial chars",
                            description: "Complex\\nstring\\twith\\"quotes\\"and\\\\backslashes",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts\\\\Path", "Test\\"Tag", "Normal"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

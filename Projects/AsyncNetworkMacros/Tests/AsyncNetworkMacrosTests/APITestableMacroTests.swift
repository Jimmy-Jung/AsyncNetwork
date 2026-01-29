//
//  APITestableMacroTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

// MARK: - Test Suite

struct APITestableMacroTests {
    // MARK: - Properties

    let testMacros: [String: Macro.Type] = [
        "APIRequest": APIRequestMacroImpl.self,
        "APITestable": APITestableMacroImpl.self,
    ]

    // MARK: - Basic Functionality Tests

    @Test("@APITestable 기본 확장 성공")
    func basicExpansionSuccess() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.success, .notFound])
            struct GetUserRequest {
                let id: String
            }
            """,
            expandedSource: """
            struct GetUserRequest {
                let id: String

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case notFound
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .notFound:
                            let errorData = Data(\"\"\"
                            {
                                "error": "Not found",
                                "code": "NOT_FOUND"
                            }
                            \"\"\".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 404,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("@APITestable errorExamples 파싱")
    func errorExamplesExpansion() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(
                errorExamples: [
                    "404": \"\"\"
                    {
                        "error": "User not found"
                    }
                    \"\"\"
                ]
            )
            struct GetUserRequest {
                let id: String
            }
            """,
            expandedSource: """
            struct GetUserRequest {
                let id: String

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case notFound
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .notFound:
                            let errorData = Data("{\\n    \\"error\\": \\"User not found\\"\\n}".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 404,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Array Type Tests

    @Test("배열 Response 타입 처리")
    func arrayResponseTypeHandling() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: [User].self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.success])
            struct GetUsersRequest {}
            """,
            expandedSource: """
            struct GetUsersRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = [User.fixture()]
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("공백이 포함된 배열 타입 처리")
    func arrayTypeWithWhitespace() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: [ User ].self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.success])
            struct GetUsersRequest {}
            """,
            expandedSource: """
            struct GetUsersRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = [User.fixture()]
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - EmptyResponse Tests

    @Test("EmptyResponse 타입 처리")
    func emptyResponseHandling() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: EmptyResponse.self,
                baseURL: "https://api.example.com",
                path: "/users/delete",
                method: .delete
            )
            @APITestable(scenarios: [.success])
            struct DeleteUserRequest {
                let id: String
            }
            """,
            expandedSource: """
            struct DeleteUserRequest {
                let id: String

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = EmptyResponse()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Status Code Mapping Tests

    @Test("다양한 상태 코드 매핑", arguments: [
        ("400", "clientError"),
        ("401", "unauthorized"),
        ("403", "forbidden"),
        ("404", "notFound"),
        ("429", "tooManyRequests"),
        ("500", "serverError"),
        ("502", "badGateway"),
        ("503", "serviceUnavailable"),
        ("504", "gatewayTimeout"),
    ])
    func statusCodeMapping(statusCode: String, expectedCase: String) {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(
                errorExamples: [
                    "\(statusCode)": \"\"\"
                    {
                        "error": "Test error"
                    }
                    \"\"\"
                ]
            )
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case \(expectedCase)
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .\(expectedCase):
                            let errorData = Data("{\\n    \\"error\\": \\"Test error\\"\\n}".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: \(statusCode),
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Predefined Scenarios Tests

    @Test("네트워크 에러 시나리오")
    func networkErrorScenario() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.networkError])
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case networkError
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .networkError:
                            return (nil, nil, URLError(.notConnectedToInternet))
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("타임아웃 시나리오")
    func timeoutScenario() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.timeout])
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case success
                    case timeout
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .timeout:
                            return (nil, nil, URLError(.timedOut))
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - JSON Escape Tests

    @Test("JSON 특수 문자 이스케이프")
    func jsonEscapeHandling() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(
                errorExamples: [
                    "400": \"\"\"
                    {
                        "error": "Invalid input",
                        "message": "Line 1\\nLine 2\\tTabbed"
                    }
                    \"\"\"
                ]
            )
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case clientError
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .clientError:
                            let errorData = Data("{\\n    \\"error\\": \\"Invalid input\\",\\n    \\"message\\": \\"Line 1\\\\nLine 2\\\\tTabbed\\"\\n}".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 400,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Error Tests

    @Test("@APIRequest 없이 @APITestable 사용 시 에러")
    func errorWhenMissingAPIRequest() {
        assertMacroExpansion(
            """
            @APITestable(scenarios: [.success])
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                    @APITestable requires @APIRequest to be declared first.

                    Usage:
                    @APIRequest(...)
                    @APITestable(...)
                    struct YourRequest { }
                    """,
                    line: 1,
                    column: 1,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    @Test("struct가 아닌 타입에 적용 시 에러")
    func errorWhenAppliedToNonStruct() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(scenarios: [.success])
            class GetUserRequest {}
            """,
            expandedSource: """
            class GetUserRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@APITestable can only be applied to a struct",
                    line: 6,
                    column: 1,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - Complex Scenarios Tests

    @Test("여러 시나리오 조합")
    func multipleScenariosCombination() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(
                scenarios: [.networkError, .timeout, .unauthorized],
                errorExamples: [
                    "404": \"\"\"
                    {
                        "error": "Not found"
                    }
                    \"\"\"
                ]
            )
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case networkError
                    case notFound
                    case success
                    case timeout
                    case unauthorized
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .notFound:
                            let errorData = Data("{\\n    \\"error\\": \\"Not found\\"\\n}".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 404,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                        case .networkError:
                            return (nil, nil, URLError(.notConnectedToInternet))
                        case .timeout:
                            return (nil, nil, URLError(.timedOut))
                        case .unauthorized:
                            let errorData = Data(\"\"\"
                            {
                                "error": "Unauthorized",
                                "code": "UNAUTHORIZED"
                            }
                            \"\"\".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 401,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Edge Cases Tests

    @Test("인자 없이 @APITestable 사용 (기본값)")
    func noArgumentsUsesDefaults() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case success
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("모든 새 상태 코드 시나리오 포함")
    func allNewStatusCodeScenarios() {
        assertMacroExpansion(
            """
            @APIRequest(
                response: UserResponse.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            @APITestable(
                scenarios: [.forbidden, .tooManyRequests, .serviceUnavailable]
            )
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                /// Mock 테스트 시나리오
                enum MockScenario {
                    case forbidden
                    case serviceUnavailable
                    case success
                    case tooManyRequests
                }

                /// Mock 응답 제공자
                static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
                    let url = URL(string: "https://api.example.com")!

                    switch scenario {
                        case .success:
                            let response = UserResponse.fixture()
                            let data = try? JSONEncoder().encode(response)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (data, httpResponse, nil)
                        case .forbidden:
                            let errorData = Data(\"\"\"
                            {
                                "error": "Forbidden",
                                "code": "FORBIDDEN"
                            }
                            \"\"\".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 403,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                        case .tooManyRequests:
                            let errorData = Data(\"\"\"
                            {
                                "error": "Too Many Requests",
                                "message": "Rate limit exceeded"
                            }
                            \"\"\".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 429,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                        case .serviceUnavailable:
                            let errorData = Data(\"\"\"
                            {
                                "error": "Service Unavailable",
                                "message": "Service is temporarily unavailable"
                            }
                            \"\"\".utf8)
                            let httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: 503,
                                httpVersion: nil,
                                headerFields: ["Content-Type": "application/json"]
                            )
                            return (errorData, httpResponse, nil)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}

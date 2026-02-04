import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import XCTest

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

/// Phase 3: swift-macro-testing을 사용한 진단 및 Fix-it 테스트
///
/// TCA/Point-Free 스타일의 스냅샷 기반 매크로 테스트
final class DiagnosticTests: XCTestCase {
    override func invokeTest() {
        // 매크로 등록
        withMacroTesting(
            macros: [
                "APIRequest": APIRequestMacroImpl.self
            ]
        ) {
            super.invokeTest()
        }
    }

    // MARK: - Basic Expansion Test

    func testBasicExpansion() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/me",
                method: .get
            )
            struct GetMeRequest {}
            """
        } expansion: {
            """
            struct GetMeRequest {

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/me"
                }
            }

            extension GetMeRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    // MARK: - Struct Validation Test

    func testClassShouldShowError() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/me",
                method: .get
            )
            class GetMeRequest {}
            """
        } diagnostics: {
            """
            @APIRequest(
            ├─ 🛑 @APIRequest는 struct에만 적용할 수 있습니다

            💡 이유: APIRequest는 값 타입(Value Type)으로 설계되어야 합니다.
               class는 참조 타입이므로 의도하지 않은 공유 상태를 유발할 수 있습니다.

            ✅ 해결 방법: 선언을 struct로 변경하세요.
            ╰─ 🛑 @APIRequest는 struct에만 적용할 수 있습니다

            💡 이유: APIRequest는 값 타입(Value Type)으로 설계되어야 합니다.
               class는 참조 타입이므로 의도하지 않은 공유 상태를 유발할 수 있습니다.

            ✅ 해결 방법: 선언을 struct로 변경하세요.
               ✏️ struct로 변경
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/me",
                method: .get
            )
            class GetMeRequest {}
            """
        }
    }

    // MARK: - Dynamic Method Test

    func testDynamicMethodExpansion() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: httpMethod
            )
            struct DynamicRequest {
                var httpMethod: HTTPMethod
            }
            """
        } expansion: {
            """
            struct DynamicRequest {
                var httpMethod: HTTPMethod

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    httpMethod
                }

                public var path: String {
                    "/users"
                }
            }

            extension DynamicRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    // MARK: - Validation Level Test

    func testValidationLevelStrict() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get,
                validationLevel: .strict
            )
            struct GetUsersRequest {}
            """
        } expansion: {
            """
            struct GetUsersRequest {

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/users"
                }
            }

            extension GetUsersRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    // MARK: - Phase 4: Type Safety Tests

    /// Phase 4: Swift.String 같은 모듈 한정자가 있는 타입 허용 테스트
    func testModuleQualifiedStringType() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/users/{id}",
                method: .get
            )
            struct GetUserRequest {
                @PathParameter var id: Swift.String
            }
            """
        } expansion: {
            """
            struct GetUserRequest {
                @PathParameter var id: Swift.String

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/users/\\(id)"
                }
            }

            extension GetUserRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    /// Phase 4: Optional<String> 표기법 허용 테스트
    func testOptionalAngleBracketNotation() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/search",
                method: .get
            )
            struct SearchRequest {
                @QueryParameter var query: Optional<String>
            }
            """
        } expansion: {
            """
            struct SearchRequest {
                @QueryParameter var query: Optional<String>

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/search"
                }
            }

            extension SearchRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    /// Phase 4: String? 표기법 허용 테스트
    func testOptionalQuestionMarkNotation() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/filter",
                method: .get
            )
            struct FilterRequest {
                @QueryParameter var category: String?
                @QueryParameter var sort: Optional<String>
            }
            """
        } expansion: {
            """
            struct FilterRequest {
                @QueryParameter var category: String?
                @QueryParameter var sort: Optional<String>

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/filter"
                }
            }

            extension FilterRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    /// Phase 4: 복잡한 제네릭 Response 타입 테스트
    func testGenericResponseType() {
        assertMacro {
            """
            @APIRequest(
                response: Result<User, APIError>.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            struct GetUsersRequest {}
            """
        } expansion: {
            """
            struct GetUsersRequest {

                public typealias Response = Result<User, APIError>

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/users"
                }
            }

            extension GetUsersRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    /// Phase 4: 모듈 한정자 충돌 방지 확인
    func testModuleQualifierPreventsConflict() {
        // AsyncNetwork.HTTPMethod와 AsyncNetwork.APIRequest가 생성되어
        // 사용자 정의 타입과 충돌하지 않는지 확인
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/users",
                method: .get
            )
            struct GetUsersRequest {}
            """
        } expansion: {
            """
            struct GetUsersRequest {

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/users"
                }
            }

            extension GetUsersRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }

    /// Phase 4: Int, Bool 등 다양한 QueryParameter 타입 테스트
    func testVariousQueryParameterTypes() {
        assertMacro {
            """
            @APIRequest(
                response: User.self,
                baseURL: "https://api.example.com",
                path: "/search",
                method: .get
            )
            struct SearchRequest {
                @QueryParameter var page: Int
                @QueryParameter var limit: Int?
                @QueryParameter var isActive: Bool
                @QueryParameter var rating: Double?
            }
            """
        } expansion: {
            """
            struct SearchRequest {
                @QueryParameter var page: Int
                @QueryParameter var limit: Int?
                @QueryParameter var isActive: Bool
                @QueryParameter var rating: Double?

                public typealias Response = User

                public var baseURLString: String {
                    "https://api.example.com"
                }

                public var method: HTTPMethod {
                    .get
                }

                public var path: String {
                    "/search"
                }
            }

            extension SearchRequest: AsyncNetwork.APIRequest {
            }
            """
        }
    }
}

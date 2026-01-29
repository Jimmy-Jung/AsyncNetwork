//
//  APITestableMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

// MARK: - APITestable Macro

/// API Request에 테스트 Mock 응답 생성 기능을 추가하는 매크로
///
/// `@APITestable` 매크로는 `@APIRequest`와 함께 사용하여 테스트 시나리오별 Mock 응답을
/// 자동으로 생성합니다. 이를 통해 네트워크 호출 없이 다양한 API 응답 상황을 테스트할 수 있습니다.
///
/// ## 주요 기능
///
/// 1. **MockScenario enum 생성**: 테스트 시나리오를 타입 안전하게 관리
/// 2. **mockResponse(for:) 메서드 생성**: 시나리오별 Mock 응답 제공
/// 3. **커스텀 에러 응답 지원**: HTTP 상태 코드별 에러 JSON 정의
/// 4. **사전 정의 시나리오**: 일반적인 네트워크 에러 시나리오 내장
///
/// ## 필수 조건
///
/// - ⚠️ `@APIRequest` 매크로가 **먼저** 선언되어야 합니다
/// - ⚠️ Response 타입은 `Codable`을 준수해야 합니다
/// - ⚠️ Response 타입에 `.fixture()` 정적 메서드가 있어야 합니다
///   - `@ResponseTestable` 매크로로 자동 생성 가능
///
/// ## 기본 사용법
///
/// ### 1. 간단한 Mock 테스트
///
/// ```swift
/// @APIRequest(
///     response: UserDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/users/{id}",
///     method: .get
/// )
/// @APITestable(scenarios: [.success, .notFound, .serverError])
/// struct GetUserRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ### 2. 커스텀 에러 응답 정의
///
/// ```swift
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: .post
/// )
/// @APITestable(
///     scenarios: [.success, .unauthorized, .clientError],
///     errorExamples: [
///         "400": """
///         {
///             "error": "Invalid request",
///             "code": "VALIDATION_ERROR",
///             "details": ["title is required"]
///         }
///         """,
///         "401": """
///         {
///             "error": "Unauthorized",
///             "code": "AUTH_REQUIRED"
///         }
///         """
///     ]
/// )
/// struct CreatePostRequest {
///     @RequestBody var post: PostInput
/// }
/// ```
///
/// ### 3. 네트워크 에러 시뮬레이션
///
/// ```swift
/// @APIRequest(
///     response: ProfileDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/profile",
///     method: .get
/// )
/// @APITestable(
///     scenarios: [.success, .networkError, .timeout]
/// )
/// struct GetProfileRequest {}
/// ```
///
/// ## 매크로 확장 결과
///
/// ### 입력
///
/// ```swift
/// @APIRequest(
///     response: UserDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/users/{id}",
///     method: .get
/// )
/// @APITestable(
///     scenarios: [.success, .notFound],
///     errorExamples: [
///         "404": """{"error": "User not found", "code": "USER_NOT_FOUND"}"""
///     ]
/// )
/// struct GetUserRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ### 출력 (생성되는 코드)
///
/// ```swift
/// struct GetUserRequest {
///     @PathParameter var id: Int
///
///     // @APIRequest가 생성한 코드
///     typealias Response = UserDTO
///     // ... (생략)
///
///     // @APITestable이 생성한 코드
///     /// Mock 테스트 시나리오
///     enum MockScenario {
///         case notFound
///         case success
///     }
///
///     /// Mock 응답 제공자
///     ///
///     /// - Parameter scenario: 시뮬레이션할 테스트 시나리오
///     /// - Returns: (Data?, URLResponse?, Error?) 튜플
///     static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
///         let url = URL(string: "https://api.example.com")!
///
///         switch scenario {
///         case .success:
///             let response = UserDTO.fixture()
///             let data = try? JSONEncoder().encode(response)
///             let httpResponse = HTTPURLResponse(
///                 url: url,
///                 statusCode: 200,
///                 httpVersion: nil,
///                 headerFields: ["Content-Type": "application/json"]
///             )
///             return (data, httpResponse, nil)
///         case .notFound:
///             let errorData = Data("""{"error": "User not found", "code": "USER_NOT_FOUND"}""".utf8)
///             let httpResponse = HTTPURLResponse(
///                 url: url,
///                 statusCode: 404,
///                 httpVersion: nil,
///                 headerFields: ["Content-Type": "application/json"]
///             )
///             return (errorData, httpResponse, nil)
///         }
///     }
/// }
/// ```
///
/// ## Swift Testing 통합 예제
///
/// ### 기본 테스트
///
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// struct GetUserRequestTests {
///     @Test("성공 시나리오 - 200 OK")
///     func testSuccess() async throws {
///         // Given
///         let request = GetUserRequest(id: 1)
///         let (data, response, error) = GetUserRequest.mockResponse(for: .success)
///
///         // Then
///         #expect(error == nil)
///         #expect((response as? HTTPURLResponse)?.statusCode == 200)
///
///         let user = try #require(data).flatMap {
///             try? JSONDecoder().decode(UserDTO.self, from: $0)
///         }
///         #expect(user != nil)
///     }
///
///     @Test("Not Found 시나리오 - 404")
///     func testNotFound() {
///         // When
///         let (data, response, error) = GetUserRequest.mockResponse(for: .notFound)
///
///         // Then
///         #expect(error == nil)
///         #expect((response as? HTTPURLResponse)?.statusCode == 404)
///
///         let errorJSON = try? JSONDecoder().decode([String: String].self, from: data!)
///         #expect(errorJSON?["code"] == "USER_NOT_FOUND")
///     }
/// }
/// ```
///
/// ### MockURLProtocol과 함께 사용
///
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// struct UserServiceIntegrationTests {
///     @Test("네트워크 계층 통합 테스트")
///     func testNetworkIntegration() async throws {
///         // Given
///         let config = URLSessionConfiguration.ephemeral
///         config.protocolClasses = [MockURLProtocol.self]
///
///         // Mock 응답 설정
///         MockURLProtocol.requestHandler = { request in
///             return GetUserRequest.mockResponse(for: .success)
///         }
///
///         let networkService = NetworkService(
///             configuration: config,
///             networkMonitor: nil,
///             checkNetworkBeforeRequest: false
///         )
///
///         // When
///         let request = GetUserRequest(id: 1)
///         let user: UserDTO = try await networkService.request(request)
///
///         // Then
///         #expect(user.id == 1)
///     }
/// }
/// ```
///
/// ## 매개변수 상세 설명
///
/// ### scenarios
///
/// 테스트할 시나리오 목록입니다. `TestScenario` enum의 케이스를 배열로 전달합니다.
///
/// **지원되는 시나리오**:
/// - `.success`: 성공 응답 (200 OK)
/// - `.clientError`: 일반 클라이언트 에러 (400 Bad Request)
/// - `.unauthorized`: 인증 실패 (401 Unauthorized)
/// - `.forbidden`: 권한 없음 (403 Forbidden)
/// - `.notFound`: 리소스 없음 (404 Not Found)
/// - `.tooManyRequests`: 요청 제한 초과 (429 Too Many Requests)
/// - `.serverError`: 서버 에러 (500 Internal Server Error)
/// - `.serviceUnavailable`: 서비스 이용 불가 (503 Service Unavailable)
/// - `.networkError`: 네트워크 연결 에러 (`URLError.notConnectedToInternet`)
/// - `.timeout`: 타임아웃 에러 (`URLError.timedOut`)
///
/// ```swift
/// @APITestable(
///     scenarios: [.success, .notFound, .serverError, .networkError, .timeout]
/// )
/// ```
///
/// ### errorExamples
///
/// HTTP 상태 코드별 커스텀 에러 JSON을 정의합니다.
///
/// **키**: HTTP 상태 코드 문자열 ("400", "404", "500" 등)
/// **값**: JSON 형식의 에러 응답 문자열
///
/// ```swift
/// @APITestable(
///     errorExamples: [
///         "400": """
///         {
///             "error": "Validation failed",
///             "fields": {
///                 "email": "Invalid format",
///                 "password": "Too short"
///             }
///         }
///         """,
///         "404": """
///         {
///             "error": "Resource not found",
///             "code": "NOT_FOUND",
///             "resource": "User"
///         }
///         """,
///         "429": """
///         {
///             "error": "Rate limit exceeded",
///             "retry_after": 60
///         }
///         """
///     ]
/// )
/// ```
///
/// ## 베스트 프랙티스
///
/// ### 1. 테스트 계층 구조
///
/// ```
/// Tests/
/// ├── Data/
/// │   ├── API/
/// │   │   ├── DTOTests.swift           # DTO fixture() 테스트
/// │   │   └── RequestTests.swift       # @APITestable 시나리오 테스트
/// │   └── Repository/
/// │       └── RepositoryTests.swift    # Repository 로직 테스트
/// └── Integration/
///     └── NetworkTests.swift           # MockURLProtocol 통합 테스트
/// ```
///
/// ### 2. fixture() 메서드와 함께 사용
///
/// Response 타입에 `@ResponseTestable` 매크로를 적용하여 `.fixture()` 메서드를 자동 생성하세요:
///
/// ```swift
/// @ResponseTestable(
///     sampleData: """
///     {
///         "id": 1,
///         "name": "John Doe",
///         "email": "john@example.com"
///     }
///     """
/// )
/// struct UserDTO: Codable {
///     let id: Int
///     let name: String
///     let email: String
/// }
/// ```
///
/// ### 3. 매개변수화된 테스트 활용
///
/// ```swift
/// @Test("다양한 에러 시나리오", arguments: [
///     (GetUserRequest.MockScenario.notFound, 404),
///     (.unauthorized, 401),
///     (.serverError, 500)
/// ])
/// func testErrorScenarios(scenario: GetUserRequest.MockScenario, expectedCode: Int) {
///     let (_, response, _) = GetUserRequest.mockResponse(for: scenario)
///     #expect((response as? HTTPURLResponse)?.statusCode == expectedCode)
/// }
/// ```
///
/// ### 4. 배열 Response 타입 처리
///
/// ```swift
/// @APIRequest(
///     response: [UserDTO].self,  // 배열 타입
///     baseURL: "https://api.example.com",
///     path: "/users",
///     method: .get
/// )
/// @APITestable(scenarios: [.success])
/// struct GetUsersRequest {}
///
/// // 생성된 mockResponse()는 [UserDTO.fixture()]를 반환
/// ```
///
/// ### 5. EmptyResponse 처리
///
/// ```swift
/// @APIRequest(
///     response: EmptyResponse.self,  // 빈 응답
///     baseURL: "https://api.example.com",
///     path: "/users/{id}",
///     method: .delete
/// )
/// @APITestable(scenarios: [.success, .notFound])
/// struct DeleteUserRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ## 주의사항 및 제한사항
///
/// ### ⚠️ 매크로 선언 순서
///
/// `@APITestable`은 반드시 `@APIRequest` **다음**에 선언해야 합니다:
///
/// ```swift
/// // ✅ 올바른 순서
/// @APIRequest(...)
/// @APITestable(...)
/// struct MyRequest {}
///
/// // ❌ 잘못된 순서 - 컴파일 에러
/// @APITestable(...)
/// @APIRequest(...)
/// struct MyRequest {}
/// ```
///
/// ### ⚠️ fixture() 메서드 필수
///
/// Response 타입에는 반드시 `.fixture()` 정적 메서드가 있어야 합니다:
///
/// ```swift
/// // 방법 1: @ResponseTestable 매크로 사용 (권장)
/// @ResponseTestable(sampleData: "...")
/// struct UserDTO: Codable { ... }
///
/// // 방법 2: 수동 구현
/// extension UserDTO {
///     static func fixture() -> UserDTO {
///         return UserDTO(id: 1, name: "Test User", email: "test@example.com")
///     }
/// }
/// ```
///
/// ### ⚠️ 중첩 배열 타입 제한
///
/// 중첩 배열 타입(`[[User]]`)은 빈 배열로 처리됩니다:
///
/// ```swift
/// @APIRequest(response: [[User]].self, ...)
/// @APITestable(scenarios: [.success])
/// struct MyRequest {}
///
/// // 생성된 코드: let response: [[User]] = []
/// ```
///
/// ### ⚠️ errorExamples 우선순위
///
/// `errorExamples`에 정의된 상태 코드는 `scenarios`보다 우선합니다:
///
/// ```swift
/// @APITestable(
///     scenarios: [.notFound],  // 기본 404 응답
///     errorExamples: [
///         "404": """{"custom": "error"}"""  // 이 응답이 사용됨
///     ]
/// )
/// ```
///
/// ## 상태 코드 매핑 테이블
///
/// | HTTP 코드 | 자동 매핑 케이스 | 설명 |
/// |----------|----------------|------|
/// | 200-299 | `success` | 성공 응답 |
/// | 400 | `clientError` | 잘못된 요청 |
/// | 401 | `unauthorized` | 인증 실패 |
/// | 403 | `forbidden` | 권한 없음 |
/// | 404 | `notFound` | 리소스 없음 |
/// | 429 | `tooManyRequests` | 요청 제한 초과 |
/// | 500 | `serverError` | 서버 에러 |
/// | 502 | `badGateway` | Bad Gateway |
/// | 503 | `serviceUnavailable` | 서비스 이용 불가 |
/// | 504 | `gatewayTimeout` | Gateway Timeout |
/// | 기타 4xx | `clientError` | 일반 클라이언트 에러 |
/// | 기타 5xx | `serverError` | 일반 서버 에러 |
///
/// ## 관련 매크로
///
/// - ``APIRequest``: API 요청 구조체 생성 (필수, 먼저 선언)
/// - ``ResponseTestable``: Response 타입에 fixture() 메서드 생성
/// - ``ResponseDocument``: Response 타입 문서화
///
@attached(member, names: named(MockScenario), named(mockResponse))
public macro APITestable(
    scenarios: [TestScenario] = [],
    errorExamples: [String: String] = [:]
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APITestableMacroImpl"
)

// MARK: - TestScenario

/// 테스트 시나리오를 정의하는 열거형
///
/// `@APITestable` 매크로의 `scenarios` 매개변수에 사용되며,
/// 다양한 네트워크 응답 상황을 타입 안전하게 시뮬레이션할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// @APITestable(
///     scenarios: [
///         .success,           // 성공 응답
///         .notFound,          // 404 에러
///         .unauthorized,      // 401 에러
///         .serverError,       // 500 에러
///         .networkError,      // 네트워크 연결 에러
///         .timeout            // 타임아웃 에러
///     ]
/// )
/// ```
///
/// ## 시나리오 분류
///
/// ### HTTP 성공 응답
/// - ``success``: 200 OK
///
/// ### HTTP 클라이언트 에러 (4xx)
/// - ``clientError``: 400 Bad Request
/// - ``unauthorized``: 401 Unauthorized
/// - ``forbidden``: 403 Forbidden
/// - ``notFound``: 404 Not Found
/// - ``tooManyRequests``: 429 Too Many Requests
///
/// ### HTTP 서버 에러 (5xx)
/// - ``serverError``: 500 Internal Server Error
/// - ``serviceUnavailable``: 503 Service Unavailable
///
/// ### 네트워크 에러
/// - ``networkError``: URLError.notConnectedToInternet
/// - ``timeout``: URLError.timedOut
///
/// - SeeAlso: ``APITestable``
public enum TestScenario {
    // MARK: - Success

    /// 성공 응답 시나리오 (200 OK)
    ///
    /// Response 타입의 `.fixture()` 메서드로 생성된 Mock 데이터를
    /// JSON으로 인코딩하여 반환합니다.
    ///
    /// ```swift
    /// let (data, response, error) = MyRequest.mockResponse(for: .success)
    /// // statusCode: 200
    /// // data: JSONEncoder().encode(Response.fixture())
    /// ```
    case success

    // MARK: - Client Errors (4xx)

    /// 일반 클라이언트 에러 (400 Bad Request)
    ///
    /// 잘못된 요청 형식이나 검증 실패를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Validation Failed",
    ///     "message": "Request validation failed"
    /// }
    /// ```
    case clientError

    /// 인증 실패 (401 Unauthorized)
    ///
    /// 인증 토큰이 없거나 만료된 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Unauthorized",
    ///     "code": "UNAUTHORIZED"
    /// }
    /// ```
    case unauthorized

    /// 권한 없음 (403 Forbidden)
    ///
    /// 인증은 되었지만 접근 권한이 없는 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Forbidden",
    ///     "code": "FORBIDDEN"
    /// }
    /// ```
    case forbidden

    /// 리소스 없음 (404 Not Found)
    ///
    /// 요청한 리소스를 찾을 수 없는 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Not found",
    ///     "code": "NOT_FOUND"
    /// }
    /// ```
    case notFound

    /// 요청 제한 초과 (429 Too Many Requests)
    ///
    /// Rate limiting에 걸린 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Too Many Requests",
    ///     "message": "Rate limit exceeded"
    /// }
    /// ```
    case tooManyRequests

    // MARK: - Server Errors (5xx)

    /// 서버 에러 (500 Internal Server Error)
    ///
    /// 서버 내부 오류를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Internal Server Error",
    ///     "message": "Server encountered an error"
    /// }
    /// ```
    case serverError

    /// Bad Gateway (502 Bad Gateway)
    ///
    /// 게이트웨이나 프록시 서버가 업스트림 서버로부터 잘못된 응답을 받은 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Bad Gateway",
    ///     "message": "Gateway received invalid response"
    /// }
    /// ```
    case badGateway

    /// 서비스 이용 불가 (503 Service Unavailable)
    ///
    /// 서버 점검이나 일시적인 과부하 상황을 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Service Unavailable",
    ///     "message": "Service is temporarily unavailable"
    /// }
    /// ```
    case serviceUnavailable

    /// Gateway Timeout (504 Gateway Timeout)
    ///
    /// 게이트웨이나 프록시 서버가 업스트림 서버로부터 제시간에 응답을 받지 못한 경우를 시뮬레이션합니다.
    ///
    /// 기본 응답:
    /// ```json
    /// {
    ///     "error": "Gateway Timeout",
    ///     "message": "Gateway timeout occurred"
    /// }
    /// ```
    case gatewayTimeout

    // MARK: - Network Errors

    /// 네트워크 연결 에러
    ///
    /// 인터넷 연결이 끊긴 상태를 시뮬레이션합니다.
    ///
    /// - Returns: `URLError(.notConnectedToInternet)` 에러 반환
    ///
    /// ```swift
    /// let (data, response, error) = MyRequest.mockResponse(for: .networkError)
    /// // data: nil
    /// // response: nil
    /// // error: URLError(.notConnectedToInternet)
    /// ```
    case networkError

    /// 타임아웃 에러
    ///
    /// 요청 시간 초과 상황을 시뮬레이션합니다.
    ///
    /// - Returns: `URLError(.timedOut)` 에러 반환
    ///
    /// ```swift
    /// let (data, response, error) = MyRequest.mockResponse(for: .timeout)
    /// // data: nil
    /// // response: nil
    /// // error: URLError(.timedOut)
    /// ```
    case timeout

    // MARK: - Deprecated

    /// 잘못된 응답 (Invalid JSON)
    ///
    /// - Warning: 현재 구현에서는 사용되지 않습니다. 향후 버전에서 제거될 예정입니다.
    @available(*, deprecated, message: "현재 구현에서는 지원하지 않습니다")
    case invalidResponse
}

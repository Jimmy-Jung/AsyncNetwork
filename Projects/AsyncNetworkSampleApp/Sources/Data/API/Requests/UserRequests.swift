//
//  UserRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

// MARK: - Error Response Models

struct UserNotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
}

struct UserValidationError: Codable, Sendable, Error {
    let error: String
    let message: String
    let fields: [String]?
}

// MARK: - Get All Users

@APIRequest(
    response: [UserDTO].self,
    title: "Get all users",
    description: """
    JSONPlaceholder에서 모든 사용자를 가져옵니다.
    
    기능:
    • 페이지네이션 지원 (_limit 파라미터)
    • 완전한 사용자 프로필 정보 포함
    
    응답 형식:
    User 객체의 배열을 반환합니다. 각 객체는 주소, 회사, 연락처 정보를 포함합니다.
    """,
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .get,
    tags: ["Users"],
    testScenarios: [.success, .serverError, .timeout],
    errorExamples: [
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch users"
        }
        """
    ],
    includeRetryTests: true,
    includePerformanceTests: true
)
struct GetAllUsersRequest {
    @QueryParameter(key: "_limit") var limit: Int?
    @QueryParameter(key: "_page") var page: Int?
}

// MARK: - Get User by ID

@APIRequest(
    response: UserDTO.self,
    title: "Get a user by ID",
    description: """
    특정 ID를 가진 사용자를 가져옵니다.
    
    파라미터:
    • id: User의 고유 식별자
    
    응답:
    완전한 사용자 프로필 정보 (주소, 회사, 연락처 포함)
    
    에러 처리:
    • 404: 사용자를 찾을 수 없음
    """,
    baseURL: jsonPlaceholderURL,
    path: "/users/{id}",
    method: .get,
    tags: ["Users"],
    errorResponses: [
        404: UserNotFoundError.self
    ],
    testScenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "error": "User not found",
          "code": "USER_NOT_FOUND"
        }
        """
    ],
    includeRetryTests: true
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
}

// MARK: - Create User

@APIRequest(
    response: UserDTO.self,
    title: "Create a new user",
    description: """
    새로운 사용자를 생성합니다.
    
    요청 바디:
    • name: 사용자 이름 (필수)
    • username: 사용자명 (필수, 고유)
    • email: 이메일 주소 (필수, 유효한 형식)
    
    검증 규칙:
    • name: 1-100자
    • username: 3-20자, 영문/숫자만
    • email: 유효한 이메일 형식
    
    에러 처리:
    • 400: 잘못된 요청 데이터
    • 409: 이미 존재하는 username 또는 email
    • 422: 검증 실패
    """,
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .post,
    tags: ["Users"],
    errorResponses: [
        400: UserValidationError.self,
        422: UserValidationError.self
    ],
    testScenarios: [.success, .clientError, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "Invalid user data"
        }
        """,
        "409": """
        {
          "error": "Conflict",
          "message": "Username or email already exists"
        }
        """,
        "422": """
        {
          "error": "Validation Failed",
          "message": "Email format is invalid",
          "fields": ["email"]
        }
        """
    ],
    includeRetryTests: false
)
struct CreateUserRequest {
    @RequestBody var body: UserBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

// MARK: - Request Body DTO

struct UserBodyDTO: Codable, Sendable {
    let name: String
    let username: String
    let email: String
    let address: AddressDTO?
    let phone: String?
    let website: String?
    let company: CompanyDTO?
}

extension UserBodyDTO {
    init(user: User) {
        self.init(
            name: user.name,
            username: user.username,
            email: user.email,
            address: user.address.map { AddressDTO(
                street: $0.street,
                suite: $0.suite,
                city: $0.city,
                zipcode: $0.zipcode,
                geo: GeoDTO(lat: $0.geo.lat, lng: $0.geo.lng)
            )},
            phone: user.phone,
            website: user.website,
            company: user.company.map { CompanyDTO(
                name: $0.name,
                catchPhrase: $0.catchPhrase,
                bs: $0.bs
            )}
        )
    }
}

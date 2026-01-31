//
//  UserRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Migrated to separated macros
//

import AsyncNetwork
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
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .get
)
struct GetAllUsersRequest {
    @QueryParameter(key: "_limit") var limit: Int?
    @QueryParameter(key: "_page") var page: Int?

    init(limit: Int? = nil, page: Int? = nil) {
        self.limit = limit
        self.page = page
    }
}

extension GetAllUsersRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetAllUsersRequest",
            title: "Get All Users",
            description: "모든 사용자를 조회합니다. limit, page 쿼리 파라미터를 지원합니다.",
            method: "GET",
            path: "/users",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Users"],
            parameters: ["limit", "page"],
            responseTypeName: "[UserDTO]"
        )
    }
}

// MARK: - Get User by ID

@APIRequest(
    response: UserDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/users/{id}",
    method: .get,
    errorResponses: [
        404: UserNotFoundError.self
    ]
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
}

extension GetUserByIdRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetUserByIdRequest",
            title: "Get User by ID",
            description: "특정 사용자를 ID로 조회합니다.",
            method: "GET",
            path: "/users/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Users"],
            parameters: ["id"],
            responseTypeName: "UserDTO"
        )
    }
}

// MARK: - Create User

@APIRequest(
    response: UserDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .post,
    errorResponses: [
        400: UserValidationError.self,
        422: UserValidationError.self
    ]
)
struct CreateUserRequest {
    @RequestBody var body: UserBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: UserBodyDTO? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

extension CreateUserRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "CreateUserRequest",
            title: "Create User",
            description: "새로운 사용자를 생성합니다.",
            method: "POST",
            path: "/users",
            baseURLString: jsonPlaceholderURL,
            headers: ["Content-Type": "application/json"],
            tags: ["Users"],
            parameters: ["body"],
            responseTypeName: "UserDTO"
        )
    }
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
            ) },
            phone: user.phone,
            website: user.website,
            company: user.company.map { CompanyDTO(
                name: $0.name,
                catchPhrase: $0.catchPhrase,
                bs: $0.bs
            ) }
        )
    }
}

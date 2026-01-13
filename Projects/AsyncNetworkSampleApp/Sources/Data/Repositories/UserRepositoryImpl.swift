//
//  UserRepositoryImpl.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

final class UserRepositoryImpl: UserRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getAllUsers() async throws -> [User] {
        let dtos: [UserDTO] = try await networkService.request(
            GetAllUsersRequest(limit: 10)
        )
        return dtos.map(User.init)
    }
    
    func getUser(by id: Int) async throws -> User {
        let dto: UserDTO = try await networkService.request(
            GetUserByIdRequest(id: id)
        )
        return User(dto: dto)
    }
    
    func createUser(_ user: User) async throws -> User {
        let body = UserBodyDTO(user: user)
        let request = CreateUserRequest(body: body)
        
        let createdDTO: UserDTO = try await networkService.request(request)
        return User(dto: createdDTO)
    }
}


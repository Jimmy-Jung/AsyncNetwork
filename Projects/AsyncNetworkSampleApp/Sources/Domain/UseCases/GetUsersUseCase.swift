//
//  GetUsersUseCase.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation

/// 사용자 목록 조회 UseCase
struct GetUsersUseCase: Sendable {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    /// 모든 사용자를 조회합니다.
    func execute() async throws -> [User] {
        try await repository.getAllUsers()
    }
    
    /// 특정 사용자를 ID로 조회합니다.
    /// - Parameter userId: 사용자 ID
    func execute(for userId: Int) async throws -> User {
        try await repository.getUser(by: userId)
    }
}


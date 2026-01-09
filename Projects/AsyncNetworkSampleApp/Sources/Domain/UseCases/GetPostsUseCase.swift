//
//  GetPostsUseCase.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 포스트 목록 조회 UseCase
///
/// 비즈니스 로직을 캡슐화하고 단일 책임을 가집니다.
/// Repository를 통해 데이터를 조회하고 필요한 비즈니스 규칙을 적용합니다.
struct GetPostsUseCase: Sendable {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    /// 모든 포스트를 조회합니다.
    func execute() async throws -> [Post] {
        try await repository.getAllPosts()
    }
    
    /// 특정 사용자의 포스트만 필터링하여 조회합니다.
    /// - Parameter userId: 사용자 ID
    func execute(for userId: Int) async throws -> [Post] {
        let allPosts = try await repository.getAllPosts()
        return allPosts.filter { $0.userId == userId }
    }
}


//
//  CreatePostUseCase.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 포스트 생성 UseCase
struct CreatePostUseCase: Sendable {
    private let repository: PostRepository
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    /// 새로운 포스트를 생성합니다.
    /// - Parameters:
    ///   - title: 포스트 제목
    ///   - body: 포스트 내용
    ///   - userId: 작성자 ID
    /// - Returns: 생성된 포스트
    func execute(
        title: String,
        body: String,
        userId: Int
    ) async throws -> Post {
        // 입력 검증
        guard !title.isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard !body.isEmpty else {
            throw ValidationError.emptyBody
        }
        
        // 포스트 생성
        let post = Post(
            id: 0, // 서버에서 할당됨
            userId: userId,
            title: title,
            body: body
        )
        
        return try await repository.createPost(post)
    }
}

enum ValidationError: Error {
    case emptyTitle
    case emptyBody
}


//
//  CommentRepositoryImpl.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import AsyncNetwork

struct CommentRepositoryImpl: CommentRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getComments(for postId: Int) async throws -> [Comment] {
        let dtos: [CommentDTO] = try await networkService.request(
            GetCommentsForPostRequest(postId: postId)
        )
        return dtos.map { Comment(dto: $0) }
    }
    
    func createComment(_ comment: Comment) async throws -> Comment {
        let bodyDTO = CommentBodyDTO(
            postId: comment.postId,
            name: comment.name,
            email: comment.email,
            body: comment.body
        )
        let request = CreateCommentRequest(
            body: bodyDTO,
            contentType: "application/json"
        )
        let dto: CommentDTO = try await networkService.request(request)
        return Comment(dto: dto)
    }
}

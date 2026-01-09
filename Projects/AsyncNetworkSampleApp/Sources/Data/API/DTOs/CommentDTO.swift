//
//  CommentDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import AsyncNetworkMacros

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "postId": 1,
      "id": 1,
      "name": "id labore ex et quam laborum",
      "email": "eliseo@example.com",
      "body": "laudantium enim quasi est quidem"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 10
)
struct CommentDTO: Codable, Sendable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Domain Conversion

extension Comment {
    init(dto: CommentDTO) {
        self.init(
            id: dto.id,
            postId: dto.postId,
            name: dto.name,
            email: dto.email,
            body: dto.body
        )
    }
}

extension CommentDTO {
    init(comment: Comment) {
        self.init(
            postId: comment.postId,
            id: comment.id,
            name: comment.name,
            email: comment.email,
            body: comment.body
        )
    }
}

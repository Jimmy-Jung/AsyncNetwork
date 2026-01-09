//
//  PostDTO.swift
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
      "userId": 1,
      "id": 1,
      "title": "sunt aut facere",
      "body": "quia et suscipit"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 10
)
struct PostDTO: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

// MARK: - Domain Conversion

extension Post {
    init(dto: PostDTO) {
        self.init(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            body: dto.body
        )
    }
}

extension PostDTO {
    init(post: Post) {
        self.init(
            userId: post.userId,
            id: post.id,
            title: post.title,
            body: post.body
        )
    }
}

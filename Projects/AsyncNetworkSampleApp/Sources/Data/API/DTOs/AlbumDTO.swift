//
//  AlbumDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "userId": 1,
      "id": 1,
      "title": "quidem molestiae enim"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 10
)
struct AlbumDTO: Codable, Sendable {
    let id: Int
    let userId: Int
    let title: String
}

@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "albumId": 1,
      "id": 1,
      "title": "accusamus beatae ad facilis cum similique qui sunt",
      "url": "https://via.placeholder.com/600/92c952",
      "thumbnailUrl": "https://via.placeholder.com/150/92c952"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 50
)
struct PhotoDTO: Codable, Sendable {
    let id: Int
    let albumId: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

extension Album {
    init(dto: AlbumDTO) {
        self.init(
            id: dto.id,
            userId: dto.userId,
            title: dto.title
        )
    }
}

extension Photo {
    init(dto: PhotoDTO) {
        self.init(
            id: dto.id,
            albumId: dto.albumId,
            title: dto.title,
            url: dto.url,
            thumbnailUrl: dto.thumbnailUrl
        )
    }
}


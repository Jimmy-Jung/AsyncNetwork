//
//  GetAlbumsUseCase.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation

/// 앨범 목록 조회 UseCase
struct GetAlbumsUseCase: Sendable {
    private let repository: AlbumRepository
    
    init(repository: AlbumRepository) {
        self.repository = repository
    }
    
    /// 특정 사용자의 모든 앨범을 조회합니다.
    /// - Parameter userId: 사용자 ID
    func execute(for userId: Int) async throws -> [Album] {
        try await repository.getAlbums(for: userId)
    }
}

/// 사진 목록 조회 UseCase
struct GetPhotosUseCase: Sendable {
    private let repository: AlbumRepository
    
    init(repository: AlbumRepository) {
        self.repository = repository
    }
    
    /// 특정 앨범의 모든 사진을 조회합니다.
    /// - Parameter albumId: 앨범 ID
    func execute(for albumId: Int) async throws -> [Photo] {
        try await repository.getPhotos(for: albumId)
    }
}


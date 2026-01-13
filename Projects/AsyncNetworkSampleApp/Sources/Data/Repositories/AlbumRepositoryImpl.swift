//
//  AlbumRepositoryImpl.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

final class AlbumRepositoryImpl: AlbumRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getAlbums(for userId: Int) async throws -> [Album] {
        let dtos: [AlbumDTO] = try await networkService.request(
            GetAlbumsForUserRequest(userId: userId)
        )
        return dtos.map(Album.init)
    }
    
    func getPhotos(for albumId: Int) async throws -> [Photo] {
        let dtos: [PhotoDTO] = try await networkService.request(
            GetPhotosForAlbumRequest(albumId: albumId)
        )
        return dtos.map(Photo.init)
    }
}


//
//  AlbumRepository.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 앨범 데이터 접근을 위한 Repository 프로토콜
protocol AlbumRepository: Sendable {
    /// 특정 사용자의 모든 앨범을 조회합니다.
    /// - Parameter userId: 사용자 ID
    func getAlbums(for userId: Int) async throws -> [Album]
    
    /// 특정 앨범의 모든 사진을 조회합니다.
    /// - Parameter albumId: 앨범 ID
    func getPhotos(for albumId: Int) async throws -> [Photo]
}


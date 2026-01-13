//
//  Album.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 앨범 도메인 모델
struct Album: Sendable, Equatable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
}

/// 사진 도메인 모델
struct Photo: Sendable, Equatable, Identifiable {
    let id: Int
    let albumId: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}


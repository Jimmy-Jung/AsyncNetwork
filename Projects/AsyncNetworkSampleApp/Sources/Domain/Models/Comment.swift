//
//  Comment.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 댓글 도메인 모델
struct Comment: Sendable, Equatable, Identifiable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}


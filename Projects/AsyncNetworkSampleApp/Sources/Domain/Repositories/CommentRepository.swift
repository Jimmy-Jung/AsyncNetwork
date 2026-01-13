//
//  CommentRepository.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 댓글 데이터 접근을 위한 Repository 프로토콜
protocol CommentRepository: Sendable {
    /// 특정 포스트의 모든 댓글을 조회합니다.
    /// - Parameter postId: 포스트 ID
    func getComments(for postId: Int) async throws -> [Comment]
    
    /// 새로운 댓글을 생성합니다.
    /// - Parameter comment: 생성할 댓글
    /// - Returns: 생성된 댓글
    func createComment(_ comment: Comment) async throws -> Comment
}


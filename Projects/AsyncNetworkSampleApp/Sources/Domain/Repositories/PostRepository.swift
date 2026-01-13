//
//  PostRepository.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 포스트 데이터 접근을 위한 Repository 프로토콜
///
/// Clean Architecture의 Dependency Inversion 원칙을 따라
/// Domain Layer가 Data Layer에 의존하지 않도록 인터페이스를 정의합니다.
protocol PostRepository: Sendable {
    /// 모든 포스트 목록을 조회합니다.
    func getAllPosts() async throws -> [Post]
    
    /// 특정 ID의 포스트를 조회합니다.
    /// - Parameter id: 포스트 ID
    func getPost(by id: Int) async throws -> Post
    
    /// 새로운 포스트를 생성합니다.
    /// - Parameter post: 생성할 포스트
    /// - Returns: 생성된 포스트 (서버에서 할당된 ID 포함)
    func createPost(_ post: Post) async throws -> Post
    
    /// 기존 포스트를 업데이트합니다.
    /// - Parameter post: 업데이트할 포스트
    /// - Returns: 업데이트된 포스트
    func updatePost(_ post: Post) async throws -> Post
    
    /// 포스트를 삭제합니다.
    /// - Parameter id: 삭제할 포스트 ID
    func deletePost(by id: Int) async throws
}


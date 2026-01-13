//
//  PostRepositoryImpl.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import Foundation

/// PostRepository 구현체
///
/// AsyncNetwork의 NetworkService를 사용하여
/// JSONPlaceholder API와 통신합니다.
final class PostRepositoryImpl: PostRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getAllPosts() async throws -> [Post] {
        let dtos: [PostDTO] = try await networkService.request(
            GetAllPostsRequest()
        )
        return dtos.map(Post.init)
    }
    
    func getPost(by id: Int) async throws -> Post {
        let dto: PostDTO = try await networkService.request(
            GetPostByIdRequest(id: id)
        )
        return Post(dto: dto)
    }
    
    func createPost(_ post: Post) async throws -> Post {
        let bodyDTO = PostBodyDTO(
            title: post.title,
            body: post.body,
            userId: post.userId
        )
        let request = CreatePostRequest(body: bodyDTO)
        let dto: PostDTO = try await networkService.request(request)
        return Post(dto: dto)
    }
    
    func updatePost(_ post: Post) async throws -> Post {
        let bodyDTO = PostBodyDTO(
            title: post.title,
            body: post.body,
            userId: post.userId
        )
        let request = UpdatePostRequest(id: post.id, body: bodyDTO)
        let dto: PostDTO = try await networkService.request(request)
        return Post(dto: dto)
    }
    
    func deletePost(by id: Int) async throws {
        let _: EmptyResponse = try await networkService.request(
            DeletePostRequest(id: id)
        )
    }
}


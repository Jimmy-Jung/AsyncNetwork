//
//  PostDetailViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import AsyncViewModel

// MARK: - PostDetailViewModel

@AsyncViewModel
final class PostDetailViewModel: ObservableObject {
    
    // MARK: - Input
    
    enum Input: Equatable, Sendable {
        case viewDidAppear
        case refreshButtonTapped
        case retryButtonTapped
        case viewDidDisappear
    }
    
    // MARK: - Action
    
    enum Action: Equatable, Sendable {
        case loadPostDetail
        case updatePost(Post)
        case updateComments([Comment])
        case setLoading(Bool)
        case handleError(SendableError)
        case clearError
        case cleanup
    }
    
    // MARK: - State
    
    struct State: Equatable, Sendable {
        var post: Post?
        var comments: [Comment] = []
        var isLoading = false
        var error: SendableError?
    }
    
    // MARK: - CancelID
    
    enum CancelID: Hashable, Sendable {
        case loadPost
        case loadComments
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let postId: Int
    private let postRepository: PostRepository
    private let commentRepository: CommentRepository
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        postId: Int,
        postRepository: PostRepository,
        commentRepository: CommentRepository
    ) {
        self.state = initialState
        self.postId = postId
        self.postRepository = postRepository
        self.commentRepository = commentRepository
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear, .refreshButtonTapped, .retryButtonTapped:
            return [.clearError, .loadPostDetail]
            
        case .viewDidDisappear:
            return [.cleanup]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadPostDetail:
            state.isLoading = true
            state.error = nil
            
            // Post와 Comments를 동시에 로드
            return [
                .concurrent(
                    .run(id: .loadPost) { [postRepository, postId] in
                        let post = try await postRepository.getPost(by: postId)
                        return .updatePost(post)
                    },
                    .run(id: .loadComments) { [commentRepository, postId] in
                        let comments = try await commentRepository.getComments(for: postId)
                        return .updateComments(comments)
                    }
                )
            ]
            
        case let .updatePost(post):
            state.post = post
            // Comments도 로드 완료되면 isLoading false
            if !state.comments.isEmpty || state.error != nil {
                state.isLoading = false
            }
            return [.none]
            
        case let .updateComments(comments):
            state.comments = comments
            // Post도 로드 완료되면 isLoading false
            if state.post != nil || state.error != nil {
                state.isLoading = false
            }
            return [.none]
            
        case let .setLoading(isLoading):
            state.isLoading = isLoading
            return [.none]
            
        case let .handleError(error):
            state.error = error
            state.isLoading = false
            return [.none]
            
        case .clearError:
            state.error = nil
            return [.none]
            
        case .cleanup:
            return [
                .cancel(id: .loadPost),
                .cancel(id: .loadComments)
            ]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}

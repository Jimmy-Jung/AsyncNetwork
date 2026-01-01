//
//  AsyncNetworkDocKitExampleApp.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkDocKit

@main
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()
    
    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: [
                "Posts": [
                    GetAllPostsRequest.metadata,
                    GetPostByIdRequest.metadata,
                    CreatePostRequest.metadata,
                    UpdatePostRequest.metadata,
                    DeletePostRequest.metadata
                ],
                "Users": [
                    GetAllUsersRequest.metadata,
                    GetUserByIdRequest.metadata,
                    CreateUserRequest.metadata
                ],
                "Comments": [
                    GetPostCommentsRequest.metadata,
                    CreateCommentRequest.metadata
                ],
                "Albums": [
                    GetUserAlbumsRequest.metadata,
                    GetAlbumPhotosRequest.metadata
                ]
            ],
            networkService: networkService,
            appTitle: "JSONPlaceholder API Docs"
        )
    }
}


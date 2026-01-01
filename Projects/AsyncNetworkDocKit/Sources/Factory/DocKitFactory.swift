//
//  DocKitFactory.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// DocKit 진입점 생성 헬퍼
@available(iOS 17.0, macOS 14.0, *)
public struct DocKitFactory {
    /// Dictionary 기반 카테고리 구조로 문서 앱 생성
    ///
    /// **사용 예시:**
    /// ```swift
    /// @main
    /// struct MyAPIDocApp: App {
    ///     let networkService = NetworkService()
    ///
    ///     var body: some Scene {
    ///         DocKitFactory.createDocApp(
    ///             endpoints: [
    ///                 "Posts": [
    ///                     GetPostsRequest.metadata,
    ///                     CreatePostRequest.metadata
    ///                 ],
    ///                 "Users": [
    ///                     GetUsersRequest.metadata
    ///                 ]
    ///             ],
    ///             networkService: networkService
    ///         )
    ///     }
    /// }
    /// ```
    public static func createDocApp(
        endpoints: [String: [EndpointMetadata]],
        networkService: NetworkService,
        appTitle: String = "API Documentation"
    ) -> some Scene {
        let categories = endpoints.map { name, endpoints in
            EndpointCategory(name: name, endpoints: endpoints)
        }.sorted { $0.name < $1.name }
        
        return WindowGroup {
            DocView(
                categories: categories,
                networkService: networkService,
                appTitle: appTitle
            )
        }
    }
    
    /// Category 배열로 문서 앱 생성
    public static func createDocApp(
        categories: [EndpointCategory],
        networkService: NetworkService,
        appTitle: String = "API Documentation"
    ) -> some Scene {
        WindowGroup {
            DocView(
                categories: categories,
                networkService: networkService,
                appTitle: appTitle
            )
        }
    }
}

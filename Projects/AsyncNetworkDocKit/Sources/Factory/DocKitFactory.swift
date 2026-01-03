//
//  DocKitFactory.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkCore
import SwiftUI

/// DocKit 진입점 생성 헬퍼
@available(iOS 17.0, macOS 14.0, *)
public struct DocKitFactory {
    /// Dictionary 기반 카테고리 구조로 문서 앱 생성
    ///
    /// **중요:** 중첩 타입들을 UI에서 펼쳐보려면, 앱 초기화 시 모든 `@DocumentedType` 타입을 등록해야 합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// @main
    /// struct MyAPIDocApp: App {
    ///     let networkService = NetworkService()
    ///
    ///     init() {
    ///         // 모든 타입 등록 (중첩 타입 UI를 위해 필요)
    ///         _ = Post.typeStructure
    ///         _ = PostBody.typeStructure
    ///         _ = User.typeStructure
    ///         // ... 모든 @DocumentedType 타입
    ///     }
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

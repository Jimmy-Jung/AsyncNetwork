//
//  DocKitFactoryTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

import AsyncNetworkCore
@testable import AsyncNetworkDocKit
import SwiftUI
import Testing

@Suite("DocKitFactory Tests")
@MainActor
struct DocKitFactoryTests {
    @available(iOS 17.0, macOS 14.0, *)

    // Test용 NetworkService 생성 함수
    func createTestNetworkService() -> NetworkService {
        return NetworkService(configuration: .default)
    }

    @Test("createDocApp(endpoints:networkService:)이 WindowGroup을 반환한다")
    @available(iOS 17.0, macOS 14.0, *)
    func createDocAppReturnsWindowGroup() {
        let networkService = createTestNetworkService()
        let endpoints: [String: [EndpointMetadata]] = [
            "Posts": [
                EndpointMetadata(
                    id: "get-posts",
                    title: "Get Posts",
                    description: "Fetch all posts",
                    method: "GET",
                    path: "/posts",
                    baseURLString: "https://api.example.com",
                    responseTypeName: "Post"
                )
            ]
        ]

        let scene = DocKitFactory.createDocApp(
            endpoints: endpoints,
            networkService: networkService
        )

        // Scene이 WindowGroup 타입인지 확인
        #expect(scene is WindowGroup<DocView>)
    }

    @Test("createDocApp(categories:networkService:)이 WindowGroup을 반환한다")
    @available(iOS 17.0, macOS 14.0, *)
    func createDocAppWithCategoriesReturnsWindowGroup() {
        let networkService = createTestNetworkService()
        let categories = [
            EndpointCategory(
                name: "Users",
                endpoints: [
                    EndpointMetadata(
                        id: "get-users",
                        title: "Get Users",
                        description: "Fetch all users",
                        method: "GET",
                        path: "/users",
                        baseURLString: "https://api.example.com",
                        responseTypeName: "User"
                    )
                ]
            )
        ]

        let scene = DocKitFactory.createDocApp(
            categories: categories,
            networkService: networkService
        )

        #expect(scene is WindowGroup<DocView>)
    }

    @Test("빈 endpoints 딕셔너리로 앱을 생성할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canCreateAppWithEmptyEndpoints() {
        let networkService = createTestNetworkService()
        let endpoints: [String: [EndpointMetadata]] = [:]

        let scene = DocKitFactory.createDocApp(
            endpoints: endpoints,
            networkService: networkService
        )

        #expect(scene is WindowGroup<DocView>)
    }

    @Test("빈 categories 배열로 앱을 생성할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canCreateAppWithEmptyCategories() {
        let networkService = createTestNetworkService()
        let categories: [EndpointCategory] = []

        let scene = DocKitFactory.createDocApp(
            categories: categories,
            networkService: networkService
        )

        #expect(scene is WindowGroup<DocView>)
    }

    @Test("커스텀 appTitle을 설정할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canSetCustomAppTitle() {
        let networkService = createTestNetworkService()
        let endpoints: [String: [EndpointMetadata]] = [:]

        let scene = DocKitFactory.createDocApp(
            endpoints: endpoints,
            networkService: networkService,
            appTitle: "Custom API Docs"
        )

        #expect(scene is WindowGroup<DocView>)
    }

    @Test("여러 카테고리의 endpoints를 포함한 앱을 생성할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canCreateAppWithMultipleCategoryEndpoints() {
        let networkService = createTestNetworkService()
        let endpoints: [String: [EndpointMetadata]] = [
            "Posts": [
                EndpointMetadata(
                    id: "get-posts",
                    title: "Get Posts",
                    description: "Fetch all posts",
                    method: "GET",
                    path: "/posts",
                    baseURLString: "https://api.example.com",
                    responseTypeName: "Post"
                ),
                EndpointMetadata(
                    id: "create-post",
                    title: "Create Post",
                    description: "Create a new post",
                    method: "POST",
                    path: "/posts",
                    baseURLString: "https://api.example.com",
                    responseTypeName: "Post"
                )
            ],
            "Users": [
                EndpointMetadata(
                    id: "get-users",
                    title: "Get Users",
                    description: "Fetch all users",
                    method: "GET",
                    path: "/users",
                    baseURLString: "https://api.example.com",
                    responseTypeName: "User"
                )
            ],
            "Comments": [
                EndpointMetadata(
                    id: "get-comments",
                    title: "Get Comments",
                    description: "Fetch all comments",
                    method: "GET",
                    path: "/comments",
                    baseURLString: "https://api.example.com",
                    responseTypeName: "Comment"
                )
            ]
        ]

        let scene = DocKitFactory.createDocApp(
            endpoints: endpoints,
            networkService: networkService
        )

        #expect(scene is WindowGroup<DocView>)
    }

    @Test("여러 EndpointCategory를 포함한 앱을 생성할 수 있다")
    @available(iOS 17.0, macOS 14.0, *)
    func canCreateAppWithMultipleCategories() {
        let networkService = createTestNetworkService()
        let categories = [
            EndpointCategory(
                name: "Authentication",
                description: "Authentication endpoints",
                endpoints: [
                    EndpointMetadata(
                        id: "login",
                        title: "Login",
                        description: "User login",
                        method: "POST",
                        path: "/auth/login",
                        baseURLString: "https://api.example.com",
                        responseTypeName: "AuthToken"
                    )
                ]
            ),
            EndpointCategory(
                name: "Profile",
                description: "User profile endpoints",
                endpoints: [
                    EndpointMetadata(
                        id: "get-profile",
                        title: "Get Profile",
                        description: "Get user profile",
                        method: "GET",
                        path: "/profile",
                        baseURLString: "https://api.example.com",
                        responseTypeName: "Profile"
                    )
                ]
            )
        ]

        let scene = DocKitFactory.createDocApp(
            categories: categories,
            networkService: networkService
        )

        #expect(scene is WindowGroup<DocView>)
    }
}

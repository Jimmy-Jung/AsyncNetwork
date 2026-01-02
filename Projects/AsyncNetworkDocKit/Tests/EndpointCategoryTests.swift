//
//  EndpointCategoryTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

import AsyncNetworkCore
@testable import AsyncNetworkDocKit
import Foundation
import Testing

@Suite("EndpointCategory Tests")
struct EndpointCategoryTests {
    @Test("EndpointCategory 초기화 시 모든 속성이 올바르게 설정된다")
    func allPropertiesAreCorrectlySet() {
        let endpoints = [
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

        let category = EndpointCategory(
            name: "Users",
            description: "User management endpoints",
            endpoints: endpoints
        )

        #expect(category.id == "Users")
        #expect(category.name == "Users")
        #expect(category.description == "User management endpoints")
        #expect(category.endpoints.count == 1)
        #expect(category.endpoints.first?.id == "get-users")
    }

    @Test("description이 nil일 때 올바르게 처리된다")
    func nilDescriptionIsHandledCorrectly() {
        let category = EndpointCategory(
            name: "Posts",
            description: nil,
            endpoints: []
        )

        #expect(category.description == nil)
    }

    @Test("빈 endpoints 배열로 초기화할 수 있다")
    func canInitializeWithEmptyEndpoints() {
        let category = EndpointCategory(
            name: "Empty",
            endpoints: []
        )

        #expect(category.endpoints.isEmpty)
    }

    @Test("id는 name과 동일하다")
    func idEqualsName() {
        let category = EndpointCategory(
            name: "TestCategory",
            endpoints: []
        )

        #expect(category.id == category.name)
    }

    @Test("여러 endpoint를 포함할 수 있다")
    func canContainMultipleEndpoints() {
        let endpoints = [
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
            ),
            EndpointMetadata(
                id: "delete-post",
                title: "Delete Post",
                description: "Delete a post",
                method: "DELETE",
                path: "/posts/{id}",
                baseURLString: "https://api.example.com",
                responseTypeName: "Void"
            )
        ]

        let category = EndpointCategory(
            name: "Posts",
            endpoints: endpoints
        )

        #expect(category.endpoints.count == 3)
        #expect(category.endpoints[0].method == "GET")
        #expect(category.endpoints[1].method == "POST")
        #expect(category.endpoints[2].method == "DELETE")
    }

    @Test("EndpointCategory는 Identifiable을 준수한다")
    func endpointCategoryIsIdentifiable() {
        let category = EndpointCategory(
            name: "Test",
            endpoints: []
        )

        let id: String = category.id
        #expect(id == "Test")
    }

    @Test("EndpointCategory는 Hashable을 준수한다")
    func endpointCategoryIsHashable() {
        let endpoints = [
            EndpointMetadata(
                id: "test",
                title: "Test",
                description: "Test endpoint",
                method: "GET",
                path: "/test",
                baseURLString: "https://api.example.com",
                responseTypeName: "String"
            )
        ]

        let category1 = EndpointCategory(name: "Test", endpoints: endpoints)
        let category2 = EndpointCategory(name: "Test", endpoints: endpoints)

        let set: Set<EndpointCategory> = [category1, category2]
        #expect(set.count == 1)
    }

    @Test("EndpointCategory는 Sendable을 준수한다")
    func endpointCategoryIsSendable() async {
        let category = EndpointCategory(
            name: "Async",
            endpoints: []
        )

        // Task로 전달 가능한지 확인
        let result = await Task {
            category.name
        }.value

        #expect(result == "Async")
    }

    @Test("동일한 이름의 카테고리는 동일한 id를 가진다")
    func categoriesWithSameNameHaveSameId() {
        let category1 = EndpointCategory(name: "Shared", endpoints: [])
        let category2 = EndpointCategory(name: "Shared", endpoints: [])

        #expect(category1.id == category2.id)
    }

    @Test("서로 다른 이름의 카테고리는 서로 다른 id를 가진다")
    func categoriesWithDifferentNamesHaveDifferentIds() {
        let category1 = EndpointCategory(name: "Category1", endpoints: [])
        let category2 = EndpointCategory(name: "Category2", endpoints: [])

        #expect(category1.id != category2.id)
    }
}

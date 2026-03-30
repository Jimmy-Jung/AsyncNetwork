//
//  DemoModels.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import Foundation

struct DemoPost: Codable, Sendable, Identifiable, Equatable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct DemoCreatePostBody: Codable, Sendable, Equatable {
    let title: String
    let body: String
    let userId: Int
}

enum DemoFixtures {
    static let samplePosts: [DemoPost] = [
        DemoPost(userId: 1, id: 1, title: "Hello AsyncNetwork", body: "코어 API만으로도 요청 구성이 가능합니다."),
        DemoPost(userId: 1, id: 2, title: "Retry Demo", body: "실패 후 재시도 흐름은 mock client로 재현합니다.")
    ]

    static let createdPost = DemoPost(
        userId: 7,
        id: 101,
        title: "Created from Example App",
        body: "POST 요청과 RequestBody 사용 예제입니다."
    )

    static var samplePostsData: Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder().encode(samplePosts)
    }

    static var createdPostData: Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder().encode(createdPost)
    }
}

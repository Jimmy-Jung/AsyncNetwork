//
//  AsyncNetwork.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

/// AsyncNetwork 통합 모듈
///
/// Core 기능과 매크로를 모두 포함하는 단일 모듈입니다.
/// 이 모듈 하나만 import하면 AsyncNetwork의 모든 기능을 사용할 수 있습니다.
///
/// ## 사용법
///
/// ```swift
/// import AsyncNetwork
///
/// @APIRequest(
///     response: [Post].self,
///     title: "Get all posts",
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: "get"
/// )
/// struct GetAllPostsRequest {}
///
/// let service = NetworkService()
/// let posts: [Post] = try await service.request(GetAllPostsRequest())
/// ```
///
/// ## 마이그레이션
///
/// 기존 코드에서 다음과 같이 변경하세요:
///
/// Before:
/// ```swift
/// import AsyncNetworkCore
/// import AsyncNetworkMacros
/// ```
///
/// After:
/// ```swift
/// import AsyncNetwork
/// ```
@_exported import AsyncNetworkCore
@_exported import AsyncNetworkMacros

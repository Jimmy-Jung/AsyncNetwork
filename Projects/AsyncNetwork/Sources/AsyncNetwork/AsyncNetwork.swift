//
//  AsyncNetwork.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

// MARK: - AsyncNetwork Module

// AsyncNetwork 통합 모듈
//
// Core 기능과 매크로를 모두 포함하는 단일 모듈입니다.
// 이 모듈 하나만 import하면 AsyncNetwork의 모든 기능을 사용할 수 있습니다.
//
// ## 사용법
//
// ```swift
// import AsyncNetwork
//
// @APIRequest(
//     response: [Post].self,
//     title: "Get all posts",
//     baseURL: "https://jsonplaceholder.typicode.com",
//     path: "/posts",
//     method: "get"
// )
// struct GetAllPostsRequest {}
//
// let service = NetworkService()
// let posts: [Post] = try await service.request(GetAllPostsRequest())
// ```
//
// ## 포함된 기능
//
// ### Core 기능 (AsyncNetworkCore)
// - `APIRequest`: API 요청 프로토콜
// - `NetworkService`: 네트워크 서비스
// - `HTTPClient`: HTTP 클라이언트
// - `RequestInterceptor`: 요청/응답 인터셉터
// - Property Wrappers: `@QueryParameter`, `@PathParameter`, `@RequestBody`, `@HeaderField`
// - Error Handling: `ErrorMapper`, `StatusCodeValidator`
// - Retry Logic: `RetryPolicy`, `RetryRule`
//
// ### 매크로 기능 (AsyncNetworkMacros)
// - `@APIRequest`: API 요청 구조체 자동 생성 매크로
//
// ## 마이그레이션
//
// 기존 코드에서 다음과 같이 변경하세요:
//
// Before:
// ```swift
// import AsyncNetworkCore
// import AsyncNetworkMacros
// ```
//
// After:
// ```swift
// import AsyncNetwork  // 단일 import로 통합!
// ```

// Core 기능 re-export
@_exported import AsyncNetworkCore

// 매크로 re-export
@_exported import AsyncNetworkMacros


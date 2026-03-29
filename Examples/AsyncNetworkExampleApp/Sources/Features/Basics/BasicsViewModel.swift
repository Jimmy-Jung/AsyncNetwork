//
//  BasicsViewModel.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation
import SwiftUI

enum BasicsExampleKind: String, CaseIterable, Identifiable, Sendable {
    case query
    case path
    case body
    case header

    var id: String { rawValue }

    var title: String {
        switch self {
        case .query: return "Query Parameter"
        case .path: return "Path Parameter"
        case .body: return "Request Body"
        case .header: return "Header Field"
        }
    }

    var subtitle: String {
        switch self {
        case .query: return "리스트 조회와 필터링"
        case .path: return "단일 리소스 조회"
        case .body: return "POST 요청과 Codable body"
        case .header: return "인증 헤더와 요청 미리보기"
        }
    }

    var codeSnippet: String {
        switch self {
        case .query:
            return """
            struct GetPostsRequest: APIRequest {
                typealias Response = [DemoPost]

                let baseURLString = "https://jsonplaceholder.typicode.com"
                let path = "/posts"
                let method: HTTPMethod = .get

                @QueryParameter var userId: Int?
                @QueryParameter(key: "_limit") var limit: Int?
            }
            """
        case .path:
            return """
            struct GetPostDetailRequest: APIRequest {
                typealias Response = DemoPost

                let baseURLString = "https://jsonplaceholder.typicode.com"
                let path = "/posts/{id}"
                let method: HTTPMethod = .get

                @PathParameter var id: Int
            }
            """
        case .body:
            return """
            struct CreatePostRequest: APIRequest {
                typealias Response = DemoPost

                let baseURLString = "https://jsonplaceholder.typicode.com"
                let path = "/posts"
                let method: HTTPMethod = .post

                @RequestBody var body: DemoCreatePostBody
            }
            """
        case .header:
            return """
            struct AuthenticatedPostsRequest: APIRequest {
                typealias Response = [DemoPost]

                let baseURLString = "https://jsonplaceholder.typicode.com"
                let path = "/posts"
                let method: HTTPMethod = .get

                @QueryParameter(key: "_limit") var limit: Int?
                @HeaderField(key: .authorization) var authorization: String?
            }
            """
        }
    }
}

struct BasicsExampleCard: Identifiable, Equatable, Sendable {
    let id: BasicsExampleKind
    let title: String
    let subtitle: String
    let codeSnippet: String
    var state: DemoLoadState
}

@MainActor
final class BasicsViewModel: ObservableObject {
    @Published private(set) var cards: [BasicsExampleCard] = BasicsExampleKind.allCases.map {
        BasicsExampleCard(
            id: $0,
            title: $0.title,
            subtitle: $0.subtitle,
            codeSnippet: $0.codeSnippet,
            state: .idle
        )
    }

    private let service: NetworkService

    init(
        service: NetworkService = NetworkService(
            interceptors: [],
            networkMonitor: NetworkMonitor.shared
        )
    ) {
        self.service = service
    }

    func run(_ kind: BasicsExampleKind) async {
        updateState(.loading, for: kind)

        do {
            let output = try await execute(kind)
            updateState(.success(output), for: kind)
        } catch {
            updateState(.failure(error.localizedDescription), for: kind)
        }
    }

    private func execute(_ kind: BasicsExampleKind) async throws -> DemoRunOutput {
        switch kind {
        case .query:
            let request = GetPostsRequest(userId: 1, limit: 3)
            let response: [DemoPost] = try await service.request(request)
            return try makeOutput(request: request, response: response, metadata: ["3개 게시글 조회"])
        case .path:
            let request = GetPostDetailRequest(id: 1)
            let response: DemoPost = try await service.request(request)
            return try makeOutput(request: request, response: response, metadata: ["id=1 단건 조회"])
        case .body:
            let request = CreatePostRequest(
                body: DemoCreatePostBody(
                    title: "Created from Example App",
                    body: "RequestBody와 Codable을 같이 사용합니다.",
                    userId: 7
                )
            )
            let response: DemoPost = try await service.request(request)
            return try makeOutput(request: request, response: response, metadata: ["POST 요청", "body 자동 인코딩"])
        case .header:
            let request = AuthenticatedPostsRequest(limit: 2, authorization: "Bearer example-token")
            let response: [DemoPost] = try await service.request(request)
            return try makeOutput(request: request, response: response, metadata: ["Authorization 헤더 포함"])
        }
    }

    private func makeOutput<Request: APIRequest, Response: Encodable>(
        request: Request,
        response: Response,
        metadata: [String]
    ) throws -> DemoRunOutput {
        let urlRequest = try request.asURLRequest()

        return DemoRunOutput(
            method: urlRequest.httpMethod ?? request.method.rawValue,
            requestURL: urlRequest.url?.absoluteString ?? "unknown",
            headers: formattedHeaders(from: urlRequest),
            metadataLines: metadata,
            responsePreview: DemoJSONFormatter.prettyString(from: response)
        )
    }

    private func formattedHeaders(from request: URLRequest) -> [String] {
        let headers = request.allHTTPHeaderFields ?? [:]
        return headers.keys.sorted().map { "\($0): \(headers[$0] ?? "")" }
    }

    private func updateState(_ state: DemoLoadState, for kind: BasicsExampleKind) {
        guard let index = cards.firstIndex(where: { $0.id == kind }) else { return }
        cards[index].state = state
    }
}

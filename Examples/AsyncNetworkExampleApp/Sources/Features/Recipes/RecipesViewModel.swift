//
//  RecipesViewModel.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation
import SwiftUI

struct RecipePreset: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let codeSnippet: String
}

@MainActor
final class RecipesViewModel: ObservableObject {
    @Published var authInterceptorEnabled = true
    @Published private(set) var authPreviewLines: [String] = []
    @Published private(set) var retryState: DemoLoadState = .idle

    let presets: [RecipePreset] = [
        RecipePreset(
            id: "default",
            title: "Default Service",
            summary: "일반 JSON API 요청에 가장 먼저 쓰는 시작점",
            codeSnippet: """
            let service = NetworkService.default(
                interceptors: [ConsoleLoggingInterceptor(minimumLevel: .info)]
            )
            """
        ),
        RecipePreset(
            id: "image",
            title: "Image Service",
            summary: "리소스 timeout과 cache 정책을 따로 가져가고 싶을 때",
            codeSnippet: """
            let imageService = NetworkService.image()
            let data = try await imageService.requestData(ImageRequest(url: url))
            """
        ),
        RecipePreset(
            id: "realtime",
            title: "Realtime Service",
            summary: "지연보다 빠른 응답이 중요한 요청",
            codeSnippet: """
            let realtimeService = NetworkService.realtime(
                interceptors: [ConsoleLoggingInterceptor(minimumLevel: .warning)]
            )
            """
        )
    ]

    func refreshAuthPreview() async {
        let request = GetPostsRequest(userId: 1, limit: 2)
        var urlRequest: URLRequest

        do {
            urlRequest = try request.asURLRequest()
            if authInterceptorEnabled {
                let interceptor = DemoAuthInterceptor(token: "example-token")
                try await interceptor.prepare(&urlRequest, target: request)
            }

            authPreviewLines = [
                "\(urlRequest.httpMethod ?? "GET") \(urlRequest.url?.absoluteString ?? "unknown")"
            ] + formattedHeaders(from: urlRequest)
        } catch {
            authPreviewLines = [error.localizedDescription]
        }
    }

    func runRetryDemo() async {
        retryState = .loading

        let client = FlakyDemoHTTPClient(
            failuresBeforeSuccess: 2,
            responseData: DemoFixtures.samplePostsData
        )

        let interceptors: [any RequestInterceptor] = authInterceptorEnabled
            ? [DemoAuthInterceptor(token: "example-token")]
            : []

        let service = NetworkService(
            httpClient: client,
            retryPolicy: RetryPolicy(configuration: .quick),
            responseProcessor: ResponseProcessor(),
            interceptors: interceptors,
            networkMonitor: nil,
            checkNetworkBeforeRequest: false
        )

        let request = GetPostsRequest(userId: 1, limit: 2)

        do {
            let posts: [DemoPost] = try await service.request(request)
            var urlRequest = try request.asURLRequest()
            if authInterceptorEnabled {
                let interceptor = DemoAuthInterceptor(token: "example-token")
                try await interceptor.prepare(&urlRequest, target: request)
            }

            let output = DemoRunOutput(
                method: urlRequest.httpMethod ?? "GET",
                requestURL: urlRequest.url?.absoluteString ?? "unknown",
                headers: formattedHeaders(from: urlRequest),
                metadataLines: await client.attemptHistory + ["RetryPolicy.quick 사용"],
                responsePreview: DemoJSONFormatter.prettyString(from: posts)
            )
            retryState = .success(output)
        } catch {
            retryState = .failure(error.localizedDescription)
        }
    }

    private func formattedHeaders(from request: URLRequest) -> [String] {
        let headers = request.allHTTPHeaderFields ?? [:]
        return headers.keys.sorted().map { "\($0): \(headers[$0] ?? "")" }
    }
}

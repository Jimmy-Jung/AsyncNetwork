//
//  BasicsViewModelTests.swift
//  AsyncNetworkExampleAppTests
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
@testable import AsyncNetworkExampleApp
import Testing

@MainActor
struct BasicsViewModelTests {
    @Test("BasicsViewModel query 예제가 성공 상태로 갱신됨")
    func runQueryExample() async throws {
        let service = NetworkService(
            httpClient: StaticDemoHTTPClient(responseData: DemoFixtures.samplePostsData),
            retryPolicy: RetryPolicy(),
            responseProcessor: ResponseProcessor(),
            interceptors: [],
            networkMonitor: nil,
            checkNetworkBeforeRequest: false
        )

        let viewModel = BasicsViewModel(service: service)
        await viewModel.run(.query)

        let card = try #require(viewModel.cards.first { $0.id == .query })

        switch card.state {
        case let .success(output):
            #expect(output.requestURL.contains("/posts"))
            #expect(output.responsePreview.contains("Hello AsyncNetwork"))
        default:
            Issue.record("query 예제가 success 상태여야 함")
        }
    }
}

//
//  RecipesViewModelTests.swift
//  AsyncNetworkExampleAppTests
//
//  Created by JunyoungJung on 2026/03/29.
//

@testable import AsyncNetworkExampleApp
import Testing

@MainActor
struct RecipesViewModelTests {
    @Test("Auth preview 에 Authorization 헤더가 포함됨")
    func refreshAuthPreview() async throws {
        let viewModel = RecipesViewModel()

        await viewModel.refreshAuthPreview()

        #expect(viewModel.authPreviewLines.contains(where: { $0.contains("Authorization: Bearer example-token") }))
    }

    @Test("Retry demo 는 3번째 시도에서 성공함")
    func runRetryDemo() async throws {
        let viewModel = RecipesViewModel()

        await viewModel.runRetryDemo()

        switch viewModel.retryState {
        case let .success(output):
            #expect(output.metadataLines.contains("Attempt 1: timedOut"))
            #expect(output.metadataLines.contains("Attempt 2: timedOut"))
            #expect(output.metadataLines.contains("Attempt 3: success"))
        default:
            Issue.record("retry demo 가 success 상태여야 함")
        }
    }
}

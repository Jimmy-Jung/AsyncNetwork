//
//  RecipesView.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import SwiftUI

struct RecipesView: View {
    @StateObject private var viewModel = RecipesViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(
                    title: "활용 포인트",
                    subtitle: "preset을 언제 고를지, 인터셉터와 재시도를 어디에 붙일지 한 화면에서 정리합니다."
                ) {
                    Text("실서비스에서는 요청 정의보다 네트워크 정책 구성이 더 자주 문제를 만듭니다. 이 화면은 그 부분만 분리해서 보여줍니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.presets) { preset in
                    SectionCard(title: preset.title, subtitle: preset.summary) {
                        CodeSnippetCard(title: preset.title, code: preset.codeSnippet)
                    }
                }

                SectionCard(title: "Auth Interceptor Preview", subtitle: "prepare 단계에서 헤더가 어떻게 주입되는지 확인") {
                    Toggle("Authorization 헤더 주입", isOn: $viewModel.authInterceptorEnabled)
                        .onChange(of: viewModel.authInterceptorEnabled) { _, _ in
                            Task {
                                await viewModel.refreshAuthPreview()
                            }
                        }

                    Text(viewModel.authPreviewLines.joined(separator: "\n"))
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                SectionCard(title: "Retry Demo", subtitle: "처음 2번은 timedOut, 마지막 1번은 success") {
                    CodeSnippetCard(
                        title: "Retry Demo",
                        code: """
                        let service = NetworkService(
                            httpClient: FlakyDemoHTTPClient(
                                failuresBeforeSuccess: 2,
                                responseData: DemoFixtures.samplePostsData
                            ),
                            retryPolicy: RetryPolicy(configuration: .quick),
                            interceptors: [DemoAuthInterceptor(token: "example-token")],
                            networkMonitor: nil,
                            checkNetworkBeforeRequest: false
                        )
                        """
                    )

                    Button {
                        Task {
                            await viewModel.runRetryDemo()
                        }
                    } label: {
                        Text("재시도 데모 실행")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    retryStateView
                }
            }
            .padding(16)
        }
        .navigationTitle("Recipes")
        .task {
            await viewModel.refreshAuthPreview()
        }
    }

    @ViewBuilder
    private var retryStateView: some View {
        switch viewModel.retryState {
        case .idle:
            StatusBadge(text: "Ready", style: .idle)
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                StatusBadge(text: "Retrying", style: .loading)
            }
        case let .failure(message):
            VStack(alignment: .leading, spacing: 8) {
                StatusBadge(text: "Failed", style: .failure)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case let .success(output):
            VStack(alignment: .leading, spacing: 10) {
                StatusBadge(text: "Success", style: .success)
                Text("\(output.method) \(output.requestURL)")
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)

                if !output.headers.isEmpty {
                    Text(output.headers.joined(separator: "\n"))
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                Text(output.metadataLines.joined(separator: "\n"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(output.responsePreview)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

//
//  BasicsView.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import SwiftUI

struct BasicsView: View {
    @StateObject private var viewModel = BasicsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(
                    title: "왜 이 화면이 필요한가",
                    subtitle: "README의 코드 조각을 실제 요청, URL, 응답으로 바로 연결합니다."
                ) {
                    Text("각 카드에서 한 가지 기능만 보여줍니다. 코드를 읽고 바로 실행 결과까지 확인하면 AsyncNetwork의 학습 속도가 훨씬 빨라집니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.cards) { card in
                    SectionCard(title: card.title, subtitle: card.subtitle) {
                        CodeSnippetCard(title: "Example", code: card.codeSnippet)

                        Button {
                            Task {
                                await viewModel.run(card.id)
                            }
                        } label: {
                            Text("실행")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("\(card.title) 예제 실행")

                        stateView(card.state)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Basics")
    }

    @ViewBuilder
    private func stateView(_ state: DemoLoadState) -> some View {
        switch state {
        case .idle:
            StatusBadge(text: "Ready", style: .idle)
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                StatusBadge(text: "Running", style: .loading)
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
                        .textSelection(.enabled)
                }

                if !output.metadataLines.isEmpty {
                    Text(output.metadataLines.joined(separator: "\n"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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

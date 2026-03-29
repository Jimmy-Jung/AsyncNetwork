//
//  MonitorView.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import SwiftUI

struct MonitorView: View {
    @StateObject private var viewModel = MonitorViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(title: "Live Network State", subtitle: "NetworkMonitor.shared 의 현재 상태") {
                    HStack {
                        StatusBadge(text: viewModel.liveSnapshot.statusText, style: .live)
                        StatusBadge(text: viewModel.liveSnapshot.connectionType, style: .live)
                    }

                    Text("Expensive: \(viewModel.liveSnapshot.isExpensive ? "Yes" : "No")")
                    Text("Constrained: \(viewModel.liveSnapshot.isConstrained ? "Yes" : "No")")
                }

                SectionCard(
                    title: "Offline Guard Comparison",
                    subtitle: "checkNetworkBeforeRequest 값에 따라 어떻게 달라지는지 비교"
                ) {
                    CodeSnippetCard(
                        title: "Offline Guard",
                        code: """
                        let guarded = NetworkService(
                            httpClient: client,
                            networkMonitor: mockMonitor,
                            checkNetworkBeforeRequest: true
                        )

                        let bypass = NetworkService(
                            httpClient: client,
                            networkMonitor: mockMonitor,
                            checkNetworkBeforeRequest: false
                        )
                        """
                    )

                    Button {
                        Task {
                            await viewModel.compareOfflineGuard()
                        }
                    } label: {
                        Text("오프라인 비교 실행")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    comparisonView
                }
            }
            .padding(16)
        }
        .navigationTitle("Monitor")
        .task {
            viewModel.startMonitoring()
        }
    }

    @ViewBuilder
    private var comparisonView: some View {
        switch viewModel.comparisonState {
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
                StatusBadge(text: "Compared", style: .success)
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

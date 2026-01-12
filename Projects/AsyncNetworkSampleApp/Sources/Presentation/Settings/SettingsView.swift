//
//  SettingsView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import SwiftUI

/// 설정 화면 (SwiftUI 래퍼)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            SettingsContentView(viewModel: viewModel)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    viewModel.send(.viewDidAppear)
                }
                .onDisappear {
                    viewModel.send(.viewDidDisappear)
                }
        }
    }
}

/// 설정 컨텐츠 뷰
private struct SettingsContentView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List {
            // MARK: - Retry Policy Section

            Section {
                Picker("Retry Policy", selection: Binding(
                    get: { viewModel.state.retryPolicyPreset },
                    set: { viewModel.send(.retryPolicyPresetSelected($0)) }
                )) {
                    ForEach(RetryPolicyPreset.allCases, id: \.self) { preset in
                        VStack(alignment: .leading) {
                            Text(preset.displayName)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(preset)
                    }
                }
            } header: {
                Text("Network Configuration")
            }

            // MARK: - ETag Cache Section

            Section {
                // ETag Count (Read-only)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("ETag Count")
                        Spacer()
                        Text(viewModel.state.etagCacheUsage.formattedUsage)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: viewModel.state.etagCacheUsage.usageRatio)
                        .tint(progressColor(for: viewModel.state.etagCacheUsage.usageRatio))
                    HStack {
                        Spacer()
                        Text(viewModel.state.etagCacheUsage.formattedPercentage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Refresh ETag Cache Usage
                Button {
                    viewModel.send(.refreshETagCacheUsageTapped)
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.state.isRefreshingETagCache {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.state.isRefreshingETagCache ? "Refreshing..." : "Refresh Cache Usage")
                        Spacer()
                    }
                }
                .disabled(viewModel.state.isRefreshingETagCache)

                // Force Reload Next Request
                Button {
                    viewModel.send(.invalidateAllETagsTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text("Force Reload Next Request")
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }

                // Clear Cache
                Button {
                    viewModel.send(.clearETagCacheTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text("Clear All Cache")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
            } header: {
                Text("ETag Cache Settings")
            } footer: {
                Text(
                    "ETag 기반 조건부 요청 사용 중\n" +
                        "• 서버 데이터 변경 시에만 새 데이터 수신 (304 Not Modified)\n" +
                        "• 네트워크 대역폭 절약 및 효율적 캐싱\n" +
                        "• LRU 정책으로 자동 메모리 관리"
                )
            }

            // MARK: - Logging Section

            Section {
                Picker("Logging Level", selection: Binding(
                    get: { viewModel.state.loggingLevel },
                    set: { viewModel.send(.loggingLevelSelected($0)) }
                )) {
                    ForEach(LoggingLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading) {
                            Text(level.displayName)
                            Text(level.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(level)
                    }
                }
            } header: {
                Text("Logging")
            }

            // MARK: - Reset Section

            Section {
                Button {
                    viewModel.send(.resetToDefaultsTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Defaults")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
            }

            // MARK: - About Section

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
    }

    // MARK: - Helper

    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0 ..< 0.5: return .green
        case 0.5 ..< 0.8: return .orange
        default: return .red
        }
    }
}

#Preview {
    SettingsView()
}

//
//  SettingsSwiftView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import SwiftUI

/// 설정 화면 (SwiftUI 래퍼)
struct SettingsSwiftView: View {
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
    @State private var showInterceptorResults = false
    @State private var showSimulationTimelines = false

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
                Text("ETag 기반 조건부 요청 사용 중\n• 서버 데이터 변경 시에만 새 데이터 수신 (304 Not Modified)\n• 네트워크 대역폭 절약 및 효율적 캐싱\n• LRU 정책으로 자동 메모리 관리")
            }

            // MARK: - Interceptor Section

            Section {
                ForEach(InterceptorType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.body)
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { viewModel.state.interceptorConfig.isEnabled(type) },
                            set: { _ in viewModel.send(.interceptorToggled(type)) }
                        ))
                        .labelsHidden()
                    }
                }

                if !viewModel.state.interceptorConfig.enabledInterceptors.isEmpty {
                    HStack {
                        Text("Chain Order")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.state.interceptorConfig.chainDescription)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Button {
                    viewModel.send(.testInterceptorsTapped)
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.state.isExecutingInterceptorTest {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.state.isExecutingInterceptorTest ? "Testing..." : "Test Interceptors")
                        Spacer()
                    }
                }
                .disabled(viewModel.state.isExecutingInterceptorTest)

                if !viewModel.state.interceptorTestResults.isEmpty {
                    Button {
                        showInterceptorResults.toggle()
                    } label: {
                        HStack {
                            Text("View Results")
                            Spacer()
                            Text("\(viewModel.state.interceptorTestResults.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Request Interceptors")
            } footer: {
                Text("인터셉터는 order 순서대로 실행됩니다")
            }

            // MARK: - Error Simulation Section

            Section {
                Picker("Error Type", selection: Binding(
                    get: { viewModel.state.errorSimulation.errorType },
                    set: { viewModel.send(.errorTypeSelected($0)) }
                )) {
                    ForEach(ErrorType.allCases) { type in
                        Label {
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: type.icon)
                        }
                        .tag(type)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Failure Rate")
                        Spacer()
                        Text("\(Int(viewModel.state.errorSimulation.failureRate * 100))%")
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { viewModel.state.errorSimulation.failureRate },
                            set: { viewModel.send(.simulationFailureRateChanged($0)) }
                        ),
                        in: 0 ... 1,
                        step: 0.1
                    )
                }

                Button {
                    viewModel.send(.startErrorSimulationTapped)
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.state.isRunningSimulation {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.state.isRunningSimulation ? "Running..." : "Start Simulation")
                        Spacer()
                    }
                }
                .disabled(viewModel.state.isRunningSimulation)

                if !viewModel.state.pastSimulationTimelines.isEmpty {
                    Button {
                        showSimulationTimelines.toggle()
                    } label: {
                        HStack {
                            Text("View Timelines")
                            Spacer()
                            Text("\(viewModel.state.pastSimulationTimelines.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Retry & Error Simulation")
            } footer: {
                Text("재시도 정책과 에러 타입을 조합하여 네트워크 재시도 동작을 테스트합니다")
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
        .sheet(isPresented: $showInterceptorResults) {
            InterceptorResultsView(
                results: viewModel.state.interceptorTestResults,
                onClear: { viewModel.send(.clearInterceptorLogsTapped) }
            )
        }
        .sheet(isPresented: $showSimulationTimelines) {
            SimulationTimelinesView(
                timelines: viewModel.state.pastSimulationTimelines,
                onClear: { viewModel.send(.clearSimulationTimelinesTapped) }
            )
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
    SettingsSwiftView()
}

// MARK: - Interceptor Results View

private struct InterceptorResultsView: View {
    let results: [InterceptorTestResult]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(results.indices, id: \.self) { index in
                    let result = results[index]

                    Section {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.statusText)
                                    .font(.headline)
                                Text(result.requestURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(result.formattedDuration)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Logs")
                            Spacer()
                            Text("\(result.logs.count)")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(result.logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("[\(log.formattedTimestamp)]")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(log.interceptorType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                Text("\(log.action): \(log.details)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Interceptor Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        onClear()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Simulation Timelines View

private struct SimulationTimelinesView: View {
    let timelines: [ErrorSimulationTimeline]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(timelines.indices, id: \.self) { index in
                    let timeline = timelines[index]

                    Section {
                        HStack {
                            Image(systemName: timeline.finalSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(timeline.finalSuccess ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(timeline.simulation.errorType.displayName)
                                    .font(.headline)
                                Text(timeline.simulation.retryPreset.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text("Total Duration")
                            Spacer()
                            Text(timeline.formattedDuration)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Attempts")
                            Spacer()
                            Text("\(timeline.attempts.count)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Failure Rate")
                            Spacer()
                            Text("\(Int(timeline.simulation.failureRate * 100))%")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(timeline.attempts, id: \.attemptNumber) { attempt in
                            HStack {
                                Image(systemName: attempt.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(attempt.success ? .green : .red)
                                    .font(.caption)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Attempt #\(attempt.attemptNumber)")
                                        .font(.caption)
                                    if let error = attempt.error {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let delay = attempt.formattedDelay {
                                        Text("Delay: \(delay)")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                }

                                Spacer()

                                Text(attempt.formattedTimestamp)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Simulation Timelines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        onClear()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

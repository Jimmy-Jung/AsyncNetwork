//
//  InterceptorsView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/12.
//

import SwiftUI

/// Request Interceptors 전용 화면 (루트 탭)
struct InterceptorsView: View {
    @ObservedObject var viewModel: InterceptorsViewModel
    @State private var showInterceptorResults = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Active Interceptors Section

                Section {
                    ForEach(InterceptorType.allCases) { type in
                        InterceptorToggleRow(
                            type: type,
                            isEnabled: viewModel.state.interceptorConfig.isEnabled(type),
                            onToggle: { viewModel.send(.interceptorToggled(type)) }
                        )
                    }

                    // Chain Order Display
                    if !viewModel.state.interceptorConfig.enabledInterceptors.isEmpty {
                        ChainOrderRow(
                            chainDescription: viewModel.state.interceptorConfig.chainDescription
                        )
                    }

                    // Test Button
                    TestInterceptorsButton(
                        isExecuting: viewModel.state.isExecutingInterceptorTest,
                        onTest: { viewModel.send(.testInterceptorsTapped) }
                    )

                    // View Results Button
                    if !viewModel.state.interceptorTestResults.isEmpty {
                        ViewResultsRow(
                            count: viewModel.state.interceptorTestResults.count,
                            onTap: { showInterceptorResults.toggle() }
                        )
                    }
                } header: {
                    Text("Active Interceptors")
                } footer: {
                    Text("인터셉터는 order 순서대로 실행됩니다")
                }

                // MARK: - About Section

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("실제 NetworkService 연동")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Text(
                            "인터셉터 토글이 실시간으로 AppDependency.networkService에 반영됩니다. " +
                                "API Playground에서 요청 시 활성화된 인터셉터가 자동으로 적용됩니다."
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("인터셉터는 네트워크 요청 전후에 실행되는 미들웨어입니다. 요청 헤더를 추가하거나, 로깅을 수행하거나, 인증 토큰을 주입하는 등의 작업을 처리할 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Interceptors")
                }
            }
            .navigationTitle("Request Interceptors")
            .sheet(isPresented: $showInterceptorResults) {
                InterceptorResultsView(
                    results: viewModel.state.interceptorTestResults,
                    onClear: { viewModel.send(.clearInterceptorLogsTapped) }
                )
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

// MARK: - InterceptorToggleRow

/// 인터셉터 토글 행
private struct InterceptorToggleRow: View {
    let type: InterceptorType
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
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
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - ChainOrderRow

/// 인터셉터 체인 순서 표시 행
private struct ChainOrderRow: View {
    let chainDescription: String

    var body: some View {
        HStack {
            Text("Chain Order")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(chainDescription)
                .font(.caption)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - TestInterceptorsButton

/// 인터셉터 테스트 버튼
private struct TestInterceptorsButton: View {
    let isExecuting: Bool
    let onTest: () -> Void

    var body: some View {
        Button {
            onTest()
        } label: {
            HStack {
                Spacer()
                if isExecuting {
                    ProgressView()
                        .padding(.trailing, 8)
                }
                Text(isExecuting ? "Testing..." : "Test Interceptors")
                Spacer()
            }
        }
        .disabled(isExecuting)
    }
}

// MARK: - ViewResultsRow

/// 테스트 결과 보기 행
private struct ViewResultsRow: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text("View Results")
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - InterceptorResultsView

/// 인터셉터 테스트 결과 뷰
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

#Preview {
    InterceptorsView(viewModel: InterceptorsViewModel())
}

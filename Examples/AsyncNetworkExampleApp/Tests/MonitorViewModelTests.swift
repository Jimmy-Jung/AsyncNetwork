//
//  MonitorViewModelTests.swift
//  AsyncNetworkExampleAppTests
//
//  Created by JunyoungJung on 2026/03/29.
//

@testable import AsyncNetworkExampleApp
import Testing

@MainActor
struct MonitorViewModelTests {
    @Test("Mock monitor 상태 변경이 snapshot 에 반영됨")
    func monitorSnapshotUpdates() async throws {
        let monitor = ExampleMockNetworkMonitor(isConnected: true, connectionType: .wifi)
        let viewModel = MonitorViewModel(monitor: monitor)

        viewModel.startMonitoring()
        monitor.update(isConnected: false, connectionType: .cellular, isExpensive: true, isConstrained: true)

        await Task.yield()

        #expect(viewModel.liveSnapshot.statusText == "Disconnected")
        #expect(viewModel.liveSnapshot.connectionType == "Cellular")
        #expect(viewModel.liveSnapshot.isExpensive == true)
        #expect(viewModel.liveSnapshot.isConstrained == true)
    }

    @Test("오프라인 guard 비교 결과를 노출함")
    func compareOfflineGuard() async throws {
        let viewModel = MonitorViewModel(monitor: ExampleMockNetworkMonitor(isConnected: true))

        await viewModel.compareOfflineGuard()

        switch viewModel.comparisonState {
        case let .success(output):
            #expect(output.metadataLines.contains(where: { $0.contains("guarded service") }))
            #expect(output.metadataLines.contains(where: { $0.contains("bypass service") }))
        default:
            Issue.record("offline guard 비교가 success 상태여야 함")
        }
    }
}

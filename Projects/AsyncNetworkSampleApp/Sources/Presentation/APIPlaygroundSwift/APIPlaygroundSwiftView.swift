//
//  APIPlaygroundSwiftView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import AsyncViewModel
import SwiftUI

/// API Playground 메인 뷰 (3열 레이아웃, AsyncNetworkDocKit 스타일 적용)
struct APIPlaygroundSwiftView: View {
    @StateObject private var viewModel: APIPlaygroundSwiftViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
        _viewModel = StateObject(wrappedValue: APIPlaygroundSwiftViewModel())
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 1열: API 리스트
            NavigationStack {
                APIMethodListView(selectedRequest: Binding<EndpointMetadata?>(
                    get: { viewModel.state.selectedRequest },
                    set: { newValue in
                        if let request = newValue {
                            viewModel.send(.requestSelected(request))
                        }
                    }
                ))
                .navigationDestination(for: EndpointMetadata.self) { request in
                    APIRequestDetailView(request: request, networkService: networkService)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.send(.settingsButtonTapped)
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } content: {
            // 2열: API 상세 정보
            if let request = viewModel.state.selectedRequest {
                APIRequestDetailView(request: request, networkService: networkService)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
            } else {
                ContentUnavailableView(
                    "Select an API",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Choose an endpoint from the list to view details")
                )
            }
        } detail: {
            // 3열: API 테스터
            if let request = viewModel.state.selectedRequest {
                APIRequestTesterView(request: request, networkService: networkService)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 450, max: 600)
            } else {
                ContentUnavailableView(
                    "No API Selected",
                    systemImage: "play.circle",
                    description: Text("Select an endpoint to test the API")
                )
            }
        }
        .onAppear {
            viewModel.send(.viewDidAppear)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.shouldPresentSettings },
            set: { if !$0 { viewModel.state.shouldPresentSettings = false } }
        )) {
            SettingsSwiftView()
        }
    }
}

#Preview {
    APIPlaygroundSwiftView(networkService: AppDependency.shared.networkService)
}

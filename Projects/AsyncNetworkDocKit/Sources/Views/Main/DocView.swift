//
//  DocView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// Redoc 스타일의 3열 문서 뷰
@available(iOS 17.0, macOS 14.0, *)
struct DocView: View {
    let categories: [EndpointCategory]
    let networkService: NetworkService
    let appTitle: String

    @State private var selectedEndpoint: EndpointMetadata?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            NavigationStack {
                EndpointListView(
                    categories: categories,
                    selection: $selectedEndpoint
                )
                .navigationTitle(appTitle)
                .navigationDestination(for: EndpointMetadata.self) { endpoint in
                    EndpointDetailView(networkService: networkService, endpoint: endpoint)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } content: {
            if let endpoint = selectedEndpoint {
                EndpointDetailView(networkService: networkService, endpoint: endpoint)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
            } else {
                ContentUnavailableView(
                    "Select an API",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Choose an endpoint from the list to view details")
                )
            }
        } detail: {
            if let endpoint = selectedEndpoint {
                APITesterView(networkService: networkService, endpoint: endpoint)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 450, max: 600)
            } else {
                ContentUnavailableView(
                    "No API Selected",
                    systemImage: "play.circle",
                    description: Text("Select an endpoint to test the API")
                )
            }
        }
    }
}

//
//  RootView.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncNetwork
import SwiftUI

struct RootView: View {
    let repository: APITestRepository

    @State private var selectedEndpoint: APIEndpoint?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            EndpointsListView(selectedEndpoint: $selectedEndpoint)
        } content: {
            if let endpoint = selectedEndpoint {
                APISpecView(endpoint: endpoint)
            } else {
                welcomeView
            }
        } detail: {
            if let endpoint = selectedEndpoint {
                APITesterView(endpoint: endpoint, repository: repository)
            } else {
                placeholderView
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("NetworkKit API Playground")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Select an API endpoint from the list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Try it out")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Test the API and see the response")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView(
        repository: DefaultAPITestRepository(networkService: AsyncNetwork.createNetworkService())
    )
}

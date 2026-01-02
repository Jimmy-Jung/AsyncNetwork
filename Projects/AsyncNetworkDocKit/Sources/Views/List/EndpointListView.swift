//
//  EndpointListView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// 엔드포인트 목록 뷰 (1열)
@available(iOS 17.0, macOS 14.0, *)
struct EndpointListView: View {
    let categories: [EndpointCategory]
    @Binding var selection: EndpointMetadata?
    @State private var searchText = ""

    var body: some View {
        List(selection: $selection) {
            ForEach(categories) { category in
                Section {
                    ForEach(filteredEndpoints(for: category)) { endpoint in
                        NavigationLink(value: endpoint) {
                            HStack {
                                HTTPMethodBadge(method: endpoint.method)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(endpoint.path)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.medium)
                                    if !endpoint.title.isEmpty {
                                        Text(endpoint.title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Label(category.name, systemImage: "folder")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search APIs...")
    }

    private func filteredEndpoints(for category: EndpointCategory) -> [EndpointMetadata] {
        if searchText.isEmpty {
            return category.endpoints
        }
        return category.endpoints.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }
}

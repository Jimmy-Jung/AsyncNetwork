//
//  APIMethodListView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import SwiftUI

/// API 메서드 리스트를 표시하는 뷰 (AsyncNetworkDocKit 스타일 적용)
struct APIMethodListView: View {
    @Binding var selectedRequest: EndpointMetadata?
    @State private var searchText = ""

    var body: some View {
        List(selection: $selectedRequest) {
            Section {
                ForEach(filteredRequests) { request in
                    NavigationLink(value: request) {
                        HStack {
                            HTTPMethodBadge(method: request.method.uppercased())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.path)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                                if !request.title.isEmpty {
                                    Text(request.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Label("API Collection", systemImage: "folder")
            }
        }
        .searchable(text: $searchText, prompt: "Search APIs...")
        .navigationTitle("API Playground")
    }

    private var filteredRequests: [EndpointMetadata] {
        if searchText.isEmpty {
            return APIRequestCatalog.all
        }
        return APIRequestCatalog.all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }
}

#Preview {
    NavigationStack {
        APIMethodListView(selectedRequest: .constant(nil as EndpointMetadata?))
    }
}

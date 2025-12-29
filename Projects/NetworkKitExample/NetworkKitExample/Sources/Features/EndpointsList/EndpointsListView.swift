//
//  EndpointsListView.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import NetworkKit
import SwiftUI

struct EndpointsListView: View {
    @Binding var selectedEndpoint: APIEndpoint?
    @State private var searchText = ""

    var body: some View {
        List(selection: $selectedEndpoint) {
            ForEach(APIEndpointsData.categories, id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(filteredEndpoints(for: category)) { endpoint in
                        EndpointRow(endpoint: endpoint)
                            .tag(endpoint)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search APIs...")
        .navigationTitle("API Endpoints")
    }

    private func filteredEndpoints(for category: String) -> [APIEndpoint] {
        let endpoints = APIEndpointsData.endpoints(for: category)
        if searchText.isEmpty {
            return endpoints
        }
        return endpoints.filter {
            $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct EndpointRow: View {
    let endpoint: APIEndpoint

    var body: some View {
        HStack(spacing: 12) {
            HTTPMethodBadge(method: endpoint.method)
            VStack(alignment: .leading, spacing: 4) {
                Text(endpoint.path)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text(endpoint.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HTTPMethodBadge: View {
    let method: HTTPMethod

    var body: some View {
        Text(method.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(methodColor)
            .cornerRadius(4)
            .frame(width: 60)
    }

    private var methodColor: Color {
        switch method {
        case .get: return .blue
        case .post: return .green
        case .put: return .orange
        case .patch: return .orange
        case .delete: return .red
        case .head: return .purple
        case .options: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        EndpointsListView(selectedEndpoint: .constant(nil))
    }
}

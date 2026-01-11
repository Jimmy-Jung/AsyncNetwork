//
//  APIRequestDetailView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import SwiftUI

/// API Request 상세 정보를 표시하는 뷰 (AsyncNetworkDocKit 스타일 적용)
struct APIRequestDetailView: View {
    let request: EndpointMetadata
    let networkService: NetworkService

    init(request: EndpointMetadata, networkService: NetworkService) {
        self.request = request
        self.networkService = networkService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                headerSection

                Divider()

                // Try It Out 버튼 (iPhone compact 모드에서만)
                #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        NavigationLink(value: request) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Try API Tester")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                #endif

                // 설명
                descriptionSection

                // 태그
                if !request.tags.isEmpty {
                    Divider()
                    tagsSection
                }

                // 엔드포인트 정보
                Divider()
                endpointInfoSection
            }
            .padding(24)
        }
        .navigationTitle("API Specification")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: EndpointMetadata.self) { endpoint in
            APIRequestTesterView(request: endpoint, networkService: networkService)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HTTPMethodBadge(method: request.method.uppercased())
                Text(request.path)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
            }
            Text(request.title)
                .font(.headline)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "doc.text")
                .font(.headline)
            Text(request.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(request.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                }
            }
        }
    }

    // MARK: - Endpoint Info Section

    private var endpointInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Endpoint Information", systemImage: "info.circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Base URL", value: request.baseURLString)
                infoRow(label: "Path", value: request.path)
                infoRow(label: "Method", value: request.method.uppercased())
                infoRow(label: "Full URL", value: "\(request.baseURLString)\(request.path)")
                infoRow(label: "Response Type", value: request.responseTypeName)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Views

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .trailing)

            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(nil)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        APIRequestDetailView(
            request: APIRequestCatalog.all.first!,
            networkService: AppDependency.shared.networkService
        )
    }
}

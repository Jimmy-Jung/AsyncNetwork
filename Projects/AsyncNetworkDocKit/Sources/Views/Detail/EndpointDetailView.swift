//
//  EndpointDetailView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// 엔드포인트 상세 뷰 (2열)
@available(iOS 17.0, macOS 14.0, *)
struct EndpointDetailView: View {
    let networkService: NetworkService
    let endpoint: EndpointMetadata
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                
                // API Tester 버튼 (iPhone만, iPad는 3열이 보이므로 불필요)
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    NavigationLink(value: endpoint) {
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
                
                descriptionSection
                
                if !endpoint.tags.isEmpty {
                    Divider()
                    tagsSection
                }
                
                if let headers = endpoint.headers, !headers.isEmpty {
                    Divider()
                    headersSection(headers)
                }
                
                if !endpoint.parameters.isEmpty {
                    Divider()
                    parametersSection
                }
                
                if let requestBodyExample = endpoint.requestBodyExample {
                    Divider()
                    requestBodySection(requestBodyExample)
                }
                
                // Response 섹션은 항상 표시 (responseExample 여부와 관계없이)
                Divider()
                responseSection
            }
            .padding(24)
        }
        .navigationTitle("API Specification")
        .navigationDestination(for: EndpointMetadata.self) { endpoint in
            APITesterView(networkService: networkService, endpoint: endpoint)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HTTPMethodBadge(method: endpoint.method)
                Text(endpoint.path)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
            }
            Text(endpoint.title)
                .font(.headline)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "doc.text")
                .font(.headline)
            Text(endpoint.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(endpoint.tags, id: \.self) { tag in
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
    
    private func headersSection(_ headers: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Headers", systemImage: "list.dash.header.rectangle")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                    if let value = headers[key] {
                        HStack(alignment: .top, spacing: 8) {
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(":")
                                .foregroundStyle(.secondary)
                            
                            Text(value)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(nil)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parameters", systemImage: "list.bullet")
                .font(.headline)
            
            ForEach(endpoint.parameters) { parameter in
                ParameterRow(parameter: parameter)
            }
        }
    }
    
    private func requestBodySection(_ example: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Request Body (DTO)", systemImage: "arrow.up.doc")
                .font(.headline)
            
            Text("Expected Structure:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            
            CodeBlock(content: example)
        }
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Response", systemImage: "arrow.down.doc")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // Response Type
                HStack {
                    Text("Type:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(endpoint.responseTypeName)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Response Structure
                if let responseStructure = endpoint.responseStructure {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response Structure:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        CodeBlock(content: responseStructure)
                    }
                }
                
                // Response Example
                if let responseExample = endpoint.responseExample {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example Response:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        CodeBlock(content: responseExample)
                    }
                }
                
                // 둘 다 없는 경우
                if endpoint.responseStructure == nil && endpoint.responseExample == nil {
                    Text("No response structure or example provided")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
    }
}


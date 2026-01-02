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

                if !endpoint.requestBodyFields.isEmpty || endpoint.requestBodyExample != nil {
                    Divider()
                    requestBodySection
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

    private var requestBodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Request Body", systemImage: "arrow.up.doc")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                // Request Body Fields
                if !endpoint.requestBodyFields.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fields:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(groupFieldsByPrefix(endpoint.requestBodyFields), id: \.key) { group in
                                renderFieldGroup(group)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }

                // Request Body Example (DTO)
                if let requestBodyExample = endpoint.requestBodyExample {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expected Structure (JSON):")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        CodeBlock(content: requestBodyExample)
                    }
                }
            }
        }
    }

    private struct FieldGroup: Identifiable {
        let key: String
        let prefix: String?
        let fields: [AsyncNetworkCore.RequestBodyFieldInfo]

        var id: String { key }
    }

    private func groupFieldsByPrefix(_ fields: [AsyncNetworkCore.RequestBodyFieldInfo]) -> [FieldGroup] {
        var groups: [String: [AsyncNetworkCore.RequestBodyFieldInfo]] = [:]

        for field in fields {
            let components = field.name.split(separator: ".")
            if components.count == 1 {
                // 최상위 필드
                groups["_root", default: []].append(field)
            } else {
                // 중첩 필드 - 첫 번째 레벨로 그룹화
                let prefix = String(components.first!)
                groups[prefix, default: []].append(field)
            }
        }

        return groups.sorted { $0.key < $1.key }.map { key, fields in
            FieldGroup(
                key: key,
                prefix: key == "_root" ? nil : key,
                fields: fields.sorted { $0.name < $1.name }
            )
        }
    }

    @ViewBuilder
    private func renderFieldGroup(_ group: FieldGroup) -> some View {
        if let prefix = group.prefix {
            // 그룹화된 필드 (토글 가능)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(group.fields) { field in
                        renderNestedField(field, groupPrefix: prefix)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(prefix)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)

                    Text("{...}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text("\(group.fields.count) fields")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 2)
        } else {
            // 최상위 필드들
            ForEach(group.fields) { field in
                renderTopLevelField(field)
            }
        }
    }

    private func renderTopLevelField(_ field: AsyncNetworkCore.RequestBodyFieldInfo) -> some View {
        HStack(alignment: .top, spacing: 4) {
            HStack(spacing: 4) {
                Text(field.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                if field.isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }
            }

            Text(":")
                .foregroundStyle(.secondary)

            Text(field.type)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.blue)

            if let example = field.exampleValue {
                Text("=")
                    .foregroundStyle(.secondary)
                Text(example)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func renderNestedField(_ field: AsyncNetworkCore.RequestBodyFieldInfo, groupPrefix: String) -> some View {
        let fullPath = field.name
        let pathWithoutPrefix = fullPath.hasPrefix(groupPrefix + ".")
            ? String(fullPath.dropFirst(groupPrefix.count + 1))
            : fullPath
        let depth = pathWithoutPrefix.split(separator: ".").count - 1
        let displayName = pathWithoutPrefix.split(separator: ".").last.map(String.init) ?? pathWithoutPrefix
        let indent = String(repeating: "  ", count: depth)

        return HStack(alignment: .top, spacing: 4) {
            if !indent.isEmpty {
                Text(indent)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.clear)
            }

            HStack(spacing: 4) {
                Text(displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                if field.isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }
            }

            Text(":")
                .foregroundStyle(.secondary)

            Text(field.type)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.blue)

            if let example = field.exampleValue {
                Text("=")
                    .foregroundStyle(.secondary)
                Text(example)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.vertical, 1)
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

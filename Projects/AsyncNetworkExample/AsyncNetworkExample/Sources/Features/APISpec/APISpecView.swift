//
//  APISpecView.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

struct APISpecView: View {
    let endpoint: APIEndpoint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                descriptionSection

                if !endpoint.parameters.isEmpty {
                    Divider()
                    parametersSection
                }

                if let requestBody = endpoint.requestBody {
                    Divider()
                    requestBodySection(requestBody)
                }

                if !endpoint.responses.isEmpty {
                    Divider()
                    responsesSection
                }
            }
            .padding(24)
        }
        .navigationTitle("API Specification")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HTTPMethodBadge(method: endpoint.method)
                Text(endpoint.path)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
            }
            Text(endpoint.summary)
                .font(.headline)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            Text(endpoint.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.headline)

            ForEach(endpoint.parameters) { parameter in
                ParameterRow(parameter: parameter)
            }
        }
    }

    private func requestBodySection(_ body: RequestBody) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Request Body")
                    .font(.headline)
                if body.required {
                    Text("required")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Text(body.contentType)
                .font(.caption)
                .foregroundStyle(.secondary)

            CodeBlock(content: body.example)
        }
    }

    private var responsesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Responses")
                .font(.headline)

            ForEach(endpoint.responses) { response in
                ResponseRow(response: response)
            }
        }
    }
}

struct ParameterRow: View {
    let parameter: APIParameter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(parameter.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)

                Text(parameter.location.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)

                if parameter.required {
                    Text("required")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                Text(parameter.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(parameter.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let example = parameter.example {
                Text("Example: \(example)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

struct ResponseRow: View {
    let response: APIResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusCodeBadge(statusCode: response.statusCode)
                Text(response.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Schema: \(response.schema)")
                .font(.caption)
                .foregroundStyle(.secondary)

            CodeBlock(content: response.example)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

struct StatusCodeBadge: View {
    let statusCode: Int

    var body: some View {
        Text("\(statusCode)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch statusCode {
        case 200 ..< 300: return .green
        case 300 ..< 400: return .blue
        case 400 ..< 500: return .orange
        case 500...: return .red
        default: return .gray
        }
    }
}

struct CodeBlock: View {
    let content: String
    @State private var text: String

    init(content: String) {
        self.content = content
        _text = State(initialValue: content)
    }

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.caption, design: .monospaced))
            .frame(height: 300)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .autocorrectionDisabled() // 자동 수정 비활성화
            .textInputAutocapitalization(.never) // 자동 대문자 비활성화
            .onChange(of: text) { _, newValue in
                // 사용자 편집 방지 (읽기 전용)
                if newValue != content {
                    text = content
                }
            }
    }
}

#Preview {
    NavigationStack {
        APISpecView(endpoint: .getPosts)
    }
}

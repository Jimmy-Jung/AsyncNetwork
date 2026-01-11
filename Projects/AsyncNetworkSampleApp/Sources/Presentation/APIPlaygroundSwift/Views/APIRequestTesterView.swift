//
//  APIRequestTesterView.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import SwiftUI

/// API Request를 테스트하는 뷰 (AsyncNetworkDocKit 스타일 적용)
struct APIRequestTesterView: View {
    let request: EndpointMetadata
    let networkService: NetworkService

    @State private var state: APIPlaygroundState
    @State private var requestTask: Task<Void, Never>?

    init(request: EndpointMetadata, networkService: NetworkService) {
        self.request = request
        self.networkService = networkService
        let existingState = APIPlaygroundStateStore.shared.getState(for: request.id)
        _state = State(initialValue: existingState)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                Divider()

                if !request.headers.isEmpty {
                    headersDisplaySection
                    Divider()
                }

                if needsParameters {
                    parametersInputSection
                    Divider()
                }

                if needsRequestBody {
                    requestBodyInputSection
                    Divider()
                }

                sendButtonSection

                if state.isLoading {
                    ProgressView("Sending request...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                if let error = state.error {
                    errorSection(error)
                }

                if state.hasBeenRequested && !state.response.isEmpty {
                    Divider()
                    requestMetadataSection
                    Divider()
                    responseDisplaySection
                }
            }
            .padding(24)
        }
        .navigationTitle("API Tester")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupDefaultValues()
        }
        .onChange(of: request.id) { _, newRequestId in
            requestTask?.cancel()
            requestTask = nil
            state = APIPlaygroundStateStore.shared.getState(for: newRequestId)
            setupDefaultValues()
        }
        .onDisappear {
            requestTask?.cancel()
            requestTask = nil
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Try It Out", systemImage: "play.circle.fill")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                HTTPMethodBadge(method: request.method.uppercased())
                Text(buildURL())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Headers Display Section

    private var headersDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Headers", systemImage: "doc.text")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(request.headers.keys.sorted()), id: \.self) { key in
                    HStack(spacing: 12) {
                        Text(key)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.medium)
                            .frame(width: 150, alignment: .trailing)

                        TextField(
                            "String",
                            text: binding(forHeader: key)
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.callout, design: .monospaced))
                    }
                }
            }
        }
    }

    // MARK: - Parameters Input Section

    private var parametersInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)

            ForEach(extractParameters(), id: \.self) { param in
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(param)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.medium)
                        Text("*")
                            .foregroundStyle(.red)
                    }
                    .frame(width: 150, alignment: .trailing)

                    TextField(
                        "String",
                        text: binding(forParameter: param)
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
                }
            }
        }
    }

    // MARK: - Request Body Input Section

    private var requestBodyInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Request Body", systemImage: "doc.plaintext")
                .font(.headline)

            TextEditor(text: $state.requestBody)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 200)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Send Button Section

    private var sendButtonSection: some View {
        Button {
            requestTask?.cancel()
            requestTask = Task {
                await sendRequest()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text("Send Request")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(state.isLoading)
        .opacity(state.isLoading ? 0.6 : 1.0)
    }

    // MARK: - Error Section

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)

            Text(error)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
    }

    // MARK: - Request Metadata Section

    private var requestMetadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                HStack {
                    Text("🌐 REQUEST")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    if !state.requestTimestamp.isEmpty {
                        Text("🕐 \(state.requestTimestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔧 Method & URL:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        HTTPMethodBadge(method: request.method.uppercased())
                        Text(buildURL())
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(nil)
                    }
                }

                if !state.requestHeaders.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📋 Headers:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(Array(state.requestHeaders.keys.sorted()), id: \.self) { key in
                            if let value = state.requestHeaders[key] {
                                HStack(alignment: .top, spacing: 4) {
                                    Text(key)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.medium)
                                    Text(":")
                                        .foregroundStyle(.secondary)
                                    Text(value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .lineLimit(nil)
                                }
                            }
                        }
                    }
                }

                if needsParameters {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔑 Parameters:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(extractParameters(), id: \.self) { param in
                            HStack(spacing: 4) {
                                Text(param)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text("=")
                                    .foregroundStyle(.secondary)
                                if let value = state.parameters[param], !value.isEmpty {
                                    Text(value)
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.medium)
                                } else {
                                    Text("(empty)")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .italic()
                                }
                            }
                        }
                    }
                }

                if !state.requestBody.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📦 Body (\(state.requestBodySize) bytes):")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ScrollView {
                            Text(state.requestBody)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(height: 150)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Response Display Section

    private var responseDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                HStack {
                    HStack(spacing: 4) {
                        Text(state.statusCode ?? 0 < 400 ? "✅" : "⚠️")
                        Text("RESPONSE")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if !state.responseTimestamp.isEmpty {
                        Text("🕐 \(state.responseTimestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(state.statusCode ?? 0 < 400 ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 12) {
                if let status = state.statusCode {
                    HStack(spacing: 8) {
                        Text("📊 Status:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text("\(status)")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor(status).opacity(0.2))
                            .foregroundStyle(statusColor(status))
                            .cornerRadius(6)
                    }
                }

                if !state.responseHeaders.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📋 Response Headers:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(Array(state.responseHeaders.keys.sorted()), id: \.self) { key in
                            if let value = state.responseHeaders[key] {
                                HStack(alignment: .top, spacing: 4) {
                                    Text(key)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.medium)
                                    Text(":")
                                        .foregroundStyle(.secondary)
                                    Text(value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("📦 Response Body (\(state.responseBodySize) bytes):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        Text(state.response)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 400)
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Views & Bindings

    private func binding(forParameter key: String) -> Binding<String> {
        Binding(
            get: { state.parameters[key] ?? "" },
            set: { state.parameters[key] = $0 }
        )
    }

    private func binding(forHeader key: String) -> Binding<String> {
        Binding(
            get: { state.headerFields[key] ?? "" },
            set: { state.headerFields[key] = $0 }
        )
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200 ..< 300: return .green
        case 300 ..< 400: return .blue
        case 400 ..< 500: return .orange
        case 500 ..< 600: return .red
        default: return .gray
        }
    }

    // MARK: - Helpers

    private var needsParameters: Bool {
        !extractParameters().isEmpty
    }

    private var needsRequestBody: Bool {
        let method = request.method.uppercased()
        return method == "POST" || method == "PUT" || method == "PATCH"
    }

    private func extractParameters() -> [String] {
        // path에서 {id}, {userId} 같은 파라미터 추출
        let pattern = "\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: request.path, range: NSRange(request.path.startIndex..., in: request.path))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: request.path) else { return nil }
            return String(request.path[range])
        }
    }

    private func buildURL() -> String {
        var path = request.path

        // 파라미터 치환
        for (key, value) in state.parameters where !value.isEmpty {
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return request.baseURLString + path
    }

    private func setupDefaultValues() {
        if state.hasBeenRequested {
            return
        }

        // 헤더 기본값 설정
        for (key, value) in request.headers {
            if state.headerFields[key] == nil {
                state.headerFields[key] = value
            }
        }

        // 파라미터 기본값 설정
        let params = extractParameters()
        for param in params {
            if state.parameters[param] == nil {
                switch param {
                case "id": state.parameters[param] = "1"
                case "userId": state.parameters[param] = "1"
                case "username": state.parameters[param] = "octocat"
                default: state.parameters[param] = ""
                }
            }
        }

        // Request Body 기본값 설정
        if needsRequestBody, state.requestBody.isEmpty {
            state.requestBody = """
            {
              "title": "Test Post",
              "body": "This is a test post",
              "userId": 1
            }
            """
        }
    }

    private func sendRequest() async {
        let currentRequestId = request.id
        let targetState = APIPlaygroundStateStore.shared.getState(for: currentRequestId)

        targetState.markAsRequested()

        targetState.isLoading = true
        targetState.error = nil
        targetState.response = ""
        targetState.statusCode = nil

        targetState.requestHeaders = [:]
        targetState.responseHeaders = [:]
        targetState.requestBodySize = 0
        targetState.responseBodySize = 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        targetState.requestTimestamp = dateFormatter.string(from: Date())

        do {
            // 헤더 준비
            var allHeaders: [String: String] = [:]
            for (key, _) in request.headers {
                if let userValue = targetState.headerFields[key], !userValue.isEmpty {
                    allHeaders[key] = userValue
                }
            }

            // Request Body 준비
            var bodyData: Data?
            if needsRequestBody, !targetState.requestBody.isEmpty {
                bodyData = targetState.requestBody.data(using: .utf8)
                allHeaders["Content-Type"] = "application/json"
                targetState.requestBodySize = bodyData?.count ?? 0
            }

            targetState.requestHeaders = allHeaders

            // DynamicAPIRequest 생성
            let apiRequest = DynamicAPIRequest(
                baseURL: request.baseURLString,
                path: buildPath(),
                method: HTTPMethod(rawValue: request.method.uppercased()) ?? .get,
                headers: allHeaders.isEmpty ? nil : allHeaders,
                queryParameters: nil,
                body: bodyData
            )

            // NetworkService로 요청 실행
            let httpResponse = try await networkService.requestRaw(apiRequest)

            targetState.responseTimestamp = dateFormatter.string(from: Date())
            targetState.statusCode = httpResponse.statusCode
            targetState.responseBodySize = httpResponse.data.count

            // 응답 헤더 파싱 (요청 헤더와 매칭되는 것만)
            if let response = httpResponse.response {
                let requestHeaderKeys = Set(request.headers.keys.map { $0.lowercased() })
                for (key, value) in response.allHeaderFields {
                    if let keyString = key as? String, let valueString = value as? String {
                        if requestHeaderKeys.contains(keyString.lowercased()) {
                            targetState.responseHeaders[keyString] = valueString
                        }
                    }
                }
            }

            // 응답 본문 파싱 (JSON 포맷팅)
            if let jsonObject = try? JSONSerialization.jsonObject(with: httpResponse.data),
               let prettyData = try? JSONSerialization.data(
                   withJSONObject: jsonObject,
                   options: [.prettyPrinted, .sortedKeys]
               ),
               let prettyString = String(data: prettyData, encoding: .utf8)
            {
                targetState.response = prettyString
            } else {
                targetState.response = String(data: httpResponse.data, encoding: .utf8) ?? "Unable to decode response"
            }

            targetState.isLoading = false

        } catch {
            targetState.responseTimestamp = dateFormatter.string(from: Date())
            targetState.error = error.localizedDescription
            targetState.isLoading = false
        }
    }

    private func buildPath() -> String {
        var path = request.path

        // 파라미터 치환
        for (key, value) in state.parameters where !value.isEmpty {
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        APIRequestTesterView(
            request: APIRequestCatalog.all.first!,
            networkService: AppDependency.shared.networkService
        )
    }
}

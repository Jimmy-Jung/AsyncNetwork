//
//  APITesterView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import SwiftUI
import AsyncNetworkCore

/// API 테스터 뷰 (3열)
@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct APITesterView: View {
    let networkService: NetworkService
    let endpoint: EndpointMetadata
    
    @State private var parameters: [String: String] = [:]
    @State private var requestBody: String = ""
    @State private var isLoading: Bool = false
    @State private var responseText: String = ""
    @State private var statusCode: Int?
    @State private var errorMessage: String?
    
    // LoggingInterceptor 스타일 상세 정보
    @State private var requestTimestamp: String = ""
    @State private var responseTimestamp: String = ""
    @State private var requestHeaders: [String: String] = [:]
    @State private var responseHeaders: [String: String] = [:]
    @State private var requestBodySize: Int = 0
    @State private var responseBodySize: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                Divider()
                
                if !endpoint.parameters.isEmpty {
                    parametersInputSection
                    Divider()
                }
                
                if endpoint.requestBodyExample != nil {
                    requestBodyInputSection
                    Divider()
                }
                
                sendButtonSection
                
                if isLoading {
                    ProgressView("Sending request...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                
                if let error = errorMessage {
                    errorSection(error)
                }
                
                if !responseText.isEmpty {
                    Divider()
                    requestMetadataSection
                    Divider()
                    responseDisplaySection
                }
            }
            .padding(24)
        }
        .navigationTitle("API Tester")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            setupDefaultValues()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Try It Out", systemImage: "play.circle.fill")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                HTTPMethodBadge(method: endpoint.method)
                Text(buildURL())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    private var parametersInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)
            
            ForEach(endpoint.parameters) { parameter in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(parameter.name)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        if parameter.isRequired {
                            Text("*")
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Text(parameter.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField(
                        parameter.exampleValue ?? "Enter \(parameter.name)",
                        text: binding(for: parameter.name)
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    
                    if let desc = parameter.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var requestBodyInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Request Body", systemImage: "doc.plaintext")
                .font(.headline)
            
            TextEditor(text: $requestBody)
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
    
    private var sendButtonSection: some View {
        Button {
            Task {
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
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
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
    
    private var requestMetadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                HStack {
                    Text("🌐 REQUEST")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    if !requestTimestamp.isEmpty {
                        Text("🕐 \(requestTimestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Method & URL
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔧 Method & URL:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        HTTPMethodBadge(method: endpoint.method)
                        Text(buildURL())
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(nil)
                    }
                }
                
                // Headers
                if !requestHeaders.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📋 Headers:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        ForEach(Array(requestHeaders.keys.sorted()), id: \.self) { key in
                            if let value = requestHeaders[key] {
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
                
                // Parameters
                if !endpoint.parameters.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔑 Parameters:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        ForEach(endpoint.parameters) { parameter in
                            HStack(spacing: 4) {
                                Text(parameter.name)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text("=")
                                    .foregroundStyle(.secondary)
                                if let value = parameters[parameter.name], !value.isEmpty {
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
                
                // Request Body
                if !requestBody.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📦 Body (\(requestBodySize) bytes):")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        ScrollView {
                            Text(requestBody)
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
    
    private var responseDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                HStack {
                    HStack(spacing: 4) {
                        Text(statusCode ?? 0 < 400 ? "✅" : "⚠️")
                        Text("RESPONSE")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if !responseTimestamp.isEmpty {
                        Text("🕐 \(responseTimestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(statusCode ?? 0 < 400 ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Status Code
                if let status = statusCode {
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
                
                // Response Headers
                if !responseHeaders.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📋 Response Headers:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        ForEach(Array(responseHeaders.keys.sorted()), id: \.self) { key in
                            if let value = responseHeaders[key] {
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
                
                // Response Body
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("📦 Response Body (\(responseBodySize) bytes):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    ScrollView {
                        Text(responseText)
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
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { parameters[key] ?? "" },
            set: { parameters[key] = $0 }
        )
    }
    
    private func setupDefaultValues() {
        for parameter in endpoint.parameters {
            if let example = parameter.exampleValue {
                parameters[parameter.name] = example
            }
        }
        
        if let bodyExample = endpoint.requestBodyExample {
            requestBody = bodyExample
        }
    }
    
    private func buildURL() -> String {
        var url = endpoint.baseURLString + endpoint.path
        
        for parameter in endpoint.parameters where parameter.location == .path {
            if let value = parameters[parameter.name], !value.isEmpty {
                url = url.replacingOccurrences(of: "{\(parameter.name)}", with: value)
            }
        }
        
        let queryParams = endpoint.parameters
            .filter { $0.location == .query }
            .compactMap { param -> String? in
                guard let value = parameters[param.name], !value.isEmpty else { return nil }
                return "\(param.name)=\(value)"
            }
        
        if !queryParams.isEmpty {
            url += "?" + queryParams.joined(separator: "&")
        }
        
        return url
    }
    
    private func sendRequest() async {
        isLoading = true
        errorMessage = nil
        responseText = ""
        statusCode = nil
        
        // Reset logging info
        requestHeaders = [:]
        responseHeaders = [:]
        requestBodySize = 0
        responseBodySize = 0
        
        // Timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        requestTimestamp = dateFormatter.string(from: Date())
        
        do {
            // Build URL with path parameters
            var path = endpoint.path
            for parameter in endpoint.parameters where parameter.location == .path {
                if let value = parameters[parameter.name], !value.isEmpty {
                    path = path.replacingOccurrences(of: "{\(parameter.name)}", with: value)
                }
            }
            
            // Collect query parameters
            var queryParams: [String: String] = [:]
            for parameter in endpoint.parameters where parameter.location == .query {
                if let value = parameters[parameter.name], !value.isEmpty {
                    queryParams[parameter.name] = value
                }
            }
            
            // Prepare request body
            var bodyData: Data?
            if !requestBody.isEmpty, ["POST", "PUT", "PATCH"].contains(endpoint.method.uppercased()) {
                bodyData = requestBody.data(using: .utf8)
                requestBodySize = bodyData?.count ?? 0
            }
            
            // Display only endpoint-defined headers in UI
            requestHeaders = endpoint.headers ?? [:]
            
            // Prepare headers for actual request
            var allHeaders = endpoint.headers ?? [:]
            if bodyData != nil {
                allHeaders["Content-Type"] = "application/json"
            }
            
            // Create dynamic API request
            let apiRequest = DynamicAPIRequest(
                baseURL: endpoint.baseURLString,
                path: path,
                method: HTTPMethod(rawValue: endpoint.method.uppercased()) ?? .get,
                headers: allHeaders.isEmpty ? nil : allHeaders,
                queryParameters: queryParams.isEmpty ? nil : queryParams,
                body: bodyData
            )
            
            // Execute request
            let httpResponse = try await networkService.requestRaw(apiRequest)
            
            // Update response timestamp
            responseTimestamp = dateFormatter.string(from: Date())
            
            // Collect response info
            statusCode = httpResponse.statusCode
            responseBodySize = httpResponse.data.count
            
            // Collect only request-defined headers in response
            // (endpoint에 정의된 헤더만 response에서도 표시)
            if let response = httpResponse.response {
                let requestHeaderKeys = Set((endpoint.headers ?? [:]).keys.map { $0.lowercased() })
                
                for (key, value) in response.allHeaderFields {
                    if let keyString = key as? String, let valueString = value as? String {
                        // endpoint에 정의된 헤더만 표시
                        if requestHeaderKeys.contains(keyString.lowercased()) {
                            responseHeaders[keyString] = valueString
                        }
                    }
                }
            }
            
            // Format response body
            if let jsonObject = try? JSONSerialization.jsonObject(with: httpResponse.data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                responseText = prettyString
            } else {
                responseText = String(data: httpResponse.data, encoding: .utf8) ?? "Unable to decode response"
            }
            
        } catch {
            responseTimestamp = dateFormatter.string(from: Date())
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .gray
        }
    }
}


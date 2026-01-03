//
//  APITesterView.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import AsyncNetworkCore
import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct APITesterView: View {
    let networkService: NetworkService
    let endpoint: EndpointMetadata

    @State private var state: APITesterState
    @State private var requestTask: Task<Void, Never>?

    init(networkService: NetworkService, endpoint: EndpointMetadata) {
        self.networkService = networkService
        self.endpoint = endpoint
        let existingState = APITesterStateStore.shared.getState(for: endpoint.id)
        _state = State(initialValue: existingState)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                Divider()

                if let headers = endpoint.headers, !headers.isEmpty {
                    headersDisplaySection
                    Divider()
                }

                if !endpoint.parameters.isEmpty {
                    parametersInputSection
                    Divider()
                }

                if !endpoint.requestBodyFields.isEmpty {
                    requestBodyFieldsInputSection
                    Divider()
                } else if endpoint.requestBodyExample != nil {
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
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .onAppear {
                setupDefaultValues()
            }
            .onChange(of: endpoint.id) { _, newEndpointId in
                // endpoint가 바뀌면 이전 Task 취소
                requestTask?.cancel()
                requestTask = nil

                // 해당 endpoint의 state로 교체
                state = APITesterStateStore.shared.getState(for: newEndpointId)
                setupDefaultValues()
            }
            .onDisappear {
                // 뷰가 사라질 때 진행 중인 Task 취소
                requestTask?.cancel()
                requestTask = nil
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

    private var headersDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Headers", systemImage: "doc.text")
                .font(.headline)

            if let headers = endpoint.headers {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                        if headers[key] != nil {
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
        }
    }

    private var parametersInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)

            ForEach(endpoint.parameters) { parameter in
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(parameter.name)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.medium)
                        if parameter.isRequired {
                            Text("*")
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(width: 150, alignment: .trailing)

                    TextField(
                        parameter.type,
                        text: binding(for: parameter.name)
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
                }
            }
        }
    }

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

    private var requestBodyFieldsInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Request Body", systemImage: "doc.plaintext")
                .font(.headline)

            // 최상위 필드만 렌더링 (중첩 필드는 각 필드 내부에서 처리)
            let topLevelFields = endpoint.requestBodyFields.filter { !$0.name.contains(".") }
            ForEach(topLevelFields) { field in
                renderTopLevelFieldInput(field)
            }
        }
    }

    @ViewBuilder
    private func renderTopLevelFieldInput(_ field: AsyncNetworkCore.RequestBodyFieldInfo) -> some View {
        switch field.fieldKind {
        case .primitive:
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text(field.name)
                        .font(.system(.callout, design: .monospaced))
                        .fontWeight(.semibold)
                    if field.isRequired {
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                .frame(width: 150, alignment: .trailing)

                requestBodyFieldInput(for: field)
            }

        case .object:
            let nestedFields = endpoint.requestBodyFields.filter { $0.name.hasPrefix(field.name + ".") }
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(nestedFields) { nestedField in
                        renderObjectNestedField(nestedField, parentPath: field.name)
                    }
                }
                .padding(.leading, 20)
            } label: {
                HStack(spacing: 8) {
                    Text(field.name)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    if field.isRequired {
                        Text("*")
                            .foregroundStyle(.red)
                    }
                    Text(field.type)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

        case .array:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(field.name)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    if field.isRequired {
                        Text("*")
                            .foregroundStyle(.red)
                    }
                    Text(field.type)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        addArrayItem(for: field.name)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                let itemCount = state.arrayItemCounts[field.name] ?? 0
                if itemCount > 0 {
                    ForEach(0 ..< itemCount, id: \.self) { index in
                        renderArrayItem(field: field, index: index)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func requestBodyFieldInput(for field: AsyncNetworkCore.RequestBodyFieldInfo) -> some View {
        let fieldType = field.type.lowercased()

        if fieldType == "bool" {
            Toggle(isOn: boolBinding(for: field.name)) {
                Text(field.type)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        } else if fieldType == "int" || fieldType == "double" {
            #if os(iOS)
                TextField(
                    field.type,
                    text: binding(forBodyField: field.name)
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, design: .monospaced))
                .keyboardType(.numberPad)
            #else
                TextField(
                    field.type,
                    text: binding(forBodyField: field.name)
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, design: .monospaced))
            #endif
        } else {
            TextField(
                field.type,
                text: binding(forBodyField: field.name)
            )
            .textFieldStyle(.roundedBorder)
            .font(.system(.callout, design: .monospaced))
        }
    }

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
                        HTTPMethodBadge(method: endpoint.method)
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
                                if let value = state.parameters[parameter.name], !value.isEmpty {
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

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { state.parameters[key] ?? "" },
            set: { state.parameters[key] = $0 }
        )
    }

    private func binding(forBodyField key: String) -> Binding<String> {
        Binding(
            get: { state.requestBodyFields[key] ?? "" },
            set: { state.requestBodyFields[key] = $0 }
        )
    }

    private func binding(forHeader key: String) -> Binding<String> {
        Binding(
            get: { state.headerFields[key] ?? "" },
            set: { state.headerFields[key] = $0 }
        )
    }

    private func boolBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: {
                if let value = state.requestBodyFields[key] {
                    return value.lowercased() == "true" || value == "1"
                }
                return false
            },
            set: { state.requestBodyFields[key] = $0 ? "true" : "false" }
        )
    }

    @ViewBuilder
    private func renderObjectNestedField(_ field: AsyncNetworkCore.RequestBodyFieldInfo, parentPath: String) -> some View {
        let relativeName = String(field.name.dropFirst(parentPath.count + 1))
        let displayName = relativeName.split(separator: ".").first.map(String.init) ?? relativeName

        if field.fieldKind == .primitive {
            HStack(spacing: 12) {
                Text(displayName)
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                if field.isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                }

                requestBodyFieldInput(for: field)
            }
        }
    }

    @ViewBuilder
    private func renderArrayItem(field: AsyncNetworkCore.RequestBodyFieldInfo, index: Int) -> some View {
        let nestedFields = endpoint.requestBodyFields.filter {
            $0.name.hasPrefix(field.name + ".")
        }

        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(nestedFields) { nestedField in
                    renderArrayItemField(nestedField, arrayPath: field.name, index: index)
                }
            }
            .padding(.leading, 20)
        } label: {
            HStack(spacing: 12) {
                Text("[\(index)]")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Spacer()

                Button {
                    removeArrayItem(for: field.name, at: index)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
        .padding(.leading, 20)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func renderArrayItemField(_ field: AsyncNetworkCore.RequestBodyFieldInfo, arrayPath: String, index: Int) -> some View {
        let relativeName = String(field.name.dropFirst(arrayPath.count + 1))
        let displayName = relativeName.split(separator: ".").first.map(String.init) ?? relativeName

        HStack(spacing: 12) {
            Text(displayName)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            if field.isRequired {
                Text("*")
                    .foregroundStyle(.red)
            }

            TextField(
                field.type,
                text: arrayFieldBinding(arrayPath: arrayPath, index: index, fieldName: relativeName)
            )
            .textFieldStyle(.roundedBorder)
            .font(.system(.callout, design: .monospaced))
        }
    }

    private func arrayFieldBinding(arrayPath: String, index: Int, fieldName: String) -> Binding<String> {
        Binding(
            get: {
                state.arrayItems[arrayPath]?[index]?[fieldName] ?? ""
            },
            set: { newValue in
                if state.arrayItems[arrayPath] == nil {
                    state.arrayItems[arrayPath] = [:]
                }
                if state.arrayItems[arrayPath]?[index] == nil {
                    state.arrayItems[arrayPath]?[index] = [:]
                }
                state.arrayItems[arrayPath]?[index]?[fieldName] = newValue
            }
        )
    }

    private func addArrayItem(for arrayPath: String) {
        let currentCount = state.arrayItemCounts[arrayPath] ?? 0
        state.arrayItemCounts[arrayPath] = currentCount + 1

        // 초기 빈 항목 생성
        if state.arrayItems[arrayPath] == nil {
            state.arrayItems[arrayPath] = [:]
        }
        state.arrayItems[arrayPath]?[currentCount] = [:]
    }

    private func removeArrayItem(for arrayPath: String, at index: Int) {
        state.arrayItems[arrayPath]?.removeValue(forKey: index)

        let remainingIndices = state.arrayItems[arrayPath]?.keys.sorted() ?? []
        state.arrayItemCounts[arrayPath] = remainingIndices.isEmpty ? 0 : (remainingIndices.last! + 1)
    }

    private func setupDefaultValues() {
        if state.hasBeenRequested {
            return
        }

        if let headers = endpoint.headers {
            for (key, value) in headers {
                if state.headerFields[key] == nil {
                    state.headerFields[key] = value
                }
            }
        }

        for parameter in endpoint.parameters {
            if let example = parameter.exampleValue, state.parameters[parameter.name] == nil {
                state.parameters[parameter.name] = example
            }
        }

        if !endpoint.requestBodyFields.isEmpty {
            for field in endpoint.requestBodyFields {
                if let example = field.exampleValue, state.requestBodyFields[field.name] == nil {
                    state.requestBodyFields[field.name] = example
                }
            }
        } else if let bodyExample = endpoint.requestBodyExample, state.requestBody.isEmpty {
            state.requestBody = bodyExample
        }
    }

    private func buildURL() -> String {
        var url = endpoint.baseURLString + endpoint.path

        for parameter in endpoint.parameters where parameter.location == .path {
            if let value = state.parameters[parameter.name], !value.isEmpty {
                url = url.replacingOccurrences(of: "{\(parameter.name)}", with: value)
            }
        }

        let queryParams = endpoint.parameters
            .filter { $0.location == .query }
            .compactMap { param -> String? in
                guard let value = state.parameters[param.name], !value.isEmpty else { return nil }
                return "\(param.name)=\(value)"
            }

        if !queryParams.isEmpty {
            url += "?" + queryParams.joined(separator: "&")
        }

        return url
    }

    private func buildJSONFromFields(using targetState: APITesterState) -> String {
        var jsonDict: [String: Any] = [:]

        let topLevelFields = endpoint.requestBodyFields.filter { !$0.name.contains(".") }

        for field in topLevelFields {
            switch field.fieldKind {
            case .primitive:
                // 기본 타입 필드
                guard let value = targetState.requestBodyFields[field.name], !value.isEmpty else {
                    continue
                }
                jsonDict[field.name] = convertPrimitiveValue(value, type: field.type)

            case .object:
                let objectData = buildNestedObject(for: field.name, using: targetState)
                if !objectData.isEmpty {
                    jsonDict[field.name] = objectData
                }

            case .array:
                let arrayData = buildArrayData(for: field.name, using: targetState)
                if !arrayData.isEmpty {
                    jsonDict[field.name] = arrayData
                }
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return jsonString
    }

    private func convertPrimitiveValue(_ value: String, type: String) -> Any {
        let fieldType = type.lowercased()
        switch fieldType {
        case "string":
            return value
        case "int":
            return Int(value) ?? 0
        case "double":
            return Double(value) ?? 0.0
        case "bool":
            return value.lowercased() == "true" || value == "1"
        default:
            return value
        }
    }

    private func buildNestedObject(for parentPath: String, using targetState: APITesterState) -> [String: Any] {
        var objectDict: [String: Any] = [:]

        let nestedFields = endpoint.requestBodyFields.filter {
            $0.name.hasPrefix(parentPath + ".") && !$0.name.dropFirst(parentPath.count + 1).contains(".")
        }

        for field in nestedFields {
            let fieldName = String(field.name.dropFirst(parentPath.count + 1))
            guard let value = targetState.requestBodyFields[field.name], !value.isEmpty else {
                continue
            }
            objectDict[fieldName] = convertPrimitiveValue(value, type: field.type)
        }

        return objectDict
    }

    private func buildArrayData(for arrayPath: String, using targetState: APITesterState) -> [[String: Any]] {
        var arrayData: [[String: Any]] = []

        guard let items = targetState.arrayItems[arrayPath] else {
            return []
        }

        let sortedIndices = items.keys.sorted()

        for index in sortedIndices {
            guard let item = items[index] else { continue }

            var itemDict: [String: Any] = [:]
            for (fieldName, value) in item {
                if !value.isEmpty {
                    // 타입 찾기
                    let fullFieldName = "\(arrayPath).\(fieldName)"
                    if let field = endpoint.requestBodyFields.first(where: { $0.name == fullFieldName }) {
                        itemDict[fieldName] = convertPrimitiveValue(value, type: field.type)
                    } else {
                        itemDict[fieldName] = value
                    }
                }
            }

            if !itemDict.isEmpty {
                arrayData.append(itemDict)
            }
        }

        return arrayData
    }

    private func sendRequest() async {
        let currentEndpointId = endpoint.id
        let targetState = APITesterStateStore.shared.getState(for: currentEndpointId)

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
            var path = endpoint.path
            for parameter in endpoint.parameters where parameter.location == .path {
                if let value = targetState.parameters[parameter.name], !value.isEmpty {
                    path = path.replacingOccurrences(of: "{\(parameter.name)}", with: value)
                }
            }

            var queryParams: [String: String] = [:]
            for parameter in endpoint.parameters where parameter.location == .query {
                if let value = targetState.parameters[parameter.name], !value.isEmpty {
                    queryParams[parameter.name] = value
                }
            }

            var bodyData: Data?
            if ["POST", "PUT", "PATCH"].contains(endpoint.method.uppercased()) {
                if !endpoint.requestBodyFields.isEmpty {
                    let jsonString = buildJSONFromFields(using: targetState)
                    bodyData = jsonString.data(using: .utf8)
                    targetState.requestBody = jsonString
                } else if !targetState.requestBody.isEmpty {
                    bodyData = targetState.requestBody.data(using: .utf8)
                }
                targetState.requestBodySize = bodyData?.count ?? 0
            }

            var allHeaders: [String: String] = [:]

            if let endpointHeaders = endpoint.headers {
                for (key, _) in endpointHeaders {
                    if let userValue = targetState.headerFields[key], !userValue.isEmpty {
                        allHeaders[key] = userValue
                    }
                }
            }

            if bodyData != nil {
                allHeaders["Content-Type"] = "application/json"
            }

            targetState.requestHeaders = allHeaders

            let apiRequest = DynamicAPIRequest(
                baseURL: endpoint.baseURLString,
                path: path,
                method: HTTPMethod(rawValue: endpoint.method.uppercased()) ?? .get,
                headers: allHeaders.isEmpty ? nil : allHeaders,
                queryParameters: queryParams.isEmpty ? nil : queryParams,
                body: bodyData
            )

            let httpResponse = try await networkService.requestRaw(apiRequest)

            targetState.responseTimestamp = dateFormatter.string(from: Date())
            targetState.statusCode = httpResponse.statusCode
            targetState.responseBodySize = httpResponse.data.count

            if let response = httpResponse.response {
                let requestHeaderKeys = Set((endpoint.headers ?? [:]).keys.map { $0.lowercased() })

                for (key, value) in response.allHeaderFields {
                    if let keyString = key as? String, let valueString = value as? String {
                        if requestHeaderKeys.contains(keyString.lowercased()) {
                            targetState.responseHeaders[keyString] = valueString
                        }
                    }
                }
            }

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

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200 ..< 300: return .green
        case 300 ..< 400: return .blue
        case 400 ..< 500: return .orange
        case 500 ..< 600: return .red
        default: return .gray
        }
    }
}

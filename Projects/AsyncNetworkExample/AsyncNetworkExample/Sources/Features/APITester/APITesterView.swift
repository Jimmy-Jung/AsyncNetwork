//
//  APITesterView.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncNetwork
import SwiftUI

struct APITesterView: View {
    let endpoint: APIEndpoint
    let repository: APITestRepository

    @StateObject private var viewModel: APITesterViewModel
    @State private var parameterValues: [String: String] = [:]
    @State private var requestBody: String = ""
    @State private var currentEndpointID: String

    init(endpoint: APIEndpoint, repository: APITestRepository) {
        self.endpoint = endpoint
        self.repository = repository
        _viewModel = StateObject(wrappedValue: APITesterViewModel(repository: repository))
        _currentEndpointID = State(initialValue: endpoint.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                requestSection
                Divider()
                responseSection
            }
            .padding(24)
        }
        .navigationTitle("Try It Out")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialValues()
            viewModel.send(.restoreState(endpointID: endpoint.id))
        }
        .onChange(of: endpoint) { _, newEndpoint in
            viewModel.send(.saveState(endpointID: currentEndpointID))
            currentEndpointID = newEndpoint.id
            setupInitialValues()
            viewModel.send(.restoreState(endpointID: newEndpoint.id))
        }
        .onChange(of: viewModel.state.isLoading) { wasLoading, isLoading in
            if wasLoading && !isLoading {
                viewModel.send(.saveState(endpointID: endpoint.id))
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HTTPMethodBadge(method: endpoint.method)
                Text(endpoint.path)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
            }
        }
    }

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Request")
                .font(.headline)

            if !endpoint.parameters.isEmpty {
                parametersInputSection
            }

            if endpoint.requestBody != nil {
                requestBodyInputSection
            }

            sendButton
        }
    }

    private var parametersInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(endpoint.parameters) { parameter in
                HStack {
                    Text(parameter.name)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    TextField(parameter.example ?? "", text: binding(for: parameter.name))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var requestBodyInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request Body")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextEditor(text: $requestBody)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 150)
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private var sendButton: some View {
        Button {
            viewModel.send(
                .sendRequest(
                    endpoint: endpoint,
                    parameters: parameterValues,
                    body: requestBody.isEmpty ? nil : requestBody
                )
            )
        } label: {
            HStack {
                if viewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(viewModel.state.isLoading ? "Sending..." : "Send Request")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .disabled(viewModel.state.isLoading)
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Response")
                    .font(.headline)
                Spacer()
                if viewModel.state.statusCode != nil {
                    Button("Clear") {
                        viewModel.send(.clearResponse)
                        viewModel.send(.saveState(endpointID: endpoint.id))
                    }
                    .font(.caption)
                }
            }

            if let statusCode = viewModel.state.statusCode {
                StatusCodeBadge(statusCode: statusCode)
            }

            if let error = viewModel.state.errorMessage {
                ErrorView(message: error)
            }

            if let body = viewModel.state.responseBody {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    CodeBlock(content: body)
                }
            }

            if let headers = viewModel.state.responseHeaders {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Headers")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    CodeBlock(content: headers)
                }
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { parameterValues[key] ?? "" },
            set: { parameterValues[key] = $0 }
        )
    }

    private func setupInitialValues() {
        requestBody = endpoint.requestBody?.example ?? ""
        parameterValues = endpoint.parameters.reduce(into: [:]) { result, param in
            result[param.name] = param.example ?? ""
        }
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        APITesterView(
            endpoint: .getPosts,
            repository: DefaultAPITestRepository(networkService: NetworkKit.createNetworkService())
        )
    }
}

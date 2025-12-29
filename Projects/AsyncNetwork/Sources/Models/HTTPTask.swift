import Foundation

public enum HTTPTask: Sendable {
    case requestPlain
    case requestData(Data)
    case requestJSONEncodable(any Encodable & Sendable)
    case requestParameters(parameters: [String: String])
    case requestQueryParameters(parameters: [String: String])
}

public extension HTTPTask {
    func apply(to request: inout URLRequest) throws {
        switch self {
        case .requestPlain:
            break

        case let .requestData(data):
            request.httpBody = data

        case let .requestJSONEncodable(encodable):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(encodable)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case let .requestParameters(parameters):
            let bodyString = parameters
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        case let .requestQueryParameters(parameters):
            guard let url = request.url else { return }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.url = components?.url
        }
    }
}

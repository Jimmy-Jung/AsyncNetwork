import Foundation

public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data
    public let request: URLRequest?
    public let response: HTTPURLResponse?

    public init(
        statusCode: Int,
        data: Data,
        request: URLRequest? = nil,
        response: HTTPURLResponse? = nil
    ) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }
}

extension HTTPResponse {
    static func from(data: Data, response: URLResponse, request: URLRequest?) throws -> HTTPResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(
                domain: "HTTPResponse",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Response is not HTTPURLResponse"]
            ))
        }

        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            data: data,
            request: request,
            response: httpResponse
        )
    }
}

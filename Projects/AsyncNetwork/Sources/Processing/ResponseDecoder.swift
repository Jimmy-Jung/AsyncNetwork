import Foundation

public enum DecodingResult<T: Decodable> {
    case success(T)
    case failure(DecodingError)
}

public struct ResponseDecoder: Sendable {
    private let jsonDecoder: JSONDecoder

    public init(jsonDecoder: JSONDecoder = Self.defaultJSONDecoder()) {
        self.jsonDecoder = jsonDecoder
    }

    public func decode<T: Decodable>(_ response: HTTPResponse, to type: T.Type) throws -> T {
        logDecodingStart(for: type)

        do {
            // EmptyResponseDto 또는 EmptyResponse는 빈 데이터 허용
            if response.data.isEmpty {
                if type is EmptyResponseDto.Type, let emptyResponse = EmptyResponseDto() as? T {
                    logDecodingSuccess(for: type)
                    return emptyResponse
                }
                if type is EmptyResponse.Type, let emptyResponse = EmptyResponse() as? T {
                    logDecodingSuccess(for: type)
                    return emptyResponse
                }
            }

            let decoded = try jsonDecoder.decode(T.self, from: response.data)
            logDecodingSuccess(for: type)
            return decoded
        } catch {
            logDecodingFailure(for: type, error: error)
            throw error
        }
    }

    public func safeDecode<T: Decodable>(_ response: HTTPResponse, to type: T.Type) -> DecodingResult<T> {
        do {
            let decoded = try decode(response, to: type)
            return .success(decoded)
        } catch let decodingError as DecodingError {
            return .failure(decodingError)
        } catch {
            // 다른 에러는 DecodingError로 래핑
            let wrappedError = DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unexpected error during decoding: \(error)"
                )
            )
            return .failure(wrappedError)
        }
    }
}

public extension ResponseDecoder {
    static func defaultJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static let `default` = ResponseDecoder()

    static func withDateFormat(_ format: String) -> ResponseDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = format
        decoder.dateDecodingStrategy = .formatted(formatter)
        return ResponseDecoder(jsonDecoder: decoder)
    }
}

private extension ResponseDecoder {
    func logDecodingStart<T>(for type: T.Type) {
        #if DEBUG
            print("🔍 [ResponseDecoder] Starting decode for type: \(type)")
        #endif
    }

    func logDecodingSuccess<T>(for type: T.Type) {
        #if DEBUG
            print("✅ [ResponseDecoder] Successfully decoded: \(type)")
        #endif
    }

    func logDecodingFailure<T>(for type: T.Type, error: Error) {
        #if DEBUG
            print("❌ [ResponseDecoder] Failed to decode \(type): \(error)")
            if let decodingError = error as? DecodingError {
                print("📋 [ResponseDecoder] Decoding error details: \(decodingError)")
            }
        #endif
    }
}

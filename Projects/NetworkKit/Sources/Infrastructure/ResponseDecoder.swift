//
//  ResponseDecoder.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - DecodingResult

/// 디코딩 결과를 나타내는 열거형
public enum DecodingResult<T: Decodable> {
    case success(T)
    case failure(DecodingError)
}

// MARK: - ResponseDecoder

/// 응답 디코딩만 담당하는 구조체
///
/// **단일 책임:**
/// - HTTP Response를 Swift 객체로 디코딩
/// - JSON 디코딩 설정 관리
/// - 디코딩 에러 처리
public struct ResponseDecoder: Sendable {
    // MARK: - Properties

    private let jsonDecoder: JSONDecoder

    // MARK: - Initialization

    public init(jsonDecoder: JSONDecoder = Self.defaultJSONDecoder()) {
        self.jsonDecoder = jsonDecoder
    }

    // MARK: - Public Methods

    /// Response를 지정된 타입으로 디코딩
    /// - Parameters:
    ///   - response: 디코딩할 HTTPResponse
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 객체
    /// - Throws: DecodingError
    public func decode<T: Decodable>(_ response: HTTPResponse, to type: T.Type) throws -> T {
        logDecodingStart(for: type)

        do {
            // EmptyResponseDto는 빈 데이터 허용
            if response.data.isEmpty && type is EmptyResponseDto.Type {
                // EmptyResponseDto의 기본 인스턴스 반환
                if let emptyResponse = EmptyResponseDto() as? T {
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

    /// Response를 지정된 타입으로 안전하게 디코딩 (Result 타입 반환)
    /// - Parameters:
    ///   - response: 디코딩할 HTTPResponse
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩 결과 (성공/실패)
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

// MARK: - ResponseDecoder + DefaultConfiguration

public extension ResponseDecoder {
    /// 기본 JSONDecoder 설정
    static func defaultJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// 기본 설정으로 ResponseDecoder 생성
    static let `default` = ResponseDecoder()

    /// 커스텀 날짜 형식을 위한 ResponseDecoder 생성
    static func withDateFormat(_ format: String) -> ResponseDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = format
        decoder.dateDecodingStrategy = .formatted(formatter)
        return ResponseDecoder(jsonDecoder: decoder)
    }
}

// MARK: - Private Logging Methods

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

//
//  HTTPHeaders.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// HTTP 헤더 관리 및 생성을 담당하는 구조체 (메서드 체이닝 방식)
public struct HTTPHeaders: Sendable {
    // MARK: - Properties

    private var headers: [String: String] = [:]

    // MARK: - Static Header Keys

    public enum HeaderKey: String, CaseIterable {
        /// 요청 본문의 데이터 형식을 서버에 알려줌
        /// 예시: application/json, application/x-www-form-urlencoded
        case contentType = "Content-Type"

        /// 클라이언트가 응답으로 받을 수 있는 콘텐츠 타입을 서버에 알려줌
        /// 예시: application/json, text/html
        case accept = "Accept"

        /// 클라이언트의 인증 정보를 서버에 전달
        /// 예시: Bearer token123, Basic base64credentials
        case authorization = "Authorization"

        /// 클라이언트 애플리케이션과 환경 정보를 서버에 전달
        /// 예시: SampleApp/1.0.0 (1) iOS/17.0 (iPhone15,2)
        case userAgent = "User-Agent"

        /// 클라이언트가 선호하는 언어를 서버에 알려줌
        /// 예시: ko-KR,ko;q=0.9,en;q=0.8
        case acceptLanguage = "Accept-Language"

        /// 앱의 버전 정보를 서버에 전달
        /// 서버에서 클라이언트 버전에 따른 API 호환성 관리에 사용
        case appVersion = "X-App-Version"

        /// 디바이스 모델 정보를 서버에 전달
        /// 예시: iPhone15,2, iPad13,1
        /// 디바이스별 최적화된 서비스 제공에 사용
        case deviceModel = "X-Device-Model"

        /// 운영체제 버전 정보를 서버에 전달
        /// 예시: 17.0, 16.4
        /// OS 버전별 기능 지원 여부 판단에 사용
        case osVersion = "X-OS-Version"

        /// 앱의 번들 식별자를 서버에 전달
        /// 예시: com.company.sampleapp
        /// 앱 식별 및 보안 검증에 사용
        case bundleId = "X-Bundle-Id"

        /// 각 요청을 고유하게 식별하는 ID
        /// 예시: 550e8400-e29b-41d4-a716-446655440000
        /// 로깅, 디버깅, 요청 추적에 사용
        case requestId = "X-Request-Id"

        /// 요청이 생성된 시간을 서버에 전달
        /// 예시: 1705123456 (Unix timestamp)
        /// 요청 유효성 검증, 로깅에 사용
        case timestamp = "X-Timestamp"

        /// 사용자 세션을 식별하는 ID
        /// 세션 관리, 사용자 상태 추적에 사용
        case sessionId = "X-Session-Id"

        /// 클라이언트 버전 정보 (appVersion과 유사하지만 별도 관리)
        /// 클라이언트-서버 버전 호환성 체크에 사용
        case clientVersion = "X-Client-Version"

        /// 클라이언트 플랫폼 정보를 서버에 전달
        /// 예시: iOS, Android
        /// 플랫폼별 서비스 제공에 사용
        case platform = "X-Platform"
    }

    // MARK: - Content Types

    public enum ContentType: String {
        case json = "application/json"
        case formURLEncoded = "application/x-www-form-urlencoded"
        case formData = "multipart/form-data"
        case textPlain = "text/plain"

        /// UTF-8 인코딩이 포함된 Content-Type
        public var withUTF8: String {
            switch self {
            case .json:
                return "application/json; charset=UTF-8"
            case .formURLEncoded:
                return "application/x-www-form-urlencoded; charset=UTF-8"
            case .textPlain:
                return "text/plain; charset=UTF-8"
            case .formData:
                return rawValue // multipart는 boundary가 별도로 설정됨
            }
        }
    }

    // MARK: - Initializers

    /// 빈 HTTPHeaders 인스턴스 생성
    public init() {}

    /// 기존 헤더 딕셔너리로 HTTPHeaders 인스턴스 생성
    /// - Parameter headers: 초기 헤더 딕셔너리
    public init(headers: [String: String]) {
        self.headers = headers
    }

    // MARK: - Method Chaining

    /// Content-Type 헤더 설정
    /// - Parameter contentType: 콘텐츠 타입
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func contentType(_ contentType: ContentType) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.contentType.rawValue] = contentType.withUTF8
        return newHeaders
    }

    /// Accept 헤더 설정
    /// - Parameter contentType: 허용할 콘텐츠 타입
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func accept(_ contentType: ContentType) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.accept.rawValue] = contentType.rawValue
        return newHeaders
    }

    /// Authorization 헤더 설정
    /// - Parameter token: 인증 토큰
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func authorization(_ token: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.authorization.rawValue] = token
        return newHeaders
    }

    /// User-Agent 헤더 설정
    /// - Parameter userAgent: 사용자 에이전트 문자열
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func userAgent(_ userAgent: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.userAgent.rawValue] = userAgent
        return newHeaders
    }

    /// Accept-Language 헤더 설정
    /// - Parameter language: 언어 설정
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func acceptLanguage(_ language: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.acceptLanguage.rawValue] = language
        return newHeaders
    }

    /// X-App-Version 헤더 설정
    /// - Parameter version: 앱 버전
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func appVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.appVersion.rawValue] = version
        return newHeaders
    }

    /// X-Device-Model 헤더 설정
    /// - Parameter model: 디바이스 모델
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func deviceModel(_ model: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.deviceModel.rawValue] = model
        return newHeaders
    }

    /// X-OS-Version 헤더 설정
    /// - Parameter version: OS 버전
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func osVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.osVersion.rawValue] = version
        return newHeaders
    }

    /// X-Bundle-Id 헤더 설정
    /// - Parameter bundleId: 번들 식별자
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func bundleId(_ bundleId: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.bundleId.rawValue] = bundleId
        return newHeaders
    }

    /// X-Request-Id 헤더 설정
    /// - Parameter requestId: 요청 ID (기본값: UUID)
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func requestId(_ requestId: String = UUID().uuidString) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.requestId.rawValue] = requestId
        return newHeaders
    }

    /// X-Timestamp 헤더 설정
    /// - Parameter timestamp: 타임스탬프 (기본값: 현재 시간)
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func timestamp(_ timestamp: String = String(Int(Date().timeIntervalSince1970))) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.timestamp.rawValue] = timestamp
        return newHeaders
    }

    /// X-Session-Id 헤더 설정
    /// - Parameter sessionId: 세션 ID
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func sessionId(_ sessionId: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.sessionId.rawValue] = sessionId
        return newHeaders
    }

    /// X-Client-Version 헤더 설정
    /// - Parameter version: 클라이언트 버전
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func clientVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.clientVersion.rawValue] = version
        return newHeaders
    }

    /// X-Platform 헤더 설정
    /// - Parameter platform: 플랫폼 (예: iOS, Android)
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func platform(_ platform: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.platform.rawValue] = platform
        return newHeaders
    }

    /// 커스텀 헤더 설정
    /// - Parameters:
    ///   - key: 헤더 키
    ///   - value: 헤더 값
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func custom(key: String, value: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[key] = value
        return newHeaders
    }

    /// 여러 헤더를 한번에 병합
    /// - Parameter additionalHeaders: 추가할 헤더 딕셔너리
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func merge(with additionalHeaders: [String: String]) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers.merge(additionalHeaders) { _, new in new }
        return newHeaders
    }

    // MARK: - Convenience Methods

    /// 기본 헤더들을 설정 (JSON Content-Type, JSON Accept)
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func defaults() -> HTTPHeaders {
        return contentType(.json)
            .accept(.json)
    }

    /// Form 데이터용 헤더들을 설정
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func form() -> HTTPHeaders {
        return contentType(.formURLEncoded)
            .accept(.json)
    }

    /// Multipart 데이터용 헤더들을 설정
    /// - Parameter boundary: multipart boundary (기본값: UUID 기반)
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func multipart(boundary: String = "Boundary-\(UUID().uuidString)") -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.contentType.rawValue] = "multipart/form-data; boundary=\(boundary)"
        newHeaders.headers[HeaderKey.accept.rawValue] = ContentType.json.rawValue
        return newHeaders
    }

    /// 인증 관련 헤더들을 설정 (기본 헤더 + Authorization)
    /// - Parameter token: 인증 토큰
    /// - Returns: HTTPHeaders 인스턴스 (체이닝용)
    @discardableResult
    public func authenticated(token: String) -> HTTPHeaders {
        return defaults()
            .authorization(token)
    }

    // MARK: - Build Method

    /// 최종 헤더 딕셔너리 반환
    /// - Returns: 헤더 딕셔너리
    public func build() -> [String: String] {
        return headers
    }

    // MARK: - Static Compatibility Methods (기존 코드 호환성을 위해 유지)

    /// 기본 HTTP 헤더들을 생성 (호환성을 위해 유지)
    /// - Returns: 기본 헤더 딕셔너리
    public static func defaultHeaders() -> [String: String] {
        return HTTPHeaders().defaults().build()
    }

    /// Authenticated API 전용 헤더들을 생성 (호환성을 위해 유지)
    /// - Parameter accKey: 인증 토큰 (옵셔널)
    /// - Returns: Authenticated API 헤더 딕셔너리
    public static func authenticatedHeaders(accKey: String? = nil) -> [String: String] {
        var builder = HTTPHeaders().defaults()
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }

    /// Form URL Encoded 전용 헤더들을 생성 (호환성을 위해 유지)
    /// - Parameter accKey: 인증 토큰 (옵셔널)
    /// - Returns: Form 데이터용 헤더 딕셔너리
    public static func formHeaders(accKey: String? = nil) -> [String: String] {
        var builder = HTTPHeaders().form()
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }

    /// 파일 업로드용 헤더들을 생성 (호환성을 위해 유지)
    /// - Parameters:
    ///   - boundary: multipart boundary
    ///   - accKey: 인증 토큰 (옵셔널)
    /// - Returns: 파일 업로드용 헤더 딕셔너리
    public static func multipartHeaders(
        boundary: String = "Boundary-\(UUID().uuidString)",
        accKey: String? = nil
    ) -> [String: String] {
        var builder = HTTPHeaders().multipart(boundary: boundary)
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }
}

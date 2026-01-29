/// HTTPHeaders.HeaderKey enum case를 실제 HTTP 헤더 이름으로 매핑하는 유틸리티
enum HeaderKeyMapper {
    /// HTTPHeaders.HeaderKey enum case를 실제 HTTP 헤더 이름으로 매핑합니다.
    ///
    /// - Parameter key: enum case 이름 (예: "authorization")
    /// - Returns: 실제 HTTP 헤더 이름 (예: "Authorization")
    static func map(_ key: String) -> String {
        let mapping: [String: String] = [
            "contentType": "Content-Type",
            "accept": "Accept",
            "authorization": "Authorization",
            "userAgent": "User-Agent",
            "acceptLanguage": "Accept-Language",
            "appVersion": "X-App-Version",
            "deviceModel": "X-Device-Model",
            "osVersion": "X-OS-Version",
            "bundleId": "X-Bundle-Id",
            "requestId": "X-Request-Id",
            "timestamp": "X-Timestamp",
            "sessionId": "X-Session-Id",
            "clientVersion": "X-Client-Version",
            "platform": "X-Platform"
        ]
        return mapping[key] ?? key
    }
}

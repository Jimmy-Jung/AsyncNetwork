//
//  RuntimeInterceptorManager.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/12.
//

import AsyncNetwork
import Foundation

/// 런타임에 인터셉터를 추가/제거할 수 있는 관리자
///
/// NetworkService는 immutable interceptors를 가지므로,
/// 이 Manager는 동적으로 활성화/비활성화할 수 있는 인터셉터를 래핑합니다.
///
/// ## 사용 방법
/// ```swift
/// let manager = RuntimeInterceptorManager(
///     loggingInterceptor: loggingInterceptor,
///     etagInterceptor: etagInterceptor
/// )
/// manager.enable(.auth)
/// manager.enable(.etag)
///
/// // NetworkService의 각 요청마다 수동으로 인터셉터 적용
/// let wrapper = RuntimeInterceptorWrapper(manager: manager)
/// ```
@MainActor
final class RuntimeInterceptorManager: ObservableObject {
    // MARK: - Properties

    /// 현재 활성화된 인터셉터 타입
    @Published private(set) var activeInterceptors: Set<InterceptorType> = []

    /// 실제 인터셉터 인스턴스들
    private var interceptorInstances: [InterceptorType: any RequestInterceptor] = [:]

    // MARK: - Initialization

    init(
        loggingInterceptor: DynamicLoggingInterceptor? = nil,
        etagInterceptor: ETagInterceptor? = nil
    ) {
        // AppDependency에서 주입받은 인터셉터 저장
        if let loggingInterceptor = loggingInterceptor {
            interceptorInstances[.consoleLogging] = loggingInterceptor
        }
        if let etagInterceptor = etagInterceptor {
            interceptorInstances[.etag] = etagInterceptor
        }

        // 나머지 인터셉터 인스턴스 생성
        setupCustomInterceptors()

        // 기본값으로 consoleLogging만 활성화 (etag는 비활성화)
        activeInterceptors = [.consoleLogging]
    }

    private func setupCustomInterceptors() {
        interceptorInstances[.auth] = AuthInterceptor()
        interceptorInstances[.customHeader] = CustomHeaderInterceptor()
        interceptorInstances[.timestamp] = TimestampInterceptor()
    }

    // MARK: - Public Methods

    /// 인터셉터를 활성화합니다
    func enable(_ type: InterceptorType) {
        activeInterceptors.insert(type)
    }

    /// 인터셉터를 비활성화합니다
    func disable(_ type: InterceptorType) {
        activeInterceptors.remove(type)
    }

    /// 인터셉터 활성화 상태를 토글합니다
    func toggle(_ type: InterceptorType) {
        if activeInterceptors.contains(type) {
            disable(type)
        } else {
            enable(type)
        }
    }

    /// 특정 인터셉터가 활성화되어 있는지 확인합니다
    func isEnabled(_ type: InterceptorType) -> Bool {
        activeInterceptors.contains(type)
    }

    /// 모든 인터셉터를 비활성화합니다
    func disableAll() {
        activeInterceptors.removeAll()
    }

    /// 여러 인터셉터를 한 번에 설정합니다
    func setActive(_ types: Set<InterceptorType>) {
        activeInterceptors = types
    }

    /// 현재 활성화된 인터셉터들을 순서대로 반환합니다
    func getActiveInterceptors() -> [any RequestInterceptor] {
        // order 순서대로 정렬
        let sortedTypes = activeInterceptors.sorted { $0.order < $1.order }
        return sortedTypes.compactMap { interceptorInstances[$0] }
    }

    /// 현재 활성화된 인터셉터 개수
    var activeCount: Int {
        activeInterceptors.count
    }
}

// MARK: - RuntimeInterceptorWrapper

/// NetworkService의 interceptors 배열에 추가할 수 있는 Wrapper
///
/// RuntimeInterceptorManager의 활성 상태를 확인하고 실제 인터셉터를 동적으로 실행합니다.
final class RuntimeInterceptorWrapper: RequestInterceptor, @unchecked Sendable {
    private let manager: RuntimeInterceptorManager

    init(manager: RuntimeInterceptorManager) {
        self.manager = manager
    }

    func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
        // 활성화된 인터셉터들을 순서대로 실행
        let activeInterceptors = await MainActor.run {
            manager.getActiveInterceptors()
        }

        for interceptor in activeInterceptors {
            try await interceptor.prepare(&request, target: target)
        }
    }

    func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        let activeInterceptors = await MainActor.run {
            manager.getActiveInterceptors()
        }

        for interceptor in activeInterceptors {
            await interceptor.willSend(request, target: target)
        }
    }

    func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        let activeInterceptors = await MainActor.run {
            manager.getActiveInterceptors()
        }

        for interceptor in activeInterceptors {
            await interceptor.didReceive(response, target: target)
        }
    }
}

// MARK: - Auth Interceptor

/// Authorization 헤더를 추가하는 인터셉터
///
/// **참고**: 이는 데모용 샘플 토큰입니다.
/// 실제 프로덕션 환경에서는 환경변수나 Keychain을 사용하세요.
final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
        // 데모용 샘플 JWT 토큰 (실제 환경에서는 환경변수/Keychain 사용)
        // 디코딩: {"sub":"1234567890","name":"AsyncNetwork Demo","iat":1516239022}
        let demoToken = Self.buildDemoToken()
        request.setValue("Bearer \(demoToken)", forHTTPHeaderField: "Authorization")
    }
    
    private static func buildDemoToken() -> String {
        // jwt.io에서 생성 가능한 공개 샘플 토큰 (실제 사용 불가)
        let parts = [
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFzeW5jTmV0d29yayBEZW1vIiwiaWF0IjoxNTE2MjM5MDIyfQ",
            "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        ]
        return parts.joined(separator: ".")
    }
}

// MARK: - Custom Header Interceptor

/// 커스텀 헤더를 추가하는 인터셉터
final class CustomHeaderInterceptor: RequestInterceptor, @unchecked Sendable {
    func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
        request.setValue("AsyncNetwork-Demo", forHTTPHeaderField: "X-Custom-Header")
    }
}

// MARK: - Timestamp Interceptor

/// 타임스탬프 헤더를 추가하는 인터셉터
final class TimestampInterceptor: RequestInterceptor, @unchecked Sendable {
    func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
        let timestamp = Date().timeIntervalSince1970
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Timestamp")
    }
}

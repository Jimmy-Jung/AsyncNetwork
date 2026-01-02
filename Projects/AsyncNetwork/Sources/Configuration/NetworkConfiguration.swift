import Foundation

public struct NetworkConfiguration: Sendable {
    public let maxRetries: Int
    public let retryDelay: TimeInterval
    public let timeout: TimeInterval
    public let enableLogging: Bool
    public let checkNetworkBeforeRequest: Bool

    public init(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        timeout: TimeInterval = 30.0,
        enableLogging: Bool = true,
        checkNetworkBeforeRequest: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.timeout = timeout
        self.enableLogging = enableLogging
        self.checkNetworkBeforeRequest = checkNetworkBeforeRequest
    }

    public static let `default` = NetworkConfiguration(
        maxRetries: 3,
        retryDelay: 1.0,
        timeout: 30.0,
        enableLogging: true,
        checkNetworkBeforeRequest: true
    )

    public static let development = NetworkConfiguration(
        maxRetries: 1,
        retryDelay: 0.5,
        timeout: 15.0,
        enableLogging: true,
        checkNetworkBeforeRequest: true
    )

    public static let test = NetworkConfiguration(
        maxRetries: 0,
        retryDelay: 0,
        timeout: 5.0,
        enableLogging: false,
        checkNetworkBeforeRequest: false // 테스트 시 네트워크 체크 비활성화
    )

    public static let stable = NetworkConfiguration(
        maxRetries: 5,
        retryDelay: 2.0,
        timeout: 60.0,
        enableLogging: true,
        checkNetworkBeforeRequest: true
    )

    public static let fast = NetworkConfiguration(
        maxRetries: 1,
        retryDelay: 0.1,
        timeout: 10.0,
        enableLogging: false,
        checkNetworkBeforeRequest: true
    )
}

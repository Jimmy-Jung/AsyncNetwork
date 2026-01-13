//
//  ETagInterceptor.swift
//  AsyncNetwork
//
//  ETag 기반 캐시 무효화 Interceptor
//  서버의 ETag를 활용하여 데이터 변경 여부를 감지하고 효율적으로 캐싱합니다.
//

import Foundation

// MARK: - ETagStorage

/// ETag를 저장하고 관리하는 전용 스토리지
///
/// **기능:**
/// - LRU (Least Recently Used) 정책으로 자동 제거
/// - 최대 저장 개수 제한
/// - Thread-safe (actor)
public actor ETagStorage {
    /// ETag 저장 항목 (값 + 마지막 접근 시간)
    private struct CacheEntry {
        let etag: String
        var lastAccessTime: Date

        init(etag: String) {
            self.etag = etag
            lastAccessTime = Date()
        }

        mutating func updateAccessTime() {
            lastAccessTime = Date()
        }
    }

    /// URL별 ETag 캐시
    private var storage: [String: CacheEntry] = [:]

    /// 최대 저장 개수
    private let maxSize: Int

    /// 정리 임계값 비율 (기본 0.8 = 80%)
    private let evictionThreshold: Double

    /// 제거할 항목 비율 (기본 0.2 = 20%)
    private let evictionRatio: Double

    // MARK: - Initialization

    /// ETagStorage 초기화
    ///
    /// - Parameters:
    ///   - maxSize: 최대 저장 개수 (기본 1000)
    ///   - evictionThreshold: 정리 시작 임계값 (기본 0.8 = 80%)
    ///   - evictionRatio: 제거할 항목 비율 (기본 0.2 = 20%)
    public init(
        maxSize: Int = 1000,
        evictionThreshold: Double = 0.8,
        evictionRatio: Double = 0.2
    ) {
        self.maxSize = maxSize
        self.evictionThreshold = evictionThreshold
        self.evictionRatio = evictionRatio
    }

    // MARK: - Public Methods

    /// ETag를 조회합니다 (접근 시간 자동 업데이트)
    ///
    /// - Parameter url: URL 문자열
    /// - Returns: 저장된 ETag (없으면 nil)
    public func get(_ url: String) -> String? {
        guard var entry = storage[url] else { return nil }

        entry.updateAccessTime()
        storage[url] = entry

        return entry.etag
    }

    /// ETag를 저장합니다 (용량 초과 시 자동 정리)
    ///
    /// - Parameters:
    ///   - etag: 저장할 ETag
    ///   - url: URL 문자열
    public func set(_ etag: String, for url: String) {
        evictIfNeeded()
        storage[url] = CacheEntry(etag: etag)
    }

    /// 특정 URL의 ETag를 제거합니다
    ///
    /// - Parameter url: URL 문자열
    public func remove(_ url: String) {
        storage.removeValue(forKey: url)
    }

    /// 모든 ETag를 제거합니다
    public func removeAll() {
        storage.removeAll()
    }

    /// 현재 저장된 ETag 개수
    public var count: Int {
        storage.count
    }

    /// 저장 용량 사용률 (0.0 ~ 1.0)
    public var usageRatio: Double {
        Double(storage.count) / Double(maxSize)
    }

    // MARK: - Private Methods

    /// 필요 시 오래된 항목을 제거합니다 (LRU 정책)
    private func evictIfNeeded() {
        let currentCount = storage.count
        let threshold = Int(Double(maxSize) * evictionThreshold)

        // 임계값을 넘지 않으면 정리하지 않음
        guard currentCount >= threshold else { return }

        let targetRemovalCount = Int(Double(currentCount) * evictionRatio)

        // 마지막 접근 시간 순으로 정렬 (오래된 것부터)
        let sortedEntries = storage.sorted { $0.value.lastAccessTime < $1.value.lastAccessTime }

        // 오래된 항목부터 제거
        for (url, _) in sortedEntries.prefix(targetRemovalCount) {
            storage.removeValue(forKey: url)
        }
    }
}

// MARK: - ETagInterceptor

/// ETag를 활용한 조건부 요청 Interceptor
///
/// **동작 방식:**
/// 1. 첫 요청: 서버가 ETag 헤더를 반환 (예: "abc123")
/// 2. 재요청: If-None-Match 헤더에 저장된 ETag 포함
/// 3. 서버 응답:
///    - 데이터 변경 없음: 304 Not Modified → URLCache 사용
///    - 데이터 변경됨: 200 OK + 새 데이터 + 새 ETag
///
/// **장점:**
/// - 서버 데이터 변경 실시간 감지
/// - 네트워크 대역폭 절약 (304 응답은 body 없음)
/// - HTTP 표준 방식
/// - 메모리 효율적 (LRU 정책)
///
/// **사용 예시:**
/// ```swift
/// let etagInterceptor = ETagInterceptor(maxStorageSize: 1000)
/// let networkService = NetworkService(
///     httpClient: httpClient,
///     interceptors: [etagInterceptor]
/// )
/// ```
public actor ETagInterceptor: RequestInterceptor {
    /// ETag 스토리지
    private let storage: ETagStorage

    // MARK: - Initialization

    /// ETagInterceptor 초기화
    ///
    /// - Parameters:
    ///   - maxStorageSize: 최대 저장 개수 (기본 1000)
    ///   - evictionThreshold: 정리 시작 임계값 (기본 0.8 = 80%)
    ///   - evictionRatio: 제거할 항목 비율 (기본 0.2 = 20%)
    public init(
        maxStorageSize: Int = 1000,
        evictionThreshold: Double = 0.8,
        evictionRatio: Double = 0.2
    ) {
        storage = ETagStorage(
            maxSize: maxStorageSize,
            evictionThreshold: evictionThreshold,
            evictionRatio: evictionRatio
        )
    }

    /// 커스텀 ETagStorage를 사용하는 초기화
    ///
    /// - Parameter storage: 사용할 ETagStorage 인스턴스
    public init(storage: ETagStorage) {
        self.storage = storage
    }

    // MARK: - RequestInterceptor Protocol

    public func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
        guard let url = request.url else { return }
        let urlString = url.absoluteString
        let httpMethod = request.httpMethod?.uppercased() ?? "GET"

        // GET, HEAD 요청만 ETag 적용
        guard ["GET", "HEAD"].contains(httpMethod) else {
            return
        }

        // ETag 검증을 위해 항상 서버에 요청 (캐시 무시)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        // 저장된 ETag가 있으면 If-None-Match 헤더 추가
        if let etag = await storage.get(urlString) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
    }

    public func didReceive(_ response: HTTPResponse, target _: (any APIRequest)?) async {
        guard let request = response.request,
              let url = request.url,
              let httpResponse = response.response
        else {
            return
        }

        let urlString = url.absoluteString

        // 응답에서 ETag 헤더 추출 및 저장
        if let etag = httpResponse.allHeaderFields["Etag"] as? String ??
            httpResponse.allHeaderFields["ETag"] as? String {
            await storage.set(etag, for: urlString)
        }
    }

    // MARK: - Public Methods

    /// 특정 URL의 ETag 캐시를 무효화합니다.
    ///
    /// - Parameter url: 캐시를 무효화할 URL
    public func invalidateETag(for url: URL) async {
        await storage.remove(url.absoluteString)
    }

    /// 모든 ETag 캐시를 무효화합니다.
    public func invalidateAllETags() async {
        await storage.removeAll()
    }

    /// 특정 URL의 저장된 ETag를 반환합니다.
    ///
    /// - Parameter url: 확인할 URL
    /// - Returns: 저장된 ETag (없으면 nil)
    public func getETag(for url: URL) async -> String? {
        return await storage.get(url.absoluteString)
    }

    /// 현재 저장된 ETag 개수를 반환합니다.
    public var currentStorageCount: Int {
        get async {
            await storage.count
        }
    }

    /// 저장 용량 사용률을 반환합니다. (0.0 ~ 1.0)
    public var storageUsageRatio: Double {
        get async {
            await storage.usageRatio
        }
    }
}

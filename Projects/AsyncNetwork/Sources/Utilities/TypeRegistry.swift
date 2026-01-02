//
//  TypeRegistry.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/02.
//

import Foundation

/// DocumentedType이 적용된 타입들을 등록하고 조회하는 레지스트리
public final class TypeRegistry: @unchecked Sendable {
    public static let shared = TypeRegistry()

    private var types: [String: TypeStructureProvider.Type] = [:]
    private let lock = NSLock()

    private init() {}

    /// 타입을 레지스트리에 등록
    public func register<T: TypeStructureProvider>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
            .components(separatedBy: ".")
            .last ?? String(describing: type)
        types[typeName] = type
    }

    /// 타입 이름으로 타입 조회
    public func type(forName name: String) -> TypeStructureProvider.Type? {
        lock.lock()
        defer { lock.unlock() }

        return types[name]
    }

    /// 모든 등록된 타입 이름 반환
    public func allTypeNames() -> [String] {
        lock.lock()
        defer { lock.unlock() }

        return Array(types.keys)
    }
}

//
//  CollectionTypeParser.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/02/01.
//  컬렉션 타입 파싱을 위한 유틸리티
//

import Foundation

// MARK: - CollectionType

/// 컬렉션 타입 분류
enum CollectionType: Equatable {
    case array(elementType: String)
    case dictionary(keyType: String, valueType: String)
    case set(elementType: String)
    case none
    
    /// 타입 문자열로부터 컬렉션 타입 파싱
    static func parse(_ typeString: String) -> CollectionType {
        let trimmed = typeString.trimmingCharacters(in: .whitespaces)
        
        // Array 타입: [Element] 또는 Array<Element>
        if let arrayType = parseArray(trimmed) {
            return arrayType
        }
        
        // Dictionary 타입: [Key: Value] 또는 Dictionary<Key, Value>
        if let dictType = parseDictionary(trimmed) {
            return dictType
        }
        
        // Set 타입: Set<Element>
        if let setType = parseSet(trimmed) {
            return setType
        }
        
        return .none
    }
    
    // MARK: - Private Parsing Methods
    
    /// 배열 타입 파싱
    private static func parseArray(_ typeString: String) -> CollectionType? {
        // [Element] 형태
        if typeString.hasPrefix("["), typeString.hasSuffix("]"), !typeString.contains(":") {
            let elementType = String(typeString.dropFirst().dropLast())
                .trimmingCharacters(in: .whitespaces)
            
            guard !elementType.isEmpty else { return nil }
            return .array(elementType: elementType)
        }
        
        // Array<Element> 형태
        if typeString.hasPrefix("Array<"), typeString.hasSuffix(">") {
            let elementType = String(typeString.dropFirst(6).dropLast())
                .trimmingCharacters(in: .whitespaces)
            
            guard !elementType.isEmpty else { return nil }
            return .array(elementType: elementType)
        }
        
        return nil
    }
    
    /// 딕셔너리 타입 파싱
    private static func parseDictionary(_ typeString: String) -> CollectionType? {
        // [Key: Value] 형태
        if typeString.hasPrefix("["), typeString.hasSuffix("]"), typeString.contains(":") {
            let inner = String(typeString.dropFirst().dropLast())
            let components = inner.split(separator: ":", maxSplits: 1)
            
            guard components.count == 2 else { return nil }
            
            let keyType = components[0].trimmingCharacters(in: .whitespaces)
            let valueType = components[1].trimmingCharacters(in: .whitespaces)
            
            guard !keyType.isEmpty, !valueType.isEmpty else { return nil }
            return .dictionary(keyType: keyType, valueType: valueType)
        }
        
        // Dictionary<Key, Value> 형태
        if typeString.hasPrefix("Dictionary<"), typeString.hasSuffix(">") {
            let inner = String(typeString.dropFirst(11).dropLast())
            let components = inner.split(separator: ",", maxSplits: 1)
            
            guard components.count == 2 else { return nil }
            
            let keyType = components[0].trimmingCharacters(in: .whitespaces)
            let valueType = components[1].trimmingCharacters(in: .whitespaces)
            
            guard !keyType.isEmpty, !valueType.isEmpty else { return nil }
            return .dictionary(keyType: keyType, valueType: valueType)
        }
        
        return nil
    }
    
    /// Set 타입 파싱
    private static func parseSet(_ typeString: String) -> CollectionType? {
        // Set<Element> 형태만 지원
        guard typeString.hasPrefix("Set<"), typeString.hasSuffix(">") else {
            return nil
        }
        
        let elementType = String(typeString.dropFirst(4).dropLast())
            .trimmingCharacters(in: .whitespaces)
        
        guard !elementType.isEmpty else { return nil }
        return .set(elementType: elementType)
    }
}

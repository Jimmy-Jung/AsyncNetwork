//
//  TypeStructureResolver.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/02.
//

import Foundation

/// DocumentedType 프로토콜을 체크하고 typeStructure를 반환하는 헬퍼 함수
public func resolveTypeStructure(for type: Any.Type) -> String? {
    // 배열 타입인 경우 요소 타입의 typeStructure 반환
    if let arrayElementType = extractArrayElementType(from: type) {
        guard let documentedType = arrayElementType as? any TypeStructureProvider.Type else {
            return nil
        }
        return documentedType.typeStructure
    }
    
    // 일반 타입
    guard let documentedType = type as? any TypeStructureProvider.Type else {
        return nil
    }
    return documentedType.typeStructure
}

/// DocumentedType이 적용된 타입의 중첩된 타입들을 모두 찾아 반환
/// TypeRegistry를 사용하여 런타임에 등록된 타입들을 조회
public func collectRelatedTypes(for type: Any.Type) -> [String: String]? {
    // 배열 타입인 경우 요소 타입으로 처리
    let targetType: Any.Type
    if let arrayElementType = extractArrayElementType(from: type) {
        targetType = arrayElementType
    } else {
        targetType = type
    }
    
    guard let documentedType = targetType as? any TypeStructureProvider.Type else {
        return nil
    }

    // Response 타입 접근하여 등록 강제 실행
    _ = documentedType.typeStructure
    _ = documentedType.relatedTypeNames

    var relatedTypes: [String: String] = [:]
    var typesToProcess: [String] = documentedType.relatedTypeNames
    var processedTypes: Set<String> = []

    print("📍 collectRelatedTypes: Response type = \(type)")
    print("📍 Related type names to process: \(typesToProcess)")

    // 먼저 모든 중첩 타입 이름을 수집 (재귀적으로)
    // 이렇게 하면 TypeRegistry에 없어도 모든 중첩 타입 이름을 알 수 있습니다.
    var allNestedTypeNames = Set<String>(typesToProcess)
    func collectAllNestedTypeNames(from typeNames: [String]) {
        for typeName in typeNames {
            if allNestedTypeNames.contains(typeName) {
                continue
            }
            allNestedTypeNames.insert(typeName)
            
            // TypeRegistry에서 찾아서 재귀적으로 수집
            if let nestedType = TypeRegistry.shared.type(forName: typeName) {
                _ = nestedType.typeStructure  // 등록 트리거
                collectAllNestedTypeNames(from: nestedType.relatedTypeNames)
            }
        }
    }
    
    // 모든 중첩 타입 이름을 먼저 수집
    collectAllNestedTypeNames(from: typesToProcess)
    typesToProcess = Array(allNestedTypeNames)

    // BFS 방식으로 모든 중첩 타입을 재귀적으로 탐색
    while !typesToProcess.isEmpty {
        let typeName = typesToProcess.removeFirst()

        // 이미 처리한 타입은 스킵
        if processedTypes.contains(typeName) {
            continue
        }
        processedTypes.insert(typeName)

        print("📍 Looking for type: \(typeName)")

        // TypeRegistry에서 타입 조회
        if let nestedType = TypeRegistry.shared.type(forName: typeName) {
            print("✅ Found type: \(typeName)")

            // 등록 강제 실행 (타입 구조와 관련 타입 이름 접근하여 등록 트리거)
            _ = nestedType.typeStructure
            _ = nestedType.relatedTypeNames

            relatedTypes[typeName] = nestedType.typeStructure

            // 이 타입이 참조하는 중첩 타입들도 큐에 추가
            typesToProcess.append(contentsOf: nestedType.relatedTypeNames)
        } else {
            print("❌ Type not found in registry: \(typeName)")
            print("📍 All registered types: \(TypeRegistry.shared.allTypeNames())")
            
            // TypeRegistry에 없으면 해당 타입이 아직 등록되지 않은 것입니다.
            // 이는 해당 타입의 _register가 실행되지 않았거나, 
            // @DocumentedType 매크로가 적용되지 않았을 수 있습니다.
        }
    }

    print("📍 Final relatedTypes count: \(relatedTypes.count)")

    return relatedTypes.isEmpty ? nil : relatedTypes
}

/// 배열 타입에서 요소 타입을 추출합니다
/// 예: Array<Post>.Type -> Post.Type, [Photo].Type -> Photo.Type
private func extractArrayElementType(from type: Any.Type) -> Any.Type? {
    let typeName = String(describing: type)
    
    // "Array<ElementType>" 형태 체크
    if typeName.hasPrefix("Array<"), typeName.hasSuffix(">") {
        // 배열의 경우 Element 타입을 가져올 수 있는 방법이 제한적
        // TypeRegistry를 사용하여 이름으로 타입 찾기
        let elementTypeName = String(typeName.dropFirst(6).dropLast()) // "Array<" 제거
        if let elementType = TypeRegistry.shared.type(forName: elementTypeName) {
            return elementType
        }
    }
    
    return nil
}

/// DocumentedType이 적용된 타입의 중첩된 타입들을 모두 찾아 반환 (Deprecated)
///
/// 이 함수는 런타임에 타입을 찾을 수 없으므로 (구조체는 Objective-C 런타임에 없음)
/// 매크로가 생성한 relatedTypeNames만 반환합니다.
/// 실제 중첩 타입 정보는 클라이언트 코드에서 제공해야 합니다.
public func resolveRelatedTypes(for type: Any.Type) -> [String: String]? {
    guard let documentedType = type as? any TypeStructureProvider.Type else {
        return nil
    }

    // relatedTypeNames만 반환 (타입 이름 목록)
    // 실제 typeStructure는 클라이언트가 수동으로 매핑해야 함
    let typeNames = documentedType.relatedTypeNames
    if typeNames.isEmpty {
        return nil
    }

    // 빈 딕셔너리 반환 (타입 이름은 있지만 구조는 찾을 수 없음)
    // EndpointDetailView에서 이를 감지하고 처리
    return [:]
}

/// 구조체 정의 문자열에서 중첩된 커스텀 타입 이름들을 추출
private func extractNestedTypeNames(from structure: String) -> Set<String> {
    var typeNames: Set<String> = []

    // 정규식으로 프로퍼티 타입 추출: let propertyName: Type 또는 let propertyName: [Type]
    let pattern = #"let\s+\w+:\s+([\w\[\]<>:,\s\?]+)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return typeNames
    }

    let nsString = structure as NSString
    let matches = regex.matches(in: structure, range: NSRange(location: 0, length: nsString.length))

    for match in matches {
        guard let range = Range(match.range(at: 1), in: structure) else { continue }
        let typeString = String(structure[range]).trimmingCharacters(in: .whitespaces)

        // 옵셔널 제거
        let typeWithoutOptional = typeString.hasSuffix("?") ? String(typeString.dropLast()) : typeString

        // 배열 체크 및 내부 타입 추출
        let baseType: String
        if typeWithoutOptional.hasPrefix("[") && typeWithoutOptional.hasSuffix("]") {
            baseType = String(typeWithoutOptional.dropFirst().dropLast())
        } else {
            baseType = typeWithoutOptional
        }

        // 프리미티브 타입이 아닌 경우만 추가
        if !isPrimitiveType(baseType) {
            typeNames.insert(baseType)
        }
    }

    return typeNames
}

/// 프리미티브 타입인지 확인
private func isPrimitiveType(_ type: String) -> Bool {
    let primitives = ["Int", "String", "Double", "Bool", "Float", "Int64", "Int32", "UInt", "Date", "Data", "URL"]
    return primitives.contains(type)
}

/// JSON 예제 문자열에서 struct 구조를 생성
public func generateStructureFromJSON(_ json: String) -> String? {
    guard let data = json.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return nil
    }

    var lines = ["struct RequestBody {"]

    for (key, value) in jsonObject.sorted(by: { $0.key < $1.key }) {
        let type = inferType(from: value)
        lines.append("    let \(key): \(type)")
    }

    lines.append("}")
    return lines.joined(separator: "\n")
}

/// JSON 값에서 Swift 타입 추론
private func inferType(from value: Any) -> String {
    switch value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is Double, is Float:
        return "Double"
    case is Bool:
        return "Bool"
    case let array as [Any]:
        if let first = array.first {
            let elementType = inferType(from: first)
            return "[\(elementType)]"
        }
        return "[Any]"
    case is [String: Any]:
        return "[String: Any]" // 중첩 객체는 간단히 표현
    case is NSNull:
        return "Any?"
    default:
        return "Any"
    }
}

/// DocumentedType 매크로가 생성하는 프로토콜
public protocol TypeStructureProvider {
    static var typeStructure: String { get }
    static var relatedTypeNames: [String] { get }
}

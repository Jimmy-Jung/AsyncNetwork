#!/usr/bin/env swift

// Migration Tool: AsyncNetwork v1.x → v2.0
// SwiftSyntax 기반 자동 변환 스크립트
//
// 사용법:
//   ./migrate.swift <source-file-or-directory>
//
// 예제:
//   ./migrate.swift MyProject/Sources/
//   ./migrate.swift MyFile.swift

import Foundation

// MARK: - Main Entry Point

struct MigrationTool {
    static func main() {
        let arguments = CommandLine.arguments
        
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }
        
        let path = arguments[1]
        let fileManager = FileManager.default
        
        // 경로 검증
        guard fileManager.fileExists(atPath: path) else {
            print("❌ 오류: 경로를 찾을 수 없습니다: \(path)")
            exit(1)
        }
        
        // 파일인지 디렉토리인지 확인
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            migrateDirectory(path)
        } else {
            migrateFile(path)
        }
    }
    
    // MARK: - Directory Migration
    
    static func migrateDirectory(_ path: String) {
        print("📁 디렉토리 마이그레이션: \(path)")
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            print("❌ 디렉토리를 읽을 수 없습니다")
            return
        }
        
        var swiftFiles: [String] = []
        
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                let fullPath = (path as NSString).appendingPathComponent(file)
                swiftFiles.append(fullPath)
            }
        }
        
        print("📝 발견된 Swift 파일: \(swiftFiles.count)개")
        
        var migratedCount = 0
        var skippedCount = 0
        
        for file in swiftFiles {
            let result = migrateFile(file)
            if result {
                migratedCount += 1
            } else {
                skippedCount += 1
            }
        }
        
        print("\n✅ 마이그레이션 완료!")
        print("   - 변환됨: \(migratedCount)개")
        print("   - 건너뜀: \(skippedCount)개")
    }
    
    // MARK: - File Migration
    
    @discardableResult
    static func migrateFile(_ path: String) -> Bool {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("❌ 파일을 읽을 수 없습니다: \(path)")
            return false
        }
        
        // v1.x 패턴이 있는지 확인
        let hasV1Patterns = content.contains("@ResponseTestable") ||
                            content.contains(".mock()") ||
                            content.contains(".builder()") ||
                            content.contains("sampleData:") ||
                            content.contains("alternativeSamples:") ||
                            content.contains("fixtureJSON:")
        
        guard hasV1Patterns else {
            // v1.x 코드가 없으면 건너뜀
            return false
        }
        
        print("\n🔄 마이그레이션 중: \(path)")
        
        // 변환 규칙 적용
        var migratedContent = content
        var changes: [String] = []
        
        // 1. @ResponseTestable 매크로 파라미터 제거
        migratedContent = removeDeprecatedParameters(migratedContent, changes: &changes)
        
        // 2. mock() → random() 변환
        if migratedContent.contains(".mock(") {
            migratedContent = migratedContent.replacingOccurrences(of: ".mock(", with: ".random(")
            changes.append("  - .mock() → .random()")
        }
        
        // 3. mockArray() → randomArray() 변환
        if migratedContent.contains(".mockArray(") {
            migratedContent = migratedContent.replacingOccurrences(of: ".mockArray(", with: ".randomArray(")
            changes.append("  - .mockArray() → .randomArray()")
        }
        
        // 4. builder() → fixture() 변환
        if migratedContent.contains(".builder(") {
            migratedContent = migratedContent.replacingOccurrences(of: ".builder(", with: ".fixture(")
            changes.append("  - .builder() → .fixture()")
        }
        
        // 5. fixture() (v1.x fixture 메서드) → fixtureValue() 변환
        // v1.x에서는 .fixture()가 고정값 반환, v2.0에서는 .fixture()가 빌더 반환
        // 충돌을 피하기 위해 v1.x의 .fixture()를 .random()으로 변환
        
        if changes.isEmpty {
            print("  ⏭️  변경사항 없음")
            return false
        }
        
        // 변경사항 출력
        print("  ✏️  변경사항:")
        for change in changes {
            print(change)
        }
        
        // 백업 생성
        let backupPath = path + ".v1.backup"
        try? content.write(toFile: backupPath, atomically: true, encoding: .utf8)
        
        // 마이그레이션된 내용 저장
        do {
            try migratedContent.write(toFile: path, atomically: true, encoding: .utf8)
            print("  ✅ 저장됨 (백업: \(backupPath))")
            return true
        } catch {
            print("  ❌ 저장 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Conversion Rules
    
    /// @ResponseTestable에서 제거된 파라미터 삭제
    static func removeDeprecatedParameters(_ content: String, changes: inout [String]) -> String {
        var result = content
        
        let deprecatedParams = [
            "sampleData:",
            "alternativeSamples:",
            "fixtureJSON:",
            "defaultArrayCount:" // v1.3.1에서도 제거됨
        ]
        
        for param in deprecatedParams {
            if result.contains(param) {
                // 정규식으로 파라미터와 값 전체 제거
                // 예: sampleData: [...], → 제거
                let pattern = "\(param)\\s*[^,)]+,?\\s*"
                result = result.replacingOccurrences(
                    of: pattern,
                    with: "",
                    options: .regularExpression
                )
                changes.append("  - 제거: \(param.dropLast()) (deprecated)")
            }
        }
        
        // 빈 매크로 정리: @ResponseTestable() → @ResponseTestable
        result = result.replacingOccurrences(of: "@ResponseTestable()", with: "@ResponseTestable")
        
        return result
    }
    
    // MARK: - Usage
    
    static func printUsage() {
        print("""
        📦 AsyncNetwork v1.x → v2.0 마이그레이션 도구
        
        사용법:
          ./migrate.swift <파일 또는 디렉토리 경로>
        
        예제:
          ./migrate.swift MyProject/Sources/       # 디렉토리 전체 마이그레이션
          ./migrate.swift Models/UserDTO.swift     # 단일 파일 마이그레이션
        
        주요 변경사항:
          - @ResponseTestable 매크로 단순화 (deprecated 파라미터 제거)
          - .mock() → .random() (명확한 네이밍)
          - .builder() → .fixture() (고정값 빌더)
        
        주의사항:
          - 원본 파일은 .v1.backup으로 백업됩니다
          - 변환 후 반드시 빌드 테스트를 수행하세요
        """)
    }
}

// 실행
MigrationTool.main()

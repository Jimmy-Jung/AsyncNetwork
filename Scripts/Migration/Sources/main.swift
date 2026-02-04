import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// AsyncNetwork v1.x → v2.0 마이그레이션 CLI 도구
@main
struct MigrationCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "migrate-async-network",
        abstract: "AsyncNetwork v1.x 코드를 v2.0으로 자동 변환합니다",
        discussion: """
        이 도구는 SwiftSyntax를 사용하여 코드를 안전하게 변환합니다.
        
        주요 변경사항:
        - @ResponseTestable 매크로 단순화
        - .mock() → .random()
        - .mockArray() → .randomArray()
        - .builder() → .fixture()
        
        원본 파일은 자동으로 백업됩니다 (.v1.backup).
        """,
        version: "2.0.0"
    )
    
    @Argument(help: "마이그레이션할 파일 또는 디렉토리 경로")
    var path: String
    
    @Flag(name: .shortAndLong, help: "백업 파일 생성 안 함")
    var noBackup = false
    
    @Flag(name: .shortAndLong, help: "자세한 출력")
    var verbose = false
    
    @Flag(name: .long, help: "Dry-run: 실제로 파일을 변경하지 않고 변경사항만 출력")
    var dryRun = false
    
    mutating func run() throws {
        let fileManager = FileManager.default
        
        // 경로 검증
        guard fileManager.fileExists(atPath: path) else {
            throw ValidationError("경로를 찾을 수 없습니다: \(path)")
        }
        
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        
        let migrator = CodeMigrator(
            createBackup: !noBackup,
            verbose: verbose,
            dryRun: dryRun
        )
        
        if isDirectory.boolValue {
            try migrator.migrateDirectory(path)
        } else {
            try migrator.migrateFile(path)
        }
    }
}

// MARK: - Code Migrator

class CodeMigrator {
    let createBackup: Bool
    let verbose: Bool
    let dryRun: Bool
    
    var stats = MigrationStats()
    
    init(createBackup: Bool, verbose: Bool, dryRun: Bool) {
        self.createBackup = createBackup
        self.verbose = verbose
        self.dryRun = dryRun
    }
    
    func migrateDirectory(_ path: String) throws {
        print("📁 디렉토리 마이그레이션: \(path)")
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            throw MigrationError.directoryReadFailed(path)
        }
        
        var swiftFiles: [String] = []
        
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") && !file.contains(".v1.backup") {
                let fullPath = (path as NSString).appendingPathComponent(file)
                swiftFiles.append(fullPath)
            }
        }
        
        print("📝 발견된 Swift 파일: \(swiftFiles.count)개\n")
        
        for file in swiftFiles {
            try? migrateFile(file)
        }
        
        printSummary()
    }
    
    func migrateFile(_ path: String) throws {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            throw MigrationError.fileReadFailed(path)
        }
        
        // SwiftSyntax로 파싱
        let sourceFile = Parser.parse(source: content)
        
        // 마이그레이션 적용
        let rewriter = MigrationRewriter()
        let migratedSyntax = rewriter.visit(sourceFile)
        
        guard rewriter.hasChanges else {
            if verbose {
                print("⏭️  변경사항 없음: \(path)")
            }
            stats.skipped += 1
            return
        }
        
        let migratedContent = migratedSyntax.description
        
        // 변경사항 출력
        print("\n🔄 \(path)")
        for change in rewriter.changes {
            print("  \(change)")
        }
        
        if dryRun {
            print("  [DRY-RUN] 실제 변경 없음")
            stats.migrated += 1
            return
        }
        
        // 백업 생성
        if createBackup {
            let backupPath = path + ".v1.backup"
            try content.write(toFile: backupPath, atomically: true, encoding: .utf8)
            if verbose {
                print("  💾 백업: \(backupPath)")
            }
        }
        
        // 저장
        try migratedContent.write(toFile: path, atomically: true, encoding: .utf8)
        print("  ✅ 저장됨")
        stats.migrated += 1
    }
    
    func printSummary() {
        print("""
        
        ═══════════════════════════════════════
        📊 마이그레이션 요약
        ═══════════════════════════════════════
        ✅ 변환됨: \(stats.migrated)개
        ⏭️  건너뜀: \(stats.skipped)개
        ═══════════════════════════════════════
        """)
    }
}

// MARK: - Migration Rewriter

class MigrationRewriter: SyntaxRewriter {
    var hasChanges = false
    var changes: [String] = []
    
    // MARK: - Attribute Rewriting (@ResponseTestable)
    
    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
        guard let attributeName = node.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
              attributeName == "ResponseTestable" else {
            return super.visit(node)
        }
        
        // v1.x 파라미터 제거
        guard case let .argumentList(arguments) = node.arguments else {
            return super.visit(node)
        }
        
        let deprecatedParams: Set<String> = [
            "sampleData",
            "alternativeSamples",
            "fixtureJSON",
            "defaultArrayCount"
        ]
        
        var filteredArguments: [LabeledExprSyntax] = []
        var removedParams: [String] = []
        
        for argument in arguments {
            if let label = argument.label?.text, deprecatedParams.contains(label) {
                removedParams.append(label)
                hasChanges = true
            } else {
                filteredArguments.append(argument)
            }
        }
        
        if !removedParams.isEmpty {
            changes.append("  ✏️  @ResponseTestable: 제거된 파라미터 - \(removedParams.joined(separator: ", "))")
        }
        
        // 파라미터가 하나도 없으면 빈 매크로로
        if filteredArguments.isEmpty {
            return node.with(\.arguments, nil)
        }
        
        let newArguments = LabeledExprListSyntax(filteredArguments)
        return node.with(\.arguments, .argumentList(newArguments))
    }
    
    // MARK: - Member Access Rewriting (.mock() → .random())
    
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        let memberName = node.declName.baseName.text
        
        switch memberName {
        case "mock":
            hasChanges = true
            changes.append("  ✏️  .mock() → .random()")
            return ExprSyntax(node.with(\.declName.baseName, .identifier("random")))
            
        case "mockArray":
            hasChanges = true
            changes.append("  ✏️  .mockArray() → .randomArray()")
            return ExprSyntax(node.with(\.declName.baseName, .identifier("randomArray")))
            
        case "builder":
            hasChanges = true
            changes.append("  ✏️  .builder() → .fixture()")
            return ExprSyntax(node.with(\.declName.baseName, .identifier("fixture")))
            
        default:
            return super.visit(node)
        }
    }
}

// MARK: - Supporting Types

struct MigrationStats {
    var migrated = 0
    var skipped = 0
}

enum MigrationError: Error, CustomStringConvertible {
    case directoryReadFailed(String)
    case fileReadFailed(String)
    
    var description: String {
        switch self {
        case .directoryReadFailed(let path):
            return "디렉토리를 읽을 수 없습니다: \(path)"
        case .fileReadFailed(let path):
            return "파일을 읽을 수 없습니다: \(path)"
        }
    }
}

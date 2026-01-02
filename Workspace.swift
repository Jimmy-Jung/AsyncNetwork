import ProjectDescription

let workspace = Workspace(
    name: "AsyncNetwork",
    projects: [
        // AsyncNetwork & AsyncNetworkDocKit은 SPM으로 관리 (Package.swift)
        "Projects/AsyncNetworkDocKitExample"
    ],
    schemes: [],
    fileHeaderTemplate: nil,
    additionalFiles: [
        // SPM Package.swift를 워크스페이스에 표시
        "Package.swift",
        "README.md"
    ],
    generationOptions: .options(
        enableAutomaticXcodeSchemes: true
    )
)

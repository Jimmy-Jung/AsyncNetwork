import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncNetworkDocKitExample",
    targets: [
        .target(
            name: "AsyncNetworkDocKitExample",
            destinations: .iOS,
            product: .app,
            bundleId: "com.asyncnetwork.AsyncNetworkDocKitExample",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:],
                ]
            ),
            sources: ["AsyncNetworkDocKitExample/Sources/**"],
            resources: ["AsyncNetworkDocKitExample/Resources/**"],
            scripts: [
                // 자동 코드 생성 스크립트
                .pre(
                    script: """
                    set -e

                    SCRIPTS_DIR="${SRCROOT}/../../Scripts"
                    PROJECT_SOURCE="${SRCROOT}/AsyncNetworkDocKitExample/Sources"
                    OUTPUT_DIR="${SRCROOT}/AsyncNetworkDocKitExample/Sources"

                    echo "🔄 Generating code..."

                    # 1. TypeRegistration 생성
                    if [ -f "$SCRIPTS_DIR/GenerateTypeRegistration.swift" ]; then
                        echo "  📝 Generating type registration..."
                        # macOS SDK를 사용하여 Swift 스크립트 실행
                        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateTypeRegistration.swift" \\
                            --project "$PROJECT_SOURCE" \\
                            --output "$OUTPUT_DIR/TypeRegistration+Generated.swift" \\
                            --module "AsyncNetworkDocKitExample" \\
                            --target "AsyncNetworkDocKitExampleApp"
                        
                        if [ $? -eq 0 ]; then
                            echo "  ✅ Type registration generated"
                        else
                            echo "  ❌ Failed to generate type registration"
                            exit 1
                        fi
                    else
                        echo "  ⚠️  TypeRegistration script not found"
                    fi

                    # 2. Endpoints 생성
                    if [ -f "$SCRIPTS_DIR/GenerateEndpoints.swift" ]; then
                        echo "  📝 Generating endpoints..."
                        # macOS SDK를 사용하여 Swift 스크립트 실행
                        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateEndpoints.swift" \\
                            --project "$PROJECT_SOURCE" \\
                            --output "$OUTPUT_DIR/Endpoints+Generated.swift" \\
                            --module "AsyncNetworkDocKitExample" \\
                            --target "AsyncNetworkDocKitExampleApp"
                        
                        if [ $? -eq 0 ]; then
                            echo "  ✅ Endpoints generated"
                        else
                            echo "  ❌ Failed to generate endpoints"
                            exit 1
                        fi
                    else
                        echo "  ⚠️  Endpoints script not found"
                    fi

                    echo "✨ Code generation completed"
                    """,
                    name: "Generate Code",
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                // AsyncNetworkDocKit (로컬 SPM 패키지 - Tuist/Package.swift 참조)
                .external(name: "AsyncNetworkDocKit"),
                // AsyncNetwork (로컬 SPM 패키지 - Tuist/Package.swift 참조)
                .external(name: "AsyncNetwork"),
            ],
            settings: .appSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "AsyncNetworkDocKitExample",
            testTargets: []
        ),
    ]
)

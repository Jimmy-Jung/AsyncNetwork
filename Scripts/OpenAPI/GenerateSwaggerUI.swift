#!/usr/bin/env swift
//
//  GenerateSwaggerUI.swift
//  AsyncNetwork
//
//  OpenAPI JSON을 Swagger UI HTML로 변환
//

import Foundation

let openAPIPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./openapi-new.json"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "./api-docs-swagger.html"

print("📄 OpenAPI 파일: \(openAPIPath)")
print("📝 출력 파일: \(outputPath)")

// OpenAPI JSON 읽기
guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: openAPIPath)),
      let jsonString = String(data: jsonData, encoding: .utf8)
else {
    print("❌ OpenAPI 파일을 읽을 수 없습니다: \(openAPIPath)")
    exit(1)
}

// Swagger UI HTML 생성
let html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation - Swagger UI</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
    <style>
        html {
            box-sizing: border-box;
            overflow: -moz-scrollbars-vertical;
            overflow-y: scroll;
        }
        *, *:before, *:after {
            box-sizing: inherit;
        }
        body {
            margin: 0;
            padding: 0;
        }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
    <script>
        window.onload = function() {
            const spec = \(jsonString);
            
            window.ui = SwaggerUIBundle({
                spec: spec,
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIStandalonePreset
                ],
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ],
                layout: "StandaloneLayout",
                tryItOutEnabled: true,
                filter: true,
                syntaxHighlight: {
                    activate: true,
                    theme: "monokai"
                }
            });
        };
    </script>
</body>
</html>
"""

// HTML 파일 저장
do {
    try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("✅ Swagger UI 문서 생성 완료!")
    print("")
    print("🎯 다음 단계:")
    print("  1. 파일 열기: open \(outputPath)")
    print("  2. 또는 브라우저에서: file://\(URL(fileURLWithPath: outputPath).absoluteString)")
    print("")
    print("💡 Swagger UI 특징:")
    print("  - 'Try it out' 버튼으로 API 테스트 가능")
    print("  - 필터링 및 검색 기능")
    print("  - 인터랙티브한 문서")
} catch {
    print("❌ 파일 저장 실패: \(error)")
    exit(1)
}

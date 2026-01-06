#!/usr/bin/env swift
//
//  GenerateAPIDocs.swift
//  AsyncNetwork
//
//  OpenAPI JSON을 HTML 문서로 변환
//

import Foundation

let openAPIPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./openapi-new.json"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "./api-docs.html"

print("📄 OpenAPI 파일: \(openAPIPath)")
print("📝 출력 파일: \(outputPath)")

// OpenAPI JSON 읽기
guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: openAPIPath)),
      let jsonString = String(data: jsonData, encoding: .utf8)
else {
    print("❌ OpenAPI 파일을 읽을 수 없습니다: \(openAPIPath)")
    exit(1)
}

// Redoc HTML 생성
let html = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>API Documentation</title>
    <style>
        body {
            margin: 0;
            padding: 0;
        }
    </style>
</head>
<body>
    <redoc spec-url='#'></redoc>
    <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
    <script>
        const spec = \(jsonString);
        Redoc.init(spec, {}, document.querySelector('redoc'));
    </script>
</body>
</html>
"""

// HTML 파일 저장
do {
    try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("✅ API 문서 생성 완료!")
    print("")
    print("🎯 다음 단계:")
    print("  1. 파일 열기: open \(outputPath)")
    print("  2. 또는 브라우저에서: file://\(URL(fileURLWithPath: outputPath).absoluteString)")
} catch {
    print("❌ 파일 저장 실패: \(error)")
    exit(1)
}

#!/usr/bin/env swift
//
//  GenerateStoplightElements.swift
//  AsyncNetwork
//
//  OpenAPI JSON을 Stoplight Elements HTML로 변환
//

import Foundation

let openAPIPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./openapi-final.json"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "./api-docs-elements.html"

print("📄 OpenAPI 파일: \(openAPIPath)")
print("📝 출력 파일: \(outputPath)")

// OpenAPI JSON 읽기
guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: openAPIPath)),
      let jsonString = String(data: jsonData, encoding: .utf8)
else {
    print("❌ OpenAPI 파일을 읽을 수 없습니다: \(openAPIPath)")
    exit(1)
}

// Stoplight Elements HTML 생성
let html = """
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation - Stoplight Elements</title>
    <meta name="description" content="AsyncNetwork API Documentation powered by Stoplight Elements">
    
    <!-- Stoplight Elements CSS -->
    <link rel="stylesheet" href="https://unpkg.com/@stoplight/elements/styles.min.css">
    
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        }
    </style>
</head>
<body>
    <!-- Stoplight Elements Container -->
    <div id="elements-container"></div>
    
    <!-- Stoplight Elements JS -->
    <script src="https://unpkg.com/@stoplight/elements/web-components.min.js"></script>
    
    <script>
        // OpenAPI 스펙을 JavaScript 객체로 삽입
        const apiSpec = \(jsonString);
        
        // Elements 초기화
        const elementsContainer = document.getElementById('elements-container');
        const apiElement = document.createElement('elements-api');
        
        apiElement.apiDescriptionDocument = JSON.stringify(apiSpec);
        apiElement.router = 'hash';
        apiElement.layout = 'sidebar';
        apiElement.tryItCredentialsPolicy = 'include';
        
        elementsContainer.appendChild(apiElement);
    </script>
</body>
</html>
"""

// 파일 저장
do {
    try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("✅ Stoplight Elements 문서 생성 완료!")
    print("")
    print("🎯 다음 단계:")
    print("  1. 파일 열기: open \(outputPath)")
    print("  2. 또는 브라우저에서: file://\(URL(fileURLWithPath: outputPath).absoluteString)")
    print("")
    print("💡 Stoplight Elements 특징:")
    print("  - Redoc 스타일의 아름다운 디자인")
    print("  - Swagger UI의 'Try it out' 기능")
    print("  - 강력한 검색 및 필터링")
    print("  - 모바일 최적화")
} catch {
    print("❌ 파일 저장 실패: \(error)")
    exit(1)
}

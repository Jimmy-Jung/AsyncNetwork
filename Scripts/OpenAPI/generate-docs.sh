#!/bin/bash
#
#  generate-docs.sh
#  AsyncNetwork
#
#  OpenAPI 스펙 생성 자동화
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          AsyncNetwork OpenAPI 스펙 생성                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 기본값 설정
DEFAULT_OUTPUT_DIR="./docs"
API_REQUEST_PATH=""
OUTPUT_PATH=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-request-path|-a)
            API_REQUEST_PATH="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --help|-h)
            echo "사용법: ./Scripts/OpenAPI/generate-docs.sh [옵션]"
            echo ""
            echo "옵션:"
            echo "  --api-request-path, -a <path>    @APIRequest 파일이 있는 경로 (필수)"
            echo "  --output, -o <path>               출력 폴더 경로 (기본값: ./docs)"
            echo "  --help, -h                        도움말 표시"
            echo ""
            echo "예시:"
            echo "  # 대화형 모드"
            echo "  ./Scripts/OpenAPI/generate-docs.sh"
            echo ""
            echo "  # 명령줄 모드"
            echo "  ./Scripts/OpenAPI/generate-docs.sh \\"
            echo "    --api-request-path Projects/YourApp/Sources \\"
            echo "    --output ./docs"
            exit 0
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            echo "도움말을 보려면 --help를 사용하세요."
            exit 1
            ;;
    esac
done

# 대화형 모드: APIRequest 경로 입력
if [ -z "$API_REQUEST_PATH" ]; then
    echo "📁 @APIRequest 파일이 있는 경로를 입력하세요."
    read -p "   경로: " user_input
    
    # 작은따옴표와 큰따옴표 제거
    user_input="${user_input//\'/}"
    user_input="${user_input//\"/}"
    API_REQUEST_PATH="$user_input"
    
    if [ -z "$API_REQUEST_PATH" ]; then
        echo "❌ APIRequest 경로가 필요합니다."
        exit 1
    fi
    echo ""
fi

# APIRequest 경로 존재 확인
if [ ! -d "$API_REQUEST_PATH" ]; then
    echo "❌ APIRequest 경로를 찾을 수 없습니다: $API_REQUEST_PATH"
    echo "   확인된 경로: $(pwd)/$API_REQUEST_PATH"
    exit 1
fi

# 대화형 모드: Output 경로 입력
if [ -z "$OUTPUT_PATH" ]; then
    echo "📁 출력 폴더 경로를 입력하세요."
    echo "   (기본값: $DEFAULT_OUTPUT_DIR)"
    read -p "   경로: " user_input
    
    if [ -z "$user_input" ]; then
        OUTPUT_PATH="$DEFAULT_OUTPUT_DIR"
        echo "   → 기본값 사용: $OUTPUT_PATH"
    else
        # 작은따옴표와 큰따옴표 제거
        user_input="${user_input//\'/}"
        user_input="${user_input//\"/}"
        OUTPUT_PATH="$user_input"
    fi
    echo ""
fi

# Output 폴더 생성
mkdir -p "$OUTPUT_PATH"
echo "📁 출력 폴더: $OUTPUT_PATH"
echo ""

# OpenAPI JSON 경로
OPENAPI_JSON="$OUTPUT_PATH/openapi.json"

# OpenAPI 스펙 생성
echo "📊 OpenAPI 스펙 생성 중..."
EXPORT_ARGS="--project \"$API_REQUEST_PATH\" --output \"$OPENAPI_JSON\" --format json --title \"AsyncNetwork API Documentation\" --version \"1.0.0\" --description \"Swift Concurrency 기반 네트워크 라이브러리 API 문서\""

eval "swift Scripts/OpenAPI/ExportOpenAPI.swift $EXPORT_ARGS"

echo ""
echo "✅ OpenAPI 스펙 생성 완료!"

# HTML 생성
echo ""
echo "📄 HTML 문서 생성 중..."

# Swagger UI HTML 생성
if [ -f "Scripts/OpenAPI/GenerateSwaggerUI.swift" ]; then
    echo "   • Swagger UI 생성 중..."
    swift Scripts/OpenAPI/GenerateSwaggerUI.swift "$OPENAPI_JSON" "$OUTPUT_PATH/api-docs-swagger.html"
else
    echo "   ⚠️  GenerateSwaggerUI.swift를 찾을 수 없습니다."
fi

# Stoplight Elements HTML 생성
if [ -f "Scripts/OpenAPI/GenerateStoplightElements.swift" ]; then
    echo "   • Stoplight Elements 생성 중..."
    swift Scripts/OpenAPI/GenerateStoplightElements.swift "$OPENAPI_JSON" "$OUTPUT_PATH/api-docs-elements.html"
else
    echo "   ⚠️  GenerateStoplightElements.swift를 찾을 수 없습니다."
fi

echo ""
echo "✅ 문서 생성 완료!"
echo ""
echo "📄 생성된 파일:"
echo "   • $OPENAPI_JSON"
if [ -f "$OUTPUT_PATH/api-docs-swagger.html" ]; then
    echo "   • $OUTPUT_PATH/api-docs-swagger.html"
fi
if [ -f "$OUTPUT_PATH/api-docs-elements.html" ]; then
    echo "   • $OUTPUT_PATH/api-docs-elements.html"
fi
echo ""
echo "🌐 브라우저에서 열기:"
if [ -f "$OUTPUT_PATH/api-docs-swagger.html" ]; then
    echo "   • open $OUTPUT_PATH/api-docs-swagger.html"
fi
if [ -f "$OUTPUT_PATH/api-docs-elements.html" ]; then
    echo "   • open $OUTPUT_PATH/api-docs-elements.html"
fi
echo ""
echo "📖 온라인 도구로 시각화:"
echo "   • Swagger Editor: https://editor.swagger.io/"
echo "   • Redoc: https://redocly.github.io/redoc/"
echo ""

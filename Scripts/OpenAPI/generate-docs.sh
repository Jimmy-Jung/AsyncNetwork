#!/bin/bash
#
#  generate-docs.sh
#  AsyncNetwork
#
#  OpenAPI 스펙 생성 및 문서화 자동화
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          AsyncNetwork API 문서 자동 생성                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 기본값 설정
DEFAULT_OUTPUT_DIR="./docs"
API_REQUEST_PATH=""
DOCUMENT_TYPE_PATH=""
OUTPUT_PATH=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-request-path|-a)
            API_REQUEST_PATH="$2"
            shift 2
            ;;
        --document-type-path|-d)
            DOCUMENT_TYPE_PATH="$2"
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
            echo "  --document-type-path, -d <path>   @DocumentedType 파일이 있는 경로 (선택)"
            echo "  --output, -o <path>               출력 폴더 경로 (기본값: ./docs)"
            echo "  --help, -h                        도움말 표시"
            echo ""
            echo "예시:"
            echo "  # 대화형 모드"
            echo "  ./Scripts/OpenAPI/generate-docs.sh"
            echo ""
            echo "  # 명령줄 모드"
            echo "  ./Scripts/OpenAPI/generate-docs.sh \\"
            echo "    --api-request-path Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \\"
            echo "    --document-type-path Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \\"
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

# 대화형 모드: DocumentType 경로 입력 (선택사항)
if [ -z "$DOCUMENT_TYPE_PATH" ]; then
    echo "📁 @DocumentedType 파일이 있는 경로를 입력하세요 (선택사항)."
    echo "   (Enter를 누르면 건너뜁니다)"
    read -p "   경로: " user_input
    
    if [ -n "$user_input" ]; then
        # 작은따옴표와 큰따옴표 제거
        user_input="${user_input//\'/}"
        user_input="${user_input//\"/}"
        DOCUMENT_TYPE_PATH="$user_input"
        echo "   → DocumentType 경로: $DOCUMENT_TYPE_PATH"
    else
        echo "   → DocumentType 경로 건너뜀"
    fi
    echo ""
fi

# DocumentType 경로 존재 확인
if [ -n "$DOCUMENT_TYPE_PATH" ] && [ ! -d "$DOCUMENT_TYPE_PATH" ]; then
    echo "❌ DocumentType 경로를 찾을 수 없습니다: $DOCUMENT_TYPE_PATH"
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

# 1. OpenAPI 스펙 생성
echo "📊 1/4 OpenAPI 스펙 생성 중..."
EXPORT_ARGS="--project \"$API_REQUEST_PATH\" --output \"$OPENAPI_JSON\" --format json --title \"AsyncNetwork API Documentation\" --version \"1.0.0\" --description \"Swift Concurrency 기반 네트워크 라이브러리 API 문서\""

if [ -n "$DOCUMENT_TYPE_PATH" ]; then
    EXPORT_ARGS="$EXPORT_ARGS --document-type-path \"$DOCUMENT_TYPE_PATH\""
fi

eval "swift Scripts/OpenAPI/ExportOpenAPI.swift $EXPORT_ARGS"

echo ""
echo "📄 2/4 Redoc HTML 생성 중..."
swift Scripts/OpenAPI/GenerateAPIDocs.swift "$OPENAPI_JSON" "$OUTPUT_PATH/api-docs-redoc.html"

echo ""
echo "📄 3/4 Swagger UI HTML 생성 중..."
swift Scripts/OpenAPI/GenerateSwaggerUI.swift "$OPENAPI_JSON" "$OUTPUT_PATH/api-docs-swagger.html"

echo ""
echo "📄 4/4 Stoplight Elements HTML 생성 중..."
swift Scripts/OpenAPI/GenerateStoplightElements.swift "$OPENAPI_JSON" "$OUTPUT_PATH/api-docs-elements.html"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      ✅ 완료!                                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "생성된 파일:"
echo "  📁 $OUTPUT_PATH/"
echo "    📊 openapi.json              - OpenAPI 3.0 스펙"
echo "    📄 api-docs-redoc.html       - Redoc (읽기 전용, 아름다운 디자인)"
echo "    📄 api-docs-swagger.html     - Swagger UI (API 테스트 가능)"
echo "    📄 api-docs-elements.html    - Stoplight Elements (최고급 UI)"
echo ""
echo "🎯 다음 단계:"
echo "  1. 공개 문서:      open \"$OUTPUT_PATH/api-docs-elements.html\"   # 🌟 추천!"
echo "  2. 읽기 전용:      open \"$OUTPUT_PATH/api-docs-redoc.html\""
echo "  3. 테스트용:       open \"$OUTPUT_PATH/api-docs-swagger.html\""
echo "  4. 라이브 프리뷰:  npx @redocly/cli preview-docs \"$OPENAPI_JSON\""
echo ""

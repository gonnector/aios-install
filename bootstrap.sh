#!/bin/bash
# ============================================================
# AIOS Install — Public Bootstrap (thin wrapper)
# ------------------------------------------------------------
# 본 스크립트는 사용자가 외우기 쉬운 단일 명령으로 진입할 수 있도록
# 만든 public 부트스트랩. 실제 Prerequisites(Xcode CLI / Homebrew /
# Bun 등) 설치, aios-dev clone, onboard 진행은 모두 private 레포의
# `aios-dev/components/onboard/bootstrap.sh` 가 담당.
#
# 사용자 명령 한 줄:
#   curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh | bash
#
# 흐름:
#   1) PAT 입력 (interactive, /dev/tty 사용 — curl|bash 패턴에서도 작동)
#   2) PAT 로 private aios-dev 의 bootstrap.sh 다운로드
#   3) GH_PAT 환경변수 전달하여 실행 (aios-dev bootstrap 이 prompt 재입력 skip)
#
# Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${CYAN}ℹ${NC} $1"; }
success() { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()    { echo -e "  ${RED}✗${NC} $1" >&2; exit 1; }

# ── 배너 ──
echo ""
echo -e "${CYAN}"
echo "  █████╗ ██╗ ██████╗ ███████╗"
echo " ██╔══██╗██║██╔═══██╗██╔════╝"
echo " ███████║██║██║   ██║███████╗"
echo " ██╔══██║██║██║   ██║╚════██║"
echo " ██║  ██║██║╚██████╔╝███████║"
echo " ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}AIOS Install${NC} ${DIM}— public bootstrap${NC}"
echo ""

# ── OS 체크 ──
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "이 스크립트는 macOS에서만 실행 가능합니다."
fi

# ── 네트워크 사전 체크 (raw URL 도달 가능한지) ──
if ! curl -fsI -o /dev/null https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh 2>/dev/null; then
  warn "GitHub raw URL 도달 실패 — 네트워크 또는 VPN 확인 필요"
fi

# ── PAT 입력 ──
# curl | bash 흐름에서는 stdin 이 파이프로 채워지므로 일반 read 가 작동 안 함.
# /dev/tty 를 직접 열어 interactive 보장.
if [[ -z "${GH_PAT:-}" ]]; then
  if [[ ! -r /dev/tty ]]; then
    fail "interactive TTY 가 없습니다. 환경변수 GH_PAT 로 PAT 전달 후 재실행하세요. 예) GH_PAT=ghp_xxx bash <(curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh)"
  fi
  echo -e "  ${CYAN}ℹ${NC} GitHub PAT를 입력하세요 (Gonnector 관리자가 제공)."
  echo -e "  ${DIM}입력 중 글자는 표시되지 않습니다 (보안).${NC}"
  read -sp "  GitHub Personal Access Token: " GH_PAT </dev/tty
  echo ""
  echo ""
else
  info "환경변수 GH_PAT 감지 (prompt 생략)"
  echo ""
fi

if [[ -z "$GH_PAT" ]]; then
  fail "토큰이 입력되지 않았습니다."
fi

# ── PAT 형식 간단 검증 (오타 방지) ──
if [[ ! "$GH_PAT" =~ ^(ghp_|github_pat_|gho_|ghu_|ghs_|ghr_) ]]; then
  warn "PAT 형식이 GitHub 표준 prefix(ghp_ / github_pat_ 등)와 다릅니다. 진행은 시도합니다."
fi

# ── PAT 권한 사전 확인 (raw URL 도달) ──
info "PAT 권한 확인 중..."
HTTP_CODE=$(curl -u "gonnector:${GH_PAT}" -fsSL -o /dev/null -w "%{http_code}" \
  "https://raw.githubusercontent.com/gonnector/aios-dev/master/components/onboard/bootstrap.sh" 2>/dev/null || echo "000")

case "$HTTP_CODE" in
  200) success "PAT 권한 확인 완료" ;;
  401|403) fail "PAT 인증 실패 (HTTP $HTTP_CODE). PAT가 유효하고 gonnector/aios-dev 접근 권한이 있는지 확인하세요." ;;
  404) fail "PAT 가 aios-dev 접근 권한이 없습니다 (HTTP 404 — private repo). fine-grained PAT 의 Repository access 에 gonnector/aios-dev 가 포함되어 있는지 확인하세요." ;;
  *)   warn "예상 외 응답 (HTTP $HTTP_CODE). 진행은 시도합니다." ;;
esac

# ── aios-dev 의 onboard bootstrap.sh 가져와 실행 ──
echo ""
info "AIOS 부트스트랩 진행 (Prerequisites + onboard 인터랙티브 흐름)..."
echo ""

export GH_PAT

if ! curl -u "gonnector:${GH_PAT}" -fsSL \
  "https://raw.githubusercontent.com/gonnector/aios-dev/master/components/onboard/bootstrap.sh" \
  | bash; then
  unset GH_PAT
  fail "AIOS 부트스트랩 실행 실패. 출력 메시지를 확인하세요."
fi

# wrapper 측 후속 메시지는 출력하지 않음 — inner bootstrap.sh 가
# Phase 1 완료 → Phase 2 (bun run onboard) 자동 진입 → onboard 가 자체 완료 안내.
# wrapper 가 중복 안내하면 사용자 혼란 (Dylan 2026-05-14 지시).
unset GH_PAT

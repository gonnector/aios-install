#!/bin/bash
# ============================================================
# AIOS Onboard — Bootstrap Script (macOS)
# Prerequisites: Xcode CLI, Homebrew, Bun 자동 설치
# Usage: bash bootstrap.sh
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
fail()    { echo -e "  ${RED}✗${NC} $1"; exit 1; }

echo ""
echo -e "${CYAN}"
echo "  █████╗ ██╗ ██████╗ ███████╗"
echo " ██╔══██╗██║██╔═══██╗██╔════╝"
echo " ███████║██║██║   ██║███████╗"
echo " ██╔══██║██║██║   ██║╚════██║"
echo " ██║  ██║██║╚██████╔╝███████║"
echo " ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}AIOS Bootstrap${NC} ${DIM}— macOS 환경 준비${NC}"
echo ""

# ── OS 체크 ──
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "이 스크립트는 macOS에서만 실행 가능합니다."
fi
success "macOS 감지됨: $(sw_vers -productVersion)"

# ── Xcode CLI Tools ──
if xcode-select -p &>/dev/null; then
  success "Xcode Command Line Tools 설치됨"
else
  info "Xcode Command Line Tools 설치 중..."
  xcode-select --install
  echo ""
  warn "설치 팝업에서 '설치'를 클릭하세요."
  warn "설치 완료 후 이 스크립트를 다시 실행하세요."
  exit 0
fi

# ── Homebrew ──
if command -v brew &>/dev/null; then
  success "Homebrew 설치됨: $(brew --version | head -1)"
else
  info "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon PATH — zprofile + zshrc 양쪽 등록 (M-1)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    grep -q '/opt/homebrew/bin/brew' ~/.zshrc 2>/dev/null || \
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  fi
  success "Homebrew 설치 완료"
fi

# ── Git ──
if command -v git &>/dev/null; then
  success "Git 설치됨: $(git --version)"
else
  info "Git 설치 중..."
  brew install git
  success "Git 설치 완료"
fi

# ── Bun ──
if command -v bun &>/dev/null; then
  success "Bun 설치됨: $(bun --version)"
else
  info "Bun 설치 중..."
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  # M-2: Bun PATH를 ~/.zshrc에도 등록 (macOS 기본 셸 = zsh)
  grep -q '.bun/bin' ~/.zshrc 2>/dev/null || \
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zshrc
  success "Bun 설치 완료: $(bun --version)"
fi

# ── cmux (Dylan 2026-04-21 신규 요건) ──
if command -v cmux &>/dev/null; then
  success "cmux 설치됨"
else
  info "cmux 설치 중..."
  if brew install cmux 2>/dev/null; then
    success "cmux 설치 완료"
  else
    warn "cmux 자동 설치 실패. 나중에 수동 설치 필요: brew install cmux"
  fi
fi

# ── WezTerm (Dylan 2026-04-21 신규 요건) ──
if command -v wezterm &>/dev/null || [[ -d "/Applications/WezTerm.app" ]]; then
  success "WezTerm 설치됨"
else
  info "WezTerm 설치 중..."
  if brew install --cask wezterm 2>/dev/null; then
    success "WezTerm 설치 완료"
  else
    warn "WezTerm 자동 설치 실패. 나중에 수동 설치 필요: brew install --cask wezterm"
  fi
fi

# ── Discord Desktop (Dylan 2026-04-21 신규 요건) ──
if [[ -d "/Applications/Discord.app" ]]; then
  success "Discord Desktop 설치됨"
else
  info "Discord Desktop 설치 중..."
  if brew install --cask discord 2>/dev/null; then
    success "Discord Desktop 설치 완료"
  else
    warn "Discord Desktop 자동 설치 실패. 나중에 수동 설치: brew install --cask discord (또는 https://discord.com/download)"
  fi
fi

echo ""
echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
echo ""

# ── AIOS Onboard 패키지 가져오기 ──
ONBOARD_DIR="$HOME/.aios-onboard"

if [[ -d "$ONBOARD_DIR" ]]; then
  info "기존 onboard 패키지 발견. 업데이트 중..."
  cd "$ONBOARD_DIR"
  if [[ -d ".git" ]]; then
    git pull --quiet 2>/dev/null || true
  fi
else
  echo -e "  ${CYAN}ℹ${NC} AIOS 패키지를 가져옵니다."
  echo ""

  # GitHub PAT 입력
  read -sp "  GitHub Personal Access Token: " GH_PAT
  echo ""

  if [[ -z "$GH_PAT" ]]; then
    fail "토큰이 입력되지 않았습니다."
  fi

  info "AIOS 레포에서 onboard 패키지 클론 중..."

  # 2026-04-22 보안 강화: credential.helper 비활성화로 macOS Keychain·git-credential-cache에
  # PAT 저장 차단. 고객 맥북에 Dylan PAT 영구 잔존 방지.
  git -c credential.helper="" clone --depth 1 --filter=blob:none --sparse \
    "https://${GH_PAT}@github.com/gonnector/aios-dev.git" \
    "$ONBOARD_DIR" 2>/dev/null || fail "레포 클론 실패. 토큰과 레포 접근 권한을 확인하세요."

  cd "$ONBOARD_DIR"

  # HIGH-3 fix: clone 직후 remote URL에서 PAT 제거 (git config·git remote -v 평문 노출 방지)
  git remote set-url origin "https://github.com/gonnector/aios-dev.git" 2>/dev/null

  git sparse-checkout set components/onboard 2>/dev/null

  success "onboard 패키지 다운로드 완료"
fi

# ── 의존성 설치 ──
WORK_DIR="$ONBOARD_DIR/components/onboard"
if [[ ! -d "$WORK_DIR" ]]; then
  fail "onboard 디렉토리를 찾을 수 없습니다: $WORK_DIR"
fi

cd "$WORK_DIR"
info "의존성 설치 중..."
bun install --silent
success "의존성 설치 완료"

# ── AIOS 핵심 스킬 git clone (Dylan 2026-04-21) ──
# PAT 이미 확보된 시점에 실행. handoff는 마켓플레이스로 설치되므로 제외.
info "AIOS 핵심 스킬 설치 중..."
mkdir -p "$HOME/.claude/skills"

declare -a CORE_SKILLS=(
  "claude-session-wrapup-skill:wrapup"
  "claude-deep-research-skill:research"
  "claude-todo-skill:todo"
)

for entry in "${CORE_SKILLS[@]}"; do
  repo="${entry%%:*}"
  alias_name="${entry##*:}"
  skill_dir="$HOME/.claude/skills/$alias_name"

  if [[ -d "$skill_dir" ]]; then
    success "스킬 $alias_name 이미 설치됨 (skip)"
    continue
  fi

  info "  $alias_name 설치 중 (gonnector/$repo)..."
  # 2026-04-22 보안 강화: credential.helper="" 로 Keychain 미저장
  if git -c credential.helper="" clone --depth 1 --quiet "https://${GH_PAT}@github.com/gonnector/${repo}.git" "$skill_dir" 2>/dev/null; then
    # remote URL에서 PAT 제거 (HIGH-3 원칙)
    git -C "$skill_dir" remote set-url origin "https://github.com/gonnector/${repo}.git" 2>/dev/null
    success "  $alias_name 설치 완료"
  else
    warn "  $alias_name 설치 실패 (PAT 권한 확인 필요)"
  fi
done

echo ""
echo -e "${GREEN}${BOLD}  ✓ Bootstrap 완료!${NC}"
echo ""
echo -e "  다음 명령어로 온보딩을 시작하세요:"
echo ""
echo -e "    ${BOLD}cd $WORK_DIR && bun run onboard${NC}"
echo ""
echo -e "  ${DIM}또는 언인스톨:${NC}"
echo -e "    ${DIM}bun run uninstall${NC}"
echo ""

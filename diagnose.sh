#!/usr/bin/env bash
# ============================================================
# AIOS Bootstrap — 진단 스크립트
# ------------------------------------------------------------
# 사용: curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/diagnose.sh | bash
#
# 또는 다운로드 후 실행:
#   curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/diagnose.sh -o /tmp/diag.sh
#   bash /tmp/diag.sh
#
# 환경 변경 없이 정보만 수집. 결과를 ~/aios-bootstrap-diagnose-<host>-<ts>.txt 에 저장.
# 토큰·비밀 자동 마스킹.
#
# Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
# ============================================================

set +e  # 에러 발생해도 모든 검사 진행

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
HOST_SHORT="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown)"
OUT="$HOME/aios-bootstrap-diagnose-$HOST_SHORT-$TIMESTAMP.txt"

c_cyn=$'\033[36m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_dim=$'\033[2m'; c_rst=$'\033[0m'

# 변수 set/unset/empty 명확 (bash 3.2 호환)
report_var() {
  local name="$1"
  local val
  if eval "[ -z \"\${${name}+x}\" ]"; then
    echo "  $name: UNSET"
  else
    val="$(eval "echo \"\$$name\"")"
    if [ -z "$val" ]; then
      echo "  $name: SET_BUT_EMPTY"
    elif [ "$name" = "GH_PAT" ]; then
      local prefix="${val:0:7}"
      echo "  $name: SET (length=${#val}, prefix=${prefix}...)"
    else
      echo "  $name: \"$val\""
    fi
  fi
}

# ─── 시작 안내 (사용자에게 무엇이 진행 중인지 즉시 표시) ──
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ${c_cyn}AIOS Bootstrap 진단 시작${c_rst}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  ${c_cyn}ℹ${c_rst} 환경 변경 없이 진단 정보만 수집합니다 (약 10~30초)."
echo "  ${c_cyn}ℹ${c_rst} 결과: 화면 + 파일 ($OUT) 동시 출력."
echo "  ${c_cyn}ℹ${c_rst} 중간에 PAT 입력 prompt 가 한 번 나옵니다 (선택)."
echo ""
echo "  ${c_dim}── 진단 진행 ──${c_rst}"
echo ""

# 출력을 화면 + 파일 동시
{
  echo "════════════════════════════════════════════════════════════════"
  echo "  AIOS Bootstrap 진단 보고서"
  echo "════════════════════════════════════════════════════════════════"
  echo "  생성 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "  호스트   : $(hostname 2>/dev/null)"
  echo "  사용자   : $(whoami)"
  echo "  PWD      : $(pwd)"

  # §1 시스템
  echo ""
  echo "── §1 시스템 정보 ──"
  echo "  macOS  : $(sw_vers -productVersion 2>/dev/null) ($(sw_vers -buildVersion 2>/dev/null))"
  echo "  arch   : $(uname -m)"
  echo "  SHELL  : $SHELL"
  echo "  bash   : $(bash --version 2>/dev/null | head -1)"
  echo "  zsh    : $(zsh --version 2>/dev/null || echo '미설치')"
  echo "  git    : $(git --version 2>/dev/null || echo '미설치')"
  echo "  bun    : $(bun --version 2>/dev/null || echo '미설치')"
  echo "  curl   : $(curl --version 2>/dev/null | head -1)"
  echo "  python3: $(python3 --version 2>/dev/null || echo '미설치')"

  # §2 환경변수
  echo ""
  echo "── §2 환경변수 ──"
  for v in GH_PAT AIOS_PATH AIOS AIOS_ORG REPOS USER_NAME WORK_NAME WORK_PATH PERSONAL_PATH HOME; do
    report_var "$v"
  done

  # §2.5 bootstrap 로그 자동 분석 (SPEC §5 통합)
  # 두 위치 탐색 (B안, 2026-05-14):
  #   - ~/.aios-onboard/logs/bootstrap-*.log (clone 성공 후 위치)
  #   - /tmp/aios-bootstrap-*.log            (clone 실패 시 시작 위치 잔존)
  #   - ~/aios-bootstrap-*.log              (구 위치, 호환성 — 0.2.x 이전)
  echo ""
  echo "── §2.5 bootstrap 로그 자동 분석 ──"
  LATEST_LOG=$(ls -t \
    "$HOME"/.aios-onboard/logs/bootstrap-*.log \
    /tmp/aios-bootstrap-*.log \
    "$HOME"/aios-bootstrap-*.log \
    2>/dev/null | head -1)
  if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
    echo "  최근 로그: $LATEST_LOG"
    echo "  생성 시각: $(stat -f '%Sm' "$LATEST_LOG" 2>/dev/null)"
    echo "  크기: $(wc -l < "$LATEST_LOG" | tr -d ' ') 줄"
    echo ""
    echo "  ── 단계 진행 매트릭스 ──"
    KNOWN_STEPS=(os-check xcode-cli homebrew git-install git-version bun-install \
                 cmux-install wezterm-install discord-install pat-prompt \
                 clone-aios-dev remote-clean bun-deps \
                 skill-clone-wrapup skill-clone-research skill-clone-todo \
                 bootstrap-complete)
    for s in "${KNOWN_STEPS[@]}"; do
      # bash 3.2 호환 — printf 패딩
      local_step=$(printf "%-30s" "$s")
      if grep -qE "\[SUCCESS[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" 2>/dev/null; then
        echo "    [${c_grn}✓${c_rst}] $local_step (완료)"
      elif grep -qE "\[ERROR[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" 2>/dev/null; then
        err_msg=$(grep -E "\[ERROR[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" | tail -1 | sed -E 's/.*\][[:space:]]*//')
        echo "    [${c_red}✗${c_rst}] $local_step (실패: $err_msg)"
      elif grep -qE "\[FAIL[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" 2>/dev/null; then
        fail_msg=$(grep -E "\[FAIL[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" | tail -1 | sed -E 's/.*\][[:space:]]*//')
        echo "    [${c_red}✗${c_rst}] $local_step (FAIL: $fail_msg)"
      elif grep -qE "\[INFO[[:space:]]*\][[:space:]]*\[${s}" "$LATEST_LOG" 2>/dev/null; then
        echo "    [${c_yel}⚠${c_rst}] $local_step (시작했으나 완료 entry 없음)"
      else
        echo "    [ ] $local_step (미진입)"
      fi
    done

    echo ""
    echo "  ── 마지막 ERROR/STDERR/FAIL entries ──"
    grep -E '\[(ERROR|STDERR|FAIL|WARN)\][[:space:]]' "$LATEST_LOG" 2>/dev/null | tail -10 | sed 's/^/    /' || echo "    (entries 없음 — 정상 완료 또는 진행 중)"

    echo ""
    echo "  ── 자동 가설 매핑 ──"
    LAST_STDERR=$(grep -E '\[STDERR[[:space:]]*\]' "$LATEST_LOG" 2>/dev/null | tail -3 | tr '\n' ' ')
    LAST_ERROR=$(grep -E '\[ERROR[[:space:]]*\]' "$LATEST_LOG" 2>/dev/null | tail -1)

    if [ -z "$LAST_ERROR" ]; then
      echo "    → ERROR entry 없음. bootstrap 정상 완료했거나 진행 중."
    elif echo "$LAST_STDERR" | grep -qiE 'authentication failed|invalid.*token|HTTP/[0-9.]+ 40[13]'; then
      echo "    → ${c_red}PAT 인증 실패${c_rst}: PAT 만료/오타. 새 PAT 발급 권장."
    elif echo "$LAST_STDERR" | grep -qiE 'repository.*not found|HTTP/[0-9.]+ 404'; then
      echo "    → ${c_red}PAT 권한 부족${c_rst}: fine-grained PAT 의 Selected repositories 에"
      echo "      gonnector/aios-dev (+ 필요 시 skill repos) 추가 후 재발급."
    elif echo "$LAST_STDERR" | grep -qiE 'could not resolve|connection.*refused|connection.*timed out|timeout'; then
      echo "    → ${c_red}네트워크 이슈${c_rst}: DNS/VPN/방화벽 확인."
    elif echo "$LAST_STDERR" | grep -qiE 'sparse.*not.*git command|unknown subcommand'; then
      echo "    → ${c_red}git 버전 낮음${c_rst}: sparse-checkout 명령 미지원 (2.25+ 필요)."
      echo "      brew install git 으로 업그레이드 권장. (※ 이번 변경에서 sparse 제거됨)"
    elif echo "$LAST_STDERR" | grep -qiE 'permission denied|operation not permitted'; then
      echo "    → ${c_red}권한 부족${c_rst}: sudo 또는 디렉토리 chmod 확인."
    elif echo "$LAST_STDERR" | grep -qiE 'disk.*full|no space left'; then
      echo "    → ${c_red}디스크 부족${c_rst}: df -h 확인 + 정리."
    else
      echo "    → 자동 매핑 안 됨. 위 ERROR/STDERR 텍스트로 Gonnector 측 수동 진단 필요."
    fi
  else
    echo "  ${c_dim}~/aios-bootstrap-*.log 파일 없음 — bootstrap 실행 흔적 없거나 (a153d2a 이전 버전)${c_rst}"
  fi

  # §3 네트워크 도달성
  echo ""
  echo "── §3 네트워크 도달성 (HTTP code) ──"
  echo "  github.com                                : $(curl -o /dev/null -s -w "%{http_code}" --max-time 5 https://github.com 2>&1 || echo TIMEOUT)"
  echo "  raw aios-install/main/README.md (public)  : $(curl -o /dev/null -s -w "%{http_code}" --max-time 5 https://raw.githubusercontent.com/gonnector/aios-install/main/README.md 2>&1 || echo TIMEOUT)"
  echo "  raw aios-dev (without PAT — 404 expected) : $(curl -o /dev/null -s -w "%{http_code}" --max-time 5 https://raw.githubusercontent.com/gonnector/aios-dev/master/components/onboard/bootstrap.sh 2>&1 || echo TIMEOUT)"

  # §4 ~/.aios-onboard 상태
  echo ""
  echo "── §4 ~/.aios-onboard 상태 ──"
  if [ -d "$HOME/.aios-onboard" ]; then
    echo "  폴더 존재"
    echo "  내용 (head -30):"
    ls -la "$HOME/.aios-onboard" 2>&1 | head -30 | sed 's/^/    /'
    echo ""
    if [ -d "$HOME/.aios-onboard/.git" ]; then
      echo "  .git/ 존재 → clone 시도된 흔적"
      echo "  git log (head -3):"
      git -C "$HOME/.aios-onboard" log --oneline 2>&1 | head -3 | sed 's/^/    /'
      echo "  remote (PAT 마스킹):"
      git -C "$HOME/.aios-onboard" remote -v 2>&1 | sed -E 's|https://[^@]*@|https://***MASKED***@|g' | sed 's/^/    /'
      echo "  config core.sparseCheckout: $(git -C "$HOME/.aios-onboard" config core.sparseCheckout 2>&1)"
      echo "  .git/info/sparse-checkout 파일:"
      if [ -f "$HOME/.aios-onboard/.git/info/sparse-checkout" ]; then
        cat "$HOME/.aios-onboard/.git/info/sparse-checkout" 2>&1 | sed 's/^/    /'
      else
        echo "    (파일 없음)"
      fi
      echo "  git sparse-checkout list:"
      git -C "$HOME/.aios-onboard" sparse-checkout list 2>&1 | sed 's/^/    /'
    else
      echo "  .git/ 없음 — 정상 clone 아님"
    fi
    echo ""
    echo "  components/onboard 존재? $([ -d "$HOME/.aios-onboard/components/onboard" ] && echo YES || echo NO)"
    if [ -d "$HOME/.aios-onboard/components/onboard" ]; then
      echo "  components/onboard 내용 (head -10):"
      ls "$HOME/.aios-onboard/components/onboard" 2>&1 | head -10 | sed 's/^/    /'
    fi
  else
    echo "  ~/.aios-onboard 폴더 없음"
  fi

  # §5 PAT 인터랙티브 검증
  echo ""
  echo "── §5 PAT 권한 검증 (선택 — Enter 만 눌러도 skip 가능) ──"

  # GH_PAT 환경변수 또는 prompt
  if [ -z "${GH_PAT:-}" ]; then
    if [ -r /dev/tty ]; then
      # 화면 직접 출력 (/dev/tty) — pipe/tee buffering 영향 회피
      printf "\n  %s GitHub PAT 입력 단계 — 권한 사전 검증에 사용 (저장·전송 안 함).\n" "ℹ" >/dev/tty
      printf "  %s 입력 시 글자가 화면에 표시되지 않습니다 (보안).\n" "ℹ" >/dev/tty
      printf "  %s 검증을 skip 하려면 그냥 Enter — 다음 단계로 진행.\n\n" "ℹ" >/dev/tty
      printf "  PAT (또는 Enter 로 skip): " >/dev/tty
      read -s GH_PAT </dev/tty
      printf "\n" >/dev/tty
      if [ -z "$GH_PAT" ]; then
        echo "  ${c_yel}⚠${c_rst} PAT 입력 skip — §5/§6 검증은 생략됩니다."
      fi
    else
      echo "  ${c_yel}⚠${c_rst} interactive TTY 없음 — PAT 검증 skip"
    fi
  else
    echo "  ${c_cyn}ℹ${c_rst} 환경변수 GH_PAT 사용 (prompt 생략)"
  fi

  if [ -n "${GH_PAT:-}" ]; then
    echo "  PAT prefix: ${GH_PAT:0:7}... (length=${#GH_PAT})"
    if [[ ! "$GH_PAT" =~ ^(ghp_|github_pat_|gho_|ghu_|ghs_|ghr_) ]]; then
      echo "  ${c_yel}⚠${c_rst} 표준 prefix 아님 — 형식 오류 가능"
    fi

    HTTP_CODE=$(curl -u "gonnector:${GH_PAT}" -o /dev/null -s -w "%{http_code}" --max-time 10 \
      "https://raw.githubusercontent.com/gonnector/aios-dev/master/components/onboard/bootstrap.sh" 2>&1)
    echo "  aios-dev raw URL with PAT: HTTP $HTTP_CODE"
    case "$HTTP_CODE" in
      200) echo "  ${c_grn}✓${c_rst} PAT 권한 OK" ;;
      401|403) echo "  ${c_red}✗${c_rst} PAT 인증 실패 (만료/오타)" ;;
      404) echo "  ${c_red}✗${c_rst} PAT 가 aios-dev 접근 권한 없음 (Selected repositories 에 미포함)" ;;
      *) echo "  ${c_yel}⚠${c_rst} 예상 외 응답 — 네트워크 또는 다른 원인" ;;
    esac

    # §6 직접 git clone 시도
    echo ""
    echo "── §6 직접 git clone 시도 (sparse 옵션 없이, stderr 정상 출력) ──"
    TMP_CLONE="/tmp/aios-clone-diag-$$"
    rm -rf "$TMP_CLONE"
    echo "  실행: git -c credential.helper=\"\" clone --depth 1 \\"
    echo "        \"https://gonnector:***@github.com/gonnector/aios-dev.git\" \\"
    echo "        \"$TMP_CLONE\""
    echo ""
    git -c credential.helper="" clone --depth 1 \
      "https://gonnector:${GH_PAT}@github.com/gonnector/aios-dev.git" \
      "$TMP_CLONE" 2>&1 | sed -E "s|${GH_PAT}|***MASKED***|g" | sed 's/^/    /'
    CLONE_EXIT=$?
    echo ""
    echo "  clone exit code: $CLONE_EXIT"
    if [ "$CLONE_EXIT" = "0" ]; then
      echo "  ${c_grn}✓${c_rst} clone 성공"
      echo "  ls (head -5):"
      ls "$TMP_CLONE" 2>&1 | head -5 | sed 's/^/    /'
      echo "  components/onboard 존재? $([ -d "$TMP_CLONE/components/onboard" ] && echo YES || echo NO)"
      if [ -d "$TMP_CLONE/components/onboard" ]; then
        echo "  → bootstrap 의 sparse 옵션 처리에 문제 가능성. 단순 clone 으로 진입 가능."
      fi

      # §6-2 sparse-checkout 명령 단독 테스트
      echo ""
      echo "── §6-2 git sparse-checkout 명령 호환성 테스트 ──"
      git -C "$TMP_CLONE" sparse-checkout set components/onboard 2>&1 | sed 's/^/    /'
      SPARSE_EXIT=$?
      echo "  sparse-checkout set exit code: $SPARSE_EXIT"
      if [ "$SPARSE_EXIT" != "0" ]; then
        echo "  ${c_red}✗${c_rst} sparse-checkout 명령 실패 — git 2.25+ 필요할 수 있음"
        echo "  현재 git: $(git --version)"
      else
        echo "  ${c_grn}✓${c_rst} sparse-checkout 명령 작동"
      fi
    else
      echo "  ${c_red}✗${c_rst} clone 실패 — 위 메시지 참조"
    fi
    rm -rf "$TMP_CLONE"

    # 메모리 정리
    unset GH_PAT
  fi

  # §7 자동 진단 + 권고
  echo ""
  echo "── §7 자동 진단 매트릭스 ──"

  ONBOARD_EXISTS="$([ -d "$HOME/.aios-onboard" ] && echo Y || echo N)"
  ONBOARD_HAS_GIT="$([ -d "$HOME/.aios-onboard/.git" ] && echo Y || echo N)"
  ONBOARD_HAS_COMPONENT="$([ -d "$HOME/.aios-onboard/components/onboard" ] && echo Y || echo N)"
  GIT_MAJOR=$(git --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
  GIT_MINOR=$(git --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f2)

  echo "  [H1] ~/.aios-onboard 존재: $ONBOARD_EXISTS"
  echo "  [H2] .git/ 존재 (clone 시도 흔적): $ONBOARD_HAS_GIT"
  echo "  [H3] components/onboard 존재 (sparse-checkout 성공 여부): $ONBOARD_HAS_COMPONENT"
  echo "  [H4] git 버전: ${GIT_MAJOR}.${GIT_MINOR} (sparse-checkout subcommand 는 2.25+ 필요)"

  echo ""
  echo "  ※ 추정 원인:"
  if [ "$ONBOARD_EXISTS" = "Y" ] && [ "$ONBOARD_HAS_GIT" = "Y" ] && [ "$ONBOARD_HAS_COMPONENT" = "N" ]; then
    echo "  → clone 은 성공, sparse-checkout 또는 partial-clone filter 단계에서 components/onboard"
    echo "    파일이 안 가져와짐. set -e + 2>/dev/null 로 silent fail."
    if [ "${GIT_MAJOR:-0}" -lt 2 ] || { [ "${GIT_MAJOR:-0}" = "2" ] && [ "${GIT_MINOR:-0}" -lt 25 ]; }; then
      echo "  → git ${GIT_MAJOR}.${GIT_MINOR} 가 너무 낮음. brew install git 으로 최신 버전 설치 권장"
    fi
  elif [ "$ONBOARD_EXISTS" = "N" ]; then
    echo "  → clone 자체가 실행 안 됐거나 폴더 생성 실패. PAT 권한 또는 네트워크 의심"
  fi

  echo ""
  echo "── §8 권장 후속 조치 ──"
  echo "  1) 위 진단 결과 파일을 Gonnector 에 메일/메신저 전달"
  echo "     파일: $OUT"
  echo ""
  if [ "$ONBOARD_EXISTS" = "Y" ] && [ "$ONBOARD_HAS_GIT" = "Y" ] && [ "$ONBOARD_HAS_COMPONENT" = "N" ]; then
    echo "  2) 즉시 우회 (sparse 옵션 없이 full clone + 직접 onboard 실행):"
    echo "       rm -rf ~/.aios-onboard"
    echo "       read -sp 'PAT: ' P && echo"
    echo "       git -c credential.helper=\"\" clone --depth 1 \\"
    echo "         \"https://gonnector:\${P}@github.com/gonnector/aios-dev.git\" \\"
    echo "         ~/.aios-onboard"
    echo "       git -C ~/.aios-onboard remote set-url origin \"https://github.com/gonnector/aios-dev.git\""
    echo "       cd ~/.aios-onboard/components/onboard && bun install && bun run onboard"
  fi

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  진단 완료 — $(date '+%Y-%m-%d %H:%M:%S')"
  echo "════════════════════════════════════════════════════════════════"
} | tee "$OUT"

# 화면에 마지막 안내 (파일에는 위 } 블록만 기록)
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ${c_grn}✓${c_rst} 진단 완료"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  결과 파일: $OUT"
echo "  ($(wc -c < "$OUT" | tr -d ' ') 바이트)"
echo ""
echo "  다음 단계: 위 파일을 Gonnector(메일/메신저)에 첨부 전달"
echo ""

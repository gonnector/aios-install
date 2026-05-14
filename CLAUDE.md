# aios-install — 운영 가이드 (CLAUDE.md)

Gonnector AIOS 의 public 진입점 레포. macOS 신규 머신 부트스트랩 + 운영 중 진단 도구.

## 1. 레포 목적

| 역할 | 설명 |
|------|------|
| **Public 진입점** | private `aios-dev` 접근 불가한 신규 머신 — 이 public repo 에서 bootstrap 시작 |
| **Thin wrapper** | PAT 입력 + aios-dev 의 실제 bootstrap.sh 호출만. 실제 설치 로직은 aios-dev 가 SSoT |
| **진단 도구** | 운영 중 trouble shooting — bootstrap 로그 자동 분석 + 자동 가설 매핑 |

private `aios-dev` 와의 관계: aios-install 은 wrapper, **aios-dev 가 SSoT**. aios-dev/bootstrap.sh 갱신 시 aios-install 자동 반영. 두 레포 동기화 부담 0.

## 2. 파일 구조

| 파일 | 역할 | 갱신 주기 |
|------|------|-----------|
| `bootstrap.sh` | thin wrapper — PAT prompt + aios-dev/bootstrap.sh curl 호출 | 인터페이스 변경 시만 (드묾) |
| `diagnose.sh` | 운영 진단 — 시스템/환경/로그/PAT/clone 검증 | 새 진단 항목 추가 시 |
| `README.md` | 사용자 빠른 시작 + 트러블슈팅 | 사용 명령/링크 변경 시 |
| `CHANGELOG.md` | Keep a Changelog 포맷 | 모든 변경에 1줄 추가 |
| `LICENSE` | MIT | 변경 거의 없음 |

**금지**: 실제 설치 로직 (Prerequisites, clone, onboard) 을 본 레포에 복제하지 말 것. aios-dev SSoT 원칙 깨짐.

## 3. 사용자 한 줄 명령 (정본)

### 3.1 정상 설치 (신규 머신)

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh | bash
```

PAT prompt 1회. 이후 자동 진행 — Prerequisites + aios-dev clone + 핵심 스킬 + onboard 8 phase.

### 3.2 진단 (bootstrap 실패 시)

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/diagnose.sh | bash
```

자동 수행: 환경 정보 + bootstrap 로그 분석 + PAT 검증(선택) + 자동 가설 매핑.

결과 화면 + 파일 동시 출력 (`~/aios-bootstrap-diagnose-<host>-<ts>.txt`).

### 3.3 비-인터랙티브 (CI 등)

```bash
GH_PAT="ghp_xxx" bash <(curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh)
```

## 4. 설계 원칙

### 4.1 보안

- **PAT 노출 0 정책**:
  - bootstrap.sh: `read -s ... </dev/tty` 로 입력. bash history 노출 X.
  - aios-dev/bootstrap.sh 가 `git -c credential.helper=""` 로 macOS Keychain 저장 차단 + clone 직후 `git remote set-url` 로 PAT 제거.
  - diagnose.sh: PAT 입력은 메모리에만 보관. 함수 끝나면 `unset GH_PAT`. 로그·결과 파일에 `mask_secrets()` 자동 적용.
- **로그 파일 권한 600** (사용자만 읽기).
- **마스킹 패턴**: PAT 평문 + `gonnector:<token>@` URL + `DISCORD_BOT_TOKEN=` 등.

### 4.2 UX (Dylan 절대 규칙 2026-05-14)

> "뭔가 실행을 하고 있으면 그게 설사 터미널 UI (TUI) 환경이라고 하더라도 무슨 실행을 왜 하고 있는 지 및 현재 어떤 상태인지에 대한 정보를 화면에 보여줘야 한다."

적용:
- 모든 스크립트 시작 시점에 **무엇/왜/소요시간/사용자가 할 일** 안내 출력
- 진행 중 단계별 메시지 (silent block 금지)
- `tee` 사용 시 `>/dev/null` 로 화면 출력 막지 말 것
- PAT prompt 같은 사용자 입력 단계는 `printf >/dev/tty` 로 buffer 우회 (pipe 환경에서도 즉시 표시)
- 완료/실패 시점에 명확한 결과 + 다음 단계 안내

### 4.3 `curl | bash` 호환성

- `read` 명령은 항상 `</dev/tty` 로 직접 받기 (pipe stdin 충돌 회피)
- `set -e` 비활성 (silent exit 원인) — 명시적 `if !` + log + fail
- bash 3.2 호환 (macOS 기본 bash)

### 4.4 호환성 / 단순성

- git 버전 의존 옵션 회피 (`--filter=blob:none --sparse` 등 git 2.20+/2.25+) — full clone 으로 단순화 (용량 미미)
- macOS 기본 도구만 사용: `bash`, `zsh`, `python3`, `curl`, `git`
- Apple Silicon + Intel 양쪽 지원

## 5. 진단 로그 시스템 (2026-05-14 신설)

### 5.1 Bootstrap 측 로그 작성

aios-dev/components/onboard/bootstrap.sh 가 `~/aios-bootstrap-<YYYYMMDD_HHMMSS>.log` 에 모든 단계 기록 (SPEC: `components/onboard/docs/20260514_spec_bootstrap-logging-and-errors_TARS-MB.md`).

형식:
```
[2026-05-14T12:34:56+0900] [INFO   ] [step-id             ] message
[2026-05-14T12:34:57+0900] [SUCCESS] [step-id             ] 완료
[2026-05-14T12:35:01+0900] [ERROR  ] [clone-aios-dev      ] git clone 실패 (exit 128)
[2026-05-14T12:35:01+0900] [STDERR ] [clone-aios-dev      ] fatal: Authentication failed
[2026-05-14T12:35:01+0900] [FAIL   ] [clone-aios-dev      ] PAT 유효성 확인
```

Step ID enum (SPEC §3.3): `os-check` / `xcode-cli` / `homebrew` / `git-install` / `git-version` / `bun-install` / `cmux-install` / `wezterm-install` / `discord-install` / `pat-prompt` / `clone-aios-dev` / `remote-clean` / `bun-deps` / `skill-clone-*` / `bootstrap-complete`.

### 5.2 Diagnose 측 로그 분석

diagnose.sh §2.5 가 자동 수행:
- `~/aios-bootstrap-*.log` 가장 최근 파일 탐색
- 단계 진행 매트릭스 (각 step-id 별 ✓/✗/⚠/공백)
- 마지막 ERROR/STDERR/FAIL/WARN entries 표시
- 자동 가설 매핑 (stderr 키워드 → 권장 조치)

### 5.3 가설 매핑 규칙

| stderr 키워드 | 가설 | 권장 조치 |
|--------------|------|----------|
| `authentication failed`, `HTTP 401/403` | PAT 만료/오타 | 새 PAT 발급 |
| `repository not found`, `HTTP 404` | PAT 가 private repo 접근 권한 없음 | fine-grained PAT Selected repositories 확인 |
| `could not resolve`, `connection refused`, `timeout` | 네트워크/DNS/VPN | 네트워크 환경 확인 |
| `sparse... not a git command`, `unknown subcommand` | git 2.25 미만 | `brew install git` |
| `permission denied` | 권한 부족 | sudo/chmod |
| `disk full`, `no space left` | 디스크 부족 | df + 정리 |

새 가설 추가 시 diagnose.sh §2.5 의 `case` 분기에 추가.

## 6. 개발 워크플로우

### 6.1 commit 규칙

- prefix: `feat:` / `fix:` / `refactor:` / `docs:` / `chore:`
- 한 commit 한 의도. `git add -A` 금지 — selective add.
- 메시지: 영향 범위 + 변경 내용 + 검증 결과.

### 6.2 push 정책

- `main` 브랜치 직접 push.
- aios-dev SPEC 변경 후 본 레포 영향 있으면 함께 commit/push.

### 6.3 호환성 검증

- 새 변경 후 격리 dry-run 권장: `bash diagnose.sh </dev/null 2>&1` 로 PAT skip 케이스 확인
- `bash -n` syntax 검증 필수

## 7. 관련 문서

- **SPEC (에러 처리·로깅)**: `aios-dev/components/onboard/docs/20260514_spec_bootstrap-logging-and-errors_TARS-MB.md`
- **aios-dev onboard**: `aios-dev/components/onboard/docs/ONBOARD-MANUAL.md`
- **고객 매뉴얼**: Gonnector 측 onboarding 자료

## 8. Repo 위치

- aios-install (public, 이 repo): https://github.com/gonnector/aios-install
- aios-dev (private, SSoT): https://github.com/gonnector/aios-dev
- aios-ops (private, 예약): pilot 2+ 크로스 디바이스 sync

## 9. Copyright

© 2026 Gonnector (고영혁). MIT License.

# Changelog

All notable changes to `aios-install` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.3.1] - 2026-05-17

본 release 의 의도: LGE AX 이은영 책임 macOS 재설치 silent fail unblock (PR1).

### Fixed

- **outer bootstrap TTY 보존 (A)** — inner bootstrap 호출 패턴을 `curl … | bash` → tempfile 다운로드 후 `bash $INNER_TMP` 로 전환. 이전 파이프 패턴이 inner 의 stdin 을 closed pipe 로 만들어 Phase 2 의 @clack/prompts TUI 가 깨지던 문제 해결. 이은영 책임 재설치 silent fail 의 직접 원인.
  - tempfile: `mktemp -t aios-inner-bootstrap.XXXXXX` + `chmod 600` + `stat -f '%Lp'` 검증 + `trap 'rm -f' EXIT INT TERM`
- **outer PAT 권한 확인 silent fail 차단 (B)** — 두 버그 수정:
  - `-f` + `|| echo "000"` 조합 제거: 이전 코드는 404 응답 시 curl -f 가 종료 코드 22 + body 없음 → `-w "%{http_code}"` 캡쳐 실패 → fallback "000" 으로 손실 → 404 분기 도달 불가. `-f` 제거하여 4xx 도 정상 캡쳐.
  - `*)` 분기를 warn → fail 로 전환. 예상 외 응답에도 inner bootstrap 진입 시도하던 silent proceed 차단.
  - 신규 분기 추가: `5*)` (GitHub 서버 일시 장애 — 잠시 후 재시도 안내), `000` 명시 (네트워크 응답 없음 — 인터넷 연결 확인 안내). `5*)` 가 `*)` 보다 먼저 와야 매칭됨.

### Added

- **`mask_credentials()` 공통 함수 (C)** — bootstrap.sh helper 영역에 추가. GitHub PAT prefix (`ghp_`, `gho_`, `ghr_`, `ghu_`, `ghs_`, `github_pat_`) 패턴을 `***` 로 마스킹. fail/info/success/warn 모든 사용자 노출 출력 함수에 통합. stderr/log 평문 PAT 노출 방지.
- **`AIOS_VERBOSE` 환경변수 (D)** — `AIOS_VERBOSE=1` 부착 시 stderr 에 trace 출력. `log_verbose()` 신설 (마스킹 통과). 사용자 디버그 시 컨텍스트 확보 목적.

### Security

- PAT prefix 마스킹 패턴 6종 (ghp_ / gho_ / ghr_ / ghu_ / ghs_ / github_pat_) 일괄 처리
- tempfile 권한 600 + 종료 시 자동 삭제 (trap)

## [0.3.0] - 2026-05-14

### Changed
- **사용자 한 줄 명령 변경**: `curl … | bash` → `bash <(curl …)` (process substitution)
  - 이유: 파이프 패턴은 bash stdin = 닫힌 파이프 (EOF). Phase 2 의 @clack/prompts (TUI) 인터랙티브 prompt 가 keypress 미수신 또는 silent exit 0
  - 관측: Jinwoo 머신 (bun 1.3.14 macOS) — `< /dev/tty` / `exec 0< /dev/tty` redirect 시도해도 raw mode 미해결
  - 해결: `bash <(curl …)` 는 bash stdin = controlling terminal 유지 → exec bun 정상 TTY 상속 → 자동 진입 매끄럽게 동작
- 영향 파일: README.md / README_ko.md / bootstrap.sh 헤더 주석 / CLAUDE.md §3.1
- 호환성: bash/zsh process substitution 지원 셸 (macOS/Linux 표준 환경 100% 지원)

## [0.2.0] - 2026-05-14

본 release 의 의도: bootstrap 진단 가능성 강화 + thin wrapper 전환 + UX 명료화.

### Added

- **`diagnose.sh`** — bootstrap 진단 스크립트 (public). 사용자 한 줄 실행:
  - `curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/diagnose.sh | bash`
  - 11 섹션 자동 검사 (시스템/환경변수/네트워크/clone 상태/PAT 권한/직접 clone/sparse-checkout 호환성/자동 가설/권장 조치)
  - `~/aios-bootstrap-*.log` 자동 탐색 + 단계 진행 매트릭스 + 자동 가설 매핑
  - 결과 화면 + 파일 동시 출력 (`~/aios-bootstrap-diagnose-<host>-<ts>.txt`)
  - 토큰·비밀 자동 마스킹

- **`CLAUDE.md`** — 운영 가이드라인 (보안 정책, UX 절대 규칙, `curl | bash` 호환성 패턴, 진단 로그 시스템, 가설 매핑 규칙)

- **`CHANGELOG.md`** — Keep a Changelog 포맷 신설

### Changed

- **`bootstrap.sh`** — thin wrapper 로 전면 재작성. 이전 mirror 구조(aios-dev/bootstrap.sh 와 거의 동일한 코드 보유) 폐기:
  - 본 wrapper: PAT prompt 입력 + 권한 사전 검증 (HTTP code 분기) + aios-dev/bootstrap.sh curl 호출 + `GH_PAT` 환경변수 전달
  - 실제 설치 로직 (Prerequisites, clone, 스킬, onboard) 은 모두 aios-dev 가 SSoT
  - DRY 위반 해소 — aios-dev 갱신 시 본 wrapper 자동 반영

- **`README.md`** — 빠른 시작 명령 갱신 (`main` 브랜치 명시), 비-인터랙티브 모드 안내, 트러블슈팅 표 추가

- **UX 절대 규칙** (Dylan 2026-05-14 지시) 전 스크립트 적용:
  - 시작 시점에 "무엇을/왜 실행 중인지 + 현재 상태" 화면 출력
  - PAT prompt 는 `printf >/dev/tty` 로 pipe buffer 우회 — `curl|bash` 환경에서도 즉시 표시
  - 진단 결과를 `tee >/dev/null` 막지 말고 화면 + 파일 동시 streaming

### Fixed

- **PAT 입력 stdin 충돌** — `curl | bash` 환경에서 일반 `read` 가 pipe stdin 에서 PAT 대신 스크립트 다음 라인을 읽어 silent 진행. `read -s ... </dev/tty` 로 수정. 신규 머신 설치 정상 작동.

- **`main` vs `master` 브랜치 불일치** — README 의 raw URL 이 `master` 명시 (실제 default `main`). 사용자가 README 따라 실행 시 404. 모든 URL `main` 으로 통일.

- **diagnose.sh grep 패턴** — `[INFO   ]` 같이 공백 패딩된 level 라벨을 `\[INFO\]` 가 매칭 못해 모든 단계가 "미진입"으로 잡힘. `\[INFO[[:space:]]*\]` 패턴으로 일괄 수정.

### Security

- 마스킹 패턴 확장: PAT 평문 + `gonnector:<token>@` URL + Discord 봇 토큰 등 — 로그·결과 파일·화면 어디에도 평문 노출 0
- diagnose.sh PAT prompt 종료 후 자동 `unset GH_PAT`
- 결과 파일 권한 600 (사용자만 읽기)

## [0.1.0] - 2026-04-22 (이전)

### Added

- 초기 `bootstrap.sh` (mirror 형태 — aios-dev 의 bootstrap.sh 와 거의 동일한 코드 보유)
- `README.md` 기본 사용 안내
- `LICENSE` (MIT)
- `.gitattributes`

---

[Unreleased]: https://github.com/gonnector/aios-install/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/gonnector/aios-install/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/gonnector/aios-install/releases/tag/v0.1.0

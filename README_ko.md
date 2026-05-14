[English](README.md) | [한국어](README_ko.md)

# AIOS 설치 시작 (aios-install)

Gonnector AIOS 를 macOS 에 설치하는 public 부트스트랩.

## 빠른 시작

터미널에서 한 줄 실행:

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh | bash
```

진행 중에 GitHub PAT 입력 prompt 가 한 번 뜹니다 (입력 시 글자 비표시). 이후는 자동 진행 — Prerequisites 설치, AIOS 코드 다운로드, 온보딩 8 phase, 런처 등록까지.

## 필요한 것

- **macOS** Sonoma (14.0) 이상, Apple Silicon 또는 Intel
- **인터넷 연결**
- **GitHub PAT** — Gonnector 관리자가 현장에서 제공 (fine-grained 권장)
- **관리자 권한 계정** (Homebrew, sudo 필요)

## 설치 흐름

1. **PAT 입력 prompt** (이 스크립트) — `/dev/tty` 에서 직접 받음, `curl | bash` 환경에서도 작동
2. **PAT 권한 사전 검증** — `gonnector/aios-dev` 접근 가능성 확인 후 실패 시 즉시 안내
3. **aios-dev 의 onboard bootstrap 호출** — `GH_PAT` 환경변수로 전달, 재입력 없음
4. **Prerequisites 자동 설치** — Xcode CLI, Homebrew, Git, Bun, cmux, WezTerm, Discord Desktop
5. **aios-dev 패키지 + 핵심 스킬 다운로드** — sparse clone
6. **대화형 온보딩 8 phase** — 시스템 설정, 에이전트 프로파일링, Discord 연동, CLAUDE.md, 런처
7. **첫 실행** — `al <에이전트>` 명령으로 세션 시작

## 비-인터랙티브 모드 (자동화용)

interactive TTY 가 없는 환경(CI, 원격 자동화 등)에서는 환경변수로 PAT 전달:

```bash
GH_PAT="ghp_xxx" bash <(curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh)
```

## 보안 정책

- PAT 은 셸 메모리에만 보관 (export 후 자동 unset). bash history 노출 X
- `read -sp ... </dev/tty` 로 PAT 입력 시 화면 비표시
- 다운스트림 `aios-dev/bootstrap.sh` 가 `git -c credential.helper=""` 로 macOS Keychain 저장 차단
- clone 직후 `git remote set-url` 로 PAT 을 git config 에서 제거
- 고객 맥북에 Dylan/관리자 PAT 영구 잔존 없음

## 트러블슈팅

| 증상 | 진단 | 조치 |
|------|------|------|
| `curl: (56) ... 404` | aios-install repo 또는 브랜치 오타 | 위 명령 그대로 복사 — 브랜치는 `main` (master 아님) |
| `HTTP 404 — private repo` 메시지 | PAT 가 `gonnector/aios-dev` 접근 권한 없음 | fine-grained PAT 의 Selected repositories 에 추가, Contents: Read-only |
| `HTTP 401/403` | PAT 만료 또는 형식 오류 | 새 PAT 발급. 형식 검증 메시지 확인 |
| `interactive TTY 가 없습니다` | CI / 원격 비인터랙티브 환경 | 위 "비-인터랙티브 모드" 섹션 참조 |
| 부트스트랩 도중 sudo 실패 | 관리자 권한 없음 또는 비밀번호 오류 | 관리자 권한 계정에서 재실행 |

## uninstall

```bash
cd ~/.aios-onboard/components/onboard
bun run uninstall
```

전체 제거 시 `~/aios-backup/` 에 에이전트 memory 백업 옵션 제공.

## Repo 구조

- **aios-install** (이 repo, public) — thin bootstrap wrapper (이 파일)
- **aios-dev** (private) — onboard 코드, 스킬, 개발 중 컴포넌트, 실제 설치 로직
- **aios-ops** (private, 예약) — pilot 2+ 크로스 디바이스 sync 또는 release cycle

## Copyright

© 2026 Gonnector (고영혁). MIT License (see LICENSE).

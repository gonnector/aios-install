# AIOS 설치 시작 (aios-install)

Gonnector AIOS를 macOS에 설치하는 public 부트스트랩 스크립트.

## 빠른 시작

터미널에서 한 줄 실행:

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/master/bootstrap.sh | bash
```

또는 저장 후 실행:

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/master/bootstrap.sh -o bootstrap.sh
bash bootstrap.sh
```

## 필요한 것

- **macOS** Sonoma (14.0) 이상, Apple Silicon 또는 Intel
- **인터넷 연결**
- **GitHub PAT** — Gonnector 관리자가 현장에서 제공
- **관리자 권한 계정** (sudo 필요)

## 설치 흐름

1. **Prerequisites 자동 설치** — Xcode CLI, Homebrew, Git, Bun, cmux, WezTerm, Discord Desktop
2. **PAT 입력 프롬프트** — Gonnector 관리자가 직접 입력
3. **AIOS 온보드 패키지 + 핵심 스킬 다운로드** — aios-dev (private)에서 자동 clone
4. **대화형 온보딩 8 Phase** — 에이전트 프로파일링, Discord 연동, CLAUDE.md 생성, 런처 설치
5. **첫 실행** — `al` 런처로 에이전트 세션 시작

## 보안 정책

- PAT은 bootstrap 실행 중 **메모리에만** 보관. macOS Keychain 저장 차단 (`git -c credential.helper=""`)
- clone 직후 `git remote set-url`로 PAT을 git config에서 제거
- 고객 맥북에 Dylan/관리자 PAT 영구 잔존 없음

## uninstall

```bash
cd ~/.aios-onboard/components/onboard
bun run uninstall
```

전체 제거 시 `~/aios-backup/` 에 에이전트 memory 백업 옵션 제공.

## Repo 구조

- **aios-install** (이 repo, public) · 부트스트랩만
- **aios-dev** (private) · 온보드 코드·스킬·개발 중 컴포넌트
- **aios-ops** (private, 예약) · Pilot 2+ 크로스 디바이스 sync 또는 release cycle 용도

## Copyright

© 2026 Gonnector (고영혁). MIT License (see LICENSE).

[English](README.md) | [한국어](README_ko.md)

# AIOS Install (aios-install)

Public bootstrap for installing Gonnector AIOS on macOS.

## Quick Start

One-line install in a terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh | bash
```

A single GitHub PAT prompt appears mid-flow (characters are hidden). The script then runs automatically — installs prerequisites, downloads AIOS code, walks through the 8-phase onboarding, and registers the launcher.

## Diagnose (when bootstrap fails)

If anything goes wrong, run the public diagnose script and forward the resulting log to Gonnector:

```bash
curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/diagnose.sh | bash
```

This collects environment info, parses the most recent `~/aios-bootstrap-*.log`, verifies PAT permission, attempts a direct `git clone`, and prints an automatic hypothesis map. Result file: `~/aios-bootstrap-diagnose-<host>-<timestamp>.txt`. Secrets are masked automatically.

## Prerequisites

- **macOS** Sonoma (14.0) or later, Apple Silicon or Intel
- **Internet connection**
- **GitHub PAT** — provided on-site by the Gonnector administrator (fine-grained recommended)
- **Administrator account** (sudo needed for Homebrew)

## Install Flow

1. **PAT prompt** (this script) — read directly from `/dev/tty` so it works under `curl | bash`
2. **PAT permission pre-check** — verifies `gonnector/aios-dev` access; fails fast with a clear message
3. **Calls `aios-dev/components/onboard/bootstrap.sh`** — passes `GH_PAT` as environment variable so no re-prompt
4. **Prerequisites auto-install** — Xcode CLI, Homebrew, Git, Bun, cmux, WezTerm, Discord Desktop
5. **Sparse partial clone** — only `components/onboard/` materializes in `~/.aios-onboard` (other components stay on the server)
6. **Interactive 8-phase onboarding** — system settings, agent profiling, Discord, CLAUDE.md, launcher
7. **First run** — `al <agent>` starts a session

## Non-interactive (CI / automation)

If no interactive TTY is available, pass the PAT via environment variable:

```bash
GH_PAT="ghp_xxx" bash <(curl -fsSL https://raw.githubusercontent.com/gonnector/aios-install/main/bootstrap.sh)
```

## Security

- PAT lives in shell memory only (auto-unset on exit). No bash history exposure.
- `read -s ... </dev/tty` hides PAT keystrokes
- Downstream `aios-dev/bootstrap.sh` disables `git credential.helper` to block macOS Keychain storage
- `git remote set-url` removes PAT from git config immediately after clone
- Sparse partial clone (`--filter=blob:none` + `core.sparseCheckout`) — only `components/onboard/` is materialized; the rest of `aios-dev` stays server-side
- No PAT, token, or secret persists on the customer machine

## Troubleshooting

| Symptom | Diagnosis | Action |
|---------|-----------|--------|
| `curl: (56) ... 404` | Wrong repo or branch | Use the command exactly — branch is `main` (not `master`) |
| `HTTP 404 — private repo` | PAT lacks `gonnector/aios-dev` access | Add to fine-grained PAT's Selected repositories with `Contents: Read-only` |
| `HTTP 401/403` | PAT expired or malformed | Issue a new PAT |
| `interactive TTY not available` | CI / remote automation | See "Non-interactive" section above |
| sudo failure during bootstrap | No admin privileges | Re-run from an admin account |
| Bootstrap silently exits | Old log present | Run `diagnose.sh` — auto-detects stage and proposes a fix |

## Uninstall

```bash
cd ~/.aios-onboard/components/onboard
bun run uninstall
```

Optionally backs up agent memory to `~/aios-backup/` before full removal.

## Repository Layout

- **aios-install** (this repo, public) — thin bootstrap wrapper + diagnose tool
- **aios-dev** (private) — onboard code, skill repos, all active components; full IP. SSoT.
- **aios-ops** (private, reserved) — pilot 2+ cross-device sync / release cycle

The wrapper here intentionally contains no install logic — `aios-dev` is the single source of truth. Updating onboarding behavior in `aios-dev` is automatically reflected through this public entry point.

## Documentation

- Operations guide for this repo: [`CLAUDE.md`](CLAUDE.md)
- Version history: [`CHANGELOG.md`](CHANGELOG.md)
- Logging & error-handling spec: `aios-dev/components/onboard/docs/20260514_spec_bootstrap-logging-and-errors_TARS-MB.md` (private)

## Copyright

© 2026 Gonnector (고영혁). MIT License — see [`LICENSE`](LICENSE).

# hmini-devenv-setting

hmini(macOS, 24시간 가동)에서 Claude Code와 Codex 에이전트 팀을 굴리기 위한 설정 키트입니다.
전체 플랜은 [구축 플랜 문서](https://claude.ai/artifact/1Z6aJjQtJXLV5wYBkG2jAx)에 있고, 이 저장소는 그 플랜을 따라 할 때 쓰는 스크립트와 템플릿을 모아 둡니다.

## 구성

| 역할 | 담당 | 이 저장소의 파일 |
|---|---|---|
| 리더 | Claude Code 메인 세션 (tmux 상시 + Remote Control) | `scripts/start-lead.sh`, `scripts/launchd/` |
| 구현 | Claude 서브에이전트 (백엔드, 프론트 분리) | `templates/.claude/agents/backend-dev.md`, `frontend-dev.md` |
| 리뷰 | Codex 플러그인 + Claude 읽기 전용 리뷰어 | `templates/.claude/agents/reviewer.md`, `templates/.codex/agents/reviewer.toml` |
| 검증 | Stop 훅에서 테스트 실행 | `templates/.claude/hooks/run-tests.sh` |
| 작업 큐 | GitHub Issues + Claude Code GitHub Actions | `templates/.github/workflows/` |
| 인계 | 공유 문서 | `templates/AGENTS.md`, `CLAUDE.md`, `STATUS.md` |

## 두 층의 설정

| 층 | 위치 | 적용 범위 | 설치 |
|---|---|---|---|
| 기본 설정 (Default Setting) | `defaults/` | hmini의 모든 프로젝트 (`~/.claude`, `~/.codex`) | `scripts/install-defaults.sh` |
| 프로젝트 템플릿 | `templates/` | 앱 저장소 하나 (FastAPI + Vue 예시) | `scripts/install-templates.sh <저장소>` |

프로젝트 쪽 `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`이 기본 설정보다 우선합니다.
기본 설정은 심볼릭 링크로 연결되므로 이 저장소의 `defaults/`를 고치고 푸시하면 그대로 기본값이 됩니다.

```
defaults/
  AGENTS.md               # 공통 규칙 원본. ~/.codex/AGENTS.md로 링크, ~/.claude/CLAUDE.md가 import
  claude/CLAUDE.md        # Claude 전용 기본 규칙 -> ~/.claude/CLAUDE.md
  claude/agents/          # 전역 서브에이전트 -> ~/.claude/agents/
  claude/hooks/           # 전역 훅 -> ~/.claude/hooks/ (.env.confidential 차단)
  claude/settings.base.json  # ~/.claude/settings.json에 합칠 permissions.deny와 hooks
  codex/agents/           # Codex 전역 서브에이전트 -> ~/.codex/agents/
scripts/
  check-prereqs.sh        # 1단계: 필요한 도구, 절전 설정 점검 (아무것도 바꾸지 않음)
  install-defaults.sh     # 3단계: 기본 설정 연결 (--dry-run, --restore, 기존 파일 백업)
  install-plugins.sh      # 3-2단계: 기본 플러그인, skill, MCP 전역 설치 (--dry-run)
  start-lead.sh           # 3단계: tmux에 리더 세션 띄우기
  install-templates.sh    # 4~8단계: 앱 저장소에 템플릿 복사 (기존 파일은 덮어쓰지 않음)
  launchd/com.hmini.claude-lead.plist  # 재부팅 후 리더 세션 자동 시작 (선택)
templates/                # 앱 저장소 루트에 복사할 파일
```

## 진행 체크리스트

각 단계의 자세한 설명은 플랜 문서를 따릅니다. 표시된 명령은 사용자가 hmini에서 직접 실행합니다.

- [ ] **1. hmini 기본 준비**
  - 시스템 설정 > 에너지에서 잠자기 방지, 정전 후 자동 시작 켜기
  - `brew install tmux git gh node` 후 `gh auth login`
  - `./scripts/check-prereqs.sh` 가 모두 OK
- [ ] **2. 앱 설치와 로그인**: Claude 데스크톱 앱, Codex Mac 앱, VS Code(+ Claude Code, Codex 확장), Codex CLI. 폰에 Claude 앱, ChatGPT 앱
- [ ] **3. 기본 설정 (Default Setting)**
  - `./scripts/install-defaults.sh --dry-run`으로 바뀔 내용 확인 후 `./scripts/install-defaults.sh`
  - 새 Claude 세션에서 `/memory`에 `~/.claude/CLAUDE.md`, `/agents`에 `reviewer`가 보이는지 확인
  - 새 Codex 세션에서 기본 규칙(한국어 응답 등)이 적용되는지 확인
- [ ] **3-2. 기본 플러그인**: `./scripts/install-plugins.sh` (사용자가 직접 실행)
  - Claude: superpowers, pyright-lsp, typescript-lsp, context7, security-guidance, frontend-design, codex (모두 공식 마켓플레이스)
  - Codex: superpowers, codex-security, Context7 MCP
  - 공용: FastAPI 공식 skill (`npx skills`)
  - LSP 플러그인용 언어 서버: `pyright`, `typescript-language-server` (npm 전역)
  - 설치 후 새 세션에서 `/context`로 토큰 부담 확인. superpowers는 작은 작업에 executing-plans 경로가 저렴함
- [ ] **3-1. 상시 리더 세션**
  - Claude Code `/config`에서 Remote Control을 모든 세션에 켜고 푸시 알림 켜기
  - `./scripts/start-lead.sh ~/claude-workspace/<앱저장소>` 실행 후 폰 Claude 앱 Code 탭에서 세션 확인
  - Claude 데스크톱 앱에서 한도 리셋 후 자동 계속 켜기 (세션 한도만 적용)
  - Codex 앱 설정 > Connections QR을 폰 ChatGPT 앱으로 스캔
- [ ] **4~5. 앱 저장소에 템플릿 적용**
  - `./scripts/install-templates.sh ~/claude-workspace/<앱저장소>`
  - `AGENTS.md`의 명령과 폴더 구조를 프로젝트에 맞게 수정
  - 새 Claude 세션에서 `/agents`에 세 에이전트가 보이는지 확인
  - `/sandbox` 켜기
- [ ] **6. Codex 연동**: Claude Code에서 아래를 차례로 실행
  ```
  /plugin marketplace add openai/codex-plugin-cc
  /plugin install codex@openai-codex
  /reload-plugins
  /codex:setup
  ```
  그다음 작은 변경으로 `/codex:review` 확인
- [ ] **7. 목표 단위 실행**: 예시
  ```
  /goal 회원가입 API와 Vue 폼을 만들고 pytest와 npm test가 0으로 끝나며 /codex:review 지적이 없을 때까지. 20턴 넘으면 멈추고 STATUS.md에 정리
  ```
- [ ] **8. 작업 큐**
  - Claude Code에서 `/install-github-app`
  - `claude setup-token`으로 만든 토큰을 앱 저장소 시크릿 `CLAUDE_CODE_OAUTH_TOKEN`에 등록
  - 폰에서 이슈에 `@claude`를 달아 PR이 생기는지 확인
- [ ] **9. 정기 작업 (선택)**: 데스크톱 앱 예약 작업 또는 `/schedule`
- [ ] **10. 확장 (필요할 때만)**: Agent Teams(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), Claude Code Projects 베타

## 비밀값: `.env`와 `.env.confidential`

- `.env`: 비밀이 아닌 설정. 에이전트가 읽을 수 있습니다.
- `.env.confidential`: API 키, 토큰 같은 비밀값. 전역 gitignore에 들어가고, Claude Code에서는 `block-confidential.sh` 훅이 이 파일 이름이 들어간 모든 도구 호출(Read, Edit, Bash 등)을 막습니다.
- 키 이름은 `.env.confidential.example`에 값 없이 적어 커밋합니다.
- 훅은 파일 경로, 검색 패턴, Bash 명령만 검사합니다. 문서 본문에 이 파일 이름을 적는 것은 막지 않습니다. 다만 Bash 명령에 이름이 들어가면(예: `grep`으로 이름 찾기) 막힙니다.
- 한계: 훅은 파일 이름을 보고 막으므로, 파일 이름 없이 읽는 코드(예: 앱을 실행해 값을 출력)까지 막지는 못합니다. Codex에는 같은 훅이 없어 `AGENTS.md` 규칙으로만 지킵니다.

## 되돌리기

- 기본 설정 파일은 이 저장소의 커밋으로 관리하므로 `git revert`로 되돌리면 링크를 통해 바로 반영됩니다.
- 전역 설치 자체를 걷어 내려면 `./scripts/install-defaults.sh --restore`. 링크를 지우고 파일마다 첫 설치 전 백업(`~/.hmini-defaults/backup/`)으로 되돌립니다.

## 주의

- auto mode에서는 Claude가 자기 `settings.json`을 고치지 못하므로 `install-defaults.sh`, `install-templates.sh`와 설정 변경은 직접 실행합니다.
- 앱 저장소는 `~/claude-workspace/<앱저장소>`에 둡니다.
- Pro 한도는 5시간 창과 주간 한도가 있습니다. 리더는 Opus, 구현과 리뷰는 Sonnet으로 나눴습니다.
- `/goal`에는 항상 턴 상한을 둡니다.
- 명령과 메뉴 이름은 2026-11 리서치 기준입니다. 설치할 때 공식 문서와 한 번 더 맞춰 봅니다.

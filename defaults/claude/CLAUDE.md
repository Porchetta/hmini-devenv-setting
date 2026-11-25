@~/claude-workspace/hmini-devenv-setting/defaults/AGENTS.md

# Claude 전용 기본 규칙

이 파일은 `hmini-devenv-setting/defaults/claude/CLAUDE.md`가 원본이고, `~/.claude/CLAUDE.md`는 이 파일을 가리키는 링크입니다.

- 큰 작업은 계획을 먼저 세우고, 서로 독립적인 부분만 서브에이전트에 나눠 맡깁니다. 서브에이전트는 이 대화를 모르므로 목표, 맡을 범위, 완료 조건을 프롬프트에 직접 적습니다.
- 변경을 마친 뒤에는 `reviewer` 서브에이전트로 읽기 전용 리뷰를 받고, Codex 플러그인이 있으면 `/codex:review`도 돌립니다.
- 긴 작업을 `/goal`로 돌릴 때는 항상 턴 상한을 둡니다. 예: `... 20턴 넘으면 멈추고 STATUS.md에 정리`
- auto mode에서는 `~/.claude/settings.json`을 직접 고치지 못합니다. 전역 설정 변경은 `hmini-devenv-setting/defaults/`의 파일을 고친 뒤 사용자에게 `scripts/install-defaults.sh` 실행을 안내합니다.

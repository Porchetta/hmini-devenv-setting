#!/usr/bin/env bash
# 기본 플러그인, skill, MCP를 Claude Code와 Codex에 전역 설치한다. 이미 있는 것은 건너뛴다.
# 목록의 근거: 개발용 Skill·Plugin 리서치 (2026-11) 문서의 "꼭 깔 것" + frontend-design
# 사용법: install-plugins.sh [--dry-run]
set -uo pipefail

dry=0; [ "${1:-}" = "--dry-run" ] && dry=1
run() { echo "+ $*"; [ "$dry" -eq 1 ] || "$@"; }
fail=0
step() { "$@" || { echo "  실패: $*" >&2; fail=1; }; }

# ---------- Claude Code 플러그인 (전부 Anthropic 공식 마켓플레이스) ----------
CLAUDE_PLUGINS=(
  superpowers@claude-plugins-official
  pyright-lsp@claude-plugins-official
  typescript-lsp@claude-plugins-official
  context7@claude-plugins-official
  security-guidance@claude-plugins-official
  frontend-design@claude-plugins-official
  codex@openai-codex
)

# ---------- Codex 플러그인 (OpenAI 큐레이션 마켓플레이스) ----------
CODEX_PLUGINS=(
  superpowers@openai-curated-remote
  codex-security@openai-curated-remote
)

# ---------- LSP 플러그인이 부르는 언어 서버 ----------
NPM_GLOBALS=(pyright typescript typescript-language-server)

echo "== LSP 언어 서버 (npm -g)"
for pkg in "${NPM_GLOBALS[@]}"; do
  if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then echo "그대로: $pkg"; else step run npm install -g "$pkg"; fi
done

echo "== Claude Code 플러그인"
grep -q 'openai-codex' <(claude plugin marketplace list 2>/dev/null) || step run claude plugin marketplace add openai/codex-plugin-cc
installed=$(claude plugin list 2>/dev/null)
for p in "${CLAUDE_PLUGINS[@]}"; do
  if grep -qF "$p" <<<"$installed"; then echo "그대로: $p"; else step run claude plugin install "$p" --scope user; fi
done

echo "== Codex 플러그인"
codex_list=$(codex plugin list 2>/dev/null)
for p in "${CODEX_PLUGINS[@]}"; do
  if grep -E "^${p//./\\.}[[:space:]]+installed" <<<"$codex_list" >/dev/null; then echo "그대로: $p"; else step run codex plugin add "$p"; fi
done

echo "== Codex MCP: Context7"
if codex mcp list 2>/dev/null | grep -q '^context7 '; then echo "그대로: context7"; else step run codex mcp add context7 -- npx -y @upstash/context7-mcp@latest; fi

echo "== FastAPI 공식 skill (Claude Code와 Codex 공용)"
step run npx -y skills add fastapi/fastapi --skill fastapi -g -y

echo
if [ "$fail" -ne 0 ]; then
  echo "일부 단계가 실패했습니다. 위 '실패' 줄을 확인하세요."; exit 1
fi
[ "$dry" -eq 1 ] && echo "dry-run이라 아무것도 설치하지 않았습니다." || echo "완료. 새 Claude 세션에서 /plugin, /context로 확인하세요."

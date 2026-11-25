#!/usr/bin/env bash
# Claude Code PreToolUse 훅: 비밀값 파일(.env.confidential)에 닿는 도구 호출을 막는다.
# Read, Edit, Write, Grep, Glob, Bash 등 모든 도구의 입력에서 파일 이름을 찾는다.
# 예시 파일(.env.confidential.example)은 허용한다.
# exit 2를 내면 Claude Code가 호출을 막고 stderr를 Claude에게 보여 준다.
set -uo pipefail

input=$(cat)
tool_input=$(printf '%s' "$input" | jq -c '.tool_input // {}' 2>/dev/null || printf '%s' "$input")

if printf '%s' "$tool_input" | grep -Eq '\.env\.confidential($|[^.A-Za-z0-9_-]|\.[^e]|\.e[^x])'; then
  echo "차단: .env.confidential은 비밀값 파일이라 읽거나 고치거나 명령에 쓸 수 없습니다. 필요한 키 이름은 .env.confidential.example에서 확인하세요." >&2
  exit 2
fi
exit 0

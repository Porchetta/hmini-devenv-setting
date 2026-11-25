#!/usr/bin/env bash
# Claude Code PreToolUse 훅: 비밀값 파일(.env 뒤에 confidential이 붙은 파일)에 닿는 도구 호출을 막는다.
# 파일 경로, 검색 패턴, Bash 명령만 검사한다. 문서 본문(Write/Edit 내용)에 파일 이름이 나오는 것은 허용한다.
# 예시 파일(...confidential.example)은 허용한다.
# exit 2를 내면 Claude Code가 호출을 막고 stderr를 Claude에게 보여 준다.
set -uo pipefail

secret_name='.env''.confidential'

input=$(cat)
targets=$(printf '%s' "$input" | jq -r '
  .tool_input // {}
  | [.file_path, .path, .notebook_path, .pattern, .glob, .command]
  | map(select(type == "string")) | join("\n")' 2>/dev/null) || targets=$input

if printf '%s' "$targets" | grep -Eq '\.env\.confidential($|[^.A-Za-z0-9_-]|\.[^e]|\.e[^x])'; then
  echo "차단: ${secret_name}은 비밀값 파일이라 읽거나 고치거나 명령에 쓸 수 없습니다. 필요한 키 이름은 ${secret_name}.example에서 확인하세요." >&2
  exit 2
fi
exit 0

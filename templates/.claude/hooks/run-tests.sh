#!/usr/bin/env bash
# Claude Code Stop 훅: 세션이 멈추기 전에 테스트를 돌린다.
# 실패하면 exit 2로 끝내 Claude가 멈추지 않고 실패 내용을 보고 고치게 한다.
# 변경된 파일이 없거나, 이미 훅 때문에 계속 중인 경우(stop_hook_active)는 통과시킨다.
set -uo pipefail

input=$(cat)
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
cd "$root" || exit 0

# 작업 트리에 변경이 없으면 테스트를 건너뛴다.
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
log=$(mktemp)
failed=0

if printf '%s\n' "$changed" | grep -q '^backend/' && [ -d backend ]; then
  (cd backend && uv run pytest -q) >"$log.be" 2>&1
  rc=$?
  # pytest exit 5 = 수집된 테스트 없음. 실패로 보지 않는다.
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 5 ]; then
    failed=1
    { echo "== backend pytest 실패"; tail -n 60 "$log.be"; } >>"$log"
  fi
fi

if printf '%s\n' "$changed" | grep -q '^frontend/' && [ -d frontend ]; then
  if ! (cd frontend && npm test --silent -- --run) >"$log.fe" 2>&1; then
    failed=1
    { echo "== frontend test 실패"; tail -n 60 "$log.fe"; } >>"$log"
  fi
fi

if [ "$failed" -ne 0 ]; then
  cat "$log" >&2
  echo "테스트가 실패했습니다. 원인을 고치고 다시 테스트하세요." >&2
  rm -f "$log" "$log.be" "$log.fe"
  exit 2
fi

rm -f "$log" "$log.be" "$log.fe"
exit 0

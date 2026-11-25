#!/usr/bin/env bash
# Claude Code Stop 훅: 세션이 멈추기 전에 테스트를 돌린다.
# 실패하면 exit 2로 끝내 Claude가 멈추지 않고 실패 내용을 보고 고치게 한다.
# 변경된 파일이 없으면 통과시킨다.
set -uo pipefail

# 훅 때문에 다시 멈추려 할 때도 테스트를 다시 돌린다. 무한 루프는 세션별 연속 실패 3회로 막는다.
MAX_BLOCKS=3
input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)
counter="${TMPDIR:-/tmp}/claude-stop-tests-${session}"

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
  if [ "$rc" -ne 0 ]; then  # exit 5(수집된 테스트 없음)도 실패로 본다
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
  rm -f "$log" "$log.be" "$log.fe"
  blocks=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
  echo "$blocks" >"$counter"
  if [ "$blocks" -gt "$MAX_BLOCKS" ]; then
    echo "테스트가 ${MAX_BLOCKS}번 연속 실패해 더는 막지 않습니다. STATUS.md에 실패 내용을 적고 사람에게 알리세요." >&2
    rm -f "$counter"
    exit 0
  fi
  echo "테스트가 실패했습니다. 원인을 고치고 다시 테스트하세요. (${blocks}/${MAX_BLOCKS})" >&2
  exit 2
fi

rm -f "$log" "$log.be" "$log.fe" "$counter"
exit 0

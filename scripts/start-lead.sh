#!/usr/bin/env bash
# tmux에 Claude Code 리더 세션을 띄운다. 이미 있으면 아무것도 하지 않는다.
# 사용법: start-lead.sh <작업 폴더> [세션 이름]
# Remote Control은 /config에서 "모든 세션에 켜기"를 해 두면 자동으로 붙는다.
set -euo pipefail

workdir=${1:?작업 폴더를 지정하세요. 예: start-lead.sh ~/claude-workspace/myapp}
session=${2:-lead}

if [ ! -d "$workdir" ]; then
  echo "폴더가 없습니다: $workdir" >&2
  exit 1
fi

if tmux has-session -t "$session" 2>/dev/null; then
  echo "tmux 세션 '$session'이 이미 실행 중입니다. 접속: tmux attach -t $session"
  exit 0
fi

tmux new-session -d -s "$session" -c "$workdir" "claude"
echo "tmux 세션 '$session' 시작 ($workdir). 접속: tmux attach -t $session"

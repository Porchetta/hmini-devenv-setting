#!/usr/bin/env bash
# hmini 사전 점검. 아무것도 설치하거나 바꾸지 않고 상태만 출력한다.
set -u

ok()   { printf '  OK    %s\n' "$1"; }
warn() { printf '  WARN  %s\n' "$1"; FAILED=1; }
FAILED=0

echo "== 명령줄 도구"
for cmd in brew git gh tmux node npm claude codex; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd ($(command -v "$cmd"))"
  else
    warn "$cmd 없음"
  fi
done

if command -v node >/dev/null 2>&1; then
  node_ver=$(node -p 'process.versions.node')
  major=${node_ver%%.*}
  minor=$(echo "$node_ver" | cut -d. -f2)
  if [ "$major" -gt 18 ] || { [ "$major" -eq 18 ] && [ "$minor" -ge 18 ]; }; then
    ok "node $node_ver (18.18 이상)"
  else
    warn "node $node_ver: codex 플러그인은 18.18 이상 필요"
  fi
fi

echo "== GitHub 로그인"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  ok "gh auth"
else
  warn "gh auth login 필요"
fi

echo "== 절전 설정 (macOS)"
if command -v pmset >/dev/null 2>&1; then
  sleep_val=$(pmset -g | awk '$1=="sleep"{print $2; exit}')
  if [ "${sleep_val:-}" = "0" ]; then
    ok "시스템 잠자기 꺼짐"
  else
    warn "시스템 잠자기 값: ${sleep_val:-알 수 없음} (시스템 설정 > 에너지에서 잠자기 방지 켜기)"
  fi
  autorestart=$(pmset -g | awk '$1=="autorestart"{print $2; exit}')
  if [ "${autorestart:-}" = "1" ]; then
    ok "정전 후 자동 시작 켜짐"
  else
    warn "정전 후 자동 시작 꺼짐 또는 확인 불가"
  fi
else
  warn "pmset 없음 (macOS가 아님)"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "모두 OK"
else
  echo "WARN 항목을 확인하세요"
fi
exit "$FAILED"

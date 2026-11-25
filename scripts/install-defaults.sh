#!/usr/bin/env bash
# 모든 프로젝트에 적용되는 기본 설정(defaults/)을 사용자 전역 위치에 연결한다.
# - 문서, 에이전트, 훅 파일은 심볼릭 링크로 연결한다. 저장소에서 고치면 바로 반영된다.
# - ~/.claude/settings.json은 기존 값을 유지한 채 permissions.deny와 hooks만 합친다.
#   이전 설치에서 넣었다가 defaults에서 빠진 deny 항목은 지운다(~/.hmini-defaults/managed.json 기준).
# - 전역 gitignore에 .env.confidential을 추가한다.
# - 바꾸기 전 기존 파일은 ~/.hmini-defaults/backup/<시각>/ 에 백업한다.
# 사용법: install-defaults.sh [--dry-run | --restore]
#   --restore: 이 스크립트가 만든 링크를 지우고, 파일마다 첫 설치 전 백업으로 되돌린다.
set -euo pipefail

mode=${1:-install}
case "$mode" in install|--dry-run|--restore) ;; *) echo "사용법: $0 [--dry-run | --restore]" >&2; exit 1;; esac
dry=0; [ "$mode" = "--dry-run" ] && dry=1

repo="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo/defaults"
state="$HOME/.hmini-defaults"
backup_root="$state/backup"
managed="$state/managed.json"
settings="$HOME/.claude/settings.json"
gitignore="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"

command -v jq >/dev/null || { echo "jq가 필요합니다" >&2; exit 1; }

# 설치 대상: "원본|목적지"
targets=("$src/claude/CLAUDE.md|$HOME/.claude/CLAUDE.md" "$src/AGENTS.md|$HOME/.codex/AGENTS.md")
for f in "$src"/claude/agents/*.md;  do targets+=("$f|$HOME/.claude/agents/$(basename "$f")"); done
for f in "$src"/claude/hooks/*.sh;   do targets+=("$f|$HOME/.claude/hooks/$(basename "$f")"); done
for f in "$src"/codex/agents/*.toml; do targets+=("$f|$HOME/.codex/agents/$(basename "$f")"); done

# ---------- 복구 ----------
if [ "$mode" = "--restore" ]; then
  # 파일마다 가장 오래된 백업(첫 설치 전 상태)으로 되돌린다.
  for t in "${targets[@]}"; do
    from=${t%%|*}; to=${t#*|}
    if [ -L "$to" ] && [ "$(readlink "$to")" = "$from" ]; then rm "$to"; echo "링크 삭제: $to"; fi
  done
  restored=" "
  for dir in $(ls -1d "$backup_root"/*/ 2>/dev/null | sort); do
    while read -r rel; do
      dest="/${rel#./}"
      case "$restored" in *" $dest "*) continue;; esac
      mkdir -p "$(dirname "$dest")"
      cp -P "$dir/${rel#./}" "$dest"
      restored="$restored$dest "
      echo "복구: $dest"
    done < <(cd "$dir" && find . \( -type f -o -type l \) -print)
  done
  [ "$restored" = " " ] && echo "백업이 없어 링크만 지웠습니다."
  rm -f "$managed"
  echo "전역 gitignore의 .env.confidential 줄은 남겨 두었습니다: $gitignore"
  exit 0
fi

# ---------- 사전 검사: 아무것도 바꾸기 전에 settings.json을 검사하고 병합 결과를 만든다 ----------
current='{}'
if [ -f "$settings" ]; then
  if ! jq -e . "$settings" >/dev/null 2>&1; then
    echo "중단: $settings 가 올바른 JSON이 아닙니다. 고친 뒤 다시 실행하세요." >&2
    exit 1
  fi
  current=$(jq . "$settings")
fi
prev_managed='[]'
[ -f "$managed" ] && prev_managed=$(jq -c '.deny // []' "$managed")

merged=$(jq -n --argjson cur "$current" --argjson prev "$prev_managed" \
  --slurpfile base "$src/claude/settings.base.json" '
  ($base[0]) as $b
  | $cur
  | .permissions = ((.permissions // {}) as $p
      | $p + {deny: ((($p.deny // []) - $prev + ($b.permissions.deny // [])) | unique)})
  | .hooks = ((.hooks // {}) as $h
      | reduce (($b.hooks // {}) | to_entries[]) as $e ($h;
          .[$e.key] = (((.[$e.key] // []) as $cur_list
            | ($e.value | map(.hooks[].command)) as $cmds
            | $cur_list | map(select((.hooks // []) | map(.command) | any(. as $c | $cmds | index($c)) | not)))
            + $e.value)))
')

backup_dir="$backup_root/$(date +%Y%m%d-%H%M%S)-$$"
run() { if [ "$dry" -eq 1 ]; then echo "  (dry-run) $*"; else "$@"; fi; }
backup_file() {
  local path=$1
  if [ -e "$path" ] || [ -L "$path" ]; then
    run mkdir -p "$backup_dir$(dirname "$path")"
    run cp -P "$path" "$backup_dir$path"
  fi
}

echo "== 링크"
for t in "${targets[@]}"; do
  from=${t%%|*}; to=${t#*|}
  if [ -L "$to" ] && [ "$(readlink "$to")" = "$from" ]; then echo "그대로: $to"; continue; fi
  backup_file "$to"
  run mkdir -p "$(dirname "$to")"
  run ln -sfn "$from" "$to"
  echo "연결: $to -> $from"
done

echo "== $settings"
if [ "$merged" = "$current" ]; then
  echo "그대로"
else
  diff <(echo "$current") <(echo "$merged") || true
  backup_file "$settings"
  if [ "$dry" -eq 0 ]; then
    mkdir -p "$(dirname "$settings")"
    printf '%s\n' "$merged" >"$settings.tmp" && mv "$settings.tmp" "$settings"
    mkdir -p "$state"
    jq '{deny: .permissions.deny}' "$src/claude/settings.base.json" >"$managed"
  fi
  echo "갱신 (permissions.deny, hooks 합침)"
fi

echo "== 전역 gitignore ($gitignore)"
if [ -f "$gitignore" ] && grep -qxF '.env.confidential' "$gitignore"; then
  echo "그대로"
else
  if [ "$dry" -eq 0 ]; then
    mkdir -p "$(dirname "$gitignore")"
    printf '.env.confidential\n' >>"$gitignore"
  fi
  echo "추가: .env.confidential"
fi

echo
if [ "$dry" -eq 1 ]; then
  echo "dry-run이라 아무것도 바꾸지 않았습니다."
else
  [ -d "$backup_dir" ] && echo "백업: $backup_dir (되돌리기: $0 --restore)"
  echo "완료. 새 Claude 세션에서 /memory, /agents, /hooks를, 새 Codex 세션에서 기본 규칙을 확인하세요."
fi

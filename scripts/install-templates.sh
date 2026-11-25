#!/usr/bin/env bash
# templates/ 아래 파일을 앱 저장소에 복사한다. 이미 있는 파일은 건너뛴다.
# .claude/settings.example.json은 .claude/settings.json이 없을 때만 그 이름으로 복사한다.
# 사용법: install-templates.sh <앱 저장소 경로>
set -euo pipefail

target=${1:?앱 저장소 경로를 지정하세요}
src="$(cd "$(dirname "$0")/.." && pwd)/templates"

if [ ! -d "$target/.git" ]; then
  echo "git 저장소가 아닙니다: $target" >&2
  exit 1
fi

copied=0; skipped=0
while IFS= read -r -d '' file; do
  rel=${file#"$src/"}
  dest="$target/$rel"
  if [ "$rel" = ".claude/settings.example.json" ]; then
    dest="$target/.claude/settings.json"
  fi
  if [ -e "$dest" ]; then
    echo "건너뜀 (이미 있음): ${dest#"$target/"}"
    skipped=$((skipped + 1))
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  echo "복사: ${dest#"$target/"}"
  copied=$((copied + 1))
done < <(find "$src" -type f -print0)

chmod +x "$target/.claude/hooks/run-tests.sh" 2>/dev/null || true
echo "완료: 복사 $copied, 건너뜀 $skipped"
echo "다음: AGENTS.md의 명령과 폴더를 프로젝트에 맞게 고치고, 새 Claude 세션에서 /agents를 확인하세요."

#!/usr/bin/env bash
# Copies the agent team template into a project. Never overwrites existing files,
# so project-specific edits (CLAUDE.md commands, tuned agents) survive a re-run.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/template" && pwd)"
dest="$(cd "${1:-.}" && pwd)"

if ! git -C "$dest" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error: $dest is not inside a git repo" >&2
  exit 1
fi

added=0
skipped=0
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"
  target="$dest/$rel"
  if [[ -e "$target" ]]; then
    echo "skip   $rel (already exists, merge by hand)"
    skipped=$((skipped + 1))
  else
    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
    echo "added  $rel"
    added=$((added + 1))
  fi
done < <(find "$src" -type f -print0)

echo "$added added, $skipped skipped"

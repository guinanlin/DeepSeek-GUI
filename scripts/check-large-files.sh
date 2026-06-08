#!/usr/bin/env bash
# Fail if tracked or staged files exceed the size limit (default 5 MiB).
set -euo pipefail

LIMIT_BYTES="${LIMIT_BYTES:-5242880}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

check_paths() {
  local label="$1"
  shift
  while IFS= read -r -d '' file; do
    [[ -f "$file" ]] || continue
    local size
    size="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")"
    if (( size > LIMIT_BYTES )); then
      printf 'ERROR: %s file too large (%s bytes): %s\n' "$label" "$size" "$file" >&2
      fail=1
    fi
  done
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    check_paths "tracked" "$file"
  done < <(git ls-files -z)
fi

if (( fail != 0 )); then
  printf 'Large files bloat git history. Compress media, use Git LFS, or host demos externally.\n' >&2
  exit 1
fi

printf 'OK: no tracked files over %s bytes.\n' "$LIMIT_BYTES"

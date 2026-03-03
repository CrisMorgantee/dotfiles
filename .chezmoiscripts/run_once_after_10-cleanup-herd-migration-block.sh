#!/bin/sh
set -eu

# Remove redundant Herd migration block (once).

ZLOCAL="${HOME}/.zshrc.local"

MARK_BEGIN="# ---- BEGIN: Herd injected exports (migrated by chezmoi) ----"
MARK_END="# ---- END: Herd injected exports ----"

[ -f "$ZLOCAL" ] || exit 0

grep -Fq "$MARK_BEGIN" "$ZLOCAL" || exit 0
grep -Fq "$MARK_END" "$ZLOCAL" || exit 0

if awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
  $0==b {inside=1; next}
  $0==e {inside=0; next}
  !inside && $0 ~ /^export[[:space:]]+HERD_[A-Z0-9_]+=/{found=1}
  END{exit(found?0:1)}
' "$ZLOCAL"; then
  tmp="${ZLOCAL}.tmp.$$"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    !skip {print}
  ' "$ZLOCAL" >"$tmp"
  mv "$tmp" "$ZLOCAL"
fi

exit 0


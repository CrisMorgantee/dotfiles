#!/bin/sh
set -eu

# Move Herd-injected exports from ~/.zshrc to ~/.zshrc.local (once).

ZSHRC="${HOME}/.zshrc"
ZLOCAL="${HOME}/.zshrc.local"

MARK_BEGIN="# ---- BEGIN: Herd injected exports (migrated by chezmoi) ----"
MARK_END="# ---- END: Herd injected exports ----"

if [ ! -f "$ZSHRC" ]; then
  exit 0
fi

# If already migrated, do nothing (idempotent).
if [ -f "$ZLOCAL" ] && grep -Fq "$MARK_BEGIN" "$ZLOCAL"; then
  exit 0
fi

# If ~/.zshrc.local already contains Herd exports, don't migrate to avoid duplicates.
if [ -f "$ZLOCAL" ] && grep -Eq '^export[[:space:]]+HERD_[A-Z0-9_]+=' "$ZLOCAL"; then
  exit 0
fi

# Extract Herd export lines from current ~/.zshrc (if any).
HERD_EXPORTS="$(grep -E '^export[[:space:]]+HERD_[A-Z0-9_]+=' "$ZSHRC" || true)"
if [ -z "$HERD_EXPORTS" ]; then
  exit 0
fi

if [ ! -f "$ZLOCAL" ]; then
  {
    printf '%s\n' "# ~/.zshrc.local"
    printf '%s\n' "# Machine-specific overrides (NOT versioned)."
    printf '\n'
  } >"$ZLOCAL"
fi

{
  printf '\n%s\n' "$MARK_BEGIN"
  printf '%s\n' "$HERD_EXPORTS"
  printf '%s\n' "$MARK_END"
} >>"$ZLOCAL"

exit 0


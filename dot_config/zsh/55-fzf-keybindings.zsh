[[ -o interactive ]] || return 0

command -v fzf >/dev/null 2>&1 || return 0

__fzf_source_keybindings() {
  emulate -L zsh

  local script="${1:-}"
  [[ -n "$script" ]] || return 1
  [[ -r "$script" ]] || return 1

  source "$script"
  return 0
}

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  __fzf_source_keybindings "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" && return 0
fi

if command -v brew >/dev/null 2>&1; then
  hb="$(brew --prefix 2>/dev/null || true)"
  [[ -n "$hb" ]] && __fzf_source_keybindings "$hb/opt/fzf/shell/key-bindings.zsh" && return 0
fi

__fzf_source_keybindings "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" && return 0
__fzf_source_keybindings "/usr/local/opt/fzf/shell/key-bindings.zsh" && return 0


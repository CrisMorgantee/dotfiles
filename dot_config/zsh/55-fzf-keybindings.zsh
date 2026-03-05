[[ -o interactive ]] || return 0

command -v fzf >/dev/null 2>&1 || return 0

__fzf_ensure_default_keybindings() {
  emulate -L zsh

  (( ${+widgets[fzf-history-widget]} )) || return 0

  local -a maps
  maps=(emacs viins main)

  local m
  for m in "${maps[@]}"; do
    bindkey -M "$m" '^R' fzf-history-widget 2>/dev/null || true
    # Warp often intercepts Ctrl-R for its own "Command Search". Provide fallbacks
    # that still work on terminals where Ctrl-R is reserved.
    bindkey -M "$m" '\er' fzf-history-widget 2>/dev/null || true     # Alt-R
    bindkey -M "$m" '^X^R' fzf-history-widget 2>/dev/null || true    # Ctrl-X Ctrl-R
    bindkey -M "$m" '^T' fzf-file-widget 2>/dev/null || true
    bindkey -M "$m" '\ec' fzf-cd-widget 2>/dev/null || true
  done
}

__fzf_source_keybindings() {
  emulate -L zsh

  local script="${1:-}"
  [[ -n "$script" ]] || return 1
  [[ -r "$script" ]] || return 1

  source "$script"
  return 0
}

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  if __fzf_source_keybindings "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"; then
    autoload -Uz add-zsh-hook
    add-zsh-hook -Uz precmd __fzf_ensure_default_keybindings
    __fzf_ensure_default_keybindings
    return 0
  fi
fi

if command -v brew >/dev/null 2>&1; then
  hb="$(brew --prefix 2>/dev/null || true)"
  if [[ -n "$hb" ]] && __fzf_source_keybindings "$hb/opt/fzf/shell/key-bindings.zsh"; then
    autoload -Uz add-zsh-hook
    add-zsh-hook -Uz precmd __fzf_ensure_default_keybindings
    __fzf_ensure_default_keybindings
    return 0
  fi
fi

if __fzf_source_keybindings "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"; then
  autoload -Uz add-zsh-hook
  add-zsh-hook -Uz precmd __fzf_ensure_default_keybindings
  __fzf_ensure_default_keybindings
  return 0
fi

if __fzf_source_keybindings "/usr/local/opt/fzf/shell/key-bindings.zsh"; then
  autoload -Uz add-zsh-hook
  add-zsh-hook -Uz precmd __fzf_ensure_default_keybindings
  __fzf_ensure_default_keybindings
  return 0
fi


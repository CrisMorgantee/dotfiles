if [[ -o interactive ]]; then
  autoload -Uz history-beginning-search-backward history-beginning-search-forward

  bindkey -e

  bindkey '^[[A' history-beginning-search-backward  # Up
  bindkey '^[[B' history-beginning-search-forward   # Down

  bindkey -M viins '^[[A' history-beginning-search-backward
  bindkey -M viins '^[[B' history-beginning-search-forward
fi


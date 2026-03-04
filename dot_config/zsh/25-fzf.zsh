[[ -o interactive ]] || return 0

if command -v fzf >/dev/null 2>&1; then
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude vendor --exclude node_modules --exclude .direnv'
  fi

  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'p=\"{}\"; ([[ -f \"$p\" ]] && bat --style=numbers --color=always --line-range=:200 \"$p\" 2>/dev/null) || ([[ -d \"$p\" ]] && eza -la --color=always \"$p\" 2>/dev/null) || true'"

  # Let fzf-tab inherit our default layout/preview.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes

  # fzf-tab is loaded asynchronously (zinit wait). Ensure Tab is bound once the
  # widget exists, even on terminals that end up overriding bindings (Warp).
  __fzf_tab_ensure_bound() {
    emulate -L zsh
    (( ${+widgets[fzf-tab-complete]} )) || return 0
    bindkey '^I' fzf-tab-complete
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook -Uz precmd __fzf_tab_ensure_bound
  __fzf_tab_ensure_bound
fi

nv() {
  emulate -L zsh
  setopt pipefail

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "nv: fzf not found"
    return 127
  fi
  if ! command -v nvim >/dev/null 2>&1; then
    print -u2 -- "nv: nvim not found"
    return 127
  fi

  local open_dir=1
  local query=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-dir|--files-only)
        open_dir=0
        shift
        ;;
      -h|--help)
        cat <<'EOF'
nv — open file/dir in Neovim via fzf

Uso:
  nv [query]            # seleciona arquivo OU diretório
  nv --no-dir [query]   # limita a seleção a arquivos

Notas:
- Se estiver dentro de um repo git, a busca acontece a partir do root do repo.
EOF
        return 0
        ;;
      *)
        query="${*}"
        break
        ;;
    esac
  done
  local -a fzf_args
  fzf_args=(--select-1 --exit-0)
  [[ -n "$query" ]] && fzf_args+=(--query "$query")

  local base="$PWD"
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    base="$(git rev-parse --show-toplevel 2>/dev/null || print -r -- "$PWD")"
  fi

  local picked=""
  if command -v fd >/dev/null 2>&1; then
    if (( open_dir )); then
      picked="$(
        (cd "$base" && fd -t f -t d --hidden --follow --exclude .git --exclude vendor --exclude node_modules --exclude .direnv .) |
          fzf "${fzf_args[@]}"
      )" || return $?
    else
      picked="$(
        (cd "$base" && fd -t f --hidden --follow --exclude .git --exclude vendor --exclude node_modules --exclude .direnv .) |
          fzf "${fzf_args[@]}"
      )" || return $?
    fi
  else
    if (( open_dir )); then
      picked="$(
        (cd "$base" && command find . -mindepth 1 \( -type f -o -type d \) 2>/dev/null | command sed 's|^\./||') |
          fzf "${fzf_args[@]}"
      )" || return $?
    else
      picked="$(
        (cd "$base" && command find . -mindepth 1 -type f 2>/dev/null | command sed 's|^\./||') |
          fzf "${fzf_args[@]}"
      )" || return $?
    fi
  fi

  [[ -n "$picked" ]] || return 0

  local target="$base/$picked"
  if [[ -d "$target" ]]; then
    if (( open_dir )); then
      nvim -- "$target"
    else
      print -u2 -- "nv: directory selected but --no-dir set: $picked"
      return 2
    fi
  else
    nvim -- "$target"
  fi
}

gb() {
  emulate -L zsh
  setopt pipefail

  command -v git >/dev/null 2>&1 || { print -u2 -- "gb: git not found"; return 127; }
  command -v fzf >/dev/null 2>&1 || { print -u2 -- "gb: fzf not found"; return 127; }

  local branch
  branch="$(
    git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads |
      fzf --select-1 --exit-0 --prompt='branch> ' \
        --preview 'git log -n 30 --color=always --oneline --decorate {}'
  )" || return $?

  [[ -n "$branch" ]] || return 0
  git switch -- "$branch"
}

gcm() {
  emulate -L zsh
  setopt pipefail

  command -v git >/dev/null 2>&1 || { print -u2 -- "gcm: git not found"; return 127; }
  command -v fzf >/dev/null 2>&1 || { print -u2 -- "gcm: fzf not found"; return 127; }

  local do_copy=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--copy) do_copy=1; shift ;;
      -h|--help)
        cat <<'EOF'
gcm — git commit browser (fzf)

Uso:
  gcm             # seleciona um commit e mostra (git show)
  gcm --copy      # copia o hash selecionado (pbcopy se disponível)
EOF
        return 0
        ;;
      *) break ;;
    esac
  done

  local sel hash
  sel="$(
    git log --color=always --date=short --pretty=format:'%C(auto)%h %ad %s %C(blue)%an%Creset' |
      fzf --ansi --no-sort --prompt='commit> ' \
        --preview 'git show --color=always {1} | sed -n "1,200p"'
  )" || return $?

  [[ -n "$sel" ]] || return 0
  hash="${sel%% *}"

  if (( do_copy )); then
    if command -v pbcopy >/dev/null 2>&1; then
      print -rn -- "$hash" | pbcopy
    else
      print -r -- "$hash"
    fi
    return 0
  fi

  git show --color=always "$hash"
}

dps() {
  emulate -L zsh
  setopt pipefail

  command -v docker >/dev/null 2>&1 || { print -u2 -- "dps: docker not found"; return 127; }
  command -v fzf >/dev/null 2>&1 || { print -u2 -- "dps: fzf not found"; return 127; }

  local action="logs"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      logs|exec|stop) action="$1"; shift ;;
      -h|--help)
        cat <<'EOF'
dps — docker container selector (fzf)

Uso:
  dps logs   # default (docker logs -f)
  dps exec   # docker exec -it (shell)
  dps stop   # docker stop
EOF
        return 0
        ;;
      *) break ;;
    esac
  done

  local line id
  line="$(
    docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}' |
      fzf --delimiter=$'\t' --with-nth=2,3,4 --prompt='docker> ' \
        --preview 'docker inspect {1} | sed -n "1,200p"'
  )" || return $?

  [[ -n "$line" ]] || return 0
  id="${line%%$'\t'*}"

  case "$action" in
    logs)
      docker logs -f --tail=200 "$id"
      ;;
    exec)
      docker exec -it "$id" sh -lc 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'
      ;;
    stop)
      docker stop "$id"
      ;;
  esac
}

sshf() {
  emulate -L zsh
  setopt pipefail

  command -v fzf >/dev/null 2>&1 || { print -u2 -- "sshf: fzf not found"; return 127; }

  local cfg="${HOME}/.ssh/config"
  [[ -r "$cfg" ]] || { print -u2 -- "sshf: ~/.ssh/config not found or unreadable"; return 2; }

  local host
  host="$(
    command awk 'tolower($1)=="host"{for(i=2;i<=NF;i++){h=$i; if(h!="*" && h!~ /[*?]/) print h}}' "$cfg" |
      command sort -u |
      fzf --select-1 --exit-0 --prompt='ssh> '
  )" || return $?

  [[ -n "$host" ]] || return 0
  ssh -- "$host"
}

ts() {
  emulate -L zsh
  setopt pipefail

  command -v tmux >/dev/null 2>&1 || { print -u2 -- "ts: tmux not found"; return 127; }
  command -v fzf >/dev/null 2>&1 || { print -u2 -- "ts: fzf not found"; return 127; }

  local name="${1:-}"
  local sessions
  sessions="$(tmux list-sessions -F '#S' 2>/dev/null || true)"

  if [[ -z "$name" ]]; then
    if [[ -z "$sessions" ]]; then
      name="main"
    else
      name="$(print -r -- "$sessions" | fzf --select-1 --exit-0 --prompt='tmux> ')" || return $?
      [[ -n "$name" ]] || return 0
    fi
  fi

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$name" 2>/dev/null || {
      tmux new-session -d -s "$name" && tmux switch-client -t "$name"
    }
  else
    tmux attach -t "$name" 2>/dev/null || tmux new-session -s "$name"
  fi
}

af() {
  emulate -L zsh
  setopt pipefail

  command -v fzf >/dev/null 2>&1 || { print -u2 -- "af: fzf not found"; return 127; }
  command -v php >/dev/null 2>&1 || { print -u2 -- "af: php not found"; return 127; }

  if [[ ! -f artisan ]]; then
    print -u2 -- "af: artisan not found in current directory"
    return 2
  fi

  local sel cmd

  # Prefer JSON when available (more precise), but fall back to --raw for compatibility.
  local json=""
  json="$(php artisan list --format=json 2>/dev/null || true)"

  if [[ -n "$json" ]] && command -v python3 >/dev/null 2>&1; then
    sel="$(
      print -r -- "$json" |
        python3 -c 'import json,sys
data=json.load(sys.stdin)
def emit(name, desc=""):
  if not name:
    return
  name=str(name)
  if name.startswith("_"):
    return
  desc="" if desc is None else str(desc)
  sys.stdout.write(f"{name}\t{desc}\n")

def iter_commands(cmds):
  if isinstance(cmds, dict):
    for name, info in cmds.items():
      desc=""
      if isinstance(info, dict):
        desc=info.get("description") or ""
      emit(name, desc)
    return
  if isinstance(cmds, list):
    for item in cmds:
      if isinstance(item, str):
        emit(item, "")
      elif isinstance(item, dict):
        name=item.get("name") or item.get("command") or item.get("full_name") or item.get("id")
        desc=item.get("description") or item.get("help") or item.get("summary") or ""
        emit(name, desc)
      elif isinstance(item, (list, tuple)) and item:
        emit(item[0], item[1] if len(item) > 1 else "")
    return

cmds=data.get("commands")
if cmds is None and isinstance(data.get("application"), dict):
  cmds=data["application"].get("commands")
iter_commands(cmds)
' |
        fzf --delimiter=$'\t' --with-nth=1,2 --prompt='artisan> ' \
          --preview 'php artisan help {1} 2>/dev/null | sed -n "1,200p"'
    )" || return $?
  else
    # Symfony Console supports --raw broadly, including older versions.
    sel="$(
      php artisan list --raw 2>/dev/null |
        command awk 'NF{cmd=$1;$1="";sub(/^ +/,"");print cmd"\t"$0}' |
        fzf --delimiter=$'\t' --with-nth=1,2 --prompt='artisan> ' \
          --preview 'php artisan help {1} 2>/dev/null | sed -n "1,200p"'
    )" || return $?
  fi

  [[ -n "$sel" ]] || return 0
  cmd="${sel%%$'\t'*}"
  php artisan "$cmd" "$@"
}

kp() {
  emulate -L zsh
  setopt pipefail

  command -v fzf >/dev/null 2>&1 || { print -u2 -- "kp: fzf not found"; return 127; }

  local sig="-TERM"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force) sig="-KILL"; shift ;;
      -h|--help)
        cat <<'EOF'
kp — kill process (fzf)

Uso:
  kp           # SIGTERM (default)
  kp -f        # SIGKILL (kill -9)
  kp --force   # SIGKILL (kill -9)

Dica: use -f só quando SIGTERM não resolver.
EOF
        return 0
        ;;
      *) break ;;
    esac
  done

  local out pids
  out="$(
    ps -eo pid=,user=,command= |
      fzf --multi --prompt='kill> ' --preview 'echo {}' --preview-window=down,3,wrap
  )" || return $?

  [[ -n "$out" ]] || return 0
  pids="$(print -r -- "$out" | command awk '{print $1}' | command tr '\n' ' ')"
  [[ -n "${pids// /}" ]] || return 0

  kill "$sig" ${=pids}
}


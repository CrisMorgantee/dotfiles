gc() {
  emulate -L zsh
  setopt pipefail no_unset

  gc_help() {
    cat <<'EOF'
gc — git commit helper

Uso:
  gc [-s] [-n] [-a|-i] [-p] "mensagem" [-- <args do git commit>]

Flags:
  -h, --help        Mostra esta ajuda
  -s, --skip        Pula hooks (SKIP_GIT_HOOKS=1) no commit (e no push se usar -p)
  -n, --no-verify   Passa --no-verify pro git commit (e pro git push se usar -p)
  -a, --add         Stage tudo com: git add -A
  -i, --interactive Stage interativo com: git add -p  (recomendado)
  -p, --push        Faz push após commitar (cria upstream com -u origin HEAD se necessário)

Exemplos:
  gc "corrige hooks"
  gc -i "refactor: staged-only"
  gc -a "update deps"
  gc -ap "update deps"         # add -A + commit + push
  gc -sap "hotfix urgente"     # skip hooks + add -A + push
  gc -s "msg" -- --no-verify   # passa args extras para git commit (opcional)
  gc -n "msg"                  # equivale a: git commit --no-verify ...

Notas:
- Sem -a/-i, o gc COMITA apenas o que já estiver staged.
- Se não houver nada staged, ele falha e sugere git add -p / gc -i.
- -a e -i são mutuamente exclusivos.
EOF
  }

  local skip=0 no_verify=0 add_all=0 add_interactive=0 do_push=0
  local -a commit_extra=()

  # Parse flags (suporta -sap e flags longas)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) gc_help; return 0 ;;
      --skip) skip=1; shift ;;
      --no-verify) no_verify=1; shift ;;
      --add) add_all=1; shift ;;
      --interactive|--patch) add_interactive=1; shift ;;
      --push) do_push=1; shift ;;
      --) shift; break ;;
      -[!-]*)
        local flags="${1#-}"
        local i ch
        for (( i=1; i<=${#flags}; i++ )); do
          ch="${flags[i]}"
          case "$ch" in
            h) gc_help; return 0 ;;
            s) skip=1 ;;
            n) no_verify=1 ;;
            a) add_all=1 ;;
            i) add_interactive=1 ;;
            p) do_push=1 ;;
            *)
              print -u2 "gc: flag inválida: -$ch"
              print -u2 "dica: gc -h"
              return 2
              ;;
          esac
        done
        shift
        ;;
      *) break ;;
    esac
  done

  local msg="${1:-}"
  if [[ -z "$msg" ]]; then
    print -u2 "gc: commit message required"
    print -u2 "dica: gc -h"
    return 2
  fi
  shift

  # argumentos extras opcionais para git commit (após --)
  if (( $# )) && [[ "$1" == "--" ]]; then
    shift
  fi
  commit_extra=("$@")

  if (( add_all && add_interactive )); then
    print -u2 "gc: use apenas um: -a (add -A) OU -i (add -p)."
    return 2
  fi

  if (( add_interactive )); then
    git add -p || return $?
  elif (( add_all )); then
    git add -A || return $?
  fi

  if git diff --cached --quiet; then
    print -u2 "gc: nada staged."
    print -u2 "  dica: git add -p   (recomendado)  ou  gc -i \"msg\""
    print -u2 "        git add -A                   ou  gc -a \"msg\""
    return 1
  fi

  local hook_env=()
  if (( skip )); then
    hook_env=(SKIP_GIT_HOOKS=1)
  fi

  if (( no_verify )); then
    if [[ " ${commit_extra[*]} " != *" --no-verify "* ]] && [[ " ${commit_extra[*]} " != *" -n "* ]]; then
      commit_extra=(--no-verify "${commit_extra[@]}")
    fi
  fi

  env "${hook_env[@]}" git commit -m "$msg" "${commit_extra[@]}" || return $?

  if (( do_push )); then
    local -a push_extra=()
    if (( no_verify )); then
      push_extra=(--no-verify)
    fi

    local upstream
    upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [[ -z "$upstream" ]]; then
      env "${hook_env[@]}" git push "${push_extra[@]}" -u origin HEAD
    else
      env "${hook_env[@]}" git push "${push_extra[@]}"
    fi
  fi
}

# link_project [slug|--no-open|--print]
link_project() {
  local PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

  local links_dir="$HOME/workspace/herd-links"
  local full_dir="$PWD"
  local slug=""
  local no_open=0
  local print_only=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --no-open) no_open=1 ;;
      --print)   print_only=1 ;;
      -*)
        echo "Unknown option: $1"
        return 2
        ;;
      *)
        [ -z "$slug" ] || { echo "Too many arguments."; return 2; }
        slug="$1"
        ;;
    esac
    shift
  done

  case "$full_dir" in
    "$links_dir"*)
      echo "Refusing to run inside $links_dir"
      return 2
      ;;
  esac

  sanitize() {
    echo "$1" \
      | command -p tr '[:upper:]' '[:lower:]' \
      | command -p sed -E 's/[ _]+/-/g; s/[^a-z0-9-]+/-/g; s/--+/-/g; s/^-+//; s/-+$//'
  }

  if [ -z "$slug" ]; then
    local laravel_root="$HOME/workspace/laravel"
    local rel=""

    case "$full_dir" in
      "$laravel_root"/*) rel="${full_dir#"$laravel_root"/}" ;;
    esac

    if [ -n "$rel" ]; then
      local seg1="${rel%%/*}"

      if [ "$rel" = "$seg1" ]; then
        slug="$seg1"
      else
        if [ "$seg1" = "clients" ]; then
          local rest="${rel#*/}" # after "clients/"
          local client="${rest%%/*}"
          if [ "$rest" != "$client" ]; then
            local app="${rest#*/}"; app="${app%%/*}"
            [ -n "$client" ] && [ -n "$app" ] && slug="$client-$app"
          fi
        else
          local seg2="${rel#*/}"; seg2="${seg2%%/*}"
          [ -n "$seg1" ] && [ -n "$seg2" ] && slug="$seg1-$seg2"
        fi
      fi
    fi
  fi

  if [ -z "$slug" ] && [ -f composer.json ]; then
    local name
    name="$(command -p sed -nE 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' composer.json | command -p head -n1)"
    [ -n "$name" ] && slug="$(echo "$name" | command -p tr '/' '-')"
  fi

  if [ -z "$slug" ] && [ -d .git ]; then
    local url repo owner cleaned
    url="$(git config --get remote.origin.url 2>/dev/null)"
    if [ -n "$url" ]; then
      cleaned="${url%.git}"
      cleaned="${cleaned##*:}"
      cleaned="${cleaned##*/}"
      repo="$cleaned"
      owner="$(echo "$url" | command -p sed -E 's|.*[:/]+([^/]+)/[^/]+(\.git)?$|\1|')"
      [ -n "$owner" ] && [ -n "$repo" ] && slug="$owner-$repo"
    fi
  fi

  if [ -z "$slug" ] && [ -f .env ]; then
    local app_name
    app_name="$(command -p sed -nE 's/^APP_NAME=(.*)$/\1/p' .env | command -p head -n1)"
    app_name="${app_name%\"}"; app_name="${app_name#\"}"
    app_name="${app_name%\'}"; app_name="${app_name#\'}"

    case "$(echo "$app_name" | command -p tr '[:upper:]' '[:lower:]')" in
      ""|laravel|app|myapp|my-app) ;;
      *) slug="$app_name" ;;
    esac
  fi

  if [ -z "$slug" ]; then
    slug="$(command -p basename "$full_dir")"
  fi

  slug="$(sanitize "$slug")"
  [ -n "$slug" ] || { echo "Could not determine slug."; return 2; }

  mkdir -p "$links_dir"
  local link_path="$links_dir/$slug"

  if [ -e "$link_path" ]; then
    if [ -L "$link_path" ]; then
      local current_target
      current_target="$(readlink "$link_path")"
      if [ "$current_target" != "$full_dir" ]; then
        echo "Link exists but points elsewhere:"
        echo "  $link_path -> $current_target"
        echo "Refusing to overwrite."
        return 2
      fi
    else
      echo "Path exists and is not a symlink: $link_path"
      return 2
    fi
  else
    ln -s "$full_dir" "$link_path"
  fi

  if [ "$print_only" -eq 1 ]; then
    echo "slug=$slug"
    echo "target=$full_dir"
    echo "link=$link_path"
    return 0
  fi

  if [ "$no_open" -eq 0 ]; then
    open "https://$slug.test"
  else
    echo "Linked: $slug"
    echo "URL: https://$slug.test"
  fi
}


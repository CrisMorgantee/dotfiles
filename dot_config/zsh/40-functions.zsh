gc() { git commit -m "${1:?commit message required}"; }

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


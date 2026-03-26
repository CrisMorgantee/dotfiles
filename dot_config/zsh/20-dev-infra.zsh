# Dev infra helpers (Docker Compose) — safe to source from ~/.zshrc

# Local Docker-only defaults. Override in ~/.zshrc.local when needed.
: "${DEV_INFRA_DIR:=$HOME/workspace/tools/dev-infra}"
: "${MYSQL_CONTAINER:=dev-mysql}"
: "${MYSQL_ROOT_PASSWORD:=root}"

__docker_compose() {
  emulate -L zsh

  if command -v docker >/dev/null 2>&1 && command docker compose version >/dev/null 2>&1; then
    command docker compose "$@"
    return $?
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    command docker-compose "$@"
    return $?
  fi

  print -r -- "dev-infra: docker compose not found (install Docker Desktop / docker compose plugin)."
  return 127
}

__dev_infra_compose() {
  emulate -L zsh

  if [[ -z "${DEV_INFRA_DIR:-}" ]]; then
    print -r -- "dev-infra: DEV_INFRA_DIR is empty."
    return 2
  fi

  if [[ ! -d "$DEV_INFRA_DIR" ]]; then
    print -r -- "dev-infra: DEV_INFRA_DIR not found: $DEV_INFRA_DIR"
    return 2
  fi

  if [[ ! -f "$DEV_INFRA_DIR/docker-compose.yml" ]]; then
    print -r -- "dev-infra: docker-compose.yml not found in: $DEV_INFRA_DIR"
    return 2
  fi

  (cd "$DEV_INFRA_DIR" && __docker_compose "$@")
}

dev-up() {
  __dev_infra_compose --profile core up -d
}

dev-up-all() {
  __dev_infra_compose --profile core --profile mail up -d
}

dev-down() {
  __dev_infra_compose down --remove-orphans
}

dev-reset() {
  __dev_infra_compose down -v --remove-orphans
}

dev-logs() {
  __dev_infra_compose logs -f --tail=200 "$@"
}

__env_get() {
  emulate -L zsh

  local key="${1:-}"
  local env_file="${2:-"$PWD/.env"}"

  [[ -n "$key" ]] || return 2
  [[ -f "$env_file" ]] || return 1

  local line k v
  while IFS= read -r line || [[ -n "$line" ]]; do
    # trim leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [[ -n "$line" ]] || continue
    [[ "${line[1]}" == "#" ]] && continue

    if [[ "$line" == export\ * ]]; then
      line="${line#export }"
      line="${line#"${line%%[![:space:]]*}"}"
    fi

    [[ "$line" == *"="* ]] || continue

    k="${line%%=*}"
    v="${line#*=}"

    # trim whitespace around key
    k="${k#"${k%%[![:space:]]*}"}"
    k="${k%"${k##*[![:space:]]}"}"

    [[ "$k" == "$key" ]] || continue

    # strip optional surrounding quotes
    if [[ "$v" == \"*\" ]]; then
      v="${v#\"}"; v="${v%\"}"
    elif [[ "$v" == \'*\' ]]; then
      v="${v#\'}"; v="${v%\'}"
    fi

    print -r -- "$v"
    return 0
  done <"$env_file"

  return 1
}

__resolve_db_name() {
  emulate -L zsh

  if [[ -n "${1:-}" ]]; then
    print -r -- "$1"
    return 0
  fi

  local env_file="$PWD/.env"
  local db=""

  db="$(__env_get DB_DATABASE "$env_file")" || true
  if [[ -z "$db" ]]; then
    if [[ ! -f "$env_file" ]]; then
      print -r -- "dev-infra: .env not found in current directory ($PWD). Provide a database name or create .env with DB_DATABASE."
      return 2
    fi
    print -r -- "dev-infra: DB_DATABASE not found/empty in $env_file. Provide a database name or set DB_DATABASE."
    return 2
  fi

  print -r -- "$db"
}

__docker_exec_i() {
  emulate -L zsh
  command docker exec -i "$@"
}

__docker_exec_it() {
  emulate -L zsh
  command docker exec -it "$@"
}

__mysql_exec_root() {
  emulate -L zsh

  local sql="${1:-}"
  [[ -n "$sql" ]] || { print -r -- "dev-infra: missing SQL."; return 2; }

  if ! command -v docker >/dev/null 2>&1; then
    print -r -- "dev-infra: docker not found."
    return 127
  fi

  if ! command docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1; then
    print -r -- "dev-infra: mysql container not found: $MYSQL_CONTAINER (did you run dev-up?)"
    return 2
  fi

  __docker_exec_i "$MYSQL_CONTAINER" mysql -uroot "-p$MYSQL_ROOT_PASSWORD" -e "$sql"
}

mkdb() {
  emulate -L zsh

  local db q
  db="$(__resolve_db_name "${1:-}")" || return $?
  q="${db//\`/\`\`}"

  __mysql_exec_root "CREATE DATABASE IF NOT EXISTS \`$q\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

dropdb() {
  emulate -L zsh

  local db q
  db="$(__resolve_db_name "${1:-}")" || return $?
  q="${db//\`/\`\`}"

  __mysql_exec_root "DROP DATABASE IF EXISTS \`$q\`;"
}

dblist() {
  emulate -L zsh
  __mysql_exec_root "SHOW DATABASES;"
}

dbuse() {
  emulate -L zsh

  local db
  db="$(__resolve_db_name "${1:-}")" || return $?

  if ! command -v docker >/dev/null 2>&1; then
    print -r -- "dev-infra: docker not found."
    return 127
  fi

  if ! command docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1; then
    print -r -- "dev-infra: mysql container not found: $MYSQL_CONTAINER (did you run dev-up?)"
    return 2
  fi

  __docker_exec_it "$MYSQL_CONTAINER" mysql -uroot "-p$MYSQL_ROOT_PASSWORD" "$db"
}


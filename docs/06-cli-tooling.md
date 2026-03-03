# Ferramentas CLI

## Objetivo

Documentar o conjunto de ferramentas CLI versionado via Brewfile (eza, vivid, bat, ripgrep, fd, delta, lazygit) e seus aliases no shell, sem sobrescrever comandos padrão de forma que quebre scripts (ex.: não substituir `cat` globalmente).

## Decisões de design

- **eza com vivid (Nord):** eza substitui `ls` nos aliases; cores via `LS_COLORS="$(vivid generate nord)"` exportado no .zshrc quando vivid está disponível. Aliases: `l` (eza -lag --time-style=long-iso), `lt` (eza --tree --level=2 --long --group --time-style=long-iso).
- **bat:** Uso sob demanda; alias `bcat='bat --theme="Nord"'`. O .zshrc explicita que não se deve sobrescrever `cat` globalmente para não quebrar scripts e ferramentas que esperam o comportamento do cat.
- **ripgrep e fd:** Aliases `g="rg"` e `find="fd"`. Substituem grep e find na linha de comando interativa. Trade-off: scripts que invocam `find` ou `grep` sem path absoluto podem usar fd/rg se o alias estiver ativo; em scripts no .zshrc isso é aceito para o uso interativo.
- **delta:** Usado como pager e diff do Git (dot_gitconfig e run_once_30); não há alias de shell para delta; ver 07-git-architecture.md.
- **lazygit:** Instalado pelo Brewfile; invocado como `lazygit` (sem alias no .zshrc no plano; manter conforme estado atual do dot_zshrc).
- **ditto:** Alias `c="ditto"` (similar a cp); mantido conforme dot_zshrc.

## Arquitetura

- **Fonte dos binários:** Homebrew (Brewfile): eza, vivid, bat, ripgrep, fd, delta, lazygit. Scripts em ~/.local/bin (versionados: tmux-auto) documentados em 16-tmux.md.
- **Configuração de cores:** vivid generate nord → LS_COLORS; aplicado no início do .zshrc (após Homebrew).
- **Aliases em `~/.config/zsh/30-aliases.zsh`:** l, lt, find, g, bcat, c e aliases do stack (Laravel, git, system, editor). Carregado pelo `.zshrc`.

## Fluxo operacional

- Ao carregar o shell: LS_COLORS é setado se vivid existir; aliases são definidos.
- Uso: `l`, `lt` para listagem; `g <pattern>` para ripgrep; `find <name>` para fd; `bcat <file>` para bat; delta usado automaticamente pelo Git.

## Validação

- `l` lista o diretório com eza; cores consistentes com Nord.
- `g --version` e `find --version` (ou equivalente) retornam ripgrep e fd.
- `bcat <arquivo>` exibe com syntax highlighting (tema Nord).
- `cat` ainda é o binário do sistema (ou o do PATH antes de qualquer override); scripts que usam `cat` não devem ser afetados pelo alias bcat.

## Modos de falha

- **vivid ou eza ausentes:** LS_COLORS não setado ou eza não encontrado. Instalar via Brewfile (run_once_10).
- **Alias find/g quebram script:** Scripts que chamam `find` ou `grep` em ambiente que carrega .zshrc podem receber fd/rg. Em scripts, usar path absoluto (/usr/bin/find, /usr/bin/grep) ou desativar aliases no script.

## Estratégia de recuperação

- Reinstalar ferramentas: `brew bundle --file=<Brewfile>` a partir do source dir.
- Remover alias: comentar a linha em `~/.config/zsh/30-aliases.zsh` e recarregar o shell; ou invocar com `command find` / `command grep` quando precisar do binário original.

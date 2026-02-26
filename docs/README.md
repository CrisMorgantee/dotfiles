# Documentação do ambiente de desenvolvimento

Documentação técnica e guias de uso do ambiente versionado via chezmoi (macOS, Zsh, Zinit, Powerlevel10k, mise, direnv, Neovim, etc.).

## Índice

| Arquivo | Conteúdo |
|---------|----------|
| [00-philosophy.md](00-philosophy.md) | Princípios: reprodutibilidade, dotfiles como código, zero secrets, camadas. |
| [01-architecture-overview.md](01-architecture-overview.md) | Visão geral: componentes, dependências, ordem de carregamento. |
| [02-bootstrap-from-zero.md](02-bootstrap-from-zero.md) | Procedimento técnico de bootstrap (decisões, passos, validação). |
| [03-homebrew.md](03-homebrew.md) | Brewfile, run_once_10, Apple Silicon. |
| [04-zsh-architecture.md](04-zsh-architecture.md) | Zinit, Powerlevel10k, plugins, keymap emacs. |
| [05-history-system.md](05-history-system.md) | Histórico: XDG_STATE_HOME, SHARE_HISTORY, history-beginning-search. |
| [06-cli-tooling.md](06-cli-tooling.md) | eza, vivid, bat, ripgrep, fd, aliases. |
| [07-git-architecture.md](07-git-architecture.md) | dot_gitconfig, run_once_30, delta, pull.rebase, ignore global. |
| [08-mise-runtime.md](08-mise-runtime.md) | mise: ativação, shims, uso por projeto. |
| [09-direnv.md](09-direnv.md) | direnv: hook, .envrc, direnv allow, secrets. |
| [10-neovim.md](10-neovim.md) | Config Neovim via external (svim), sem NVIM_APPNAME. |
| [11-chezmoi-architecture.md](11-chezmoi-architecture.md) | Source dir, run_once, externals, data, .chezmoiignore. |
| [12-macos-defaults.md](12-macos-defaults.md) | run_once_20: UI, teclado, Finder, Dock, firewall. |
| [13-security-model.md](13-security-model.md) | Sem API keys no .zshrc; .zshrc.local; direnv + Keychain/1Password. |
| [14-guia-de-uso.md](14-guia-de-uso.md) | Uso prático: mise, direnv, pnpm, zoxide, fzf-tab (como configurar e usar nos projetos). |
| [15-guia-de-instalacao.md](15-guia-de-instalacao.md) | Instalação passo a passo para quem está do zero (comandos, verificação). |
| [troubleshooting.md](troubleshooting.md) | Problemas comuns e correções. |

## Por onde começar

- **Instalar o ambiente do zero:** [15-guia-de-instalacao.md](15-guia-de-instalacao.md).
- **Usar mise e direnv em projetos:** [14-guia-de-uso.md](14-guia-de-uso.md).
- **Entender a arquitetura:** [01-architecture-overview.md](01-architecture-overview.md).
- **Algo quebrou:** [troubleshooting.md](troubleshooting.md).

# Documentação do ambiente de desenvolvimento

Documentação técnica e guias de uso do ambiente versionado via chezmoi (macOS, Zsh, Zinit, Powerlevel10k, mise, direnv, Neovim, etc.).

Links rápidos:

- [README da raiz](../README.md)
- [Instalação](15-guia-de-instalacao.md)
- [SSH e GitHub](17-ssh-e-github.md)
- [Guia de uso](14-guia-de-uso.md)
- [Solução de problemas](18-solucao-de-problemas.md)

## Índice

### Fundamentos

| Arquivo | Conteúdo |
|---------|----------|
| [00-filosofia.md](00-filosofia.md) | Princípios: reprodutibilidade, dotfiles como código, zero secrets, camadas. |
| [01-visao-geral.md](01-visao-geral.md) | Visão geral: componentes, dependências, ordem de carregamento. |
| [02-bootstrap-do-zero.md](02-bootstrap-do-zero.md) | Procedimento técnico de bootstrap (decisões, passos, validação). |

### Componentes

| Arquivo | Conteúdo |
|---------|----------|
| [03-homebrew.md](03-homebrew.md) | Brewfile, run_once_10 (passo a passo e referência), Apple Silicon. |
| [04-zsh.md](04-zsh.md) | Zinit, Powerlevel10k, plugins, keymap emacs. |
| [05-historico.md](05-historico.md) | Histórico: ~/.zsh_history, INC_APPEND_HISTORY, history-beginning-search. |
| [06-cli.md](06-cli.md) | eza, vivid, bat, ripgrep, fd, aliases. |
| [07-git.md](07-git.md) | dot_gitconfig.tmpl, run_once_30 (referência das opções), delta, pull.rebase, ignore global. |
| [08-mise.md](08-mise.md) | mise: ativação, shims, uso por projeto. |
| [09-direnv.md](09-direnv.md) | direnv: hook, .envrc, direnv allow, secrets. |
| [10-neovim.md](10-neovim.md) | Config Neovim via external (svim), sem NVIM_APPNAME. |
| [11-chezmoi.md](11-chezmoi.md) | Source dir, run_once, externals, data, .chezmoiignore. |
| [12-macos.md](12-macos.md) | run_once_20: referência de cada default (UI, teclado, trackpad, Finder, Dock, screenshots, Safari, firewall). |
| [13-seguranca.md](13-seguranca.md) | Sem API keys no .zshrc; .zshrc.local; direnv + Keychain/1Password. |

### Guias

| Arquivo | Conteúdo |
|---------|----------|
| [14-guia-de-uso.md](14-guia-de-uso.md) | Uso prático: mise, direnv, pnpm, zoxide, fzf-tab (como configurar e usar nos projetos). |
| [15-guia-de-instalacao.md](15-guia-de-instalacao.md) | Instalação passo a passo para quem está do zero (comandos, verificação). |
| [16-tmux.md](16-tmux.md) | Tmux: auto-session por hostname em SSH, TPM e plugins. |
| [17-ssh-e-github.md](17-ssh-e-github.md) | SSH para GitHub: chave única, chave por app/repo, aliases, deploy keys e bootstrap deste ambiente. |

### Suporte

| Arquivo | Conteúdo |
|---------|----------|
| [18-solucao-de-problemas.md](18-solucao-de-problemas.md) | Problemas comuns e correções. |

## Convenção de nomes

- `README.md`: ponto de entrada da pasta `docs/`.
- `NN-tema.md`: documentos versionados por ordem lógica de leitura e manutenção.
- Conceitos genéricos usam nomes curtos em português: `filosofia`, `visao-geral`, `seguranca`, `historico`.
- Ferramentas e produtos mantêm o nome oficial: `homebrew`, `zsh`, `git`, `mise`, `direnv`, `neovim`, `tmux`.
- Guias operacionais usam nomes explícitos: `guia-de-instalacao`, `guia-de-uso`, `ssh-e-github`, `solucao-de-problemas`.

## Critérios de organização

- A numeração segue a jornada principal: entender -> instalar -> usar -> resolver problemas.
- Os grupos visuais ajudam na navegação, mas a ordem numérica continua sendo a trilha principal.
- Arquivos de referência por componente ficam no meio da sequência para facilitar consulta recorrente.
- Guias operacionais ficam no final da trilha principal, perto do momento em que costumam ser usados.
- Solução de problemas fica por último, como material de apoio e consulta.

## Por onde começar

- **Entender o repositório rapidamente:** [../README.md](../README.md).
- **Instalar o ambiente do zero:** [15-guia-de-instalacao.md](15-guia-de-instalacao.md).
- **Configurar SSH e GitHub:** [17-ssh-e-github.md](17-ssh-e-github.md).
- **Usar mise e direnv em projetos:** [14-guia-de-uso.md](14-guia-de-uso.md).
- **Entender a arquitetura:** [01-visao-geral.md](01-visao-geral.md).
- **Algo quebrou:** [18-solucao-de-problemas.md](18-solucao-de-problemas.md).

## Papel de cada guia

- [`../README.md`](../README.md): visão rápida, princípios e entrada no projeto.
- [`15-guia-de-instalacao.md`](15-guia-de-instalacao.md): passo a passo da instalação.
- [`17-ssh-e-github.md`](17-ssh-e-github.md): referência completa de autenticação GitHub/SSH.

## Fluxo recomendado de leitura

- Primeira vez no repo: [`../README.md`](../README.md) -> [`15-guia-de-instalacao.md`](15-guia-de-instalacao.md) -> [`17-ssh-e-github.md`](17-ssh-e-github.md).
- Entender a base conceitual: [`00-filosofia.md`](00-filosofia.md) -> [`01-visao-geral.md`](01-visao-geral.md) -> [`02-bootstrap-do-zero.md`](02-bootstrap-do-zero.md).
- Entender a implementação: [`11-chezmoi.md`](11-chezmoi.md) -> [`04-zsh.md`](04-zsh.md) -> [`07-git.md`](07-git.md) -> [`13-seguranca.md`](13-seguranca.md).
- Consultar operação do dia a dia: [`14-guia-de-uso.md`](14-guia-de-uso.md) -> [`16-tmux.md`](16-tmux.md) -> [`18-solucao-de-problemas.md`](18-solucao-de-problemas.md).

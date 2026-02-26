# Visão geral da arquitetura

## Objetivo

Oferecer uma visão única do sistema: componentes, dependências e ordem de carregamento, para que bootstrap, depuração e alterações sigam uma sequência conhecida.

## Decisões de design

- **Ordem de carregamento no .zshrc:** (1) Instant prompt do Powerlevel10k (cedo, sem output acima que possa bloquear); (2) shellenv do Homebrew para Apple Silicon; (3) vivid/LS_COLORS se disponível; (4) compinit (em cache); (5) Zinit; (6) tema Powerlevel10k e ~/.p10k.zsh; (7) plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting); (8) mise activate; (9) append de PATH para ~/.composer/vendor/bin e ~/.local/bin; (10) direnv hook; (11) zoxide init; (12) history e keybindings; (13) source ~/.zshrc.local se existir. Essa ordem mantém o prompt rápido, ferramentas no PATH antes do uso e evita lógica duplicada de PATH.
- **Construção única do PATH:** Homebrew primeiro (do shellenv), depois shims do mise (de `mise activate zsh`), depois um append explícito para bins do usuário. Sem `typeset -U PATH`; sem exports de PATH espalhados.

## Arquitetura

**Artefatos versionados (no source do chezmoi):**


| Artefato                            | Target                 | Propósito                                                                                        |
| ----------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------ |
| dot_zshrc                           | ~/.zshrc               | Config do shell, plugins, histórico, aliases                                                     |
| dot_gitconfig                       | ~/.gitconfig           | Config global do Git (pull.rebase, delta, aliases etc.)                                          |
| dot_p10k.zsh                        | ~/.p10k.zsh            | Tema Powerlevel10k (Nord, estilo Pure)                                                           |
| dot_zshrc.local.example             | ~/.zshrc.local.example | Modelo para config local da máquina (não aplicado como .local)                                   |
| run_once_10_homebrew-bundle.sh.tmpl | run once               | Instalar Homebrew se ausente, brew bundle a partir do Brewfile, fzf install                      |
| run_once_20_macos-defaults.sh.tmpl  | run once               | Defaults do macOS (UI, teclado, Finder, Dock, screenshots, Safari, firewall)                     |
| run_once_30_git.sh.tmpl             | run once               | Identidade Git se ausente (a partir de data), defaults principais, delta, aliases, ignore global |
| homebrew/Brewfile                   | —                      | Lista de fórmulas e casks para run_once_10                                                       |


**Externo (conteúdo não está no repo):**


| Externo      | Target         | Origem                                                                              |
| ------------ | -------------- | ----------------------------------------------------------------------------------- |
| .config/nvim | ~/.config/nvim | [git@github.com](mailto:git@github.com):Simplify-Technology/svim.git (refresh 168h) |


**Dependências:** Zinit depende do Homebrew (instalado via run_once_10). Powerlevel10k e plugins dependem do Zinit. mise, direnv, zoxide dependem de estarem no PATH (Homebrew ou mise). Delta e config do Git dependem de run_once_10 (git, delta) e run_once_30. Config do Neovim depende de run_once_10 (neovim) e do chezmoi apply (clone externo).

## Fluxo operacional

**Sequência de bootstrap:** Instalar chezmoi → clonar repo → fornecer data (name, email para run_once_30) → `chezmoi init --apply` ou `chezmoi apply` → run_once 10, 20, 30 executam na ordem (10: Homebrew + Brewfile; 20: defaults macOS; 30: Git). Abrir Warp (ou terminal), iniciar Zsh; .zshrc roda na ordem acima.

**Inicialização do shell (resumida):** instant prompt → brew shellenv → compinit → zinit → p10k + config → plugins → mise → PATH append → direnv hook → zoxide → opts de history + bindkeys → .zshrc.local.

## Validação

- `which zinit mise direnv zoxide` — todos devem resolver (zinit em HOMEBREW_PREFIX/opt/zinit, demais no PATH).
- `zsh -i -c 'echo OK'` — shell interativo inicia sem erro.
- `echo $HISTFILE` — deve estar sob XDG_STATE_HOME (ex.: ~/.local/state/zsh/history).
- `echo $XDG_STATE_HOME` — definido ou vazio; se vazio, HISTFILE usa ~/.local/state por padrão neste setup.
- O diretório do HISTFILE deve existir; .zshrc executa `mkdir -p "${HISTFILE:h}"` para que o primeiro start interativo crie o diretório.

## Modos de falha

- **Zinit/p10k não carregam:** Em geral HOMEBREW_PREFIX não definido ou Homebrew fora do PATH antes do .zshrc rodar. Correção: garantir que run_once_10 rodou e shellenv foi avaliado (ex.: login shell ou Warp iniciado após o apply).
- **mise/direnv fora do PATH:** mise vem do Homebrew; direnv do Homebrew. Se `brew bundle` não rodou ou falhou, podem estar ausentes. Correção: rodar run_once_10 ou `brew bundle --file=...`.
- **Diretório de histórico ausente:** Se HISTFILE está definido mas o diretório pai não existe e a linha mkdir falhou (ex.: home somente leitura), o histórico não é salvo. Correção: criar o diretório manualmente ou corrigir permissões.

## Estratégia de recuperação

- Garantir Homebrew no PATH antes do Zinit: manter o bloco do Homebrew no topo do .zshrc (apenas abaixo do instant prompt).
- Garantir que o diretório de histórico exista: o `mkdir -p "${HISTFILE:h}"` já presente no .zshrc basta em instalações normais; caso contrário, criar o path manualmente.
- Documentar a ordem completa de bootstrap em 02-bootstrap-from-zero.md para que reinstalações sigam a mesma sequência.


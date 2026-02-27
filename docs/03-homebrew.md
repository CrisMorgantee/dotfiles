# Homebrew

## Objetivo

Centralizar a instalação de fórmulas e casks em um único Brewfile versionado, aplicado por um run_once que instala o Homebrew se ausente e executa `brew bundle`, garantindo reprodutibilidade entre máquinas e path correto para Apple Silicon.

## Referência do run_once_10_homebrew-bundle.sh.tmpl

Cada passo do script e o que faz:

| Passo | O que faz |
|-------|-----------|
| Verificação de `brew` | Se `brew` não existir, instala o Homebrew com o script oficial (`curl` do repositório GitHub), com `NONINTERACTIVE=1`. |
| Apple Silicon | Se existir `/opt/homebrew/bin/brew`, executa `eval "$(/opt/homebrew/bin/brew shellenv)"` para colocar o Homebrew no PATH na sessão atual. |
| `brew update` | Atualiza o Homebrew e as fórmulas. |
| `brew bundle check --file="$BREWFILE"` | Verifica se todos os itens do Brewfile estão instalados; `$BREWFILE` é `{{ .chezmoi.sourceDir }}/homebrew/Brewfile`. |
| `brew bundle --file="$BREWFILE"` | Se o check falhar, instala o que faltar (fórmulas e casks listados no Brewfile). A lista exata de pacotes está em `homebrew/Brewfile` no source do chezmoi. |
| Pós-passo fzf | Se o binário `fzf` existir, executa `$(brew --prefix)/opt/fzf/install --no-bash --no-fish --no-zsh` para instalar keybindings/completion sem alterar config de shell (o Zsh já usa fzf via Zinit/fzf-tab). |

Para saber **quais** fórmulas e casks são instalados, consulte o arquivo `homebrew/Brewfile` no repositório do chezmoi.

## Decisões de design

- **Brewfile como única fonte:** Todas as dependências CLI e GUI listadas no plano (git, zsh, zinit, neovim, mise, direnv, zoxide, fzf, fd, ripgrep, bat, eza, delta, lazygit, gnupg, pinentry-mac, vivid; Warp, Orbstack, Raycast, Rectangle) ficam em `homebrew/Brewfile`. Nada é instalado via `brew install` manual fora do bundle para evitar deriva.
- **run_once_10:** (1) Instala Homebrew se `brew` não existir (script oficial, NONINTERACTIVE=1). (2) Garante shellenv para Apple Silicon (`/opt/homebrew/bin/brew`). (3) `brew update`; (4) `brew bundle check --file="$BREWFILE"` e, se falhar, `brew bundle --file="$BREWFILE"`. (5) Pós-passo: se fzf existir, executa `install` do fzf com `--no-bash --no-fish --no-zsh` para não alterar config de shell (o Zinit já carrega fzf-tab). Trade-off: run_once usa template `{{ .chezmoi.sourceDir }}`; em execução manual é preciso substituir pelo path real.
- **Apple Silicon:** O script verifica `-x /opt/homebrew/bin/brew` e faz `eval "$(/opt/homebrew/bin/brew shellenv)"` para colocar Homebrew no PATH. O .zshrc faz o mesmo no início; assim o shell e o run_once veem o mesmo PATH.

## Arquitetura

- **Arquivo:** `homebrew/Brewfile` no source do chezmoi (não é um dotfile; é referenciado pelo run_once).
- **Script:** `run_once_10_homebrew-bundle.sh.tmpl` → executado uma vez por máquina; instala Homebrew se necessário, depois `brew update` e `brew bundle` a partir do Brewfile no source dir.
- **Ordem:** run_once_10 deve ser o primeiro run_once relevante para o shell (Zinit e demais dependem do Homebrew).

## Fluxo operacional

1. Primeiro `chezmoi apply`: run_once_10 é executado.
2. Se Homebrew não existe: download e instalação do instalador oficial; em seguida shellenv e bundle.
3. Se Homebrew existe: shellenv, update, bundle check; se algo faltar, bundle install.
4. fzf: install sem hooks de shell (opcional, idempotente).

## Validação

- `command -v brew` e `brew --prefix` retornam path (ex.: /opt/homebrew).
- `brew bundle check --file=<path-do-Brewfile>` retorna sucesso após o run_once.
- `command -v zinit mise direnv zoxide nvim` resolvem para bins do Homebrew (ou mise shims quando aplicável).

## Modos de falha

- **Rede ou proxy:** Instalação do Homebrew ou `brew update`/`brew bundle` podem falhar. Ajustar proxy/SSL ou repetir em outra rede.
- **Permissões:** Diretório de instalação do Homebrew sem permissão de escrita. Corrigir dono ou path.
- **Brewfile com fórmula inexistente ou renomeada:** `brew bundle` falha. Atualizar Brewfile conforme mensagem de erro.

## Estratégia de recuperação

- Reexecutar run_once_10: do source dir, `bash run_once_10_homebrew-bundle.sh` após substituir `{{ .chezmoi.sourceDir }}` pelo path real no script já renderizado (ou usar `chezmoi execute-template` para obter o path e injetar). Alternativa: rodar manualmente `eval "$(/opt/homebrew/bin/brew shellenv)"`, `brew update`, `brew bundle --file=<path-do-Brewfile>`.
- Reverter um pacote: remover do Brewfile e rodar `brew bundle --file=...` (bundle não desinstala automaticamente; usar `brew uninstall` se necessário).

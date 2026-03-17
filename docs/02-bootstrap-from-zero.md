# Bootstrap a partir do zero

## Objetivo

Procedimento determinístico para levar um Mac do zero (ou onboarding de desenvolvedor) até um ambiente funcional: shell Zsh com prompt Powerlevel10k, mise, direnv, zoxide, CLI (eza, bat, ripgrep, fd, delta, lazygit), Git configurado e Neovim com config externa.

## Decisões de design

- **Pré-requisitos mínimos:** Xcode Command Line Tools (ou confirmação de que já estão instalados); conta GitHub para clone do repo do chezmoi e do externo do Neovim. Não é necessário instalar o Homebrew manualmente antes do run_once_10: o script instala se estiver ausente.
- **Data do chezmoi obrigatória para identidade Git:** O run_once_30_git define `user.name` e `user.email` apenas quando não estão já configurados globalmente e quando existem `{{ .data.name }}` e `{{ .data.email }}` no template. Para instalação do zero sem identidade Git prévia, é necessário fornecer data em `~/.config/chezmoi/chezmoi.toml` (seção `[data]`) antes do `init`/`apply`. Sem data, o run_once_30 não define identidade e o desenvolvedor precisará configurar manualmente.
- **Ordem dos run_once:** 10 (Homebrew + Brewfile) deve rodar antes de qualquer uso de brew/zinit no shell; 20 (macOS defaults) exige sudo; 30 (Git) depende de git estar no PATH (instalado pelo 10); 40 instala o TPM do tmux (plugins).

## Arquitetura

Passos numerados, idempotentes onde possível:

1. **Xcode Command Line Tools:** Instalar ou confirmar (`xcode-select -p`). Necessário para compilação e para o instalador do Homebrew.
2. **Instalar chezmoi:** Via script oficial ou, se já houver Homebrew em outra máquina, `brew install chezmoi`. Em Mac novo, uso típico: script de instalação do site do chezmoi.
3. **Inicializar e aplicar:** criar `~/.config/chezmoi/chezmoi.toml` com `[data]`, por exemplo `name = "Cristiano Morgante"` e `email = "cristiano@morgante.com.br"`, e então rodar `chezmoi init --apply git@github.com:CrisMorgantee/dotfiles.git`.
4. **Dotfiles e run_once:** O primeiro `chezmoi apply` (ou o do `init --apply`) copia os dotfiles para os targets e executa os run_once 10, 20, 30 e 40 na ordem. Não é necessário rodar run_once manualmente a menos que tenham falhado ou não tenham sido executados.
5. **.zshrc.local:** Se a máquina precisar de config local (ex.: PATH do Herd), copiar `~/.zshrc.local.example` para `~/.zshrc.local` e editar. Não versionado.
6. **Abrir Warp e validar:** Definir Warp para usar Zsh como shell. Ver seção Validação.

## Fluxo operacional

- **Comandos (exemplo):**  
  `mkdir -p ~/.config/chezmoi && cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
name = "Cristiano Morgante"
email = "cristiano@morgante.com.br"
EOF
chezmoi init --apply git@github.com:CrisMorgantee/dotfiles.git`  
  (Substituir URL e data conforme o repo e a identidade desejada.)
- **Quando pede sudo:** run_once_20 (defaults do macOS) pede sudo uma vez; o script mantém o sudo vivo durante a execução.
- **Interação:** Primeiro clone pode exigir autenticação GitHub (SSH ou HTTPS). Por projeto, `direnv allow` é necessário na primeira entrada em diretório com `.envrc`.

## Validação

Checklist final após abrir o Warp (ou terminal configurado para Zsh):

- Shell é Zsh: `echo $ZSH_VERSION`.
- Prompt é Powerlevel10k (estilo Pure/Nord): visual.
- `mise --version` e `direnv version` retornam versões.
- `l` (alias para eza) lista o diretório; `g --version` (ripgrep) funciona.
- `nvim --version` existe (Brewfile instala neovim).
- Histórico: `echo $HISTFILE` deve ser `~/.zsh_history`. Digite um prefixo (ex.: `cd `) e use **Seta para cima/baixo** para validar `history-beginning-search`.
- Git: `git config --global user.name` e `user.email` preenchidos (se data foi fornecida e run_once_30 rodou).

## Modos de falha

- **run_once_10 falha:** Rede indisponível, proxy ou permissões no diretório de instalação do Homebrew. Instalador do Homebrew pode pedir confirmação; usar NONINTERACTIVE=1 no script se apropriado.
- **run_once_20 cancelado:** Usuário cancela o sudo; alguns defaults não são aplicados. Reexecutar o script manualmente quando desejar.
- **run_once_30 sem data:** Se `.data.name` e `.data.email` não foram fornecidos, o run_once não define identidade Git. Solução: definir data, reaplicar (run_once já rodado não redefine identity se já existir) ou configurar `git config --global user.name/user.email` manualmente.
- **Neovim ausente:** Até o Brewfile ser aplicado (run_once_10), `nvim` pode não existir. Garantir que run_once_10 concluiu; em caso de falha, rodar `brew bundle --file=<path-do-Brewfile>` a partir do source dir.

## Estratégia de recuperação

- Rodar run_once manualmente: do diretório source do chezmoi, executar o script renderizado. O run_once_10 usa `{{ .chezmoi.sourceDir }}`; em execução manual, substituir por o path real do source (ex.: `$(chezmoi source-path)` ou o path do clone).
- Preencher data e reaplicar: adicionar `name` e `email` ao data do chezmoi e rodar `chezmoi apply`; em seguida, se a identidade ainda não estiver definida, rodar run_once_30 manualmente ou definir `user.name`/`user.email` com `git config --global`.
- Neovim faltando: `brew install neovim` ou `brew bundle --file=<Brewfile>` a partir do source dir.

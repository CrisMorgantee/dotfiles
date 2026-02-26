# Neovim

## Objetivo

Documentar a configuração do Neovim neste ambiente: config em ~/.config/nvim obtida via chezmoi external (repositório svim), sem NVIM_APPNAME e sem wrapper custom; editor global do Git (core.editor nvim).

## Decisões de design

- **Config via external:** O arquivo .chezmoiexternal.toml declara que o target .config/nvim é um repositório git externo: `git@github.com:Simplify-Technology/svim.git`, refresh a cada 168h. O chezmoi clona ou atualiza esse repo em ~/.config/nvim. Nenhum arquivo de config do nvim é versionado como dotfile dentro do repo principal do chezmoi; apenas a referência externa.
- **Sem NVIM_APPNAME:** Neovim é invocado como `nvim`; não há uso de NVIM_APPNAME para config alternativa. A config é a padrão em ~/.config/nvim.
- **Sem wrapper custom:** Não há script ou alias que invoque nvim com opções especiais além das do próprio config (init.lua etc. dentro do repo svim). O alias `neoconfig` no .zshrc apenas faz `cd ~/.config/nvim && nvim init.lua` para editar a config.
- **core.editor:** dot_gitconfig e run_once_30 definem core.editor como "nvim" para que Git abra o editor padrão com Neovim.

## Arquitetura

- **Fonte da config:** Repositório externo svim (Simplify-Technology/svim). Definido em .chezmoiexternal.toml no source do chezmoi.
- **Target:** ~/.config/nvim (diretório gerenciado pelo chezmoi como external; conteúdo vem do clone do svim).
- **Binário:** Neovim instalado via Homebrew (Brewfile); disponível como `nvim` após run_once_10.
- **Fluxo chezmoi:** No `chezmoi apply`, o chezmoi verifica/atualiza o external conforme refreshPeriod; não há run_once específico para o nvim além do clone/update do external.

## Fluxo operacional

- Após primeiro apply: chezmoi clona o repo svim em ~/.config/nvim (ou atualiza se já existir). Neovim já está instalado pelo Brewfile.
- Edição da config do nvim: editar arquivos em ~/.config/nvim (ou no clone do svim e fazer push; no próximo apply o chezmoi pode puxar atualizações conforme refreshPeriod). Ou usar `neoconfig` para abrir init.lua.
- Git: ao executar `git commit` ou similar, Git invoca `nvim` como editor.

## Validação

- `nvim --version` retorna a versão do Neovim (Homebrew).
- `ls ~/.config/nvim` mostra conteúdo do repo (init.lua ou estrutura do svim).
- `git config --global core.editor` retorna nvim.
- Abrir nvim não mostra erro de config ausente (config carregada de ~/.config/nvim).

## Modos de falha

- **~/.config/nvim ausente ou vazio:** External não clonado (rede, SSH, permissões) ou refresh não executado. Executar `chezmoi apply` novamente; verificar acesso a git@github.com:Simplify-Technology/svim.git.
- **nvim não encontrado:** Brewfile não aplicado ou run_once_10 falhou. Instalar com `brew install neovim` ou brew bundle.
- **Editor do Git não abre nvim:** core.editor não está como nvim. Verificar dot_gitconfig e run_once_30; `git config --global core.editor nvim`.

## Estratégia de recuperação

- Reaplicar external: `chezmoi apply` para que o chezmoi atualize o clone em ~/.config/nvim. Para forçar atualização do external, consultar documentação do chezmoi (ex.: refresh de externals).
- Reinstalar Neovim: `brew install neovim` ou brew bundle.
- Trocar editor do Git temporariamente: `git config --global core.editor "outro-editor"`.

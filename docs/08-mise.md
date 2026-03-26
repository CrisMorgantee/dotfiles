# Mise (runtime manager)

## Objetivo

Documentar o uso do mise como gerenciador de versões de runtimes (Node, Python, etc.): ativação no Zsh, inclusão dos shims no PATH e integração com o restante do .zshrc (PATH único: Homebrew, depois mise, depois bins do usuário).

## Decisões de design

- **mise activate zsh:** Avaliado no .zshrc com `eval "$(mise activate zsh)"` quando `mise` existe no PATH. Colocado após Zinit e plugins para que o PATH já tenha o Homebrew (onde mise é instalado pelo Brewfile). mise injeta shims no PATH; versões por projeto ou globais passam a ser resolvidas via mise.
- **Ordem do PATH:** Homebrew (shellenv) primeiro; em seguida mise (shims); depois um único append no .zshrc: `$PATH:$HOME/.composer/vendor/bin:$HOME/.local/bin`. Não há `typeset -U PATH` nem múltiplos exports de PATH espalhados.
- **Uso por projeto:** Em cada repositório pode existir .mise.toml (ou arquivo equivalente suportado pelo mise) definindo versões de ferramentas; ao entrar no diretório, mise usa essa config. direnv é carregado depois do mise no .zshrc e pode complementar variáveis de ambiente por projeto.

## Arquitetura

- **Instalação:** mise instalado via Homebrew (Brewfile). Disponível em /opt/homebrew/bin/mise (Apple Silicon) após run_once_10.
- **Ativação:** Bloco no .zshrc: `if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi`. Seguido de `export PATH="$PATH:$HOME/.composer/vendor/bin:$HOME/.local/bin"`.
- **Sem wrapper custom:** Neovim e outros não usam NVIM_APPNAME ou wrapper que dependa do mise além do PATH; mise apenas expõe binários nas versões escolhidas.

## Fluxo operacional

- Shell inicia: Homebrew no PATH; Zinit e plugins carregam; mise activate adiciona shims ao PATH; PATH append adiciona composer e .local/bin; direnv hook é avaliado.
- Em diretório com .mise.toml: mise resolve as versões configuradas; comandos (node, python, etc.) usam essas versões via shims.
- Troca de projeto: ao mudar de diretório, mise e direnv reavaliam; PATH e env podem mudar conforme a config do projeto.

## Validação

- `which mise` resolve (Homebrew).
- `mise --version` retorna versão.
- Em um projeto com .mise.toml: `which node` (ou outra ferramenta gerenciada) pode apontar para path dentro do cache do mise (shim).

## Modos de falha

- **mise não no PATH:** Homebrew não carregado antes do bloco mise (ex.: .zshrc em subshell sem shellenv). Garantir ordem no .zshrc e que run_once_10 rodou.
- **Shims não atualizados:** Após instalar uma nova versão via mise, o shim pode já estar correto; se não, reiniciar o shell ou rodar `mise trust`/reentrar no diretório conforme documentação do mise.

## Estratégia de recuperação

- Reinstalar mise: `brew install mise` ou `brew bundle --file=<Brewfile>`.
- Desativar mise temporariamente: comentar o bloco `eval "$(mise activate zsh)"` e recarregar o shell; o PATH deixará de incluir os shims do mise.

Para configuração por projeto, comandos do dia a dia e exemplos de uso, ver [14-guia-de-uso.md](14-guia-de-uso.md).

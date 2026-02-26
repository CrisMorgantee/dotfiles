# Direnv

## Objetivo

Documentar o uso do direnv para variáveis de ambiente e secrets por diretório: hook no Zsh, .envrc, direnv allow e integração recomendada com Keychain/1Password para não colocar API keys no .zshrc.

## Decisões de design

- **direnv hook zsh:** Avaliado no .zshrc com `eval "$(direnv hook zsh)"` quando `direnv` existe no PATH. Posicionado após mise e PATH append para que o direnv tenha o PATH final. O hook faz com que, ao mudar de diretório, o direnv carregue ou descarregue o .envrc do diretório atual.
- **.envrc por projeto:** Em cada repositório ou pasta de projeto pode existir .envrc; o direnv carrega as variáveis definidas (export) ao entrar no diretório e as remove ao sair. Requer `direnv allow` uma vez por diretório (e por máquina) por segurança.
- **Secrets:** Nenhuma API key no .zshrc. Por projeto: usar .envrc para variáveis que o direnv pode exportar; para valores sensíveis, carregar a partir de Keychain ou 1Password (ferramentas externas ou scripts chamados pelo .envrc) em vez de gravar o secret em texto plano no .envrc. Global: Keychain ou 1Password e recuperação sob demanda.

## Arquitetura

- **Instalação:** direnv via Homebrew (Brewfile). Disponível após run_once_10.
- **Ativação:** Bloco no .zshrc: `if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi`.
- **Fluxo:** Usuário entra em diretório com .envrc → direnv executa .envrc (se allow foi dado) e exporta variáveis no ambiente do shell atual.

## Fluxo operacional

- Primeira vez em um diretório com .envrc: direnv exibe mensagem pedindo `direnv allow`. Usuário executa `direnv allow`; a partir daí o .envrc é carregado ao entrar no diretório.
- Entrada/saída: ao `cd` para o diretório, direnv carrega; ao `cd` para fora, direnv descarrega as variáveis que adicionou.
- Secrets: .envrc pode chamar um script que lê do Keychain/1Password e exporta variáveis; o secret não fica no .envrc em texto plano.

## Validação

- `direnv version` retorna versão.
- Em diretório com .envrc e após `direnv allow`: variáveis definidas no .envrc aparecem no ambiente (echo $VAR).
- Comentar o bloco direnv no .zshrc e recarregar: ao entrar no diretório, variáveis do .envrc não são carregadas (confirma que o hook é a fonte).

## Modos de falha

- **direnv não no PATH:** Homebrew não carregado ou run_once_10 não executado. Corrigir PATH e instalar direnv.
- **direnv allow não executado:** .envrc não é carregado; direnv mostra aviso. Executar `direnv allow` no diretório.
- **.envrc com erro:** direnv pode recusar carregar; mensagem de erro aparece ao entrar. Corrigir sintaxe ou comandos no .envrc.

## Estratégia de recuperação

- Reinstalar direnv: `brew install direnv` ou brew bundle.
- Revogar allow: `direnv deny` no diretório; na próxima entrada será necessário `direnv allow` novamente.
- Desativar hook: comentar `eval "$(direnv hook zsh)"` no .zshrc e recarregar; nenhum .envrc será carregado automaticamente.

Para exemplos de .envrc, layout, dotenv e uso em projetos, ver [14-guia-de-uso.md](14-guia-de-uso.md).

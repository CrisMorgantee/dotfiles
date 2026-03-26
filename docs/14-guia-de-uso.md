# Guia de uso das ferramentas

Documentação voltada ao usuário final: como configurar e usar mise, direnv e outras ferramentas do ambiente no dia a dia e nos projetos. Para arquitetura e decisões de design, ver os docs 08 (mise), 09 (direnv) e correlatos.

---

## Mise

### O que é e quando usar

O mise gerencia versões de runtimes (Node, Python, Ruby, Go, etc.) e de gerenciadores de pacotes (pnpm, npm, yarn) por projeto ou globalmente. Ao entrar em um diretório com configuração, o mise expõe os binários da versão definida nesse projeto, sem alterar o sistema inteiro.

### Configuração global (opcional)

Para definir uma versão padrão quando não houver config no projeto:

```bash
mise use -g node@20
mise use -g python@3.12
mise use -g pnpm@9
```

Isso grava em `~/.config/mise/config.toml` (ou arquivo global do mise). Recomendado apenas para ferramentas que você usa fora de projetos versionados.

### Configuração por projeto (recomendado)

No **raiz do repositório** do projeto, crie um arquivo que o mise reconhece. Duas opções suportadas:

**Opção 1: `.mise.toml`** (recomendado; formato TOML)

```toml
[tools]
node = "20"
python = "3.12"
pnpm = "9"

# Versão exata (lock)
# node = "20.10.0"
# python = "3.12.1"
# pnpm = "9.14.2"
```

**Opção 2: `.tool-versions`** (compatível com asdf)

```
node 20.10.0
python 3.12.1
pnpm 9.14.2
```

Ao entrar no diretório (`cd projeto/`), o mise passa a usar essas versões para `node`, `python`, `pnpm`, etc., nesse shell.

### Comandos úteis

| Comando | Uso |
|---------|-----|
| `mise install` | Instala as versões definidas no .mise.toml (ou .tool-versions) do diretório atual. Rode na raiz do projeto na primeira vez ou quando alguém adicionar uma nova versão. |
| `mise use node@20` | Define a versão de Node no projeto atual (cria ou atualiza .mise.toml). |
| `mise use pnpm@9` | Define a versão de pnpm no projeto atual. |
| `mise use -g node@20` | Define a versão global de Node. |
| `mise use -g pnpm@9` | Define a versão global de pnpm. |
| `mise current` | Mostra as versões em uso no diretório atual. |
| `mise ls` | Lista ferramentas e versões instaladas (cache do mise). |
| `mise trust` | Marca o diretório como confiável (útil se o mise pedir confirmação em algum fluxo). |

### Fluxo típico em um projeto novo

1. Clonar o repo do projeto.
2. Entrar no diretório: `cd meu-projeto`.
3. Se já existir `.mise.toml` ou `.tool-versions`: rodar `mise install` para instalar as versões listadas.
4. Se não existir: definir as versões desejadas, por exemplo `mise use node@20`, `mise use pnpm@9` e `mise use python@3.12`; isso cria o arquivo. Commitar o arquivo para o time.
5. A partir daí, em qualquer terminal aberto nesse diretório, `node`, `pnpm` e `python` serão os do mise.

### O que versionar no repositório

Versionar `.mise.toml` (ou `.tool-versions`) no Git. Assim todos os desenvolvedores e o CI usam as mesmas versões. Não versionar `~/.config/mise/` (config global) a menos que seja um dotfile seu; o foco é o arquivo na raiz do projeto.

---

## Direnv

### O que é e quando usar

O direnv carrega e descarrega variáveis de ambiente conforme você entra e sai de diretórios. Serve para: PATH adicional (bins do projeto), variáveis de projeto (APP_ENV, DATABASE_URL), e integração com arquivos `.env` sem exportar manualmente no shell.

### O que fazer no projeto

Na **raiz do repositório** (ou em qualquer pasta onde queira env específico), crie um arquivo `.envrc`. Na primeira vez que entrar nesse diretório, o direnv vai pedir que você execute `direnv allow`; depois disso, o conteúdo do `.envrc` será aplicado automaticamente sempre que você `cd` para lá.

### Exemplo mínimo (.envrc)

Apenas exportar variáveis:

```bash
export APP_ENV=local
export DATABASE_URL="sqlite:///./database.sqlite"
```

### Carregar arquivo .env (dotenv)

Se o projeto já tem um `.env` (e você não quer colocar secrets no .envrc):

```bash
# Carrega .env e exporta as variáveis definidas nele
dotenv
```

Requisito: o direnv precisa do comando `dotenv`. Em muitos sistemas vem no pacote do direnv ou pode ser habilitado. Alternativa sem dotenv: usar `source_env .env` se o direnv suportar (ou ler o .env manualmente com um script).

Se usar `dotenv`, mantenha `.env` no `.gitignore`; o `.envrc` pode ser versionado (e conter apenas `dotenv` ou `source_env .env`), sem gravar valores sensíveis.

### Layout de ambiente (Node, Python, etc.)

Para adicionar bins do projeto ao PATH (ex.: `node_modules/.bin`, `venv/bin`):

**Node (npm):**

```bash
layout node
# Ao entrar no dir, direnv usa a versão do Node do mise (se houver) e adiciona node_modules/.bin ao PATH
```

**pnpm:**

```bash
layout pnpm
# Usa a versão do pnpm do mise (se houver) e ajusta o PATH para os binários instalados pelo pnpm (node_modules/.bin).
# Recomendado para projetos que usam pnpm em vez de npm.
```

**Yarn:** use `layout node` (yarn coloca bins em node_modules/.bin da mesma forma) ou verifique na documentação do direnv se há `layout yarn`.

**Python (venv):**

```bash
layout python
# Cria/usa um venv na pasta .direnv ou padrão do direnv; ativa e adiciona ao PATH
```

**Combinando com mise:** Em projetos com `.mise.toml`, o mise já define a versão do Node/pnpm/Python; o direnv só adiciona PATH e layout:

```bash
layout node   # projeto npm
layout pnpm   # projeto pnpm
layout python # projeto Python
```

### Comandos úteis

| Comando | Uso |
|---------|-----|
| `direnv allow` | Necessário na primeira vez em um diretório com .envrc (e após alterar o .envrc). Autoriza o direnv a executar o .envrc nesse diretório. |
| `direnv deny` | Revoga a autorização; na próxima entrada o direnv pedirá `direnv allow` de novo. |
| `direnv status` | Mostra se o diretório atual tem .envrc, se está allowed e quais variáveis foram carregadas. |
| `direnv reload` | Recarrega o .envrc do diretório atual (útil após editar o .envrc). |

### Boas práticas

- **Não colocar secrets em texto plano no .envrc.** Se o .envrc for versionado, qualquer valor sensível vaza. Use `dotenv` apontando para um `.env` que está no .gitignore, ou um script que lê do Keychain/1Password e exporta as variáveis.
- **Versionar .envrc quando for seguro.** Conteúdos como `layout node`, `layout pnpm`, `export APP_ENV=local` ou `dotenv` são seguros. Variáveis com secrets não.
- **.env no .gitignore.** Arquivo `.env` normalmente contém secrets; nunca versionar.

### Fluxo típico em um projeto novo

1. Na raiz do projeto, criar `.envrc` (ex.: `layout node`, `layout pnpm` ou `dotenv` + exports não sensíveis).
2. Se usar `.env`: criar a partir de `.env.example` (versionado), copiar para `.env`, preencher valores locais; manter `.env` no .gitignore.
3. No terminal, entrar no diretório: `cd meu-projeto`.
4. O direnv exibirá que o .envrc não está autorizado. Rodar `direnv allow`.
5. Nas próximas vezes, ao entrar no diretório, o ambiente será carregado automaticamente.

---

## Outras ferramentas (referência rápida)

### Zoxide (navegação)

- **Uso:** Em vez de `cd caminho/longo`, digite `z parte-do-caminho` (ou `j parte-do-caminho` se tiver alias). O zoxide usa frecência e relevância para ir ao diretório mais provável.
- **Exemplo:** `z proj` pode levar a `~/workspace/meu-projeto`. Não é necessário configurar por projeto; o uso diário vai “treinando” o ranking.

### Fzf-tab (completar com Tab)

- **Uso:** Ao pressionar Tab em comandos que têm muitas opções (arquivos, branches, etc.), o fzf-tab abre um seletor interativo. Navegue com setas ou digite para filtrar; Enter escolhe o item.
- **Não exige configuração no projeto;** já ativo pelo Zinit no .zshrc.
- **Warp:** se o Tab não abrir o seletor, rode `exec zsh` para recarregar o shell (o plugin pode carregar de forma assíncrona).

### fzf (atalhos e funções)

- **Tab:** continua sendo do **fzf-tab** (completion do Zsh).
- **Atalhos clássicos do fzf:** `Ctrl-R` (histórico), `Ctrl-T` (arquivos no prompt), `Alt-C` (cd) — habilitados via módulo `~/.config/zsh/55-fzf-keybindings.zsh` sem ativar completion do fzf (evita conflito com fzf-tab).
- **Comandos úteis:**
  - `nv [query]`: seleciona **arquivo ou diretório** com fzf e abre no Neovim.
  - `nv --no-dir [query]`: limita a seleção a **arquivos** (útil se você quer só abrir arquivos).
  - `kp`: seleciona processo(s) e envia SIGTERM.
  - `kp -f` / `kp --force`: envia SIGKILL (kill -9) — use só quando necessário.
  - `gb`: troca de branch com preview.
  - `gcm`: navegador de commits (seleciona e executa `git show`).
  - `gcm --copy`: copia o hash do commit selecionado (usa `pbcopy` quando disponível).
  - `gc "mensagem"`: helper de commit (comita só o que já estiver staged). Flags comuns:
    - `gc -i "msg"`: stage interativo (`git add -p`) + commit
    - `gc -a "msg"`: stage tudo (`git add -A`) + commit
    - `gc -p "msg"`: push após commitar
    - `gc -s "msg"`: define `SKIP_GIT_HOOKS=1` (hooks que respeitam essa variável “pulam”)
    - `gc -n "msg"`: passa `--no-verify` para `git commit` (e para `git push` quando usar `-p`)
  - `dps [logs|exec|stop]`: selector de containers Docker.
  - `sshf`: selector de hosts do `~/.ssh/config` e `~/.ssh/config.local`.
  - `ts [nome]`: selector/attach de sessão tmux (ou cria sessão).
  - `af [args...]`: selector de comandos do `php artisan` e executa o comando escolhido (usa JSON quando disponível — compatível com `commands` como lista ou mapa — com fallback para `artisan list --raw`).

### Histórico (setas com prefixo)

- **Uso:** Digite o início de um comando (ex.: `git commit`) e pressione **Seta para cima**. O Zsh mostra apenas entradas do histórico que **começam** com esse prefixo. Seta para baixo percorre na ordem inversa.
- **Não exige configuração no projeto;** já ativo no shell (history-beginning-search).

### Bat e eza (saída de arquivos)

- **bat:** Para ver arquivo com syntax highlighting: `bat arquivo` ou use o alias `bcat arquivo` (tema Nord). O `cat` do sistema não é alterado globalmente.
- **eza:** Aliases `l` (listagem longa) e `lt` (árvore 2 níveis). Cores via vivid (Nord); já configurado no .zshrc.

---

## Ordem de aplicação no mesmo diretório

Se um projeto tiver **mise** e **direnv**:

1. Ao entrar no diretório, o **mise** é avaliado primeiro (pelo hook no .zshrc): versões de Node/Python/etc. passam a ser as do .mise.toml.
2. Em seguida o **direnv** carrega o .envrc: layout (node/python), PATH adicional, variáveis exportadas.
3. Resultado: você tem a versão correta do runtime e o ambiente (PATH, variáveis) do projeto. Ao sair do diretório, o direnv descarrega; o mise passa a usar a config do novo diretório (ou a global).

Nenhuma ação extra é necessária além de manter `.mise.toml` e `.envrc` na raiz e rodar `mise install` e `direnv allow` quando for a primeira vez no projeto.

---

## Exemplo: projeto Node + pnpm

Fluxo completo para um repositório que usa Node e pnpm:

1. **Na raiz do projeto**, crie ou edite `.mise.toml`:

```toml
[tools]
node = "20"
pnpm = "9"
```

2. Rode `mise install` para instalar as versões (Node e pnpm são instalados pelo mise).

3. Crie `.envrc` na raiz:

```bash
layout pnpm
```

4. Execute `direnv allow`.

5. Instale as dependências do projeto: `pnpm install`. A partir daí, ao entrar nesse diretório, o mise garante `node` e `pnpm` corretos e o direnv garante que os bins de `node_modules/.bin` estejam no PATH.

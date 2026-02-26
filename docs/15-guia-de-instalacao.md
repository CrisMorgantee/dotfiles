# Guia de instalação (passo a passo)

Este guia é para quem está começando do zero: Mac novo ou reinstalação, sem dotfiles nem Homebrew. Siga a ordem dos passos; cada um traz o comando a executar, o que você deve ver na tela e o que fazer em caso de erro. Para a visão técnica e decisões de design, ver [02-bootstrap-from-zero.md](02-bootstrap-from-zero.md).

---

## Antes de começar

**O que você precisa:**

- Mac com macOS. Este ambiente foi testado em **Apple Silicon** (M1/M2/M3). Em Mac com chip Intel, o Homebrew usa `/usr/local`; o .zshrc só adiciona `/opt/homebrew`. Se usar Intel, siga as instruções do instalador do Homebrew para colocar o `brew` no PATH (ex.: adicionar o `eval` sugerido no `.zprofile`).
- Acesso à internet.
- Conta no GitHub (para clonar o repositório dos dotfiles e, se for o caso, o repositório da config do Neovim).
- Seu **nome** e **e-mail** para configurar o Git (serão usados em commits). Tenha esses dados à mão.

**Tempo estimado:** 15 a 30 minutos (depende da rede e do tempo de instalação do Homebrew e dos pacotes).

---

## Passo 1: Xcode Command Line Tools

O instalador do Homebrew e várias ferramentas dependem dos Command Line Tools da Apple.

1. Abra o **Terminal** (Aplicativos > Utilitários > Terminal) ou use o Terminal integrado do sistema.
2. Rode:

```bash
xcode-select -p
```

**Se aparecer um path** (ex.: `/Library/Developer/CommandLineTools`): os tools já estão instalados. Vá para o Passo 2.

**Se aparecer erro** ("xcode-select: error: unable to get active developer directory"): os tools não estão instalados. Rode:

```bash
xcode-select --install
```

3. Abre uma janela pedindo para instalar "Command Line Developer Tools". Clique em **Instalar** e aguarde o fim da instalação.
4. Quando terminar, rode de novo `xcode-select -p` para confirmar. Depois vá para o Passo 2.

---

## Passo 2: Instalar o chezmoi

O chezmoi é a ferramenta que vai aplicar os dotfiles e rodar os scripts de configuração. Em um Mac novo ainda não há Homebrew, então usamos o script oficial do chezmoi.

1. No Terminal, execute (copie e cole a linha inteira):

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

2. O script baixa e instala o chezmoi. Ao final, deve aparecer uma mensagem indicando que a instalação foi concluída.
3. Confirme que o chezmoi está disponível:

```bash
chezmoi --version
```

Deve aparecer o número da versão (ex.: `chezmoi version 2.x.x`).

**Se der erro:** Verifique sua conexão com a internet. Se estiver atrás de proxy, pode ser necessário configurar variáveis de ambiente (`HTTP_PROXY`, `HTTPS_PROXY`) antes de rodar o script. Documentação: [get.chezmoi.io](https://get.chezmoi.io).

---

## Passo 3: Clonar o repositório e aplicar a configuração

Neste passo você vai dizer ao chezmoi **qual repositório** usar (a URL do seu repo de dotfiles) e informar **nome e e-mail** para o Git. O chezmoi vai clonar o repo, copiar os arquivos de configuração para o lugar certo e rodar os scripts que instalam Homebrew, pacotes e configuram o sistema.

**Substitua** na linha abaixo a URL do repositório, o nome e o e-mail pelos seus (ou use o exemplo com os dados deste ambiente):

Comando único (uma linha):

```bash
chezmoi init --apply -D name="Seu Nome" -D email="seu@email.com" -- URL_DO_SEU_REPO
```

**Exemplo** (repositório e identidade deste ambiente):

```bash
chezmoi init --apply -D name="Cristiano Morgante" -D email="cristiano@morgante.com.br" -- git@github.com:CrisMorgantee/dotfiles.git
```

Se preferir HTTPS em vez de SSH:

```bash
chezmoi init --apply -D name="Cristiano Morgante" -D email="cristiano@morgante.com.br" -- https://github.com/CrisMorgantee/dotfiles.git
```

**O que acontece:**

1. O chezmoi clona o repositório para `~/.local/share/chezmoi` (ou path configurado).
2. Aplica os dotfiles (`.zshrc`, `.gitconfig`, `.p10k.zsh`, etc.) nos locais corretos da sua home.
3. Executa três scripts na ordem:
   - **run_once_10:** Instala o Homebrew (se ainda não existir) e instala todos os pacotes do Brewfile (Zsh, Zinit, Neovim, mise, direnv, eza, bat, git, delta, etc.). Pode levar vários minutos.
   - **run_once_20:** Aplica defaults do macOS (teclado, Finder, Dock, firewall, etc.). **Vai pedir sua senha de administrador (sudo)** uma vez. Digite a senha quando solicitado.
   - **run_once_30:** Configura o Git global (editor, pull com rebase, delta, identidade com o nome e e-mail que você passou).

**Se o repositório for privado ou usar SSH:** Tenha a chave SSH configurada no Mac ou use a URL HTTPS e faça login quando o Git pedir (ou use um token). Na primeira vez, o macOS pode pedir permissão para acessar chaves ou rede.

**Se aparecer erro de rede ou de Git:** Verifique a URL do repo, a conexão e as credenciais (SSH ou HTTPS). Depois disso, você pode tentar de novo com:

```bash
chezmoi apply -D name="Seu Nome" -D email="seu@email.com"
```

(Isso reaplica a config; os run_once que já rodaram não repetem as mesmas ações destrutivas.) Exemplo com os dados deste ambiente:

```bash
chezmoi apply -D name="Cristiano Morgante" -D email="cristiano@morgante.com.br"
```

---

## Passo 4: Abrir o terminal (Warp) e usar o Zsh

O Brewfile instala o **Warp** como terminal. O ambiente está preparado para usar o **Zsh** como shell padrão.

1. Abra o **Warp** (via Spotlight: Cmd+Espaço, digite "Warp").
2. O Warp deve abrir usando o Zsh e carregar o seu `.zshrc`. Você deve ver:
   - Um prompt com estilo “Pure” (duas linhas, diretório, branch do Git se estiver em um repo).
   - Cores no tema Nord.

**Se o Warp não estiver usando Zsh:** Nas preferências do Warp, defina o shell padrão como **Zsh** (path típico: `/opt/homebrew/bin/zsh` ou `/bin/zsh` em Mac com Homebrew).

**Se o prompt não carregar ou der erro:** Feche o Warp e abra de novo. Se ainda falhar, ver [troubleshooting.md](troubleshooting.md) (seção “Zinit ou Powerlevel10k não carregam”).

---

## Passo 5 (opcional): Config local da máquina

Se você precisar de configuração só nesta máquina (por exemplo, PATH do Herd para Laravel, ou outro binário local), use o arquivo `.zshrc.local`, que **não** é versionado.

1. Copie o exemplo para o arquivo local:

```bash
cp ~/.zshrc.local.example ~/.zshrc.local
```

2. Edite com o editor que preferir (ex.: Neovim já instalado):

```bash
nvim ~/.zshrc.local
```

3. Descomente ou adicione as linhas que precisar (ex.: PATH do Herd). Salve e feche. Na próxima abertura do terminal, o `.zshrc` já carrega o `.zshrc.local` automaticamente.

---

## Passo 6: Verificar se está tudo certo

Rode os comandos abaixo no Warp (ou em qualquer terminal configurado para Zsh). Todos devem funcionar sem erro.

| O que verificar | Comando | Resultado esperado |
|-----------------|---------|--------------------|
| Shell é Zsh | `echo $ZSH_VERSION` | Número da versão (ex.: 5.9) |
| mise instalado | `mise --version` | Versão do mise |
| direnv instalado | `direnv version` | Versão do direnv |
| Listagem (eza) | `l` | Lista o diretório com cores |
| Ripgrep | `g --version` | Versão do ripgrep |
| Neovim | `nvim --version` | Versão do Neovim |
| Git configurado | `git config --global user.name` | Seu nome |
| Git configurado | `git config --global user.email` | Seu e-mail |

**Histórico compartilhado:** Abra uma segunda aba ou janela do Warp, digite um comando em uma delas (ex.: `echo teste`) e na outra pressione **Seta para cima**. O comando deve aparecer (compartilhamento de histórico entre terminais).

**Se algo falhar:** Consulte [troubleshooting.md](troubleshooting.md). Os problemas mais comuns são: Homebrew não no PATH (rodar o run_once_10), identidade do Git vazia (passar `name` e `email` no apply), ou prompt não carregando (verificar ordem do .zshrc e instalação do Zinit).

---

## Resumo dos comandos (copy-paste)

Use este bloco como referência. Para este ambiente (Cristiano Morgante / CrisMorgantee/dotfiles), os comandos já vêm preenchidos; para outro usuário, substitua nome, e-mail e URL do repo.

```bash
# 1) Command Line Tools (se necessário)
xcode-select -p || xcode-select --install

# 2) Instalar chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 3) Aplicar dotfiles (exemplo: Cristiano Morgante / CrisMorgantee/dotfiles)
chezmoi init --apply -D name="Cristiano Morgante" -D email="cristiano@morgante.com.br" -- git@github.com:CrisMorgantee/dotfiles.git

# 4) Abrir o Warp e usar Zsh; opcional: config local
cp ~/.zshrc.local.example ~/.zshrc.local   # só se for usar config local
```

Depois, abra o Warp e rode os comandos da tabela do Passo 6 para validar.

---

## Próximos passos

- Para usar **mise** e **direnv** em projetos (Node, pnpm, Python, etc.), ver [14-guia-de-uso.md](14-guia-de-uso.md).
- Para entender a arquitetura do ambiente (run_once, dotfiles, data), ver [01-architecture-overview.md](01-architecture-overview.md) e [11-chezmoi-architecture.md](11-chezmoi-architecture.md).
- Para problemas após a instalação, ver [troubleshooting.md](troubleshooting.md).

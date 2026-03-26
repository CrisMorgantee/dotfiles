# Filosofia

## Objetivo

Definir os princípios que regem este ambiente de desenvolvimento: reprodutibilidade a partir de uma única fonte de verdade, dotfiles como código versionado, zero secrets em arquivos rastreados e um modelo em camadas (sistema, runtime, projeto), para que reinstalações, onboarding e manutenção permaneçam determinísticos e auditáveis.

## Decisões de design

- **chezmoi em vez de alternativas:** Ferramenta única para aplicação de dotfiles, scripts run_once e repositórios externos. Estado declarativo; sem árvores de symlinks ou scripts ad hoc. Trade-off: curva de aprendizado e layout do source dir; benefício: apply idempotente e diff explícito.
- **Brewfile único:** Todas as fórmulas e casks do Homebrew ficam em um arquivo. O bootstrap run_once instala ou atualiza a partir dele. Evita deriva entre máquinas; único lugar para adicionar/remover pacotes.
- **run_once para efeitos colaterais:** Identidade, config global do git, defaults do macOS e bundle do Homebrew são aplicados via scripts run_once. Rodam uma vez por máquina após o primeiro apply; idempotentes quando possível para que reexecutar seja seguro. Mantém dotfiles restritos ao conteúdo que pertence ao próprio arquivo.
- **.zshrc vs .zshrc.local:** O `.zshrc` versionado não contém caminhos específicos da máquina (ex.: Herd), nem secrets, nem exports pontuais. Dados por máquina e secretos vão em `~/.zshrc.local` (não versionado; ver `.zshrc.local.example`).
- **Secrets:** Nenhuma API key ou token em `.zshrc` ou em qualquer arquivo versionado. Por projeto: `.envrc` com direnv; carregar secrets via direnv ou ferramentas que leem do Keychain/1Password. Global: Keychain ou 1Password e recuperação segura quando necessário.

## Arquitetura

Camadas (o topo depende da base):

1. **Sistema:** macOS (Apple Silicon), Xcode Command Line Tools (ou equivalente), Homebrew. Fornece CLI base e gerenciador de pacotes.
2. **Shell:** Zsh, Zinit, Powerlevel10k, plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting). Fornece shell interativo e prompt.
3. **Runtime:** mise (versões de ferramentas), direnv (env por diretório). Fornece runtimes e variáveis de ambiente por projeto.
4. **Ferramentas:** CLI (eza, bat, ripgrep, fd, delta, lazygit), config do Git, Neovim (config via repo externo). Tudo consumido a partir da camada shell/runtime.

Fluxo de configuração: editar no diretório source do chezmoi, executar `chezmoi apply`; scripts run_once rodam no primeiro apply (ou quando reexecutados manualmente).

## Fluxo operacional

1. Alteração é feita no diretório source do chezmoi (ex.: `~/.local/share/chezmoi` ou o clone do repo).
2. `chezmoi diff` (opcional) mostra o que seria aplicado.
3. `chezmoi apply` atualiza os targets (ex.: `~/.zshrc`, `~/.gitconfig`) e, uma vez por máquina, executa os scripts run_once.
4. Validação: shell inicia sem erro, comandos necessários existem, nenhum secret em `chezmoi managed`.

## Validação

- Executar `chezmoi managed` e garantir que nenhum path listado deve conter secrets.
- Se `chezmoi verify` estiver configurado, executá-lo após o apply.
- Fazer grep no source dir por padrões que indiquem secrets (API key, token, password) e confirmar ausência em arquivos rastreados.

## Modos de falha

- **Data do chezmoi ausente:** run_once_30_git espera `.data.name` e `.data.email` para identidade quando a identidade global do git não está definida. Sem data, a identidade não é definida no primeiro bootstrap.
- **run_once falha (rede):** run_once_10 (install/bundle do Homebrew) pode falhar por rede ou permissões; run_once_20 (defaults do macOS) exige sudo e pode ser cancelado.
- **Conflito dotfile vs run_once:** Se um dotfile e um script run_once definem a mesma opção do git, a ordem de aplicação e a idempotência do run_once determinam o estado final. Política: dotfiles são a fonte de verdade de conteúdo; run_once só define o que não pode viver em dotfile (ex.: identidade quando se usa template data).

## Estratégia de recuperação

- Reaplicar todos os dotfiles: `chezmoi apply`.
- Reexecutar um run_once manualmente: rodar o script a partir do source dir (substituir `{{ .chezmoi.sourceDir }}` pelo path real do source se necessário).
- Restaurar o source dir a partir de backup ou clonar o repo de novo e executar `chezmoi apply` novamente.

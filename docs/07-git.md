# Arquitetura Git

## Objetivo

Definir a configuração global do Git: fonte de verdade em `dot_gitconfig.tmpl` (incluindo política `pull.rebase = true`), papel do run_once_30 para identidade e idempotência no bootstrap, uso do delta como pager, e ignore global.

## Referência das configurações (run_once_30_git.sh.tmpl)

Cada opção aplicada pelo script e o efeito prático:

### Identidade (somente se ainda não definida)

| Opção | Valor (exemplo) | O que faz |
|-------|-----------------|-----------|
| `user.name` | `{{ .data.name }}` | Nome usado em commits; preenchido só se não existir e houver `data.name` no chezmoi. |
| `user.email` | `{{ .data.email }}` | E-mail usado em commits; preenchido só se não existir e houver `data.email` no chezmoi. |

### Core e fluxo de trabalho

| Opção | Valor | O que faz |
|-------|--------|-----------|
| `init.defaultBranch` | `main` | Nova branch padrão ao fazer `git init`. |
| `core.editor` | `nvim` | Editor usado para mensagens de commit e rebase interativo. |
| `core.autocrlf` | `input` | Converte CRLF→LF ao commitar; não converte ao fazer checkout (evita mudanças desnecessárias em arquivos de texto no macOS/Linux). |
| `fetch.prune` | `true` | Ao fazer fetch, remove referências a branches que já não existem no remoto. |
| `fetch.pruneTags` | `true` | Remove referências a tags que foram removidas no remoto. |
| `pull.rebase` | `true` | `git pull` faz rebase em vez de merge, mantendo histórico linear. |
| `push.default` | `simple` | `git push` sem argumentos envia só a branch atual e só se o nome coincidir com a do remoto. |
| `branch.autosetuprebase` | `always` | Novas branches são configuradas para fazer rebase ao dar pull. |
| `rebase.autostash` | `true` | Ao iniciar rebase com working tree sujo, faz stash automático e restaura depois. |
| `rerere.enabled` | `true` | Reutiliza resoluções de conflito em rebases/merges repetidos. |
| `push.autoSetupRemote` | `true` | Ao dar push em branch nova, cria o tracking no remoto se não existir. |

### Delta (se o binário `delta` estiver instalado)

| Opção | Valor | O que faz |
|-------|--------|-----------|
| `core.pager` | `delta` | Usa delta para exibir diffs e logs coloridos. |
| `interactive.diffFilter` | `delta --color-only` | Diffs no rebase interativo passam pelo delta. |
| `delta.navigate` | `true` | Navegação entre hunks no pager. |
| `delta.side-by-side` | `true` | Diff lado a lado. |
| `delta.line-numbers` | `true` | Mostra números de linha. |
| `delta.hyperlinks` | `true` | Links clicáveis no terminal (ex.: para abrir arquivo no editor). |
| `delta.hyperlinks-file-link-format` | `vscode://file/{path}:{line}` | Formato do link para abrir no editor. |
| `delta.syntax-theme` | `Nord` | Tema de sintaxe do delta. |
| `delta.features` | `decorations` | Ativa decorações (commit, file, hunk). |
| `delta.decorations.commit-decoration-style` | `bold yellow box` | Estilo do cabeçalho de commit no diff. |
| `delta.decorations.file-style` | `bold yellow` | Estilo do nome do arquivo. |
| `delta.decorations.hunk-header-style` | `cyan` | Estilo do cabeçalho de hunk. |

### Aliases

O run_once_30 define os aliases mínimos (st, co, br, lg). O `dot_gitconfig.tmpl` é a referência versionada e pode sobrescrever `lg` (ex.: formato estendido com autor e data) e adicionar outros (ex.: `pf`).

| Alias | Comando (run_once / `dot_gitconfig.tmpl`) | O que faz |
|-------|-------------------------------------|-----------|
| `st` | `status -sb` | Status resumido com branch. |
| `co` | `checkout` | Atalho para checkout. |
| `br` | `branch -vv` | Lista branches com tracking e último commit. |
| `lg` | `log --oneline --decorate --graph --all` (run_once) ou formato estendido no dotfile | Log com grafo e todas as branches. |
| `pf` | `push --force-with-lease` | Push forçado com proteção (apenas no `dot_gitconfig.tmpl`). |

### Ignore global

O script cria `~/.config/git/ignore` e adiciona (se ainda não existirem) os padrões abaixo. Define `core.excludesfile` para esse arquivo, para que o Git ignore esses itens em todos os repositórios.

- **macOS:** `.DS_Store`, `.AppleDouble`, `.LSOverride`, `Icon?`, `._*`, `.Spotlight-V100`, `.Trashes`
- **Editor temp:** `*.swp`, `*.swo`, `*~`
- **Logs:** `*.log`, `npm-debug.log*`, `yarn-debug.log*`, `pnpm-debug.log*`
- **Archives:** `*.zip`, `*.tar`, `*.gz`, `*.rar` (se um projeto precisar versionar algum, use `git add -f`)

## Decisões de design

- **Política pull.rebase true:** Única fonte de verdade é o `dot_gitconfig.tmpl`, seção `[pull] rebase = true`. Pull sempre faz rebase em vez de merge. O run_once_30_git também executa `git config --global pull.rebase true` para garantir o valor em máquinas novas (idempotente); o conteúdo versionado que prevalece no dia a dia é o do template renderizado.
- **`dot_gitconfig.tmpl` versionado:** Contém init.defaultBranch, core (pager, editor, autocrlf, excludesfile com path `~/.config/git/ignore`), interactive.diffFilter, delta (navigate, side-by-side, line-numbers, hyperlinks, syntax-theme Nord, decorations), merge.conflictstyle, [pull] rebase = true e aliases (st, co, br, lg, pf). A seção `[user]` só é renderizada quando `data.name` e `data.email` estão definidos, evitando identidade hardcoded no repo.
- **Identidade via data:** Em bootstrap do zero, se user.name/user.email não estão configurados, run_once_30 usa `{{ .data.name }}` e `{{ .data.email }}`. Para reinstalação limpa é necessário fornecer data ao chezmoi (documentado em 02-bootstrap e 11-chezmoi).
- **Delta:** core.pager e interactive.diffFilter; tema Nord; decorations (commit, file, hunk-header). Configurado no `dot_gitconfig.tmpl` e repetido no run_once_30 quando delta está instalado, para idempotência.
- **Global ignore:** Arquivo em ~/.config/git/ignore; run_once_30 cria o diretório, adiciona entradas (macOS, editor temp, logs, archives) de forma idempotente e seta core.excludesfile.

## Arquitetura

- **Artefatos:** `dot_gitconfig.tmpl` → ~/.gitconfig. run_once_30_git.sh.tmpl executa uma vez: identidade (se faltar e data existir), init.defaultBranch, core.editor/autocrlf, fetch.prune/pruneTags, pull.rebase, push.default/autoSetupRemote, branch.autosetuprebase, rebase.autostash, rerere, delta (se instalado), aliases mínimos (st, co, br, lg), criação do arquivo de ignore e core.excludesfile. O template renderizado prevalece para aliases e pull.rebase após apply.
- **Ordem:** `dot_gitconfig.tmpl` é aplicado pelo chezmoi apply; run_once_30 roda após e pode sobrescrever apenas o que não está versionado no dotfile (ex.: identity quando vinda de template). Para opções versionadas (pull.rebase, delta), o template renderizado é a referência; run_once apenas reforça em bootstrap.

## Fluxo operacional

- Após primeiro apply: run_once_30 roda e define identidade (se data fornecida), defaults e delta. Leituras subsequentes de config vêm de ~/.gitconfig (atualizado pelo chezmoi a partir do `dot_gitconfig.tmpl`).
- Alteração de config: editar `dot_gitconfig.tmpl` no source dir, `chezmoi apply`; não é necessário rodar run_once_30 de novo para opções já no dotfile.
- Alteração de identidade em máquina existente: editar ~/.gitconfig diretamente ou usar git config --global; para nova máquina, usar data no chezmoi ou run_once_30 com data.

## Validação

- `git config --global pull.rebase` retorna true.
- `git config --global core.pager` retorna delta (se delta instalado).
- `git config --global user.name` e user.email preenchidos (em bootstrap com data).
- `git config --global core.excludesfile` aponta para ~/.config/git/ignore; arquivo existe e contém os padrões de ignore (macOS, editor temp, logs, archives).

## Modos de falha

- **Identidade vazia após bootstrap:** Data não fornecida ao chezmoi; run_once_30 não define name/email. Fornecer data e reaplicar ou configurar manualmente.
- **Delta não usado:** delta não instalado (Brewfile não aplicado ou run_once_10 falhou). run_once_30 detecta e não seta core.pager; Git usa pager padrão. Instalar delta e rodar run_once_30 ou setar core.pager manualmente.
- **Conflito entre `dot_gitconfig.tmpl` e run_once:** Se o template renderizado for aplicado depois do run_once, o conteúdo do dotfile prevalece. Ordem normal do chezmoi: dotfiles aplicados, depois run_once; assim run_once pode ter rodado primeiro e o apply do dotfile sobrescreve. Manter pull.rebase e opções de delta no template para consistência.

## Estratégia de recuperação

- Reaplicar `dot_gitconfig.tmpl`: `chezmoi apply` para restaurar ~/.gitconfig a partir do source.
- Redefinir identidade: adicionar name/email ao data do chezmoi, `chezmoi apply`, e se run_once_30 já tiver rodado, `git config --global user.name "..." user.email "..."`.
- Restaurar ignore global: run_once_30 recria o arquivo e as entradas; reexecutar o script (substituindo source dir) ou editar ~/.config/git/ignore manualmente.

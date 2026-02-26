# Arquitetura Git

## Objetivo

Definir a configuração global do Git: fonte de verdade em dot_gitconfig (incluindo política `pull.rebase = true`), papel do run_once_30 para identidade e idempotência no bootstrap, uso do delta como pager, e ignore global.

## Decisões de design

- **Política pull.rebase true:** Única fonte de verdade é o dot_gitconfig, seção `[pull] rebase = true`. Pull sempre faz rebase em vez de merge. O run_once_30_git também executa `git config --global pull.rebase true` para garantir o valor em máquinas novas (idempotente); o conteúdo versionado que prevalece no dia a dia é o do dot_gitconfig.
- **dot_gitconfig versionado:** Contém init.defaultBranch, core (pager, editor, autocrlf, excludesfile), interactive.diffFilter, delta (navigate, side-by-side, line-numbers, hyperlinks, syntax-theme Nord, decorations), merge.conflictstyle, user (name/email podem estar fixos no arquivo; run_once_30 só preenche quando não existem e quando há data).
- **Identidade via data:** Em bootstrap do zero, se user.name/user.email não estão configurados, run_once_30 usa `{{ .data.name }}` e `{{ .data.email }}`. Para reinstalação limpa é necessário fornecer data ao chezmoi (documentado em 02-bootstrap e 11-chezmoi).
- **Delta:** core.pager e interactive.diffFilter; tema Nord; decorations (commit, file, hunk-header). Configurado no dot_gitconfig e repetido no run_once_30 quando delta está instalado, para idempotência.
- **Global ignore:** Arquivo em ~/.config/git/ignore; run_once_30 cria o diretório, adiciona entradas (.DS_Store, .idea/, .vscode/, *.swp, *.swo) de forma idempotente e seta core.excludesfile.

## Arquitetura

- **Artefatos:** dot_gitconfig → ~/.gitconfig. run_once_30_git.sh.tmpl executa uma vez: identidade (se faltar e data existir), init.defaultBranch, core.editor/autocrlf, fetch.prune/pruneTags, pull.rebase, push.default/autoSetupRemote, branch.autosetuprebase, rebase.autostash, rerere, delta (se instalado), aliases (st, co, br, lg), criação do arquivo de ignore e core.excludesfile.
- **Ordem:** dot_gitconfig é aplicado pelo chezmoi apply; run_once_30 roda após e pode sobrescrever apenas o que não está versionado no dotfile (ex.: identity quando vinda de template). Para opções versionadas (pull.rebase, delta), o dot_gitconfig é a referência; run_once apenas reforça em bootstrap.

## Fluxo operacional

- Após primeiro apply: run_once_30 roda e define identidade (se data fornecida), defaults e delta. Leituras subsequentes de config vêm de ~/.gitconfig (atualizado pelo chezmoi a partir do dot_gitconfig).
- Alteração de config: editar dot_gitconfig no source dir, `chezmoi apply`; não é necessário rodar run_once_30 de novo para opções já no dotfile.
- Alteração de identidade em máquina existente: editar ~/.gitconfig diretamente ou usar git config --global; para nova máquina, usar data no chezmoi ou run_once_30 com data.

## Validação

- `git config --global pull.rebase` retorna true.
- `git config --global core.pager` retorna delta (se delta instalado).
- `git config --global user.name` e user.email preenchidos (em bootstrap com data).
- `git config --global core.excludesfile` aponta para ~/.config/git/ignore; arquivo existe e contém .DS_Store etc.

## Modos de falha

- **Identidade vazia após bootstrap:** Data não fornecida ao chezmoi; run_once_30 não define name/email. Fornecer data e reaplicar ou configurar manualmente.
- **Delta não usado:** delta não instalado (Brewfile não aplicado ou run_once_10 falhou). run_once_30 detecta e não seta core.pager; Git usa pager padrão. Instalar delta e rodar run_once_30 ou setar core.pager manualmente.
- **Conflito entre dot_gitconfig e run_once:** Se o dot_gitconfig for aplicado depois do run_once, o conteúdo do dotfile prevalece. Ordem normal do chezmoi: dotfiles aplicados, depois run_once; assim run_once pode ter rodado primeiro e o apply do dotfile sobrescreve. Manter pull.rebase e opções de delta no dot_gitconfig para consistência.

## Estratégia de recuperação

- Reaplicar dot_gitconfig: `chezmoi apply` para restaurar ~/.gitconfig a partir do source.
- Redefinir identidade: adicionar name/email ao data do chezmoi, `chezmoi apply`, e se run_once_30 já tiver rodado, `git config --global user.name "..." user.email "..."`.
- Restaurar ignore global: run_once_30 recria o arquivo e as entradas; reexecutar o script (substituindo source dir) ou editar ~/.config/git/ignore manualmente.

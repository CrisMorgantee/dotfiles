# Arquitetura Chezmoi

## Objetivo

Descrever como o chezmoi gerencia este ambiente: source directory, targets dos dotfiles e run_once, externals, .chezmoiignore, uso de data (name, email) e operações diff/apply para manutenção e recuperação.

## Decisões de design

- **Source directory:** O repositório do chezmoi (clone ou ~/.local/share/chezmoi) é o source. Contém arquivos com prefixo `dot_` (aplicados em ~/ com o ponto), run_once_*.sh.tmpl (executados uma vez por máquina), homebrew/Brewfile e .chezmoiexternal.toml. Não editar os targets em ~/ para alterações permanentes; editar no source e aplicar.
- **Data para identidade Git:** run_once_30_git usa `{{ .data.name }}` e `{{ .data.email }}` para definir user.name e user.email quando ainda não estão configurados. Para bootstrap do zero é obrigatório fornecer data em `~/.config/chezmoi/chezmoi.toml`, na seção `[data]`. Documentado em 02-bootstrap-do-zero.md e aqui.
- **run_once:** Scripts run_once_10, _20, _30, _40 são executados uma vez após o apply; o chezmoi registra que já rodaram. Para reexecutar é necessário usar a opção apropriada do chezmoi (ex.: run_once novamente) ou executar o script manualmente com o path do source substituído onde necessário.
- **.chezmoiscripts (hooks):** Scripts em `.chezmoiscripts/` com nome `run_once_before_*` ou `run_once_after_*` rodam automaticamente antes/depois do apply. Usado aqui para criar diretórios-base (`~/.config`, `~/.config/nvim`) em bootstrap limpo e para lidar com configurações locais/injetadas por ferramentas externas (ex.: Herd) sem gerar churn no repo.
- **Externals:** .chezmoiexternal.toml define `.config/nvim` como git-repo externo `git@github.com:Simplify-Technology/svim.git`. O chezmoi clona/atualiza no target; refreshPeriod 168h. Conteúdo do nvim não está no source; está no repo externo.
- **.chezmoiignore:** Ignora .zshrc.local (não versionado), .DS_Store, padrões para chaves e secrets (**/*.pem, **/*.key, **/id_*, **/*secret*, **/*token*, **/*credentials*), herd-*. Garante que secrets e arquivos locais não sejam incluídos acidentalmente.
- **Separação público/privado:** O `~/.ssh/config` versionado contém apenas defaults seguros e inclui `~/.ssh/config.local` para hosts privados não versionados. Backups e históricos locais devem ficar fora do Git.

## Arquitetura

- **Mapeamento:** dot_zshrc → ~/.zshrc; dot_config/zsh/*.zsh → ~/.config/zsh/*.zsh; dot_gitconfig.tmpl → ~/.gitconfig; dot_p10k.zsh → ~/.p10k.zsh; dot_tmux.conf → ~/.tmux.conf; dot_local/bin/executable_tmux-auto → ~/.local/bin/tmux-auto (executável); dot_zshrc.local.example → ~/.zshrc.local.example; private_dot_ssh/private_config → ~/.ssh/config; private_dot_ssh/private_config.local.example → ~/.ssh/config.local.example. run_once_10/20/30/40 executam em ordem numérica; homebrew/Brewfile é lido pelo run_once_10.
- **Hooks locais:** `.chezmoiscripts/run_once_before_05-create-xdg-dirs.sh` cria `~/.config` e `~/.config/nvim` antes de externals como o do Neovim. `.chezmoiscripts/run_once_before_10-migrate-herd-exports-to-zshrc-local.sh` e `.chezmoiscripts/run_once_after_10-cleanup-herd-migration-block.sh` evitam que exports injetados no `~/.zshrc` virem mudanças permanentes no `dot_zshrc`.
- **Templates:** run_once usam {{ .chezmoi.sourceDir }} e {{ .data.name }}/{{ .data.email }}. `dot_gitconfig.tmpl` usa essa mesma data para renderizar a seção `[user]` apenas quando a identidade estiver configurada.
- **Data:** Pode vir de arquivo (`~/.config/chezmoi/chezmoi.toml` ou outro arquivo de config suportado pelo chezmoi). Campos usados: name, email (run_once_30).

## Fluxo operacional

- Alteração: editar arquivo no source (ex.: dot_zshrc); `chezmoi diff` para ver diferenças; `chezmoi apply` para aplicar.
- Bootstrap: `chezmoi init --apply <repo>` com data (name, email); apply copia arquivos e executa run_once na ordem. Neste ambiente, o repo principal costuma ser `git@github.com:CrisMorgantee/dotfiles.git`.
- Atualizar external: `chezmoi apply` pode atualizar o clone do nvim conforme refreshPeriod; para forçar, ver documentação do chezmoi.

## Validação

- `chezmoi managed` lista todos os targets gerenciados; nenhum path de secret deve aparecer.
- `chezmoi diff` após alteração no source mostra as diferenças esperadas.
- Após apply, ~/.zshrc, ~/.gitconfig, ~/.p10k.zsh, ~/.tmux.conf e ~/.local/bin/tmux-auto refletem o conteúdo do source (e run_once já executados deixam estado consistente).

## Modos de falha

- **Data ausente e run_once_30 não define identidade:** Em máquina nova sem user.name/user.email e sem data, run_once_30 não preenche. Fornecer data e reaplicar ou configurar Git manualmente.
- **run_once falha (rede, sudo):** run_once_10 ou _20 podem falhar; aplicar novamente ou executar scripts manualmente com path correto.
- **External não atualiza:** Rede ou SSH; refreshPeriod não atingido. Verificar conectividade e config do external.

## Estratégia de recuperação

- Reaplicar tudo: `chezmoi apply` (e, se necessário, reexecutar run_once conforme documentação do chezmoi).
- Restaurar source do backup ou re-clonar o repo do chezmoi; em seguida `chezmoi apply`.
- Remover um target do gerenciamento: usar opções do chezmoi para deixar de gerenciar (ex.: remove); o arquivo em ~/ pode ser mantido ou deletado conforme desejado.

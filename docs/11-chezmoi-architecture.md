# Arquitetura Chezmoi

## Objetivo

Descrever como o chezmoi gerencia este ambiente: source directory, targets dos dotfiles e run_once, externals, .chezmoiignore, uso de data (name, email) e operações diff/apply para manutenção e recuperação.

## Decisões de design

- **Source directory:** O repositório do chezmoi (clone ou ~/.local/share/chezmoi) é o source. Contém arquivos com prefixo `dot_` (aplicados em ~/ com o ponto), run_once_*.sh.tmpl (executados uma vez por máquina), homebrew/Brewfile e .chezmoiexternal.toml. Não editar os targets em ~/ para alterações permanentes; editar no source e aplicar.
- **Data para identidade Git:** run_once_30_git usa `{{ .data.name }}` e `{{ .data.email }}` para definir user.name e user.email quando ainda não estão configurados. Para bootstrap do zero é obrigatório fornecer data (arquivo de config do chezmoi, ex. ~/.config/chezmoi/chezmoi.toml com [data], ou flags -D name= -D email= no init/apply). Documentado em 02-bootstrap-from-zero.md e aqui.
- **run_once:** Scripts run_once_10, _20, _30 são executados uma vez após o apply; o chezmoi registra que já rodaram. Para reexecutar é necessário usar a opção apropriada do chezmoi (ex.: run_once novamente) ou executar o script manualmente com o path do source substituído onde necessário.
- **Externals:** .chezmoiexternal.toml define .config/nvim como git-repo (svim). O chezmoi clona/atualiza no target; refreshPeriod 168h. Conteúdo do nvim não está no source; está no repo externo.
- **.chezmoiignore:** Ignora .zshrc.local (não versionado), .DS_Store, padrões para chaves e secrets (**/*.pem, **/*.key, **/id_*, **/*secret*, **/*token*, **/*credentials*), herd-*. Garante que secrets e arquivos locais não sejam incluídos acidentalmente.

## Arquitetura

- **Mapeamento:** dot_zshrc → ~/.zshrc; dot_gitconfig → ~/.gitconfig; dot_p10k.zsh → ~/.p10k.zsh; dot_zshrc.local.example → ~/.zshrc.local.example. run_once_10/20/30 executam em ordem numérica; homebrew/Brewfile é apenas lido pelo run_once_10.
- **Templates:** run_once usam {{ .chezmoi.sourceDir }} e {{ .data.name }}/{{ .data.email }}. dot_gitconfig pode conter placeholders se desejado; no estado atual o dot_gitconfig tem valores fixos para user.
- **Data:** Pode vir de arquivo (chezmoi.toml em config ou no source) ou de -D no init/apply. Campos usados: name, email (run_once_30).

## Fluxo operacional

- Alteração: editar arquivo no source (ex.: dot_zshrc); `chezmoi diff` para ver diferenças; `chezmoi apply` para aplicar.
- Bootstrap: `chezmoi init --apply <repo>` com data (name, email); apply copia arquivos e executa run_once na ordem.
- Atualizar external: `chezmoi apply` pode atualizar o clone do nvim conforme refreshPeriod; para forçar, ver documentação do chezmoi.

## Validação

- `chezmoi managed` lista todos os targets gerenciados; nenhum path de secret deve aparecer.
- `chezmoi diff` após alteração no source mostra as diferenças esperadas.
- Após apply, ~/.zshrc, ~/.gitconfig, ~/.p10k.zsh refletem o conteúdo do source (e run_once já executados deixam estado consistente).

## Modos de falha

- **Data ausente e run_once_30 não define identidade:** Em máquina nova sem user.name/user.email e sem data, run_once_30 não preenche. Fornecer data e reaplicar ou configurar Git manualmente.
- **run_once falha (rede, sudo):** run_once_10 ou _20 podem falhar; aplicar novamente ou executar scripts manualmente com path correto.
- **External não atualiza:** Rede ou SSH; refreshPeriod não atingido. Verificar conectividade e config do external.

## Estratégia de recuperação

- Reaplicar tudo: `chezmoi apply` (e, se necessário, reexecutar run_once conforme documentação do chezmoi).
- Restaurar source do backup ou re-clonar o repo do chezmoi; em seguida `chezmoi apply`.
- Remover um target do gerenciamento: usar opções do chezmoi para deixar de gerenciar (ex.: remove); o arquivo em ~/ pode ser mantido ou deletado conforme desejado.

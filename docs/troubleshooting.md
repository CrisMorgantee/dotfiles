# Troubleshooting

Problemas comuns, causas prováveis e correções. Manter linguagem técnica e objetiva.

---

## Prompt lento ou atraso ao abrir o shell

**Causas:** Output ou comandos que pedem input acima do bloco do instant prompt do Powerlevel10k; ou compinit/plugin pesado executando antes do prompt estar pronto.

**Validação:** Comentar temporariamente blocos entre o início do .zshrc e o carregamento do p10k e recarregar; se o prompt ficar rápido, o atraso está nessa região. Verificar se não há `echo`, `read` ou comando interativo antes do instant prompt.

**Correção:** Manter o instant prompt no topo; não adicionar output acima dele. Usar `wait` nos plugins Zinit (já usado: wait"0" e wait"1") para adiar carregamento. Se um plugin for pesado, aumentar o wait ou carregar com lazy.

**Reverter:** Restaurar a ordem original do .zshrc via `chezmoi apply` se alterações quebraram o startup.

---

## Histórico não compartilhado entre terminais

**Causas:** SHARE_HISTORY ou INC_APPEND_HISTORY desativados; HISTFILE diferente entre sessões; diretório do HISTFILE inexistente ou sem permissão de escrita.

**Validação:** `echo $HISTFILE` em dois terminais deve ser idêntico (ex.: ~/.local/state/zsh/history). `setopt | grep -E 'share|append'` deve mostrar SHARE_HISTORY e INC_APPEND_HISTORY. Verificar se o diretório existe: `[[ -d "${HISTFILE:h}" ]]`.

**Correção:** Garantir que o bloco de history no .zshrc está ativo (setopt APPEND_HISTORY, INC_APPEND_HISTORY, SHARE_HISTORY). Garantir `mkdir -p "${HISTFILE:h}"`. Se HISTFILE estiver em path diferente por sessão (ex.: variável não exportada em contexto de login), padronizar para o mesmo path (XDG_STATE_HOME ou ~/.local/state).

**Reverter:** Restaurar dot_zshrc; recriar o diretório do histórico se foi removido.

---

## mise ou direnv não encontrados / não ativos

**Causas:** Homebrew não está no PATH quando o .zshrc é carregado; run_once_10 não rodou ou falhou; brew bundle não instalou mise/direnv.

**Validação:** `which brew` e `which mise` / `which direnv`; `brew list mise direnv`. Em subshell não interativo, o .zshrc pode não ser carregado completo (Warp/iTerm carregam .zshrc em sessão interativa).

**Correção:** Garantir que o bloco `eval "$(/opt/homebrew/bin/brew shellenv)"` está antes do bloco do mise/direnv no .zshrc. Rodar run_once_10 ou `brew bundle --file=<path-do-Brewfile>`. Reiniciar o terminal após instalação.

**Reverter:** Comentar os blocos `eval "$(mise activate zsh)"` e `eval "$(direnv hook zsh)"` no .zshrc para desativar sem desinstalar.

---

## Delta não usado no Git (diff/log)

**Causas:** delta não instalado; core.pager ou interactive.diffFilter não configurados; run_once_30 não rodou após instalação do delta.

**Validação:** `git config --global core.pager` deve retornar delta. `which delta` deve resolver. `git log` ou `git diff` devem exibir com side-by-side e cores (Nord).

**Correção:** Instalar delta via `brew install delta` ou brew bundle. Rodar run_once_30 manualmente (com path do source correto) ou setar manualmente: `git config --global core.pager delta` e `git config --global interactive.diffFilter "delta --color-only"`. Ver dot_gitconfig e run_once_30 para o conjunto completo de opções do delta.

**Reverter:** `git config --global --unset core.pager` (e interactive.diffFilter se desejado) para voltar ao pager padrão.

---

## run_once não rodou ou falhou

**Causas:** run_once já foi marcado como executado pelo chezmoi e não reexecuta; script falhou por rede (run_once_10), sudo cancelado (run_once_20) ou data ausente (run_once_30); path do source errado em execução manual.

**Validação:** Verificar no chezmoi se o run_once consta como executado (documentação do chezmoi). Rodar o script manualmente com bash e observar erros (substituir `{{ .chezmoi.sourceDir }}` pelo path real no run_once_10).

**Correção:** Para run_once_10: garantir rede e permissões; executar o script manualmente com BREWFILE ou source dir correto. Para run_once_20: executar novamente e inserir sudo quando pedido. Para run_once_30: fornecer data (name, email) ao chezmoi e reaplicar; ou configurar git config --global user.name/user.email manualmente. Forçar reexecução de run_once conforme opções do chezmoi (ex.: chezmoi re-run run_once).

**Reverter:** Conforme o script: run_once_10 não desinstala pacotes; run_once_20 pode ser revertido por defaults delete ou Preferências do Sistema; run_once_30 pode ser sobrescrito editando ~/.gitconfig ou reaplicando dot_gitconfig.

---

## Zinit ou Powerlevel10k não carregam

**Causas:** HOMEBREW_PREFIX não definido; Homebrew não no PATH antes do source do Zinit; arquivo instant prompt do p10k ausente ou corrompido; ~/.p10k.zsh ausente.

**Validação:** `echo $HOMEBREW_PREFIX` (deve ser /opt/homebrew no Apple Silicon). `[[ -f "$HOMEBREW_PREFIX/opt/zinit/zinit.zsh" ]]`. `[[ -f ~/.p10k.zsh ]]`. Ordem no .zshrc: Homebrew antes de Zinit.

**Correção:** Garantir run_once_10 executado; manter bloco Homebrew no topo do .zshrc (apenas abaixo do instant prompt). Reaplicar dotfiles: `chezmoi apply` para dot_zshrc e dot_p10k.zsh. Deletar cache do instant prompt (arquivo p10k-instant-prompt-* em XDG_CACHE_HOME) para o p10k regenerar na próxima abertura.

**Reverter:** Restaurar dot_zshrc e dot_p10k.zsh do source; recarregar shell.

---

## Identidade Git vazia após bootstrap

**Causas:** Data do chezmoi (name, email) não fornecida no init/apply; run_once_30 rodou mas os templates {{ .data.name }} e {{ .data.email }} estavam vazios.

**Validação:** `git config --global user.name` e `user.email`; se vazios, identidade não foi setada.

**Correção:** Fornecer data ao chezmoi: criar ou editar config com [data] name e email, ou usar `chezmoi apply -D name="..." -D email="..."`. Se run_once_30 já tiver rodado, definir manualmente: `git config --global user.name "..." user.email "..."`. Documentado em 02-bootstrap-from-zero.md e 11-chezmoi-architecture.md.

**Reverter:** `git config --global --unset user.name user.email` se quiser remover; depois redefinir conforme desejado.

# Sistema de histórico

## Objetivo

Configurar o histórico do Zsh em um único arquivo estável (`~/.zsh_history`), com escrita incremental, deduplicação/limpeza e busca por prefixo com setas (history-beginning-search), mantendo tamanhos limitados para desempenho.

## Decisões de design

- **HISTFILE em ~/.zsh_history:** `HISTFILE="$HOME/.zsh_history"`. Arquivo único e previsível (compatível com ferramentas e setups comuns).
- **HISTSIZE e SAVEHIST 50000:** Limite de entradas em memória e em disco. Trade-off: mais histórico vs. arquivo maior; 50000 é aceitável para uso interativo moderno.
- **APPEND_HISTORY + INC_APPEND_HISTORY (sem SHARE_HISTORY):** Comandos são anexados imediatamente ao arquivo, mas o histórico **não é compartilhado ao vivo** entre shells. EXTENDED_HISTORY para timestamp por entrada; HIST_IGNORE_DUPS, HIST_IGNORE_SPACE, HIST_REDUCE_BLANKS para reduzir ruído.
- **history-beginning-search (setas):** Autoload das funções e bind em ^[[A/^[[B] (e viins). Digitar um prefixo e pressionar seta para cima/baixo percorre apenas entradas que começam com esse prefixo. Keymap emacs garantido com `bindkey -e` antes dos bindings.

## Arquitetura

- Variáveis: HISTFILE, HISTSIZE, SAVEHIST.
- setopts: APPEND_HISTORY, INC_APPEND_HISTORY, HIST_IGNORE_DUPS, HIST_IGNORE_SPACE, HIST_REDUCE_BLANKS, EXTENDED_HISTORY. SHARE_HISTORY é explicitamente desativado (unsetopt).
- Keybindings: history-beginning-search-backward/forward nas setas; bindkey -e; bindings em viins para segurança.

Tudo definido em dot_zshrc (blocos SETTINGS e HISTORY SEARCH).

## Fluxo operacional

- Ao iniciar o Zsh: HISTFILE é setado; setopts são aplicados.
- A cada comando (conforme INC_APPEND_HISTORY): a entrada é anexada ao arquivo em disco.
- Em um novo terminal: ao abrir, o Zsh lê o mesmo HISTFILE; comandos já digitados em outros terminais ficam disponíveis a partir do próximo start (não é live-shared).
- Busca: usuário digita prefixo (ex.: "git"), seta para cima percorre apenas linhas que começam com "git".

## Validação

- `echo $HISTFILE` deve mostrar `~/.zsh_history`.
- Em um terminal: execute um comando (ex.: `echo teste`). Abra um **novo** terminal e pressione seta para cima: o comando deve aparecer.
- Digitar "cd " e seta para cima: apenas entradas que começam com "cd " aparecem.

## Modos de falha

- **Histórico não persiste:** Falha de escrita em `$HOME` (permissões, disco cheio). Corrigir permissões/armazenamento.
- **Histórico não aparece em outros terminais imediatamente:** Esperado (SHARE_HISTORY desativado). Se quiser live-sharing, habilitar SHARE_HISTORY no dot_zshrc.
- **Arquivo de history muito grande:** Com SAVEHIST=50000 o tamanho é limitado; se o arquivo foi corrompido ou truncado, o Zsh pode ignorar. Backup e truncar se necessário.

## Estratégia de recuperação

- Restaurar setopts: garantir que o bloco de history no .zshrc está conforme o source; `chezmoi apply` se necessário.
- Se os bindings não funcionarem: verificar se `bindkey -e` está ativo e se as sequências ^[[A/^[[B] correspondem ao terminal (Warp/iTerm2 em geral usam as mesmas).

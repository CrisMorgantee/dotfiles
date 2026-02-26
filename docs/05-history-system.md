# Sistema de histórico

## Objetivo

Configurar o histórico do Zsh para uso em XDG_STATE_HOME, compartilhamento entre shells (SHARE_HISTORY, INC_APPEND_HISTORY), deduplicação e limpeza, e busca por prefixo com setas (history-beginning-search), mantendo tamanhos limitados para desempenho.

## Decisões de design

- **HISTFILE em XDG_STATE_HOME:** `HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"`. Segue XDG Base Directory; estado mutável fora do home tradicional. Se XDG_STATE_HOME não estiver definido, fallback para ~/.local/state.
- **Diretório criado no startup:** `mkdir -p "${HISTFILE:h}"` garante que o diretório exista antes de qualquer escrita; evita falha silenciosa quando o arquivo de history não pode ser criado.
- **HISTSIZE e SAVEHIST 20000:** Limite de entradas em memória e em disco. Trade-off: mais histórico vs. arquivo maior e possível lentidão em buscas; 20000 é um compromisso razoável.
- **APPEND_HISTORY, INC_APPEND_HISTORY, SHARE_HISTORY:** Comandos são anexados imediatamente e o histórico é compartilhado entre sessões, de modo que vários terminais veem os mesmos comandos. EXTENDED_HISTORY para timestamp por entrada; HIST_IGNORE_DUPS, HIST_IGNORE_SPACE, HIST_REDUCE_BLANKS para reduzir ruído.
- **history-beginning-search (setas):** Autoload das funções e bind em ^[[A/^[[B] (e viins). Digitar um prefixo e pressionar seta para cima/baixo percorre apenas entradas que começam com esse prefixo. Keymap emacs garantido com `bindkey -e` antes dos bindings.

## Arquitetura

- Variáveis: HISTFILE, HISTSIZE, SAVEHIST.
- setopts: APPEND_HISTORY, INC_APPEND_HISTORY, SHARE_HISTORY, HIST_IGNORE_DUPS, HIST_IGNORE_SPACE, HIST_REDUCE_BLANKS, EXTENDED_HISTORY.
- Criação do diretório: uma linha no .zshrc, executada em todo login interativo.
- Keybindings: history-beginning-search-backward/forward nas setas; bindkey -e; bindings em viins para segurança.

Tudo definido em dot_zshrc (blocos SETTINGS e HISTORY SEARCH).

## Fluxo operacional

- Ao iniciar o Zsh: HISTFILE é setado; mkdir é executado; setopts são aplicados.
- A cada comando (ou no final da linha, conforme INC_APPEND_HISTORY): a entrada é anexada ao histórico em memória e escrita no arquivo (compartilhado).
- Em um novo terminal: ao abrir, o Zsh lê o mesmo HISTFILE; comandos já digitados em outros terminais ficam disponíveis.
- Busca: usuário digita prefixo (ex.: "git"), seta para cima percorre apenas linhas que começam com "git".

## Validação

- `echo $HISTFILE` mostra path sob ~/.local/state/zsh (ou $XDG_STATE_HOME/zsh).
- `[[ -d "${HISTFILE:h}" ]] && echo ok` confirma que o diretório existe.
- Dois terminais: comando em um, no outro seta para cima mostra o comando (após o próximo prompt).
- Digitar "cd " e seta para cima: apenas entradas que começam com "cd " aparecem.

## Modos de falha

- **Diretório do histórico não criado:** Home somente leitura ou permissões; mkdir falha. Histórico não é persistido. Corrigir permissões ou apontar HISTFILE para um path gravável.
- **Histórico não compartilhado:** SHARE_HISTORY/INC_APPEND_HISTORY desativados ou HISTFILE diferente entre shells (ex.: variável não exportada em subshell). Garantir que o mesmo .zshrc é carregado e que HISTFILE é o mesmo.
- **Arquivo de history muito grande:** Com SAVEHIST=20000 o tamanho é limitado; se o arquivo foi corrompido ou truncado, o Zsh pode ignorar. Backup e truncar se necessário.

## Estratégia de recuperação

- Recriar diretório: `mkdir -p ~/.local/state/zsh` (ou o path usado por HISTFILE).
- Restaurar setopts: garantir que o bloco de history no .zshrc não foi alterado; `chezmoi apply` se necessário.
- Se os bindings não funcionarem: verificar se `bindkey -e` está ativo e se as sequências ^[[A/^[[B] correspondem ao terminal (Warp/iTerm2 em geral usam as mesmas).

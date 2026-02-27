# Arquitetura Zsh

## Objetivo

Descrever a pilha do shell: carregamento do Zinit, tema Powerlevel10k com instant prompt, plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting), keymap emacs e a ordem exata de inicialização para permitir depuração e alterações consistentes.

## Decisões de design

- **Zinit via Homebrew:** Zinit é carregado a partir de `$HOMEBREW_PREFIX/opt/zinit/zinit.zsh`. Evita clone manual no home; versão controlada pelo Brewfile. Depende de Homebrew estar no PATH antes (bloco no .zshrc logo após o instant prompt).
- **Powerlevel10k com instant prompt:** O instant prompt é carregado no início do .zshrc (arquivo em XDG_CACHE_HOME) para desenhar o prompt o mais cedo possível e evitar atraso. Nenhum comando que produza output ou peça input pode ficar acima desse bloco. Tema e configuração: Zinit carrega romkatv/powerlevel10k (depth=1, lucid); em seguida `[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh`.
- **Plugins na ordem:** fzf-tab (wait"0"), zsh-autosuggestions (wait"0", atload _zsh_autosuggest_start), fast-syntax-highlighting (wait"1"). Lucid para não poluir o output. Syntax highlighting com wait maior para manter o prompt rápido.
- **Keymap emacs:** `bindkey -e` é definido antes dos bindings de history-beginning-search; bindings explícitos para setas (^[[A/^[[B) em emacs e viins para garantir busca no histórico por prefixo independente do modo.

## Arquitetura

Sequência no .zshrc:

1. Instant prompt p10k (se arquivo existir).
2. Homebrew shellenv (Apple Silicon).
3. LS_COLORS via vivid (nord) se vivid existir.
4. compinit com cache (zcompdump em XDG_CACHE_HOME).
5. source zinit.zsh (Homebrew).
6. Zinit ice + light powerlevel10k; source ~/.p10k.zsh.
7. Zinit light fzf-tab, zsh-autosuggestions, fast-syntax-highlighting.
8. mise activate zsh; PATH append.
9. direnv hook zsh.
10. zoxide init zsh.
11. HISTFILE e setopts de history.
12. Aliases e funções.
13. autoload history-beginning-search; bindkey -e; bindings setas.
14. tmux-auto (se shell interativo e em SSH: attach/cria sessão tmux nomeada pelo hostname; TMUX_AUTOSTART=1 força local).
15. source ~/.zshrc.local se existir.

Artefatos: dot_zshrc → ~/.zshrc; dot_p10k.zsh → ~/.p10k.zsh. Zinit e plugins vêm do GitHub via Zinit (powerlevel10k, fzf-tab, zsh-autosuggestions, fast-syntax-highlighting).

## Fluxo operacional

Ao abrir um terminal interativo: Zsh lê ~/.zshrc na ordem acima. Instant prompt pode já ter sido gerado em execução anterior (p10k instant prompt). Qualquer alteração em .zshrc ou .p10k.zsh exige novo shell ou `source ~/.zshrc` para refletir (algumas opções do p10k permitem hot reload; neste setup está desabilitado).

## Validação

- `which zinit` (ou tipo equivalente) aponta para o script do Homebrew.
- Prompt exibe estilo Pure/Nord (dois níveis, dir, vcs, prompt_char; rprompt com command_execution_time, virtualenv, context).
- Tab abre fzf-tab; setas sob prefixo fazem history-beginning-search; sugestões aparecem em cinza.
- `bindkey -e` ativo; não há conflito com vi mode a menos que seja intencional.

## Modos de falha

- **Zinit não carrega:** HOMEBREW_PREFIX não definido ou Homebrew não no PATH. Corrigir garantindo que o bloco do Homebrew no .zshrc está antes do source do Zinit e que run_once_10 rodou.
- **Prompt lento:** Output ou compinit antes do instant prompt; ou plugin pesado sem wait. Manter instant prompt no topo; usar wait nos plugins.
- **p10k não encontrado:** ~/.p10k.zsh ausente (dot_p10k.zsh não aplicado). Executar `chezmoi apply` para criar ~/.p10k.zsh.

## Estratégia de recuperação

- Reaplicar dotfiles: `chezmoi apply` para .zshrc e .p10k.zsh.
- Regenerar instant prompt: deletar o arquivo em XDG_CACHE_HOME (p10k-instant-prompt-*); na próxima abertura do shell o p10k recria.
- Desativar um plugin: comentar o bloco zinit correspondente no .zshrc e recarregar o shell.

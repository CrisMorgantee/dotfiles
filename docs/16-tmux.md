# Tmux: auto-session e plugins (TPM)

## Objetivo

Documentar a integração do tmux com este ambiente: sessão automática por hostname em SSH, TPM e plugins (nordtheme, tmux-yank).

## Decisões de design

- **Auto-session apenas em SSH:** O script `tmux-auto` (em ~/.local/bin) só inicia/attach tmux quando a sessão é via SSH (`SSH_CONNECTION`, `SSH_CLIENT` ou `SSH_TTY`). Em terminal local não entra em tmux automaticamente. Para forçar no local: `export TMUX_AUTOSTART=1` (ex.: no ~/.zshrc.local).
- **Sessão por hostname:** A sessão tmux criada em SSH tem o nome do host (hostname curto, sem domínio). Assim cada host remoto tem sua sessão identificável; reconexão usa a mesma sessão.
- **Config e plugins versionados:** dot_tmux.conf aplica cores (nordtheme), tmux-yank (OSC52/pbcopy), TPM. run_once_40 instala o TPM (clone em ~/.tmux/plugins/tpm) uma vez por máquina.

## Artefatos

| Source (chezmoi)                      | Target                    | Descrição |
|---------------------------------------|---------------------------|-----------|
| dot_tmux.conf                         | ~/.tmux.conf              | Config: status-left/right, interval 5, keybindings, TPM, nordtheme, tmux-yank. |
| dot_local/bin/executable_tmux-auto    | ~/.local/bin/tmux-auto    | Se não estiver em tmux e (SSH ou TMUX_AUTOSTART=1): exec tmux new -As hostname. Chamado pelo .zshrc em shell interativo. |
| run_once_40_tmux-tpm.sh.tmpl          | run once                  | Instala TPM em ~/.tmux/plugins/tpm (git clone). |

## Fluxo

- **Login SSH (sem tmux):** Zsh carrega .zshrc; no fim, tmux-auto vê SSH e TMUX vazio → `exec tmux new -As <host>`. O processo do shell é substituído pelo tmux; o novo shell dentro do tmux carrega .zshrc de novo, mas TMUX já está setado e tmux-auto sai sem fazer nada.
- **Terminal local:** tmux-auto não roda (a menos que TMUX_AUTOSTART=1). Comportamento normal sem tmux.
- **Dentro do tmux:** status-right mostra data/hora; plugins são carregados via TPM.

## Variáveis

- **TMUX_AUTOSTART=1:** Fazer tmux-auto rodar também em terminal local (attach/criar sessão por hostname).
- **TMUX_SESSION_NAME:** Nome da sessão em vez do hostname (opcional).

## Validação

- Em SSH, após login: deve estar dentro de tmux, sessão com nome do host. `echo $TMUX` não vazio.
- Local sem TMUX_AUTOSTART: não entra em tmux ao abrir terminal.
- `which tmux-auto` resolve para ~/.local/bin (PATH do .zshrc).

## Modos de falha

- **tmux-auto não encontrado:** ~/.local/bin não no PATH quando .zshrc roda (improvável; PATH append está antes do bloco tmux-auto). Verificar `command -v tmux-auto`.
- **TPM/plugins não carregam:** run_once_40 não rodou ou falhou (rede). Rodar manualmente o script ou `git clone` do TPM; depois `prefix + I` no tmux para instalar plugins.

## Estratégia de recuperação

- Desativar auto-session: comentar o bloco "TMUX AUTO-SESSION" no dot_zshrc e aplicar.
- Forçar sessão local: em ~/.zshrc.local, `export TMUX_AUTOSTART=1`.
- Ajustar status: em dot_tmux.conf, alterar `status-right` conforme preferir.

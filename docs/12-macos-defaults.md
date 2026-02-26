# Defaults do macOS

## Objetivo

Documentar o script run_once_20 que aplica defaults do macOS (UI, teclado, trackpad, Finder, Dock, screenshots, Safari, firewall) para deixar o sistema alinhado com um perfil de desenvolvedor: menos animações, teclado mais responsivo, Finder útil, Dock automático e firewall ativo.

## Decisões de design

- **Apenas macOS:** O script verifica `uname -s == Darwin` e sai sem erro em outros sistemas. Não altera Linux ou Windows.
- **Sudo uma vez:** Alguns defaults e o firewall exigem privilégios de administrador. O script chama `sudo -v` e mantém a sessão sudo viva em background (loop a cada 60s) enquanto roda, para não pedir senha várias vezes.
- **Grupos de defaults:** UI/UX (janela, scroll, reduce motion, painéis expandidos); teclado (KeyRepeat, InitialKeyRepeat); trackpad (tap to click); Finder (extensões visíveis, status bar, path bar, arquivos ocultos, lista como padrão, pastas primeiro, sem .DS_Store em rede/USB); Dock (autohide, delay zero, animação rápida, sem animação ao abrir app); screenshots (diretório e PNG); Safari (menu Develop, extras WebKit); segurança (firewall aplicativo e stealth). Ao final, reinício de Finder, Dock e SystemUIServer para aplicar mudanças.
- **Idempotência:** Rodar o script várias vezes produz o mesmo estado; não há efeito colateral acumulativo.
- **Risco:** reduceMotion e alguns defaults podem ser revertidos ou ignorados pelo macOS em versões mais novas ou em configurações corporativas. O script usa `|| true` onde apropriado para não falhar.

## Arquitetura

- **Script:** run_once_20_macos-defaults.sh.tmpl. Executado uma vez por máquina pelo chezmoi. Não há template dinâmico além do possível; o conteúdo é estático.
- **Ordem:** Após run_once_10 (para não depender de pacotes); antes ou depois do run_once_30 é irrelevante para o macOS em si. O usuário pode cancelar o sudo e pular o script; pode reexecutá-lo depois.

## Fluxo operacional

1. Durante o primeiro `chezmoi apply`, run_once_20 é executado.
2. Script pede sudo; usuário insere senha.
3. Blocos de defaults são aplicados em sequência; firewall é ativado (sudo).
4. killall Finder, Dock, SystemUIServer para aplicar mudanças visuais.
5. Mensagem final informa que algumas mudanças podem exigir logout/restart.

## Validação

- `defaults read NSGlobalDomain NSWindowResizeTime` retorna um float (ex.: 0.001).
- `defaults read com.apple.dock autohide` retorna 1 (true).
- `defaults read com.apple.finder ShowPathbar` retorna 1.
- Firewall: Preferências do Sistema > Rede > Firewall deve indicar ativo (o script usa socketfilterfw).

## Modos de falha

- **Usuário cancela sudo:** Script falha ou não aplica itens que exigem admin. Reexecutar o script quando desejar; inserir senha quando solicitado.
- **macOS reverte ou ignora:** Em alguns macOS ou políticas MDM, reduceMotion ou outros podem ser sobrescritos. Ajustar manualmente nas Preferências se necessário.
- **killall em app crítico:** Finder/Dock/SystemUIServer reiniciam; em geral é seguro. Se houver problema, logout/login ou restart restaura o estado.

## Estratégia de recuperação

- Reexecutar o script: executar manualmente o run_once_20 (após renderizar o template se necessário) a partir do source dir. O chezmoi pode ter marcado como executado; usar a opção do chezmoi para forçar reexecução de run_once se disponível.
- Reverter um default específico: usar `defaults delete ...` ou redefinir pela interface do Sistema. Documentar o comando original em run_once_20 para saber o domínio/chave.
- Desativar firewall: Preferências do Sistema ou `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off` (não recomendado).

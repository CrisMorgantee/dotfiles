# Defaults do macOS

## Objetivo

Documentar o script run_once_20 que aplica defaults do macOS (UI, teclado, trackpad, Finder, Dock, screenshots, Safari, firewall) para deixar o sistema alinhado com um perfil de desenvolvedor: menos animações, teclado mais responsivo, Finder útil, Dock automático e firewall ativo.

## Referência das configurações (run_once_20_macos-defaults.sh.tmpl)

Cada comando aplicado pelo script e o efeito prático para o usuário:

### UI / UX (animações e latência)

| Domínio/Chave | Valor | O que faz |
|---------------|--------|-----------|
| `NSGlobalDomain NSWindowResizeTime` | `0.001` (float) | Reduz o tempo de animação ao redimensionar janelas; deixa o redimensionamento quase instantâneo. |
| `NSGlobalDomain NSScrollViewRubberbanding` | `false` | Desativa o “rubber band” (efeito de bounce) ao rolar além do fim do conteúdo; menos distração visual. |
| `com.apple.universalaccess reduceMotion` (currentHost e global) | `true` | Ativa “Reduzir movimento” (acessibilidade); menos animações no sistema. Em versões recentes o macOS pode ignorar ou travar esta chave. |
| `NSGlobalDomain NSNavPanelExpandedStateForSaveMode` / `NSNavPanelExpandedStateForSaveMode2` | `true` | Painel “Salvar” abre já expandido (mostra mais opções de local e formato). |
| `NSGlobalDomain PMPrintingExpandedStateForPrint` / `PMPrintingExpandedStateForPrint2` | `true` | Painel “Imprimir” abre já expandido. |

### Teclado e entrada

| Domínio/Chave | Valor | O que faz |
|---------------|--------|-----------|
| `NSGlobalDomain KeyRepeat` | `2` (int) | Velocidade de repetição da tecla quando mantida pressionada (valor baixo = mais rápido). A interface do macOS pode limitar o valor efetivo. |
| `NSGlobalDomain InitialKeyRepeat` | `15` (int) | Atraso (em ms) antes de começar a repetir a tecla; valor baixo = resposta mais rápida. |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking` | `true` | Ativa “toque para clicar” no trackpad (Bluetooth). |
| `com.apple.AppleMultitouchTrackpad Clicking` | `true` | Ativa “toque para clicar” no trackpad integrado. |
| `NSGlobalDomain com.apple.mouse.tapBehavior` (currentHost e global) | `1` (int) | Comportamento de toque do mouse/trackpad; 1 = tap to click. |

### Finder

| Domínio/Chave | Valor | O que faz |
|---------------|--------|-----------|
| `NSGlobalDomain AppleShowAllExtensions` | `true` | Mostra todas as extensões de arquivo (ex.: `.txt`, `.json`) no Finder. |
| `com.apple.finder ShowStatusBar` | `true` | Mostra a barra de status na parte inferior da janela do Finder (itens selecionados, espaço em disco). |
| `com.apple.finder ShowPathbar` | `true` | Mostra a barra de caminho (path) na parte inferior; útil para ver e navegar pelo path completo. |
| `com.apple.finder AppleShowAllFiles` | `true` | Mostra arquivos e pastas ocultos (nome começando com `.`); essencial para desenvolvimento. |
| `com.apple.finder FXPreferredViewStyle` | `"Nlsv"` | Define a visualização padrão do Finder como lista (List view). |
| `com.apple.finder _FXSortFoldersFirst` | `true` | Ao ordenar por nome, mantém pastas no topo. |
| `com.apple.desktopservices DSDontWriteNetworkStores` | `true` | Evita criar `.DS_Store` em volumes de rede; menos “lixo” em repositórios e shares. |
| `com.apple.desktopservices DSDontWriteUSBStores` | `true` | Evita criar `.DS_Store` em pendrives e volumes USB. |

### Dock

| Domínio/Chave | Valor | O que faz |
|---------------|--------|-----------|
| `com.apple.dock autohide` | `true` | Oculta o Dock quando não está em uso; reaparece ao passar o mouse na borda. |
| `com.apple.dock autohide-delay` | `0` (float) | Remove o atraso para o Dock aparecer ao aproximar o cursor. |
| `com.apple.dock autohide-time-modifier` | `0.15` (float) | Acelera a animação de mostrar/ocultar o Dock. |
| `com.apple.dock launchanim` | `false` | Desativa a animação de “pulo” ao abrir um aplicativo a partir do Dock. |

### Screenshots

| Ação | O que faz |
|------|-----------|
| `mkdir -p "$HOME/Pictures/Screenshots"` | Cria o diretório de capturas de tela (se não existir). |
| `com.apple.screencapture location` | `"$HOME/Pictures/Screenshots"` | Define o destino das capturas de tela (⌘⇧3, ⌘⇧4, etc.) para essa pasta. |
| `com.apple.screencapture type` | `"png"` | Formato das capturas: PNG (sem perda, adequado para docs e código). |

### Safari

As preferências do Safari são gravadas no container do app (sandbox). **Feche o Safari** antes de rodar o script para que os `defaults write` tenham efeito. Se o script falhar nesse bloco, feche o Safari e reexecute o run_once_20 ou aplique os comandos manualmente.

| Domínio/Chave | Valor | O que faz |
|---------------|--------|-----------|
| `com.apple.Safari IncludeDevelopMenu` | `true` | Exibe o menu “Desenvolver” (ferramentas de desenvolvedor). |
| `com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey` | `true` | Habilita extras de desenvolvedor no WebKit (inspetor, etc.). |
| `com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled` | `true` | Habilita extras de desenvolvedor no WebKit2 para o grupo de conteúdo do Safari. |

### Segurança

| Ação | O que faz |
|------|-----------|
| `socketfilterfw --setglobalstate on` | Ativa o Firewall de aplicativos (requer sudo). |
| `socketfilterfw --setstealthmode on` | Ativa o modo stealth: o Mac não responde a sondas de rede não solicitadas. |

### Aplicação das mudanças

O script encerra reiniciando os processos afetados para que as preferências tenham efeito imediato:

- `killall Finder` — aplica mudanças do Finder (visualização, barra de path, etc.).
- `killall Dock` — aplica mudanças do Dock (autohide, animações).
- `killall SystemUIServer` — aplica mudanças da barra de menu e ícones do sistema.

Algumas alterações (por exemplo reduce motion ou teclado) podem exigir logout ou reinício para efeito completo.

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
- **Safari em execução:** O Safari é sandboxed; as preferências ficam no container do app. Se o Safari estiver aberto, os `defaults write com.apple.Safari` podem falhar. O script não aborta: apenas registra o aviso e segue. Feche o Safari e reexecute o script para aplicar as preferências do Safari (menu Desenvolver).

## Estratégia de recuperação

- Reexecutar o script: executar manualmente o run_once_20 (após renderizar o template se necessário) a partir do source dir. O chezmoi pode ter marcado como executado; usar a opção do chezmoi para forçar reexecução de run_once se disponível.
- Reverter um default específico: usar `defaults delete ...` ou redefinir pela interface do Sistema. Documentar o comando original em run_once_20 para saber o domínio/chave.
- Desativar firewall: Preferências do Sistema ou `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off` (não recomendado).

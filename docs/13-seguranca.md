# Modelo de segurança

## Objetivo

Definir as regras de segurança do ambiente: nenhuma API key ou token no .zshrc ou em arquivos versionados; uso de .zshrc.local não versionado para config local; `~/.ssh/config.local` para hosts privados; direnv e Keychain/1Password para secrets por projeto e globais; .chezmoiignore para evitar inclusão acidental de chaves e credenciais.

## Decisões de design

- **Nenhuma API key no .zshrc:** O arquivo dot_zshrc (e portanto ~/.zshrc) não exporta variáveis que contenham secrets. Comentário explícito no .zshrc recomenda: por projeto, .envrc com direnv; global, Keychain ou 1Password e recuperação segura. Trade-off: conveniência de colocar export no .zshrc vs. risco de vazamento em backup, clone ou tela compartilhada; a política é zero secrets em arquivos versionados.
- **.zshrc.local não versionado:** Configuração específica da máquina (ex.: PATH do Herd, variáveis locais) fica em ~/.zshrc.local. O arquivo é ignorado pelo chezmoi (.chezmoiignore lista .zshrc.local). O repo contém apenas .zshrc.local.example como modelo; o usuário copia para .zshrc.local e edita. Assim, secrets ou paths locais não entram no versionamento.
- **SSH privado fora do repo:** O `~/.ssh/config` versionado deve conter apenas defaults públicos e aliases seguros (ex.: GitHub). Hosts internos, usuários específicos, domínios de clientes e caminhos de chaves dedicadas devem ficar em `~/.ssh/config.local`, não versionado. O repo contém apenas `~/.ssh/config.local.example` como referência.
- **Escolha da estratégia de chave SSH:** Em workstation pessoal, a opção mais simples costuma ser uma única chave associada à sua conta GitHub. Quando houver múltiplas contas, múltiplas organizações ou desejo de isolamento entre repositórios/aplicações, usar uma chave por app/repo e aliases em `~/.ssh/config.local`. Para servidores/automação, preferir deploy keys ou outra abordagem específica de automação. Ver `17-ssh-e-github.md`.
- **direnv + Keychain/1Password:** Por projeto: .envrc pode carregar variáveis; para valores sensíveis, o .envrc pode chamar um helper que lê do Keychain ou 1Password e exporta (evitando gravar o secret em texto plano no .envrc). Global: usar Keychain ou 1Password e, quando necessário, um comando ou script que recupera o valor e o injeta no ambiente ou em ferramenta (ex.: git credential).
- **.chezmoiignore:** Padrões que garantem que chaves e credenciais nunca sejam adicionados ao source: **/*.pem, **/*.key, **/id_*, **/*secret*, **/*token*, **/*credentials*. Também .zshrc.local e herd-*. Assim, mesmo que o usuário coloque um arquivo sensível no diretório do chezmoi, o chezmoi não o inclui em managed.
- **Backups e histórico fora do Git:** Arquivos em diretórios como `.backup/` e `.history/` não devem ser versionados em um repo público, porque ampliam a superfície de exposição e podem reintroduzir conteúdo já removido dos arquivos atuais.

## Arquitetura

- **Camadas:** (1) Arquivos versionados: zero secrets e zero contexto privado desnecessário. (2) Arquivos ignorados: .zshrc.local; padrões de chaves no .chezmoiignore; arquivos locais fora do repo como `~/.ssh/config.local`. (3) Runtime: direnv carrega .envrc (com allow por diretório); secrets obtidos via ferramentas externas (Keychain/1Password) quando necessário.
- **Fluxo de secret:** Necessidade de API key em projeto → definir no .envrc via chamada a script que lê Keychain/1Password e exporta; ou usar ferramenta que suporta credential helper (ex.: git). Nunca colar a key no .zshrc ou em arquivo versionado.

## Fluxo operacional

- Novo projeto que precisa de API key: criar .envrc que chama helper (Keychain/1Password) ou documentar que a variável deve ser setada manualmente após `direnv allow` (sem gravar o valor no repo). .envrc pode estar no .gitignore do projeto se contiver referências locais.
- Nova máquina: copiar .zshrc.local.example para .zshrc.local; não versionar .zshrc.local. Secrets globais continuam no Keychain/1Password da conta.
- Hosts privados: copiar `~/.ssh/config.local.example` para `~/.ssh/config.local`, preencher aliases/usuários/identities locais e manter esse arquivo fora do versionamento.
- Chaves GitHub por app/repo: se optar por chaves separadas, gerar cada uma fora do repo, adicionar ao `ssh-agent`/Keychain e mapear aliases locais no `~/.ssh/config.local`.
- Chezmoi apply: .chezmoiignore garante que arquivos sensíveis no source dir não sejam aplicados como targets; chezmoi managed não deve listar paths de chaves.

## Validação

- Grep no source do chezmoi por padrões de key/token/password (ex.: API_KEY=, token=, password=) em arquivos não ignorados; resultado esperado: nenhum match em arquivos versionados.
- `chezmoi managed` não lista .zshrc.local nem arquivos que coincidam com os padrões do .chezmoiignore.
- Revisão de .zshrc e dotfiles: nenhum export de variável que pareça secret.
- Revisão de exposição contextual: nenhum hostname interno, domínio de cliente, usuário privado, e-mail pessoal hardcoded ou backup histórico desnecessário no repo público.

## Modos de falha

- **Secret colado no .zshrc por engano:** Se for commitado e pushed, o secret fica no histórico do repo. Mitigação: nunca colar; usar .zshrc.local (ignorado) ou direnv + helper. Se já ocorreu: rotacionar o secret, remover do arquivo e considerar histórico do repo comprometido.
- **.envrc com secret em texto plano:** Se o .envrc do projeto for versionado no repo do projeto com valor sensível, o secret vaza. Política: .envrc não deve conter valores; apenas carregar de Keychain/1Password ou deixar para o desenvolvedor setar localmente (e .envrc no .gitignore se necessário).
- **Arquivo de chave no source dir:** Se um .pem ou id_* for colocado no source do chezmoi, .chezmoiignore evita que seja gerenciado; mas o arquivo ainda está no disco. Não colocar chaves no diretório do chezmoi; usar diretório fora do repo ou agent/Keychain.

## Estratégia de recuperação

- Remover secret do .zshrc: editar dot_zshrc, remover a linha, aplicar; rotacionar o secret se já foi exposto.
- Garantir que .zshrc.local está no .chezmoiignore: verificar .chezmoiignore; se estiver listado, o chezmoi não o aplica nem o rastreia.
- Após vazamento: rotacionar todas as credenciais expostas; remover do histórico do repo (rewrite) se o repo for público ou compartilhado, e avisar usuários que clonaram.

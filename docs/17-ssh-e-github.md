# SSH e GitHub

## Objetivo

Documentar o acesso aos repositórios Git usados neste ambiente, a geração de chaves SSH no macOS, o uso de uma chave única ou de chaves separadas por aplicação/repositório, e como integrar isso ao `~/.ssh/config` e `~/.ssh/config.local`.

## Repositórios usados por padrão

Este ambiente usa, por padrão:

- Dotfiles: `git@github.com:CrisMorgantee/dotfiles.git`
- Config do Neovim (external): `git@github.com:Simplify-Technology/svim.git`

Se você tiver acesso a ambos os repositórios, pode usar este setup como está e alterar apenas sua identidade local (`name` e `email`) no `chezmoi.toml`.

Se você for usar um fork ou outro repositório:

- troque a URL do `chezmoi init --apply`;
- ajuste `.chezmoiexternal.toml` se não quiser usar `Simplify-Technology/svim.git`;
- mantenha o mesmo modelo de SSH descrito aqui.

## Quando você precisa de SSH

Você precisa de SSH quando:

- for inicializar os dotfiles com `git@github.com:CrisMorgantee/dotfiles.git`;
- o `chezmoi apply` precisar clonar ou atualizar `git@github.com:Simplify-Technology/svim.git`;
- quiser evitar login interativo via HTTPS/token em operações do Git.

Mesmo que você use HTTPS para o repositório dos dotfiles, o external do Neovim continua usando SSH por padrão. Portanto, para o bootstrap completo funcionar sem intervenção manual, o ideal é configurar SSH para o GitHub logo no início.

## Estratégias recomendadas

### Opção 1: uma chave para sua conta GitHub

Use esta opção quando:

- sua conta GitHub já tem acesso aos dois repositórios;
- você quer o setup mais simples;
- não precisa isolar chaves por app ou por organização.

Fluxo:

1. Gerar uma chave `ed25519`.
2. Adicionar a chave ao `ssh-agent` e ao Keychain do macOS.
3. Cadastrar a chave pública na sua conta GitHub.
4. Testar com `ssh -T git@github.com`.
5. Usar os repositórios normalmente com `git@github.com:OWNER/REPO.git`.

### Opção 2: uma chave por aplicação ou repositório

Use esta opção quando:

- você quer separar acesso aos dotfiles e ao Neovim;
- usa mais de uma conta GitHub;
- quer reduzir impacto de rotação/revogação de uma chave;
- precisa de aliases específicos no `~/.ssh/config.local`.

Fluxo:

1. Gerar uma chave para cada repositório/app.
2. Adicionar todas ao `ssh-agent`.
3. Criar aliases no `~/.ssh/config.local` com `IdentityFile` dedicado.
4. Cadastrar cada chave pública no destino correto.
5. Usar a URL com alias SSH.

Exemplo:

```sshconfig
Host github-dotfiles
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_dotfiles
  IdentitiesOnly yes

Host github-svim
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_svim
  IdentitiesOnly yes
```

Nesse caso, as URLs ficam assim:

```bash
git clone git@github-dotfiles:CrisMorgantee/dotfiles.git
git clone git@github-svim:Simplify-Technology/svim.git
```

Importante: o alias SSH só é usado se a URL do Git também usar esse alias. Ou seja:

- `git@github.com:OWNER/REPO.git` usa o host `github.com`;
- `git@github-dotfiles:OWNER/REPO.git` usa o alias `github-dotfiles`;
- `git@github-svim:OWNER/REPO.git` usa o alias `github-svim`.

No contexto deste ambiente, isso significa que uma estratégia de "uma chave por app" exige:

- usar `git@github-dotfiles:CrisMorgantee/dotfiles.git` no `chezmoi init`, se quiser uma chave dedicada para os dotfiles;
- ajustar `.chezmoiexternal.toml` para `git@github-svim:Simplify-Technology/svim.git`, se quiser uma chave dedicada para o external do Neovim.

## Gerar uma nova chave SSH no macOS

Conforme a documentação do GitHub para macOS, a opção preferencial hoje é `ed25519`, com passphrase e integração ao `ssh-agent`/Keychain.

### Verificar se já existem chaves

```bash
ls -la ~/.ssh
```

Arquivos comuns:

- privada: `~/.ssh/id_ed25519`
- pública: `~/.ssh/id_ed25519.pub`

Se você já tiver uma chave adequada e quiser reutilizá-la, não precisa gerar outra.

### Gerar uma chave única para GitHub

```bash
ssh-keygen -t ed25519 -C "seu-email@github.com" -f ~/.ssh/id_ed25519
```

### Gerar uma chave por aplicação

```bash
ssh-keygen -t ed25519 -C "dotfiles" -f ~/.ssh/id_ed25519_dotfiles
ssh-keygen -t ed25519 -C "svim" -f ~/.ssh/id_ed25519_svim
```

Recomendações:

- use passphrase;
- mantenha nomes previsíveis;
- não armazene chaves privadas dentro do repositório de dotfiles.

## Adicionar a chave ao ssh-agent no macOS

Para uma chave única:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Para múltiplas chaves:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_dotfiles
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_svim
```

Para validar:

```bash
ssh-add -l
```

## Cadastrar a chave pública no GitHub

Mostre o conteúdo da chave pública:

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Ou, se estiver usando múltiplas chaves:

```bash
pbcopy < ~/.ssh/id_ed25519_dotfiles.pub
pbcopy < ~/.ssh/id_ed25519_svim.pub
```

Depois, no GitHub:

1. Abra as configurações da conta ou do repositório.
2. Cole a chave pública.
3. Dê um nome claro para a chave.

### Quando adicionar na conta

Adicione a chave na conta GitHub quando:

- ela representa você como usuário;
- ela deve acessar vários repositórios aos quais sua conta tem permissão.

### Quando usar deploy key

Use deploy key quando:

- a chave pertence a um servidor ou automação;
- a chave deve acessar apenas um repositório;
- você quer isolar o acesso por repositório.

Importante: pelas recomendações do GitHub, deploy key é por repositório. Em um servidor com múltiplos repositórios, gere uma chave por repositório e mapeie cada uma com um alias no `~/.ssh/config`.

## Configuração do `~/.ssh/config`

O repo aplica um `~/.ssh/config` público/safe com:

- defaults globais;
- `github.com` com `AddKeysToAgent`, `UseKeychain` e `IdentityFile ~/.ssh/id_ed25519`;
- `Include ~/.ssh/config.local` para tudo que for privado ou específico.

Isso significa:

- se você usar uma única chave padrão em `~/.ssh/id_ed25519`, o arquivo versionado já atende;
- se você usar múltiplas chaves, complete o `~/.ssh/config.local`.

## Configuração do `~/.ssh/config.local`

O `~/.ssh/config.local` é o lugar certo para:

- aliases GitHub com múltiplas chaves;
- hosts privados;
- chaves dedicadas por app;
- overrides locais que não devem ir para o repo público.

Existe um exemplo em `~/.ssh/config.local.example`.

## Testes recomendados

### Testar a chave padrão

```bash
ssh -T git@github.com
```

### Testar um alias dedicado

```bash
ssh -T git@github-dotfiles
ssh -T git@github-svim
```

### Testar o bootstrap real deste ambiente

```bash
chezmoi init --apply git@github.com:CrisMorgantee/dotfiles.git
```

Depois do bootstrap:

```bash
chezmoi apply
ls ~/.config/nvim
```

Se `~/.config/nvim` estiver populado, o external do Neovim também conseguiu autenticar e clonar corretamente.

## Fluxos práticos

### Usar exatamente este ambiente

1. Configure SSH para o GitHub.
2. Garanta acesso a `CrisMorgantee/dotfiles` e `Simplify-Technology/svim`.
3. Crie `~/.config/chezmoi/chezmoi.toml` com seu nome e e-mail.
4. Rode `chezmoi init --apply git@github.com:CrisMorgantee/dotfiles.git`.

Esse é o caminho mais simples quando `github.com` usa uma chave padrão única com acesso aos dois repositórios.

### Usar este ambiente como base, mas com fork

1. Faça fork do repositório de dotfiles.
2. Decida se vai continuar usando `Simplify-Technology/svim.git` ou seu próprio fork.
3. Se necessário, edite `.chezmoiexternal.toml` para apontar para outro repo do Neovim.
4. Rode `chezmoi init --apply git@github.com:SEU-USUARIO/SEU-FORK.git`.

### Usar uma chave por app

1. Gere `id_ed25519_dotfiles` e `id_ed25519_svim`.
2. Adicione ambas ao agent/Keychain.
3. Configure `github-dotfiles` e `github-svim` no `~/.ssh/config.local`.
4. Use a URL com alias correspondente.
5. Se quiser uma chave dedicada também para o external do Neovim, ajuste `.chezmoiexternal.toml`.

Exemplo:

```bash
chezmoi init --apply git@github-dotfiles:CrisMorgantee/dotfiles.git
```

```toml
[".config/nvim"]
    type = "git-repo"
    url = "git@github-svim:Simplify-Technology/svim.git"
    refreshPeriod = "168h"
```

## Falhas comuns

### `Permission denied (publickey)`

Causas comuns:

- chave pública não cadastrada no GitHub;
- chave errada no alias usado;
- `IdentityFile` aponta para arquivo inexistente;
- você usou `git@github.com:...` mas queria `git@github-dotfiles:...`.

Validação:

```bash
ssh -T git@github.com
ssh -T git@github-dotfiles
ssh -T git@github-svim
```

### Dotfiles clonam, mas o Neovim external falha

Causa comum:

- o `chezmoi init` foi feito com HTTPS ou com uma chave que acessa apenas um repo, mas `Simplify-Technology/svim.git` continua exigindo outra autenticação.

Correção:

- configurar SSH para `Simplify-Technology/svim.git`;
- ou alterar `.chezmoiexternal.toml` para um repo acessível ao usuário.

### `sshf` não mostra meus aliases

O helper `sshf` lê `~/.ssh/config` e `~/.ssh/config.local`. Se o alias não aparecer:

- confirme que ele está em um desses arquivos;
- evite padrões com `*` ou `?` se quiser que apareçam no seletor;
- recarregue o shell com `exec zsh`.

## Referências usadas

- GitHub Docs: geração de chave SSH no macOS e integração com `ssh-agent`/Keychain.
- GitHub Docs: deploy keys e recomendação de uma chave por repositório em cenários de automação.

# Dotfiles com chezmoi

Ambiente de desenvolvimento versionado com `chezmoi`, focado em macOS, Zsh, Homebrew, Powerlevel10k, `mise`, `direnv`, Neovim e tmux.

O objetivo deste repositório é manter um setup reproduzível, documentado e seguro para uso diário, evitando versionar secrets, hosts privados ou overrides específicos da máquina.

Os repositórios usados por padrão neste ambiente são:

- dotfiles: [`git@github.com:CrisMorgantee/dotfiles.git`](https://github.com/CrisMorgantee/dotfiles)
- Neovim external: [`git@github.com:Simplify-Technology/svim.git`](https://github.com/Simplify-Technology/svim)

Se o usuário tiver acesso a esses repositórios, pode usar o setup como está e alterar apenas identidade/local overrides. Se preferir um fork, a documentação cobre como adaptar o fluxo.

## O que este repo entrega

- Bootstrap de um Mac com `chezmoi`.
- Shell Zsh com plugins, aliases, funções e prompt.
- Setup base de Git, CLI, tmux, mise, direnv e Neovim.
- Separação clara entre configuração pública e overrides locais.

## Por onde começar

- Quer instalar este ambiente: vá para [`docs/15-guia-de-instalacao.md`](docs/15-guia-de-instalacao.md).
- Quer configurar acesso GitHub/SSH: vá para [`docs/17-ssh-e-github.md`](docs/17-ssh-e-github.md).
- Quer entender a arquitetura: vá para [`docs/01-visao-geral.md`](docs/01-visao-geral.md).
- Quer ver o mapa completo da documentação: vá para [`docs/README.md`](docs/README.md).

## Passo a passo rápido

1. Instale o `chezmoi`:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

2. Crie sua identidade local:

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
name = "Seu Nome"
email = "seu@email.com"
EOF
```

3. Se for usar os repositórios padrão via SSH, configure seu acesso ao GitHub.

4. Aplique o ambiente:

Se você vai usar este setup exatamente como está:

```bash
chezmoi init --apply git@github.com:CrisMorgantee/dotfiles.git
```

Se você vai usar um fork:

```bash
chezmoi init --apply URL_DO_SEU_REPO
```

5. Abra o terminal e valide:

```bash
chezmoi apply
git config --global user.name
nvim --version
```

Para o fluxo completo:

- [`docs/15-guia-de-instalacao.md`](docs/15-guia-de-instalacao.md): instalação passo a passo;
- [`docs/17-ssh-e-github.md`](docs/17-ssh-e-github.md): SSH/GitHub, chave única ou por app/repo.

## Para quem é este repo

- Quem quer bootstrapar um Mac novo com um ambiente de desenvolvimento consistente.
- Quem usa `chezmoi` para versionar dotfiles e scripts de setup.
- Quem quer separar configuração pública de dados locais ou sensíveis.

## Princípios

- Zero secrets em arquivos versionados.
- Overrides locais em arquivos não versionados.
- Instalação previsível com `chezmoi init --apply`.
- Documentação técnica e guias de uso mantidos no diretório `docs/`.

## Estrutura da documentação

- [`docs/README.md`](docs/README.md): índice geral da documentação.
- [`docs/15-guia-de-instalacao.md`](docs/15-guia-de-instalacao.md): instalação do zero.
- [`docs/17-ssh-e-github.md`](docs/17-ssh-e-github.md): acesso GitHub/SSH, incluindo chave única ou por app/repo.
- [`docs/14-guia-de-uso.md`](docs/14-guia-de-uso.md): uso cotidiano das ferramentas.
- [`docs/13-seguranca.md`](docs/13-seguranca.md): modelo de segurança e separação entre público e privado.
- [`docs/01-visao-geral.md`](docs/01-visao-geral.md): visão geral da arquitetura.

## Público vs. privado

Se este repo for público:

- mantenha secrets fora do repositório;
- mantenha hosts privados fora de `~/.ssh/config` versionado;
- prefira exemplos com placeholders, não com identidade real;
- use arquivos locais como `~/.zshrc.local` e `~/.ssh/config.local` para dados específicos da máquina ou do trabalho.

## Estado atual

Este setup foi pensado principalmente para macOS e Apple Silicon. Parte da configuração pode funcionar em outros ambientes, mas os scripts e defaults documentados assumem macOS.

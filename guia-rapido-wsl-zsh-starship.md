# Guia Rápido — WSL, Linux e Terminal

**Uso diário:** WSL 2, Ubuntu/Debian, Fedora, Zsh e Starship  
**Versão:** 1.1 · **Revisado em:** 2026-09-25

> Comandos do **Windows**: PowerShell/CMD. Comandos do **Linux**: dentro da distro WSL.

## Índice

- [WSL](#wsl)
- [Pacotes](#pacotes)
- [Sistema e logs](#sistema-e-logs)
- [Rede](#rede)
- [Git](#git)
- [Zsh e Starship](#zsh-e-starship)
- [Ferramentas de terminal](#ferramentas-de-terminal)
- [Problemas comuns](#problemas-comuns)
- [Checklist de segurança](#checklist-de-segurança)
- [Referências](#referências)

---

## WSL

### Ver e abrir distros

```powershell
wsl -l -v                 # Lista distros, estado e versão
wsl -d Ubuntu             # Abre uma distro específica
wsl --shutdown            # Para todas as distros e a VM do WSL
wsl --terminate Ubuntu    # Para somente uma distro
```

### Backup e remoção

```powershell
wsl --export Ubuntu C:\Backup\ubuntu.tar
wsl --unregister Ubuntu-ZshStarDeb
```

> ⚠️ `--unregister` apaga definitivamente a distro e todos os arquivos dela. Exporte antes se houver algo importante.

### Restaurar ou ajustar WSL 2

```powershell
wsl --import Ubuntu-Backup C:\WSL\Ubuntu-Backup C:\Backup\ubuntu.tar --version 2
wsl --set-version Ubuntu 2
wsl --set-default-version 2
```

[Voltar ao índice](#índice)

---

## Pacotes

### Ubuntu / Debian

```bash
sudo apt update                    # Atualiza catálogo
sudo apt upgrade                   # Atualiza pacotes
sudo apt install <pacote>          # Instala
sudo apt remove <pacote>           # Remove, preserva configuração
sudo apt autoremove                # Remove dependências não usadas
apt search <termo>                 # Pesquisa
```

### Fedora

```bash
sudo dnf upgrade --refresh         # Atualiza catálogo e pacotes
sudo dnf install <pacote>          # Instala
sudo dnf remove <pacote>           # Remove
dnf search <termo>                 # Pesquisa
sudo dnf clean all                 # Limpa metadados/cache
```

[Voltar ao índice](#índice)

---

## Sistema e logs

```bash
systemctl status <serviço>         # Estado e erro recente
sudo systemctl restart <serviço>   # Reinicia serviço
sudo systemctl enable <serviço>    # Inicia junto do sistema
journalctl -u <serviço> -n 50      # Últimas 50 linhas do serviço
journalctl -f                      # Logs em tempo real
df -h                              # Espaço nos discos
free -h                            # RAM e swap
```

> No WSL, `systemctl` só funciona se o systemd estiver habilitado para aquela distro.

[Voltar ao índice](#índice)

---

## Rede

```bash
ping -c 4 1.1.1.1                 # Testa rede sem depender de DNS
ping -c 4 google.com              # Testa rede e DNS
cat /etc/resolv.conf              # Mostra DNS configurado
ss -tuln                          # Portas locais em escuta
curl -I http://localhost:8080     # Testa aplicação HTTP local
```

[Voltar ao índice](#índice)

---

## Git

```bash
git status                         # Arquivos alterados e branch atual
git add <arquivo>                  # Prepara alteração
git commit -m "mensagem clara"     # Registra alteração
git pull --ff-only                 # Atualiza sem merge automático inesperado
git push                           # Envia commits
git switch -c nome-da-branch       # Cria e troca de branch
git switch nome-da-branch          # Troca de branch
git log --oneline --graph --all    # Histórico resumido
```

### Conflito

1. Rode `git status` para identificar os arquivos.
2. Edite os trechos entre `<<<<<<<`, `=======` e `>>>>>>>`.
3. Teste o projeto, então execute `git add <arquivo>` e `git commit`.

[Voltar ao índice](#índice)

---

## Zsh e Starship

```bash
source ~/.zshrc                   # Recarrega configuração do Zsh
starship --version                 # Confirma instalação
rm -f ~/.zcompdump*               # Remove cache de completion do Zsh
source ~/.zshrc                   # Gera/recarrega completion
```

Arquivos mais comuns:

```text
~/.zshrc                          # Configuração principal do Zsh
~/.config/starship.toml           # Tema/configuração do Starship
```

> Se o Zsh ficar lento, comente temporariamente plugins/aliases recentes no `~/.zshrc`, recarregue e teste. Seu setup pode usar zoxide, fzf, eza, fd, ripgrep, bat e plugins de histórico/autossugestão. [file:8]

[Voltar ao índice](#índice)

---

## Ferramentas de terminal

```bash
z <trecho>                        # Navega por histórico de diretórios (zoxide)
eza -la                           # Lista detalhada, se eza estiver instalado
fd "nome"                         # Procura arquivos, se fd estiver instalado
rg "texto"                        # Procura conteúdo em arquivos (ripgrep)
bat arquivo.txt                   # Lê arquivo com destaque, se bat instalado
```

Atalhos úteis:

- `Ctrl + R`: busca reversa no histórico do shell.
- `Ctrl + T`: seletor fzf de arquivos/diretórios, se configurado.
- `Tab`: completa comandos e caminhos.

[Voltar ao índice](#índice)

---

## Problemas comuns

### WSL não inicia ou está sem rede

```powershell
wsl --shutdown
wsl -d Ubuntu
```

Se continuar, reinicie o Windows. Dentro da distro, teste primeiro `ping -c 4 1.1.1.1`; se funcionar mas `ping -c 4 google.com` falhar, o problema tende a ser DNS.

### Disco cheio

```bash
df -h
du -sh ~/* 2>/dev/null
```

Depois limpe somente o que reconhecer: no Ubuntu, `sudo apt autoremove && sudo apt clean`; no Fedora, `sudo dnf clean all`. Antes de remover arquivos grandes, confirme o caminho com `ls -lh`.

### Serviço não inicia

```bash
systemctl status <serviço>
journalctl -u <serviço> -n 50 --no-pager
```

Verifique mensagem de erro, configuração, porta ocupada e dependências antes de tentar reinstalar o serviço.

### Permissão negada

```bash
ls -ld <caminho>
```

Use `sudo` apenas quando a ação realmente exigir privilégios. Evite `chmod -R 777` e `chown -R` sem revisar o caminho: ambos podem causar problemas de segurança ou alterar muitos arquivos.

[Voltar ao índice](#índice)

---

## Checklist de segurança

Antes de remover distro, limpar diretórios ou alterar configurações importantes:

- [ ] Confirme em qual distro e diretório você está: `pwd` e `wsl -l -v`
- [ ] Faça backup ou exporte a distro: `wsl --export <distro> <arquivo.tar>`
- [ ] Revise o comando antes de usar `sudo`, `rm`, `--unregister` ou `-R`
- [ ] Mude uma coisa por vez e valide o resultado

[Voltar ao índice](#índice)

---

## Referências

- Microsoft WSL: https://learn.microsoft.com/pt-br/windows/wsl
- Ubuntu no WSL: https://ubuntu.com/wsl/docs/stable
- Fedora no WSL: https://docs.fedoraproject.org/en-US/cloud/wsl
- Zsh: https://zsh.sourceforge.io
- Starship: https://starship.rs

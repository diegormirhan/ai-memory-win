# Escopo Windows nativo

## Resultado desejado

O usuário instala e inicia o ai-memory em uma máquina Windows com um fluxo
pequeno e idempotente:

```powershell
irm <url-do-instalador> | iex
ai-memory setup
```

O formato final pode mudar, mas a experiência deve continuar equivalente:
instalar o binário, inicializar os dados, manter o servidor local disponível,
configurar os agentes selecionados e confirmar que tudo funciona.

## Contrato do instalador PowerShell

O futuro `install.ps1` deve:

1. localizar ou instalar `ai-memory.exe` em diretório do usuário;
2. usar `%LOCALAPPDATA%\ai-memory` como raiz padrão de dados e configuração;
3. iniciar `ai-memory init` sem sobrescrever uma instalação existente;
4. criar uma tarefa por usuário no Agendador do Windows para executar
   `ai-memory serve` no logon e reiniciar após falha;
5. oferecer integração explícita de MCP e hooks para os agentes escolhidos;
6. criar backup antes de alterar configurações de agentes;
7. suportar `-WhatIf`, mensagens de falha acionáveis e verificação final com
   `ai-memory status`.

O instalador não deve exigir sessão elevada para a instalação padrão. Não deve
baixar ou executar conteúdo sem validação de origem quando houver release
assinada ou checksum disponível.

## O que já foi removido da distribuição

Os artefatos externos de Docker, Nix, AUR, systemd, launchd, wrappers de
contêiner, workflows CI/CD originais, hooks `.sh` e scripts Unix foram
removidos desta árvore. A raiz foi reduzida a crates, hooks PowerShell, testes,
documentação e avaliações.

## Trabalho que ainda falta

Ainda existem abstrações e ramos de compatibilidade multiplataforma dentro do
Rust. Eles não devem ser apagados por arquivo inteiro, pois vários módulos
também atendem o Windows. A ordem segura de migração é:

1. fazer o workspace compilar e testar no toolchain Windows;
2. retirar ramos Docker e resolução de escopo de contêiner;
3. retirar renderização de hooks POSIX/Git Bash, preservando comandos diretos
   `ai-memory.exe hook` e os adaptadores PowerShell necessários;
4. deixar o ciclo de vida do servidor baseado em Ctrl-C e Task Scheduler,
   não SIGTERM/systemd;
5. implementar `install.ps1` com testes usando raiz temporária e chamadas do
   Agendador simuladas;
6. configurar CI Windows somente depois que o fluxo local estiver estável.

Ao remover qualquer ramo, procure suas referências com `rg` e acrescente um
teste de regressão para o comportamento Windows que o substitui.

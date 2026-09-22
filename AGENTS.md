# Instruções para agentes

Este é um fork do ai-memory em migração para uma experiência **Windows nativa**
e simples. Leia, nesta ordem:

1. `docs/CODEX_START_HERE.md`
2. `docs/PROJECT_CONTEXT.md`
3. `docs/WINDOWS_NATIVE_SCOPE.md`
4. `docs/ARCHITECTURE.md` quando a tarefa tocar a arquitetura interna.

## Regras

- O fluxo padrão não pode depender de Docker, WSL, Linux, macOS, systemd,
  launchd ou hooks `.sh`.
- Preserve sanitização, escrita SQLite por um único escritor, resolução tipada
  de escopo e escrita atômica do wiki.
- Faça mudanças pequenas, com busca prévia por referências usando `rg`.
- Para persistência no Windows, use Task Scheduler por usuário e dados em
  `%LOCALAPPDATA%\\ai-memory` como padrão.
- O objetivo é um único instalador idempotente `install.ps1`, não uma matriz
  de formas de instalação.

## Verificação

Antes de concluir uma mudança de código, execute:

```powershell
cargo fmt --all -- --check
cargo test --workspace --all-targets
```

# Comece aqui — contexto para o Codex

Leia nesta ordem ao abrir uma nova sessão:

1. `AGENTS.md` — regras canônicas da base e invariantes de segurança;
2. `docs/PROJECT_CONTEXT.md` — intenção e princípios deste fork;
3. `docs/WINDOWS_NATIVE_SCOPE.md` — escopo, decisões e sequência da migração;
4. `docs/ARCHITECTURE.md` — mapa técnico da arquitetura herdada;
5. o arquivo ou crate diretamente relacionado à tarefa atual.

## Estado atual

Este é um fork em redução para Windows nativo. A limpeza de arquivos de
distribuição já ocorreu; a simplificação interna do Rust e o instalador
PowerShell ainda não foram implementados. Não presuma que referências a Docker,
Linux ou macOS dentro dos crates sejam fluxos suportados: elas são trabalho de
migração pendente.

## Mapa rápido dos crates

| Crate | Responsabilidade |
| --- | --- |
| `ai-memory-core` | tipos de domínio, IDs e erros; sem I/O |
| `ai-memory-store` | SQLite, migrações, índices e escritor único |
| `ai-memory-wiki` | escrita atômica de Markdown, watcher e Git |
| `ai-memory-hooks` | schemas, sanitização e entrada de hooks |
| `ai-memory-mcp` | MCP e rotas HTTP/admin |
| `ai-memory-llm` | provedores LLM e embeddings |
| `ai-memory-consolidate` | compilação de sessões, retenção e curadoria |
| `ai-memory-web` | UI web somente leitura e API |
| `ai-memory-workstream` | transcritos e lançamento gerenciado |
| `ai-memory-cli` | `ai-memory.exe`, comandos e instalação de integrações |

## Regras de trabalho

- Faça mudanças pequenas e focadas; não misture limpeza de plataforma com
  features novas.
- Preserve sanitização, escrita SQLite serializada, resolução tipada de escopo
  e escrita atômica do wiki.
- Use `rg` antes de remover uma referência ou um caminho de compatibilidade.
- Não recrie Docker, WSL, systemd, launchd ou hooks `.sh` como fallback.
- Prefira `%LOCALAPPDATA%` e Task Scheduler para instalação e persistência do
  servidor no Windows.
- Antes de declarar uma mudança pronta, rode no mínimo:

  ```powershell
  cargo fmt --all -- --check
  cargo test --workspace --all-targets
  ```

## Próxima tarefa recomendada

Primeiro, corrija o ambiente Rust local e execute o baseline de compilação.
Depois transforme um único caminho de ponta a ponta: binário Windows → servidor
local → um agente (por exemplo Codex) → MCP + hook → `ai-memory status`.
Não implemente todos os agentes antes de esse caminho mínimo estar confiável.

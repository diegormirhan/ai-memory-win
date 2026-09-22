# ai-memory for Windows

`ai-memory` gives AI coding agents a shared, persistent memory on a native
Windows machine. It records sanitized lifecycle events, compiles them into a
Git-backed Markdown wiki, and exposes recall and handoffs through MCP.

This repository deliberately supports **Windows only**. It contains no Docker
runtime, WSL workflow, Unix package, or non-Windows release path.

## How it works

```text
agent lifecycle hooks
        |
        v
  ai-memory.exe hook
        |
        v
  native ai-memory server
        |
        +-- SQLite index (derived data)
        +-- Markdown wiki (source of truth)
        +-- MCP tools and local web UI
```

The server owns one data directory. The wiki is ordinary Markdown committed to
Git; SQLite provides fast full-text search, entity links, handoffs, and optional
embeddings. A single writer serializes mutations so concurrent agents can work
against one project safely.

## Native Windows status

The source currently retains cross-platform abstractions in Rust, but the
distribution surface has been reduced to native Windows artifacts. The intended
installation path is a PowerShell installer that will:

1. install or locate `ai-memory.exe`;
2. create `%LOCALAPPDATA%\\ai-memory` for data and configuration;
3. register a Windows Task Scheduler task for `ai-memory serve`;
4. add the binary directory to the user `PATH` when requested; and
5. run `install-mcp` and `install-hooks` for selected agent CLIs.

See [the native Windows guide](docs/windows.md) for the target structure and
the staged migration plan.

## Contexto da migração

Para retomar o projeto em uma sessão nova do Codex, leia
[Comece aqui](docs/CODEX_START_HERE.md). Os motivos deste fork estão em
[Contexto do projeto](docs/PROJECT_CONTEXT.md), e o contrato da versão Windows
está em [Escopo Windows nativo](docs/WINDOWS_NATIVE_SCOPE.md).

## Development

Rust 1.95 is pinned in `rust-toolchain.toml`. From PowerShell:

```powershell
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace --all-targets
```

The workspace is split by responsibility:

- `ai-memory-core`: domain types and invariants;
- `ai-memory-store`: SQLite, migrations, indexing, and writer actor;
- `ai-memory-wiki`: atomic Markdown and Git operations;
- `ai-memory-hooks`: sanitization and hook ingestion;
- `ai-memory-mcp`: MCP and HTTP routing;
- `ai-memory-consolidate`: session compilation and retention;
- `ai-memory-web`: read-only web UI and API;
- `ai-memory-cli`: the `ai-memory.exe` entry point.

The architectural detail is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

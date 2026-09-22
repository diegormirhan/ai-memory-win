# Native Windows guide

## Runtime model

`ai-memory.exe` runs two roles:

- `ai-memory serve` owns the local data directory, the SQLite writer, MCP HTTP
  endpoints, hook ingress, and optional read-only web UI.
- Every other command is a short-lived client or maintenance command. In
  particular, `ai-memory hook` receives one lifecycle event from an agent and
  sends it through the same sanitized ingestion path.

The default native data root should be `%LOCALAPPDATA%\\ai-memory`. It contains
the Git-backed `wiki`, derived `db`, raw bounded transcript ledger, logs, and
configuration. Do not let two server processes own the same data root.

## Intended installer

The repository will use a root `install.ps1` as the sole supported installer.
It should be idempotent and split into small functions:

1. `Assert-Prerequisites` checks Windows version, PowerShell, and the selected
   installation source.
2. `Install-AiMemoryBinary` installs a signed/released `ai-memory.exe` into a
   user-owned directory such as `%LOCALAPPDATA%\\Programs\\ai-memory`.
3. `Initialize-AiMemoryData` creates `%LOCALAPPDATA%\\ai-memory`, writes only
   missing configuration, and runs `ai-memory init`.
4. `Install-ServiceTask` creates a per-user Task Scheduler task that starts
   `ai-memory serve` at logon and restarts it after failure. It must never
   require an elevated PowerShell session.
5. `Install-AgentIntegration` calls `install-mcp --apply` and
   `install-hooks --apply` for agents explicitly selected by the user.
6. `Test-Installation` calls `ai-memory status` and reports the data directory,
   server URL, task name, and installed integrations.

The installer must support `-WhatIf`, avoid overwriting existing config or
agent settings without a backup, and use `Start-Process -Wait` / explicit exit
code checks for native executables.

## Agent integration

Native hooks should invoke `ai-memory.exe hook` directly wherever an agent
supports executable-plus-arguments hook configuration. This avoids a shell
process and preserves the bounded hook path. Agent configurations that require
a command string may use PowerShell only as a compatibility adapter.

MCP configuration points the agent at the loopback server, normally
`http://127.0.0.1:49374`. Do not expose that listener to a network unless
authentication and TLS termination have been deliberately configured.

## Migration work remaining

The removed packaging files were only the outer distribution layer. To make
the codebase Windows-only, perform the remaining work in this order:

1. replace Docker/container scope fallbacks with native current-directory and
   explicit scope resolution;
2. remove Unix shell hook rendering and retain native hook command rendering;
3. remove container detection and Docker-specific uninstall, upgrade, and
   setup-agent branches;
4. replace Unix signal handling with Windows Ctrl-C and Task Scheduler process
   lifecycle behavior;
5. restrict CI and release packaging to `x86_64-pc-windows-msvc`; and
6. add installer tests using a temporary data root and mocked Task Scheduler
   calls before enabling it on a real profile.

Keep the typed scope resolver, sanitizer, single SQLite writer, atomic wiki
writes, and Git checkpointing unchanged: those are platform-neutral safety
boundaries.

# Contexto do projeto

## Por que este fork existe

Este projeto parte do ai-memory, mas segue uma direção de produto diferente:
uma instalação local, nativa e opinativa para Windows. A meta é permitir que
uma pessoa use memória persistente para agentes de código sem precisar escolher
entre Docker, WSL, distribuições Linux, serviços Unix, múltiplos gerenciadores
de pacote ou sequências longas de comandos.

O problema que queremos resolver não é a capacidade do ai-memory original. A
base técnica já oferece captura por hooks, MCP, wiki Markdown versionada por
Git, SQLite para busca e handoffs entre agentes. O problema é reduzir a carga
operacional para o caso de uso principal: uma máquina Windows rodando agentes
locais.

## Princípios de produto

1. **Um caminho padrão.** A instalação comum deve caber em um instalador
   PowerShell e uma etapa simples de integração do agente.
2. **Windows nativo.** Não depender de Docker nem WSL para o fluxo normal.
3. **Local por padrão.** Dados e servidor ficam na máquina do usuário e o
   listener inicia em loopback.
4. **Avançado não é padrão.** Diretório de dados customizado, servidor remoto,
   autenticação, provedores LLM e configurações incomuns podem existir, mas não
   devem aparecer como decisões obrigatórias durante a instalação inicial.
5. **Menos caminhos, mais confiabilidade.** Cada alternativa adicional cria
   combinações de teste, documentação, upgrade e suporte. Preferimos uma
   experiência previsível a uma matriz ampla de ambientes.

## O que continua valioso da arquitetura original

- Markdown no Git como fonte de verdade;
- SQLite como índice derivado e busca rápida;
- sanitização como fronteira de privacidade;
- um único escritor SQLite;
- identidade tipada de workspace, projeto e página;
- hooks de captura limitados e fire-and-forget;
- MCP para leitura, busca, handoffs e escrita controlada.

Não reimplemente esses limites de segurança durante a simplificação. O objetivo
é remover superfícies de distribuição e compatibilidade, não enfraquecer as
garantias de dados, privacidade ou concorrência.

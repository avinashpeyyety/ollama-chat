# Agent guide — ollama-chat

## Execution policy

**Primary:** Grok Build Composer 2.5 Fast. **Fallback:** local ornith/qwen when credits ≥70% — see `../ai-lab-vault/EXECUTION.md` and `../ai-lab-vault/05-cost/COST-LOG.md`.

This repo is for **local QA** of models — never spends Grok credits.

## Before you code

1. Read `NEXT.md` — implement **item 1 only**
2. Do not edit unrelated repos in the same session
3. Match existing style: ES modules, minimal deps, no drive-by refactors

## Project

Local HTTPS chat app. Supervisor on `:3443`, chat API on `:3445`, proxies to Ollama `:11434`.

```
control-server.js  →  server.js  →  Ollama
public/app.js      →  streaming UI
```

## Models

Default stack: `qwen3.5:9b` + `ornith:9b`. Model list is dynamic from `/api/models`.

## Verify changes

```bash
npm run restart-and-test
```

Open https://localhost:3443 — hard-refresh after `app.js` changes (`?v=` bump in `index.html`).

## Do not

- Replace `server.js` / `app.js` with placeholders
- Add cloud API dependencies
- Commit `.venv`, `node_modules`, `certs/`, or `server.log`

## Obsidian

Planning & pipelines: `../ai-lab-vault/01-projects/ollama-chat.md`
# New Project Structure — Multi-Repo with Claude Code Agents

## Folder Structure

```
MyProject/                        ← workspace root (its own git repo: "project-config")
├── CLAUDE.md                     ← master, uses @imports to pull from docs/
├── .mcp.json                     ← project-level MCP overrides (DB credentials etc.)
├── .claude/
│   ├── agents/
│   │   ├── backend-agent.md
│   │   ├── frontend-agent.md
│   │   ├── libs-agent.md
│   │   ├── review-security.md
│   │   ├── deployment-engineer.md
│   │   └── docs-writer.md
│   ├── commands/                 ← custom slash commands (project skills)
│   │   ├── deploy-staging.md
│   │   ├── review-pr.md
│   │   └── sync-docs.md
│   └── settings.json             ← shared permissions, hooks
├── backend/                      ← cloned repo
│   ├── CLAUDE.md                 ← backend-specific context
│   └── ...
├── frontend/                     ← cloned repo
│   ├── CLAUDE.md
│   └── ...
├── libs/                         ← cloned repo
│   ├── CLAUDE.md
│   └── ...
└── docs/                         ← cloned repo
    ├── CLAUDE.md                 ← docs-agent context
    ├── architecture.md
    ├── api-contracts.md
    ├── decisions.md              ← architectural decision records (ADRs)
    ├── in-progress.md            ← agent handoff queue
    └── ...
```

The **workspace root** (`MyProject/`) is its own git repo tracking only Claude config —
`CLAUDE.md`, `.claude/`, `.mcp.json`. Each sub-project is an independent repo cloned
into the workspace.

---

## Master CLAUDE.md — Where Does It Live?

**At the workspace root**, not inside the docs repo. Claude Code reads CLAUDE.md by
walking **up from the working directory**. It does not automatically reach into `docs/`.
The docs repo's CLAUDE.md only loads when working inside `docs/`.

**The right pattern:** workspace root `CLAUDE.md` uses `@` includes to pull from docs:

```markdown
# Master CLAUDE.md — MyProject

## Project overview
@./docs/architecture.md
@./docs/api-contracts.md

## Backend
See backend/CLAUDE.md

## Frontend
See frontend/CLAUDE.md
```

This way:
- Architecture documentation lives in the docs repo (single source of truth)
- Claude's context is assembled from those files at session start
- The docs agent updates `docs/architecture.md` → change reflects in Claude's context next session

---

## Agents

| Agent | Scope | Tools |
|-------|-------|-------|
| `backend-agent` | Backend repo only — features, fixes, tests | Read, Write, Edit, Bash |
| `frontend-agent` | Frontend repo only — components, services | Read, Write, Edit, Bash |
| `libs-agent` | Shared libraries — breaking changes, versioning | Read, Write, Edit, Bash |
| `review-security` | Cross-repo diff + security audit (read-only) | Read, Glob, Grep, Bash |
| `deployment-engineer` | Docker, CI/CD, infra | Read, Edit, Bash |
| `docs-writer` | Docs repo only — keeps docs in sync with code | Read, Write, Edit, Glob, Grep |

**Rule:** Each agent has a tight scope — one agent, one repo. The `review-security`
agent is the only one that reads across repos, and it should be read-only.

---

## Context Window Strategy

### 1. Keep CLAUDE.md files lean
Each sub-project CLAUDE.md should be a reference card, not a tutorial. Aim for
under 150 lines. Deep detail goes in `docs/` and gets `@imported` only when needed.

### 2. Session discipline — one agent, one task
Don't have the backend agent aware of the entire frontend. Scope each agent to
exactly what it needs. If the backend agent needs the API contract, import only
`docs/api-contracts.md` in its definition — nothing else.

### 3. Memory files as rolling summary
Maintain memory at `~/.claude/projects/.../memory/`:

```
memory/
├── MEMORY.md          ← index + key decisions (keep under 200 lines)
├── backend.md         ← backend patterns, gotchas, solved problems
├── frontend.md        ← frontend conventions, component patterns
├── decisions.md       ← ADR log: why X was chosen over Y
└── progress.md        ← completed features, in-flight work
```

After each significant session, have the docs-writer agent update the relevant
memory file.

### 4. Use /compact proactively
Don't wait for the context warning. Compact mid-session before switching to a
new feature area.

### 5. Agents for isolation, not just automation
Background agents run with their own fresh context. For a large feature, spawn
a background agent per repo and let them work in parallel rather than doing
everything serially in one context.

---

## What Not to Miss

### API contract / shared types
Define where the truth about your API shape lives **before writing any code**:
- OpenAPI spec in `docs/api-contracts/` — both backend and frontend agents validate against it
- Shared TypeScript types in `libs/` — frontend imports directly
- This is the most common source of cross-repo drift. Define it explicitly.

### Agent handoff protocol
When the backend agent finishes an endpoint, how does the frontend agent know?
Use `docs/in-progress.md` as a shared work queue:
- Backend writes: "endpoint X complete, spec at `docs/api/X.md`"
- Frontend picks it up next session

### Git submodules vs plain clones
Submodules give version-pinning (workspace tracks exact commits of each sub-repo)
but add friction. For fast-moving development, plain clones are simpler. Decide early
and document the decision.

### `.claude/settings.json` permissions
For a trusted private project, auto-approve common operations. A shared `settings.json`
at the workspace root avoids re-approving the same tools in every session.

### Environment/secrets per context
`.mcp.json` should reference **environment variables** rather than hardcoded credentials,
so different environments (dev/staging/prod) just set different env vars:

```json
"env": {
  "MSSQL_SERVER": "${DB_SERVER}",
  "MSSQL_DATABASE": "${DB_NAME}",
  "MSSQL_PASSWORD": "${DB_PASSWORD}"
}
```

### Cross-repo review trigger
The `review-security` agent needs to know which repos changed. Hook it to
`docs/changelog.md` — each agent appends to it, and the reviewer reads the
changelog rather than diffing all repos blindly.

### Docs-first discipline
Since you're building the docs-writer agent, enforce: every merged feature must
have an updated `docs/` entry before it's "done". Bake this check into your
`review-security` agent's checklist.

---

## Recommended Start Sequence

1. Create `MyProject/` workspace root repo
2. Write `docs/architecture.md` and `docs/api-contracts.md` **before any code**
3. Write the master `CLAUDE.md` with `@imports` from docs
4. Define all 6 agents in `.claude/agents/`
5. Define custom slash commands in `.claude/commands/`
6. Set up `.mcp.json` with env-var-based credentials
7. Clone each sub-repo into the workspace
8. Write each sub-project `CLAUDE.md`
9. Start coding — backend and frontend agents both work against the same contract

---

## GitHub Copilot CLI — Comparison and Dual-Tool Structure

> My earlier comparison was wrong. Copilot CLI is a full terminal agent with the same
> core capabilities as Claude Code. Here is the accurate picture.

### Feature Comparison

| Feature | Claude Code | Copilot CLI |
|---------|-------------|-------------|
| Context file | `CLAUDE.md` (with `@import`) | `AGENTS.md` |
| Sub-agents | `.claude/agents/*.md` (frontmatter) | `.agent.md` in plugin `agents/` |
| Skills / commands | `.claude/commands/*.md` | `SKILL.md` directories in `skills/` |
| MCP servers | `.mcp.json` | `.mcp.json` — **identical format** |
| Hooks | `.claude/settings.json` hooks | `.github/hooks/*.json` |
| Plan mode | Plan mode / `Shift+Tab` | `/plan` command / `Shift+Tab` |
| Parallel agents | Background agents | `/fleet` command |
| Multi-model | Claude only | GPT / Claude / Gemini via `/model` |
| GitHub integration | Via GitHub MCP server | Native GitHub MCP server built-in |
| Plugin bundle | No — flat directories | `plugin.json` bundles agents+skills+hooks+MCP |
| Auto-memory | `~/.claude/projects/.../memory/` | No built-in equivalent |
| `@import` in context file | Yes — pull docs into context | No — flat single file |

Note: Skills can live in `.github/skills` **or** `.claude/skills` — deliberate
cross-compatibility between the two tools.

### Copilot CLI Project Structure

```
MyProject/
├── AGENTS.md                         ← master context (≈ CLAUDE.md, no @import)
├── .mcp.json                         ← identical format to Claude Code
├── .github/
│   ├── hooks/
│   │   └── policy.json               ← lifecycle hooks (≈ .claude/settings.json hooks)
│   └── copilot-instructions.md       ← VS Code Copilot context (separate from CLI)
├── .copilot/
│   └── my-plugin/
│       ├── plugin.json               ← bundles agents + skills + MCP
│       ├── agents/
│       │   ├── backend.agent.md
│       │   ├── frontend.agent.md
│       │   ├── libs.agent.md
│       │   ├── review-security.agent.md
│       │   ├── deployment-engineer.agent.md
│       │   └── docs-writer.agent.md
│       ├── skills/
│       │   ├── deploy-staging/SKILL.md
│       │   ├── review-pr/SKILL.md
│       │   └── sync-docs/SKILL.md
│       └── .mcp.json
├── backend/
│   ├── AGENTS.md
│   └── ...
├── frontend/
│   ├── AGENTS.md
│   └── ...
├── libs/
│   ├── AGENTS.md
│   └── ...
└── docs/
    ├── AGENTS.md
    └── ...
```

### Agent file format (`.agent.md`) — nearly identical to Claude Code

```markdown
---
name: backend-agent
description: Implements features in the backend repo.
tools: ["bash", "edit", "view"]
---

You are a backend specialist for MyProject...
```

### Plugin manifest (`plugin.json`) — Copilot's unique bundling mechanism

```json
{
  "name": "myproject-agents",
  "version": "1.0.0",
  "agents": "agents/",
  "skills": ["skills/"],
  "hooks": "../.github/hooks/policy.json",
  "mcpServers": ".mcp.json"
}
```

### Real Differences

**Copilot CLI advantages:**
- Multi-model: switch between GPT-4.1, Claude, Gemini with `/model`
- `/fleet`: explicit parallel execution with result convergence
- Plugin system: bundle + version agents as a distributable package
- Native GitHub MCP: issues, PRs, Actions built-in with no config
- Enterprise SSO: company GitHub auth works out of the box

**Claude Code advantages:**
- `@import` in CLAUDE.md: pull docs content into context automatically
- Auto-memory: cross-session persistence built-in
- Simpler structure: no plugin manifest needed

### Dual-Tool Setup (support both from one codebase)

Since `.mcp.json` is identical and agent frontmatter is nearly the same, maintain both
with minimal duplication:

```
MyProject/
├── CLAUDE.md              ← Claude Code master context (with @imports)
├── AGENTS.md              ← Copilot CLI master context (same content, flat)
├── .mcp.json              ← shared by both tools, identical format
├── .claude/
│   └── agents/            ← Claude Code agents
│       └── backend.md
└── .copilot/
    └── plugin/
        └── agents/        ← Copilot CLI agents (same instructions, .agent.md extension)
            └── backend.agent.md
```

---

## Summary Checklist

- [ ] Workspace root repo created (`project-config`)
- [ ] `CLAUDE.md` at workspace root with `@imports` from `docs/`
- [ ] `docs/` repo: `architecture.md`, `api-contracts.md`, `decisions.md`, `in-progress.md`
- [ ] 6 agent files in `.claude/agents/`
- [ ] Custom slash commands in `.claude/commands/`
- [ ] `.mcp.json` with env-var credentials
- [ ] `.claude/settings.json` with shared permissions
- [ ] Each sub-repo has its own `CLAUDE.md`
- [ ] Memory strategy documented in `memory/MEMORY.md`
- [ ] Agent handoff protocol defined in `docs/in-progress.md`
- [ ] Git submodule vs clone decision made and documented

# ADR-001: Cline over aider as the primary coding agent

**Status:** Accepted  
**Date:** 2026-04-18

---

## Context

We need a coding agent that connects to our remote Ollama instance via SSH tunnel and assists with real development work. Two strong candidates: aider (CLI) and Cline (VS Code extension).

---

## Decision

**Use Cline as the primary coding agent.**

---

## Comparison

| Capability | aider | Cline |
|-----------|-------|-------|
| Interface | Terminal REPL | VS Code sidebar — full IDE integration |
| File context | You specify files explicitly (`/add file.java`) | Reads repo map automatically, explores on its own |
| Diff review | Printed to terminal | Visual diff in editor, approve/reject per change |
| Multi-file edits | Works but manual | Native — plans and edits across files |
| Approval flow | Confirm in terminal | Click Approve/Reject per action, like Claude Code |
| Shell commands | Runs git, tests | Can run terminal commands with your approval |
| Model config | CLI flag or `.aider.conf.yml` | VS Code settings — point at `localhost:11434` |
| Repo awareness | Git-based repo map | Full repo scan + can request specific files |
| `--message` one-liners | ✅ `aider --message "..."` | ❌ Interactive only |
| Offline/headless use | ✅ Works in any terminal | ❌ Requires VS Code |

---

## Why Cline Wins For This Setup

**1. Approval flow matches how we actually work**  
Cline shows each proposed file change as a diff and asks for approval before writing. aider prints changes to the terminal — easy to miss, harder to review on long outputs.

**2. No file management overhead**  
With aider you constantly `/add` files to context. Cline scans the repo and pulls in what it needs. For a new codebase you're unfamiliar with, this matters.

**3. VS Code is already open**  
We're already in the editor. Running a parallel terminal session for aider adds friction. Cline lives in the sidebar.

**4. Better for the "app we're building tomorrow"**  
The next phase is building a backend server. That involves multiple files, multiple languages (Java/Python + config), and iterative editing. Cline handles this better than aider with a 14B model.

---

## Why aider Is Still Worth Knowing

- Headless environments (no VS Code — remote servers, CI)
- One-shot commands: `aider --message "fix this bug"` in a script
- Lighter weight — no IDE needed

---

## Consequences

- aider remains installed and documented as a secondary option
- All primary development against the remote model goes through Cline
- `scripts/tunnel.sh` remains the same — Cline connects to `localhost:11434` just like aider did

---

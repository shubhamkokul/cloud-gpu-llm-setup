# Backend API — Replace the SSH Tunnel

> **Status: In Progress** — picking this up next session.

The SSH tunnel works but has one fundamental limitation: it's tied to a single machine with a terminal open. Your phone can't reach it. A second laptop can't reach it without its own tunnel.

This doc covers replacing the tunnel with a proper backend that runs alongside Ollama on the remote machine.

---

## The Problem With SSH Tunnel

```
Current setup:
  Your PC only → terminal open → localhost:11434 → tunnel → remote Ollama

What we want:
  Any device → HTTPS + auth → backend → Ollama → response
```

---

## Target Architecture

```
Phone / Tablet / Any PC
        ↓  HTTPS + Bearer token
┌──────────────────────────────────┐
│        Remote GPU Machine        │
│                                  │
│  Backend Server (port 8080)      │
│  ├── Auth middleware             │
│  ├── Rate limiting               │
│  ├── /api/chat endpoint          │
│  └── /health endpoint            │
│         ↓                        │
│  Ollama (localhost:11434)        │
│         ↓                        │
│  Qwen 14B in VRAM                │
└──────────────────────────────────┘
```

---

## Stack Decision (TBD)

Options being considered:

| Option | Pros | Cons |
|--------|------|------|
| **FastAPI (Python)** | Minimal boilerplate, async, already have Python on instance | Another language if you're Java-first |
| **Spring Boot (Java)** | Familiar, production patterns, good auth libraries | Heavy for a proxy server |
| **Express (Node)** | Lightweight, fast to write | Less familiar |

---

## Planned Endpoints

```
POST /api/chat          ← proxies to Ollama /api/chat
GET  /api/models        ← lists available models
GET  /health            ← liveness check
```

---

## Auth Strategy (TBD)

- API key (simple, one key per device) — good enough for personal use
- JWT — proper login flow, expiry — better if sharing with others

---

## Security Layers

1. Bearer token on every request
2. Ollama stays bound to `localhost` only — not reachable directly
3. Optional: IP whitelist for extra hardening

---

## TODO

- [ ] Choose stack
- [ ] Implement auth middleware
- [ ] Implement `/api/chat` proxy
- [ ] Set up nginx for SSL termination
- [ ] Test from phone
- [ ] Document and push

---

## Related

- [[04-ssh-tunnel.md]] — current method this replaces
- [[Setup — Direct API]] — earlier notes on this approach

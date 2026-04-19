# Deploy Ollama + Pull Model

> Install Ollama on the rented GPU, start the server, and download the model. After this step the model is running and responding to API calls — all on the remote machine.

---

## What Is Ollama

Ollama is a model server. It does three things:

1. **Downloads and manages models** — one command to pull any model from the Ollama library
2. **Loads models into GPU VRAM** — handles quantization, memory management, offloading
3. **Exposes an API** — OpenAI-compatible REST API on port `11434`

You don't talk to the model directly. You talk to Ollama, and Ollama talks to the model.

---

## Architecture

```
Remote Machine (RTX 3090 24GB)
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │              Ollama Server                  │   │
│  │         listening on :11434                 │   │
│  │                                             │   │
│  │   POST /api/generate   ──────────────────┐  │   │
│  │   POST /api/chat                         │  │   │
│  │   GET  /api/tags                         ▼  │   │
│  │                                  ┌──────────┤   │
│  │                                  │  Model   │   │
│  └──────────────────────────────────┤  Loaded  │   │
│                                     │  in VRAM │   │
│  GPU VRAM (24GB)                    │          │   │
│  ┌──────────────────────────────┐   │ Qwen 14B │   │
│  │ Qwen 2.5 Coder 14B Q4_K_M   │   │ ~9GB     │   │
│  │ ~9GB loaded                  │◄──┘          │   │
│  └──────────────────────────────┘   └──────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
          ▲
          │  port 11434 (localhost only — not public)
          │
    Only reachable via SSH tunnel from your PC
```

---

## Step 1 — Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

This script:
- Detects Linux + NVIDIA GPU
- Downloads the Ollama binary to `/usr/local/bin/ollama`
- Installs the systemd service

**Verify installation:**
```bash
ollama --version
# ollama version 0.21.0
```

> Note: You may see `Warning: could not connect to a running Ollama instance` — that's fine.
> The binary is installed but the server isn't started yet.

---

## Step 2 — Start the Ollama Server

```bash
nohup ollama serve > /var/log/ollama.log 2>&1 &
```

- `nohup` — keeps the server running after you disconnect
- `ollama serve` — starts the API server on port 11434
- `> /var/log/ollama.log 2>&1` — logs to file
- `&` — runs in background

**Verify it's running:**
```bash
ollama list
# NAME    ID    SIZE    MODIFIED
# (empty — no models yet, but no error means server is up)
```

---

## Step 3 — Pull the Model

```bash
nohup ollama pull qwen2.5-coder:14b > /var/log/ollama-pull.log 2>&1 &
```

This downloads **Qwen 2.5 Coder 14B** at Q4_K_M quantization — ~9GB.

**Monitor progress:**
```bash
tail -f /var/log/ollama-pull.log
```

Expected output while downloading:
```
pulling manifest
pulling 6e4c57a8b2d5... 12% ▕████             ▏ 1.1 GB/9.0 GB  45 MB/s  2m45s
```

Expected output when complete:
```
pulling manifest
pulling 6e4c57a8b2d5... 100% ▕████████████████▏ 9.0 GB
verifying sha256 digest
writing manifest
success
```

**Verify model is ready:**
```bash
ollama list
# NAME                    ID              SIZE      MODIFIED
# qwen2.5-coder:14b       a7e7cf1b8b4c    9.0 GB    1 minute ago
```

---

## Why Qwen 2.5 Coder 14B

| Property | Value |
|----------|-------|
| Parameters | 14 billion |
| Quantization | Q4_K_M (~93% of full quality) |
| VRAM needed | ~9GB |
| VRAM available | 24GB (RTX 3090) |
| Headroom | ~15GB (context headroom, no spillover risk) |
| Speed | ~63-73 tok/s on RTX 3090 (vs ~15 tok/s for 32B) |
| License | Apache 2.0 (fully open) |
| Benchmark | Strong on HumanEval and LiveCodeBench for its size |

We evaluated 32B first — it fits in 24GB at Q4_K_M and the output quality is marginally better. But 14B runs 4-5x faster on the same GPU, costs the same per hour, and handles all real coding tasks without meaningful quality loss. See [ADR-002](../docs/adr-002-32b-vs-14b-model-selection.md) for the full comparison.

---

## Step 4 — Quick Smoke Test

Once the model is downloaded, run a quick test directly on the remote machine:

```bash
ollama run qwen2.5-coder:14b "Write a Java method to check if a string is a palindrome"
```

You should see the model stream a response. Type `/bye` to exit.

**Check GPU is being used:**
```bash
nvidia-smi
```

Look for:
```
| Processes:                                                              |
|  GPU   GI   CI        PID   Type   Process name            GPU Memory  |
|        ID   ID                                             Usage       |
|========================================================================|
|    0   N/A  N/A     12345      C   /usr/local/bin/ollama     9500MiB  |
```

~9-10GB used = model is in VRAM = GPU inference ✅

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `command not found: ollama` | Install didn't complete. Re-run the curl install command. |
| `ollama list` hangs | Server isn't running. Run `nohup ollama serve > /var/log/ollama.log 2>&1 &` |
| Pull stuck at 0% | Network issue on the instance. Try `ollama pull qwen2.5-coder:14b` without nohup to see the error directly. |
| `error: model requires more system memory` | VRAM full. Run `nvidia-smi` to check. Kill other processes if any. |
| Model loads but runs slow (<5 tok/s) | Model is spilling to CPU RAM. Check VRAM usage — try 14B instead. |

---

## Instance State After This Step

```
Remote Machine
├── /usr/local/bin/ollama          ← Ollama binary
├── /var/log/ollama.log            ← Server logs
├── /var/log/ollama-pull.log       ← Download logs
└── ~/.ollama/models/              ← Downloaded models (~9GB)
    └── qwen2.5-coder:14b
```

---

## Next

→ [[04-ssh-tunnel.md]] — connect your local machine to this running model

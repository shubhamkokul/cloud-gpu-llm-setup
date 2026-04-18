# Connect via SSH Tunnel

> Forward the remote Ollama port to your local machine. After this step, tools on your PC talk to `localhost:11434` — they have no idea the model is running 500 miles away on a rented GPU.

---

## How It Works

```
Your Local Machine                    Remote GPU (Vast.ai)
┌──────────────────────────┐          ┌──────────────────────────┐
│                          │          │                          │
│  curl / aider / Cline    │          │  Ollama Server           │
│  http://localhost:11434  │          │  localhost:11434         │
│           │              │          │         ▲                │
│           ▼              │          │         │                │
│  ┌─────────────────┐     │          │         │                │
│  │   SSH Tunnel    │─────┼──────────┼─────────┘                │
│  │  -L 11434:      │     │ encrypted│                          │
│  │  localhost:     │     │   SSH    │  Model in VRAM           │
│  │  11434          │     │          │  Qwen 2.5 Coder 32B      │
│  └─────────────────┘     │          │  ~20GB / 24GB used       │
│                          │          │                          │
└──────────────────────────┘          └──────────────────────────┘

From your PC's perspective: model is at localhost:11434
From the internet's perspective: nothing is exposed — SSH only
```

### Why This Is Secure

- Ollama on the remote machine listens on `localhost` only — not reachable from the internet
- The only open port on the remote machine is SSH (22 / mapped port)
- All traffic goes through an encrypted SSH connection
- No API keys, no nginx, no firewall rules needed

---

## Option A — Use the Script (Recommended)

```bash
# From the project root:
bash scripts/tunnel.sh
```

Output:
```
================================================
  Ollama SSH Tunnel
================================================
  Remote : 209.146.116.50:36764
  Tunnel : localhost:11434 → remote:11434
  Key    : ~/.ssh/vastai-key
------------------------------------------------
  Model API: http://localhost:11434
  Ctrl+C to disconnect
================================================
```

Terminal will hang — that's correct. The tunnel is active as long as this terminal is open.

---

## Option B — Run Manually

```bash
ssh -N \
    -L 11434:localhost:11434 \
    -p 36764 \
    root@209.146.116.50 \
    -i ~/.ssh/vastai-key \
    -o ServerAliveInterval=30
```

- `-N` — no shell, just forward ports
- `-L 11434:localhost:11434` — forward local 11434 to remote 11434
- `-o ServerAliveInterval=30` — send keepalive every 30s to prevent timeout

---

## Verify the Tunnel Works

Open a **new terminal** (keep the tunnel terminal open) and run:

```bash
# List available models:
curl http://localhost:11434/api/tags
```

Expected response:
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:14b",
      "size": 18500000000,
      ...
    }
  ]
}
```

---

## Test Inference

```bash
curl http://localhost:11434/api/generate \
  -d '{
    "model": "qwen2.5-coder:14b",
    "prompt": "Write a Java method to check if a number is prime",
    "stream": false
  }'
```

You should get a JSON response with the generated code. First call takes 10-20 seconds (model loading into VRAM). Subsequent calls are fast.

---

## How aider Connects (No Extra Config Needed)

This is the key insight — **aider doesn't need to know about the tunnel.**

When you run:
```bash
aider --model ollama_chat/qwen2.5-coder:14b
```

aider sees `ollama_chat/` prefix and automatically hits `http://localhost:11434`. That's the exact port the SSH tunnel is forwarding. The full chain:

```
aider → localhost:11434 → SSH tunnel → remote GPU:11434 → Ollama → Qwen 32B
```

From aider's perspective: model is local.
From reality: model is running on a rented RTX 3090 in California.

Verify the chain is live before starting aider:
```bash
curl http://localhost:11434/api/tags
# Should return: {"models":[{"name":"qwen2.5-coder:14b",...}]}
```

If that returns the model — aider will work.

---

## Connect Your Tools

> See [ADR-001](adr-001-cline-vs-aider.md) for why Cline is recommended over aider.

### Cline (VS Code) ⭐ Recommended

```
1. Open VS Code
2. Extensions → search "Cline" → Install
3. Cline sidebar → Settings (gear icon):
   - API Provider: Ollama
   - Base URL: http://localhost:11434
   - Model: qwen2.5-coder:14b
4. Open any project folder
5. Ask Cline to make a change — it reads files, shows diffs, asks approval
```

Cline connects to `localhost:11434` — same port the tunnel forwards. It has no idea the model is remote. The full chain:

```
Cline → localhost:11434 → SSH tunnel → remote GPU:11434 → Ollama → Qwen 14B
```

### aider (CLI — secondary option)

```bash
pip install aider-chat

cd ~/your-project
aider --model ollama_chat/qwen2.5-coder:14b --no-auto-commits
```

Use aider for headless/scripted workflows. Use Cline for interactive development.

### Continue (VS Code autocomplete)

```json
// ~/.continue/config.json
{
  "models": [{
    "title": "Qwen 32B (Cloud GPU)",
    "provider": "ollama",
    "model": "qwen2.5-coder:14b",
    "apiBase": "http://localhost:11434"
  }]
}
```

### Raw Python

```python
import requests

response = requests.post(
    "http://localhost:11434/api/generate",
    json={
        "model": "qwen2.5-coder:14b",
        "prompt": "Write a binary search in Java",
        "stream": False
    }
)
print(response.json()["response"])
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `curl: Connection refused` on localhost | Tunnel terminal closed. Re-run `bash scripts/tunnel.sh`. |
| Tunnel drops after a few minutes | Add `-o ServerAliveInterval=30 -o ServerAliveCountMax=3` — already in the script. |
| `model not found` error | Model still downloading on remote. Check with `ssh ... "ollama list"`. |
| First request very slow (30-60s) | Normal — model loading into VRAM. Second request will be fast. |
| `ssh: connect to host ... port 36764: Connection refused` | Instance was destroyed or IP changed. Check Vast.ai dashboard for new connection details. |

---

## Important: Update Connection Details When You Rent a New Instance

The IP and port in `scripts/tunnel.sh` are specific to this rental session. When you destroy and re-rent:

```bash
# Edit scripts/tunnel.sh:
SSH_HOST="<new-ip>"
SSH_PORT="<new-port>"
```

Or pass them inline:
```bash
SSH_HOST=203.0.113.99 SSH_PORT=41234 bash scripts/tunnel.sh
```

---

## Next

→ [[05-test-benchmark.md]] — run the test suite and measure tokens/sec

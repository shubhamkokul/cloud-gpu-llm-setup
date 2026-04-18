# Cloud GPU LLM Setup

Run open-source large language models on rented cloud GPUs — no OpenAI, no Anthropic, full control.

## What This Is

A step-by-step, hands-on guide to:
1. Renting a GPU on Vast.ai
2. Deploying Ollama on the rented machine
3. Running Qwen 2.5 Coder 32B (open-source, Apache 2.0 licensed)
4. Connecting from your local machine via SSH tunnel
5. Benchmarking and knowing when to stop billing

Everything was executed and documented as it happened — not a tutorial written after the fact.

## Stack

| Layer | Choice |
|-------|--------|
| GPU Rental | Vast.ai |
| Model Server | Ollama |
| Model | Qwen 2.5 Coder 32B Q4_K_M |
| GPU | RTX 3090 24GB (~$0.15/hr) |
| Connection | SSH Tunnel |

## Docs

- [01 — Machine Selection](docs/01-machine-selection.md)
- [02 — SSH Setup](docs/02-ssh-setup.md)
- [03 — Deploy Ollama](docs/03-deploy-ollama.md) *(in progress)*
- [04 — Connect via SSH Tunnel](docs/04-ssh-tunnel.md) *(in progress)*
- [05 — Test & Benchmark](docs/05-test-benchmark.md) *(in progress)*

## Cost

About $0.15/hr on a 3090. A $10 deposit covers ~65 hours of runtime.

## Prerequisites

- Vast.ai account
- SSH client (OpenSSH)
- curl
- Python 3.x + pip (for aider, optional)

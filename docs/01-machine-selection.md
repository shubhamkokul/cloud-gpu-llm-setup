# Machine Selection

> How we picked the GPU and why. Documented so the reasoning is reproducible.

---

## Goal

Run an open-source LLM on a rented cloud GPU. No OpenAI. No Anthropic. Full control over the model.

Initial target was Qwen 2.5 Coder **32B** — we sized the GPU around it. After evaluation we settled on **14B** for unit economics. The 24GB GPU selection holds either way. See [ADR-002](adr-002-32b-vs-14b-model-selection.md) for why.

---

## VRAM Is the Constraint

The model dictates the hardware requirement, not the other way around.

```
Qwen 2.5 Coder 32B at Q4_K_M quantization ≈ 20GB VRAM needed
```

This immediately rules out any GPU with less than 24GB VRAM.

---

## Options We Looked At (Vast.ai, April 2026)

| GPU | VRAM | Price/hr | Verdict |
|-----|------|----------|---------|
| RTX 4080S | 16GB | $0.155 | ❌ Not enough VRAM for 32B |
| RTX 5080 | 16GB | $0.156 | ❌ Not enough VRAM. Also 96.9% reliability |
| RTX 5090 | 32GB | $0.514 | ✅ Works but 3x more expensive than needed |
| **RTX 3090** | **24GB** | **$0.146** | **✅ Picked — best value** |

---

## Why RTX 3090

- **24GB VRAM** — sized to fit Qwen 32B at Q4_K_M with ~4GB headroom; more than enough for 14B (~9GB VRAM)
- **$0.146/hr** — cheapest 24GB option available
- **99.42% reliability** — above our 99% threshold
- **7 month max duration** — stable host, not a fly-by-night listing
- **nvme storage** — fast model loading

The CPU (Xeon E5-2695 v4) is older but irrelevant — LLM inference is GPU-bound.
PCIe 3.0 instead of 4.0 is a minor bandwidth difference, not a bottleneck for inference.

---

## Instance Details

| Field | Value |
|-------|-------|
| Machine ID | m:43503 |
| Host | 155125 |
| Location | California, US |
| GPU | 1x RTX 3090 24GB |
| CPU | Xeon E5-2695 v4 (9.0/72 CPU) |
| RAM | 32/258 GB |
| Storage | 96.3 GB nvme |
| Price | $0.146/hr |
| Reliability | 99.42% |
| Template | NVIDIA CUDA |

---

## Cost Estimate for This Session

```
Setup + model download:    ~1 hour   → $0.15
Testing + benchmarking:    ~1 hour   → $0.15
Buffer:                    ~1 hour   → $0.15
                                       ------
Total estimated:                       ~$0.45
```

With $10 loaded, this leaves ~$9.55 for future sessions.

---

## What Went Wrong With This Instance (Lessons Learned)

This instance had three problems not visible from the listing:

| Problem | Impact | How to Avoid |
|---------|--------|--------------|
| Only 32GB disk allocated (requested 50GB) | 32B model = 19GB, leaves <8GB headroom. Any `ollama run` command tries to pull updates and fills disk instantly. With 14B (~9GB) there's more breathing room, but still verify first. | Verify disk with `df -h /` immediately after connecting, before pulling model |
| SSH daemon crashes when Ollama is restarted | Can't restart Ollama without losing SSH access | Use `nohup` properly, never kill Ollama in an active SSH session. Or use tmux. |
| CUDA libraries missing after fresh Ollama install | Model ran on CPU (0% GPU) for hours | Always verify GPU detection after install: `grep 'inference compute' /var/log/ollama.log` |

### Pre-Flight Checklist (Run Before Pulling Any Model)

```bash
# 1. Verify disk space — need at least 15GB free for the 14B model
df -h /
# Must show: Avail > 15G

# 2. Verify GPU is detected by Ollama
ollama --version
nohup ollama serve > /var/log/ollama.log 2>&1 &
sleep 5
grep 'inference compute' /var/log/ollama.log
# Must show: library=CUDA ... name="NVIDIA GeForce RTX 3090"

# 3. Only pull model after both checks pass
ollama pull qwen2.5-coder:14b
```

### Never Use `ollama run` for Inference

`ollama run` checks for model updates every time and will attempt a re-download if the manifest changed. On a tight disk, this kills you.

Always use the API directly:
```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:14b","prompt":"your prompt","stream":true}'
```

---

## Next

→ [[02-ssh-setup.md]]

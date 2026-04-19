# ADR-002: Qwen 2.5 Coder 14B over 32B as the primary model

**Status:** Accepted  
**Date:** 2026-04-19

---

## Context

The initial plan was to run Qwen 2.5 Coder **32B** — the largest open-source coding model that fits in a single 24GB GPU. It ranks above GPT-4o on HumanEval and LiveCodeBench. The RTX 3090 was specifically selected because 32B at Q4_K_M quantization needs ~20GB VRAM, leaving just ~4GB headroom.

After getting the setup running, the question became: does 32B quality justify the tradeoffs in speed and economics for the actual work we're doing?

---

## Decision

**Use Qwen 2.5 Coder 14B Q4_K_M as the primary model.**

---

## Comparison

| Property | Qwen 2.5 Coder 32B | Qwen 2.5 Coder 14B |
|----------|-------------------|-------------------|
| Parameters | 32 billion | 14 billion |
| Quantization | Q4_K_M | Q4_K_M |
| VRAM needed | ~20GB | ~9GB |
| VRAM headroom (on 3090 24GB) | ~4GB | ~15GB |
| Speed (RTX 3090) | ~15 tok/s | ~63–73 tok/s |
| GPU cost/hr (Vast.ai) | $0.146 | $0.146 (same GPU) |
| Model download size | ~18.5GB | ~9GB |
| Disk risk | High — tight on 32GB disk | Low — comfortable |
| Cold start (first load) | ~15–20s | ~5s |

---

## Why 14B Suffices

**1. Speed is the dominant variable for interactive use**  
At 15 tok/s, a 300-token response from 32B takes 20 seconds. At 63–73 tok/s, 14B returns the same response in ~4–5 seconds. When you're iterating with Cline — reading diffs, approving changes, asking follow-ups — that 4x speed difference shapes the entire development experience. 14B feels immediate. 32B feels like waiting.

**2. Quality difference doesn't show up in practice**  
32B has a measurable benchmark advantage on HumanEval and LiveCodeBench. In real use — writing Java services, React components, fixing bugs, refactoring — 14B produces correct, well-structured code. The marginal quality gain from 32B doesn't translate to fewer revisions or better output for the tasks we actually run.

**3. Unit economics favor 14B**  
The GPU cost is identical — we're paying for the machine, not the model size. But 14B produces 4–5x more output per dollar of compute time:

```
32B: 15 tok/s × 3600s = 54,000 tokens/hr @ $0.146 → ~$0.0027 per 1K tokens
14B: 68 tok/s × 3600s = 244,800 tokens/hr @ $0.146 → ~$0.0006 per 1K tokens
```

Same GPU, same cost, 4.5x more throughput. For a personal dev setup where you're paying per hour, throughput per dollar is the right metric.

**4. Operational stability**  
32B at ~20GB VRAM leaves only 4GB headroom. Any spike in context length or Ollama overhead risks spillover to CPU RAM, dropping speed to <5 tok/s. 14B at ~9GB leaves 15GB free — no risk of spillover, stable performance across long sessions.

**5. Disk footprint**  
32B = 18.5GB on disk. On a Vast.ai instance with 32GB allocated, that leaves ~8GB before `ollama run` update checks fill the disk. 14B = 9GB — half the disk footprint, no operational landmines.

---

## Why We Still Evaluated 32B First

32B was the right starting hypothesis. It's the strongest open coding model that fits in a single consumer GPU. If the quality gap had been visible in practice, or if the use case were batch processing (where speed matters less), 32B would be the right call.

Testing it directly was the only way to know that 14B was good enough. The answer isn't obvious from benchmarks alone — it required running both on real tasks.

---

## Consequences

- All tooling (Cline, aider, Continue) is configured against `qwen2.5-coder:14b`
- The RTX 3090 24GB remains the right GPU — 14B leaves room to grow context or run experiments
- 32B remains a documented option if use cases shift (batch inference, long-context tasks where quality matters more than speed)
- See [05 — Test & Benchmark](05-test-benchmark.md) for actual speed measurements on the RTX 3090

# Test & Benchmark

> Verify the setup works end-to-end. Run inference tests, measure speed, connect real tools.

---

## Environment

| Component | Value |
|-----------|-------|
| GPU | RTX 3090 24GB |
| Model | Qwen 2.5 Coder 14B Q4_K_M |
| VRAM used | 15,000 MiB / 24,576 MiB |
| GPU layers | 49/49 (100% GPU — no CPU spillover) |
| Connection | SSH Tunnel → localhost:11434 |

---

## Test 1 — Model Loaded in GPU

Before running any tests, verify the model is fully in VRAM:

```bash
nvidia-smi | grep MiB
# Expected: ~15000MiB / 24576MiB used

grep 'offloaded' /var/log/ollama.log | tail -2
# Expected: offloaded 49/49 layers to GPU
```

If layers < total (e.g. 49/65), the model is spilling to CPU RAM. See troubleshooting below.

---

## Test 2 — Basic Inference via API

```bash
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen2.5-coder:14b","messages":[{"role":"user","content":"say hi"}],"stream":false}'
```

**Result:**
```json
{"message":{"content":"Hello! How can I assist you today?"},"eval_count":10,"eval_duration":135713613}
```

**Speed: 73 tok/s** on a short response (model already loaded, minimal context).

---

## Test 3 — Real Code Generation

```bash
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen2.5-coder:14b","messages":[{"role":"user","content":"Write a Java thread-safe LRU cache with O(1) get and put. Code only."}],"stream":false}'
```

**Result:**
```java
import java.util.LinkedHashMap;
import java.util.Map;

public class LRUCache<K, V> {
    private final int capacity;
    private final Map<K, V> cache;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        this.cache = new LinkedHashMap<>(capacity, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
                return size() > LRUCache.this.capacity;
            }
        };
    }

    public synchronized V get(K key) {
        return cache.getOrDefault(key, null);
    }

    public synchronized void put(K key, V value) {
        cache.put(key, value);
    }
}
```

**Speed: 63.5 tok/s** — 350 tokens in 5.5 seconds.

Code quality: correct. Thread safety via `synchronized`. Uses `LinkedHashMap` with access-order for O(1) LRU eviction.

---

## Test 4 — aider (CLI Coding Agent)

Connected aider to the remote model via SSH tunnel.

**Config (`~/.aider.conf.yml`):**
```yaml
model: ollama_chat/qwen2.5-coder:14b
no-auto-commits: true
```

**Command:**
```bash
aider --message "create a simple Java program to reverse a string"
```

**Result — `reverse_string.java` created:**
```java
public class ReverseString {
    public static void main(String[] args) {
        String original = "Hello";
        String reversed = new StringBuilder(original).reverse().toString();
        System.out.println("Original: " + original);
        System.out.println("Reversed: " + reversed);
    }
}
```

aider read the repo context, generated the file, wrote it to disk, and committed it to git — all via the remote model over the SSH tunnel.

---

## Speed Summary

| Test | Tokens | Time | Tok/s |
|------|--------|------|-------|
| "say hi" (warm) | 10 | 0.14s | 73 |
| LRU Cache (warm) | 350 | 5.5s | 63.5 |
| First load (cold) | — | ~5s | — |

**~63-73 tok/s** is the expected range for Qwen 2.5 Coder 14B on an RTX 3090 with full GPU offload.

---

## Troubleshooting

### Model running on CPU (slow — <5 tok/s)

Check GPU layers:
```bash
grep 'offloaded' /var/log/ollama.log | tail -2
# Bad:  offloaded 49/65 layers to GPU  ← partial CPU spillover
# Good: offloaded 49/49 layers to GPU  ← full GPU
```

If partial: model is too large for available VRAM. Either:
- Use a smaller model (`qwen2.5-coder:14b` instead of `32b`)
- Reduce context length: `OLLAMA_CONTEXT_LENGTH=2048 ollama serve`

### CUDA not detected after fresh Ollama install

```bash
grep 'inference compute' /var/log/ollama.log
# Should show: library=CUDA ... description="NVIDIA GeForce RTX 3090"
```

If missing, CUDA libs weren't found during install. Fix:
```bash
echo '/usr/local/cuda/lib64' > /etc/ld.so.conf.d/cuda.conf
ldconfig
curl -fsSL https://ollama.com/install.sh | sh
```

Verify fix:
```bash
ls /usr/local/lib/ollama/
# Should show: cuda_v12  cuda_v13  vulkan  (not just vulkan)
```

### `ollama run` fills disk

Never use `ollama run` for inference — it checks for model updates and may trigger a re-download. Use the API directly:
```bash
# Use this instead:
curl http://localhost:11434/api/chat \
  -d '{"model":"qwen2.5-coder:14b","messages":[{"role":"user","content":"..."}],"stream":false}'
```

### Disk full after model download

```bash
# Check for partial downloads:
du -sh /root/.ollama/models/blobs/*-partial* 2>/dev/null

# Delete them:
rm -f /root/.ollama/models/blobs/*-partial*

# Verify space freed:
df -h /
```

---

## Next Steps

- [[Setup — SSH Tunnel]] → connect from your local machine
- Connect VS Code via Cline extension (same `localhost:11434` endpoint)
- Connect Continue extension for inline autocomplete

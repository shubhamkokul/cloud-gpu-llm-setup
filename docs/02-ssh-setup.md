# SSH Setup

> Generate an SSH key pair, upload the public key to Vast.ai, and verify you can connect to the rented instance.

---

## Why a Dedicated Key

We generate a new key specifically for Vast.ai rather than reusing an existing one.
One key per service = if a key is compromised, you revoke one key without affecting other servers.

---

## Step 1 — Generate Key Pair

```bash
ssh-keygen -t ed25519 -C "your-email@gmail.com" -f ~/.ssh/vastai-key
```

- `-t ed25519` — modern algorithm, smaller and more secure than RSA
- `-f ~/.ssh/vastai-key` — saves as `vastai-key` (private) and `vastai-key.pub` (public)
- Set a passphrase when prompted (optional but recommended)

**Output:**
```
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Your identification has been saved in /home/user/.ssh/vastai-key
Your public key has been saved in /home/user/.ssh/vastai-key.pub
```

---

## Step 2 — View Public Key

```bash
cat ~/.ssh/vastai-key.pub
```

Output looks like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@gmail.com
```

Copy the entire line.

---

## Step 3 — Add to Vast.ai

```
1. Vast.ai → Account (top right) → SSH Keys
2. Click "Add SSH Key"
3. Paste the public key
4. Save
```

> The **public key** (.pub) is safe to share — it's designed to be public.
> The **private key** (vastai-key) never leaves your machine. Never commit it to git.

---

## Step 4 — Connect to Instance

Once your instance is Running, Vast.ai shows an SSH command in the dashboard:

```bash
ssh -p <port> root@<ip-address> -i ~/.ssh/vastai-key
```

Example:
```bash
ssh -p 34567 root@203.0.113.42 -i ~/.ssh/vastai-key
```

**Expected output:**
```
Welcome to Ubuntu 22.04...
root@container:~#
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Permission denied (publickey)` | Public key not on Vast.ai. Re-check Account → SSH Keys. |
| `Connection refused` | Instance still starting. Wait 1-2 min, try again. |
| `Connection timed out` | Wrong IP or port. Copy SSH command directly from Vast.ai dashboard. |
| Passphrase prompt every time | Run `ssh-add ~/.ssh/vastai-key` to add key to agent for the session. |

---

## Next

→ [[03-deploy-ollama.md]]

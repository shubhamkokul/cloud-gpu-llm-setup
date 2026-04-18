#!/bin/bash
# tunnel.sh — Forward remote Ollama port to localhost
#
# Usage:
#   SSH_HOST=1.2.3.4 SSH_PORT=36764 ./scripts/tunnel.sh
#
# Get SSH_HOST and SSH_PORT from your Vast.ai dashboard after renting an instance.
# After running, Ollama is available at http://localhost:11434
# from any tool on your local machine (aider, Cline, curl, etc.)
#
# Keep this terminal open while using the model.
# Ctrl+C to close the tunnel.

SSH_KEY="${SSH_KEY:-$HOME/.ssh/vastai-key}"
SSH_HOST="${SSH_HOST:?Set SSH_HOST to your Vast.ai instance IP. Example: SSH_HOST=1.2.3.4 SSH_PORT=36764 ./scripts/tunnel.sh}"
SSH_PORT="${SSH_PORT:?Set SSH_PORT to your Vast.ai SSH port. Example: SSH_HOST=1.2.3.4 SSH_PORT=36764 ./scripts/tunnel.sh}"
LOCAL_PORT="${LOCAL_PORT:-11434}"
REMOTE_PORT="${REMOTE_PORT:-11434}"

echo ""
echo "================================================"
echo "  Ollama SSH Tunnel"
echo "================================================"
echo "  Remote : $SSH_HOST:$SSH_PORT"
echo "  Tunnel : localhost:$LOCAL_PORT → remote:$REMOTE_PORT"
echo "  Key    : $SSH_KEY"
echo "------------------------------------------------"
echo "  Model API: http://localhost:$LOCAL_PORT"
echo "  Ctrl+C to disconnect"
echo "================================================"
echo ""

ssh -N \
    -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} \
    -p ${SSH_PORT} \
    root@${SSH_HOST} \
    -i ${SSH_KEY} \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3

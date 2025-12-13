#!/bin/bash
set -e

echo "=========================================="
echo "Starting Kohya_ss Template v4"
echo "=========================================="

# 初回またはバージョン更新時に同期
if [ ! -d "/workspace/kohya_ss" ] || [ ! -f "/workspace/kohya_ss/.synced" ]; then
    echo "Syncing kohya_ss to /workspace..."
    rsync -rlptDu /kohya_ss/ /workspace/kohya_ss/
    touch /workspace/kohya_ss/.synced
    echo "Sync complete!"
else
    echo "Kohya_ss already synced, skipping..."
fi

# JupyterLab起動
echo "Starting JupyterLab on port 8888..."
jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.token="" \
    --ServerApp.password="" \
    --ServerApp.allow_origin="*" \
    --ServerApp.root_dir=/ \
    > /workspace/logs/jupyter.log 2>&1 &

# JupyterLabの起動を待つ
echo "Waiting for JupyterLab to start..."
sleep 10

# JupyterLabが起動しているか確認
if pgrep -f "jupyter-lab" > /dev/null; then
    echo "✓ JupyterLab started successfully"
else
    echo "✗ JupyterLab failed to start, check /workspace/logs/jupyter.log"
fi

# Kohya_ss起動
echo "Starting Kohya_ss on port 3013..."
cd /workspace/kohya_ss
bash gui.sh --listen 0.0.0.0 --server_port 3013 2>&1 | tee /workspace/logs/kohya_ss.log
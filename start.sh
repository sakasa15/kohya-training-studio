#!/bin/bash
set -e

echo "=========================================="
echo "Starting Kohya_ss Template v6"
echo "=========================================="

# 環境変数（デフォルト値）
ENABLE_JUPYTER=${ENABLE_JUPYTER:-1}
JUPYTER_PORT=${JUPYTER_PORT:-8888}
KOHYA_PORT=${KOHYA_PORT:-3013}

SRC_DIR="/opt/kohya_ss"
DST_DIR="/workspace/kohya_ss"
LOG_DIR="/workspace/logs"

# ログディレクトリ作成
mkdir -p "$LOG_DIR"

# --- Kohya_ss 同期 ---
if [ ! -d "$DST_DIR" ] || [ ! -f "$DST_DIR/.synced" ]; then
    echo "Syncing kohya_ss to /workspace..."
    rsync -rlptDu --info=progress2 "$SRC_DIR/" "$DST_DIR/"
    touch "$DST_DIR/.synced"
    echo "Sync complete!"
else
    echo "Kohya_ss already synced, skipping..."
fi

cd "$DST_DIR"

# --- venv 作成・有効化 ---
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv --system-site-packages venv
fi

source venv/bin/activate

# --- pip 更新 ---
pip install --upgrade pip --quiet

# --- 依存関係インストール（初回のみ） ---
if [ ! -f ".deps_installed" ]; then
    echo "Installing Kohya_ss dependencies..."
    
    # requirements.txt があるか確認
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    elif [ -f "requirements_runpod.txt" ]; then
        pip install -r requirements_runpod.txt
    else
        echo "Warning: No requirements file found"
    fi
    
    touch .deps_installed
    echo "Dependencies installed!"
else
    echo "Dependencies already installed, skipping..."
fi

# --- JupyterLab 起動 ---
if [ "$ENABLE_JUPYTER" = "1" ]; then
    echo "Starting JupyterLab on port $JUPYTER_PORT..."
    
    # JupyterLabがvenvにあるか確認
    if ! command -v jupyter &> /dev/null; then
        echo "Installing JupyterLab in venv..."
        pip install jupyterlab notebook ipywidgets
    fi
    
    jupyter lab \
        --ip=0.0.0.0 \
        --port="$JUPYTER_PORT" \
        --no-browser \
        --allow-root \
        --ServerApp.token="" \
        --ServerApp.password="" \
        --ServerApp.allow_origin="*" \
        --ServerApp.root_dir=/workspace \
        > "$LOG_DIR/jupyter.log" 2>&1 &
    
    JUPYTER_PID=$!
    echo "JupyterLab started (PID: $JUPYTER_PID)"
    
    sleep 5
    
    if ps -p $JUPYTER_PID > /dev/null; then
        echo "✓ JupyterLab is running"
    else
        echo "✗ JupyterLab failed to start, check $LOG_DIR/jupyter.log"
    fi
else
    echo "JupyterLab disabled (set ENABLE_JUPYTER=1 to enable)"
fi

# --- Kohya_ss 起動 ---
echo "Starting Kohya_ss on port $KOHYA_PORT..."
exec bash gui.sh \
    --listen 0.0.0.0 \
    --server_port "$KOHYA_PORT" \
    2>&1 | tee "$LOG_DIR/kohya_ss.log"
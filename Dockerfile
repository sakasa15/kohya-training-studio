FROM runpod/pytorch:2.2.0-py3.10-cuda12.1.1-devel-ubuntu22.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    TEMPLATE_VERSION=v40

WORKDIR /

# 必要なパッケージをインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-tk \
        python3-venv \
        git \
        wget \
        curl \
        rsync \
        jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Pythonパッケージをインストール
RUN pip3 install --no-cache-dir \
    jupyterlab \
    notebook \
    ipywidgets \
    "huggingface-hub>=0.23.2,<1.0" \
    requests \
    tqdm

# kohya_ss をクローン（サブモジュール含む）
RUN git clone --depth 1 --branch v25.0.3 https://github.com/bmaltais/kohya_ss.git /opt/kohya_ss && \
    cd /opt/kohya_ss && \
    git submodule update --init --recursive

# スクリプトを配置
COPY scripts/model_downloader.py /opt/scripts/model_downloader.py
RUN chmod +x /opt/scripts/model_downloader.py

# ログ用ディレクトリ作成
RUN mkdir -p /workspace/logs

# スタートスクリプトを配置
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3013 8888
ENTRYPOINT ["/start.sh"]

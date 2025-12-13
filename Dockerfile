FROM runpod/pytorch:2.2.0-py3.10-cuda12.1.1-devel-ubuntu22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

WORKDIR /

# 必要なパッケージ
RUN apt-get update && apt-get install -y \
    python3-tk \
    python3-venv \
    git \
    wget \
    curl \
    rsync \
    jq \
    && rm -rf /var/lib/apt/lists/*

# JupyterLab（システムにインストール）
RUN pip3 install --no-cache-dir \
    jupyterlab \
    notebook \
    ipywidgets

# Kohya_ssをクローン（/opt に配置）
RUN git clone https://github.com/bmaltais/kohya_ss.git /opt/kohya_ss && \
    test -d /opt/kohya_ss

# ログディレクトリ
RUN mkdir -p /workspace/logs

# 起動スクリプト
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3013 8888

ENTRYPOINT ["/start.sh"]

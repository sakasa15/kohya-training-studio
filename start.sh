#!/bin/bash
# v40c
set -e

echo "=========================================="
echo "Kohya RunPod Template ${TEMPLATE_VERSION}"
echo "=========================================="

# 環境変数（デフォルト値）
ENABLE_JUPYTER=${ENABLE_JUPYTER:-1}
JUPYTER_PORT=${JUPYTER_PORT:-8888}
KOHYA_PORT=${KOHYA_PORT:-3013}

SRC_DIR="/opt/kohya_ss"
DST_DIR="/workspace/kohya_ss"
LOG_DIR="/workspace/logs"

mkdir -p "$LOG_DIR"

# ========================================
# ネットワークボリューム確認（堅牢化）
# ========================================
echo "Checking network volume... / ネットワークボリュームを確認中..."

if [ ! -d "/workspace" ]; then
    echo "❌ ERROR: /workspace not found"
    echo "❌ エラー: /workspace が見つかりません"
    echo "Please mount Network Volume to /workspace"
    echo "ネットワークボリュームを /workspace にマウントしてください"
    exit 1
fi

# 応答速度チェック
echo "Testing network volume response... / ボリューム応答速度をテスト中..."
START_TIME=$(date +%s)
ls /workspace > /dev/null 2>&1
END_TIME=$(date +%s)
RESPONSE_TIME=$((END_TIME - START_TIME))

if [ $RESPONSE_TIME -gt 5 ]; then
    echo "⚠️  Warning: Slow network volume response (${RESPONSE_TIME}s)"
    echo "⚠️  警告: ネットワークボリュームの応答が遅い (${RESPONSE_TIME}秒)"
    echo "Waiting for volume to stabilize... / ボリュームの安定化を待っています..."
    sleep 10
fi

echo "✓ Network volume ready (${RESPONSE_TIME}s) / ネットワークボリューム準備完了"

# --- Kohya_ss 同期 ---
if [ ! -d "$DST_DIR" ] || [ ! -f "$DST_DIR/.synced" ]; then
    echo "Syncing kohya_ss to /workspace..."
    rsync -rlptDu --info=progress2 "$SRC_DIR/" "$DST_DIR/"
    
    # サブモジュール確認
    if [ ! -d "$DST_DIR/sd-scripts/.git" ]; then
        echo "Initializing submodules..."
        cd "$DST_DIR"
        git submodule update --init --recursive
    fi
    
    touch "$DST_DIR/.synced"
    echo "Sync complete!"
else
    echo "Kohya_ss already synced, skipping..."
fi

cd "$DST_DIR"

# ========================================
# モデルディレクトリのシンボリックリンク（堅牢化）
# ========================================
echo "Setting up models directory... / モデルディレクトリをセットアップ中..."
SHARED_MODELS="/workspace/models"
MAX_RETRIES=3
RETRY_COUNT=0

# ディレクトリ作成をリトライ
echo "Creating model directories... / モデルディレクトリを作成中..."
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if mkdir -p "$SHARED_MODELS"/{Stable-diffusion,Lora,VAE,embeddings} 2>/dev/null; then
        echo "✓ Models directories created / モデルディレクトリ作成完了"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️  Retry $RETRY_COUNT/$MAX_RETRIES: Creating directories..."
        echo "⚠️  リトライ $RETRY_COUNT/$MAX_RETRIES: ディレクトリを作成中..."
        sleep 3
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ ERROR: Failed to create model directories after $MAX_RETRIES attempts"
    echo "❌ エラー: $MAX_RETRIES 回試行後もモデルディレクトリの作成に失敗"
    echo "Network volume may not be writable / ネットワークボリュームが書き込み不可の可能性"
    exit 1
fi

# 既存のmodelsを削除
if [ -e "$DST_DIR/models" ]; then
    echo "Removing existing models directory/link... / 既存のmodelsディレクトリを削除中..."
    rm -rf "$DST_DIR/models"
fi

# シンボリックリンク作成
echo "Creating symlink... / シンボリックリンクを作成中..."
ln -s "$SHARED_MODELS" "$DST_DIR/models"

# 検証
if [ -L "$DST_DIR/models" ]; then
    echo "✓ Models symlink created successfully / シンボリックリンク作成成功"
    echo "  Link: $DST_DIR/models -> $SHARED_MODELS"
else
    echo "❌ ERROR: Failed to create symlink"
    echo "❌ エラー: シンボリックリンクの作成に失敗"
    exit 1
fi

# --- モデルダウンローダーとノートブックの準備 ---
if [ ! -f "/workspace/scripts/model_downloader.py" ]; then
    echo "📥 Copying model downloader to /workspace/scripts..."
    mkdir -p /workspace/scripts
    cp /opt/scripts/model_downloader.py /workspace/scripts/
fi

# Download_Models.ipynb - 初回のみ作成（ダウンロード履歴を保持）
if [ ! -f "/workspace/Download_Models.ipynb" ]; then
    echo "📝 Creating Download_Models.ipynb..."
    cat << 'NOTEBOOK_EOF' > /workspace/Download_Models.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "header",
   "metadata": {},
   "source": [
    "# 🎨 Kohya_ss Model Downloader\n",
    "\n",
    "**Easy model download for Kohya_ss training**  \n",
    "学習に使用するモデルを簡単にダウンロードできます\n",
    "\n",
    "## 💡 Note / 注意\n",
    "- **This notebook preserves your download history across sessions**  \n",
    "  **このノートブックはセッション間でダウンロード履歴を保持します**\n",
    "- You can see which models you've already downloaded  \n",
    "  既にダウンロードしたモデルを確認できます\n",
    "- To reset: Delete this file and restart Pod  \n",
    "  リセットするには: このファイルを削除してPodを再起動\n",
    "\n",
    "## 📦 How to Use / 使い方\n",
    "1. Select a cell and press **Shift + Enter** to run  \n",
    "   セルを選択して **Shift + Enter** で実行\n",
    "2. Or click the ▶ button at the top  \n",
    "   または上部の ▶ ボタンをクリック\n",
    "\n",
    "---"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "token-header",
   "metadata": {},
   "source": [
    "## 🔑 Hugging Face Token設定 (Flux・SD3.5を使う場合)\n",
    "\n",
    "FluxやSD3.5をダウンロードする場合は、以下のセルにHugging FaceのAccess Tokenを入力して実行してください。\n",
    "SD1.5・SDXLのみ使用する場合はスキップできます。\n",
    "\n",
    "**トークンの取得方法:** https://huggingface.co/settings/tokens"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "set-hf-token",
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "\n",
    "# ここにHugging FaceのAccess Tokenを貼り付けてください\n",
    "# Paste your Hugging Face Access Token here\n",
    "HF_TOKEN = \"\"  # 例: \"hf_xxxxxxxxxxxxxxxxxxxxxxxx\"\n",
    "\n",
    "if HF_TOKEN:\n",
    "    os.environ[\"HF_TOKEN\"] = HF_TOKEN\n",
    "    print(\"✅ HF Token set successfully / HFトークンを設定しました\")\n",
    "    print(\"   Flux and SD3.5 downloads are now enabled\")\n",
    "    print(\"   Flux・SD3.5のダウンロードが可能になりました\")\n",
    "else:\n",
    "    print(\"⚠️  No token set - Flux/SD3.5 will not be available\")\n",
    "    print(\"   トークン未設定 - Flux/SD3.5はダウンロードできません\")\n",
    "    print(\"   SD1.5/SDXL/Anime models are still available\")\n",
    "    print(\"   SD1.5/SDXL/Animeモデルは引き続き使用可能です\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "list-header",
   "metadata": {},
   "source": [
    "## 📋 List Available Models / 利用可能なモデル一覧"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "list-models",
   "metadata": {},
   "outputs": [],
   "source": [
    "!python /workspace/scripts/model_downloader.py list"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "required-header",
   "metadata": {},
   "source": [
    "---\n",
    "## 🔥 Required Models / 必須モデル\n",
    "**Basic models for training / 基本学習用**"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-sd15",
   "metadata": {},
   "outputs": [],
   "source": [
    "# SD 1.5 - Most popular for LoRA training (4.27 GB)\n",
    "# SD 1.5 - LoRA学習の定番 (4.27 GB)\n",
    "!python /workspace/scripts/model_downloader.py download sd15"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-sdxl",
   "metadata": {},
   "outputs": [],
   "source": [
    "# SDXL Base 1.0 - High resolution training (6.94 GB)\n",
    "# SDXL Base 1.0 - 高解像度学習用 (6.94 GB)\n",
    "!python /workspace/scripts/model_downloader.py download sdxl-base"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "recommended-header",
   "metadata": {},
   "source": [
    "---\n",
    "## ⭐ Recommended Models / 推奨モデル\n",
    "**For quality improvement and specialized use / 品質向上・特化用**"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-vae",
   "metadata": {},
   "outputs": [],
   "source": [
    "# VAE for SD 1.5 - Better colors (Optional, 335 MB)\n",
    "# SD 1.5用 VAE - 色味が鮮やかに（オプション・335 MB）\n",
    "!python /workspace/scripts/model_downloader.py download vae-mse"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-wd15",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Waifu Diffusion 1.5 Beta 3 - Anime/Manga specialized (2.0 GB)\n",
    "# Waifu Diffusion 1.5 Beta 3 - Anime/Manga特化 (2.0 GB)\n",
    "!python /workspace/scripts/model_downloader.py download wd15-beta3"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-anything",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Anything V5 - General purpose anime model (2.13 GB)\n",
    "# Anything V5 - 汎用Animeモデル (2.13 GB)\n",
    "!python /workspace/scripts/model_downloader.py download anythingv5"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-realistic",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Realistic Vision V5.1 - Photorealistic (2.13 GB)\n",
    "# Realistic Vision V5.1 - 写実的 (2.13 GB)\n",
    "!python /workspace/scripts/model_downloader.py download realisticvision"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "flux-header",
   "metadata": {},
   "source": [
    "---\n",
    "## 🚀 Flux・SD3.5 Models / 最新モデル\n",
    "**⚠️ Requires Hugging Face Token / HFトークンが必要です**  \n",
    "上の「🔑 Hugging Face Token設定」セルを先に実行してください"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-flux-dev",
   "metadata": {},
   "outputs": [],
   "source": [
    "# FLUX.1 Dev - Latest high quality model (23.8 GB, 24GB+ VRAM recommended)\n",
    "# FLUX.1 Dev - 最新高品質モデル (23.8 GB, VRAM 24GB以上推奨)\n",
    "!python /workspace/scripts/model_downloader.py download flux-dev"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-flux-schnell",
   "metadata": {},
   "outputs": [],
   "source": [
    "# FLUX.1 Schnell - Fast inference version (23.8 GB, 24GB+ VRAM recommended)\n",
    "# FLUX.1 Schnell - 高速推論版 (23.8 GB, VRAM 24GB以上推奨)\n",
    "!python /workspace/scripts/model_downloader.py download flux-schnell"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-sd35-large",
   "metadata": {},
   "outputs": [],
   "source": [
    "# SD 3.5 Large - Stability AI latest (16.0 GB, 16GB+ VRAM recommended)\n",
    "# SD 3.5 Large - Stability AI最新モデル (16.0 GB, VRAM 16GB以上推奨)\n",
    "!python /workspace/scripts/model_downloader.py download sd35-large"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-sd35-medium",
   "metadata": {},
   "outputs": [],
   "source": [
    "# SD 3.5 Medium - Balanced size and quality (8.9 GB, 10GB+ VRAM recommended)\n",
    "# SD 3.5 Medium - サイズと品質のバランス型 (8.9 GB, VRAM 10GB以上推奨)\n",
    "!python /workspace/scripts/model_downloader.py download sd35-medium"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "custom-header",
   "metadata": {},
   "source": [
    "---\n",
    "## 🌐 Download from Custom URL / カスタムURLからダウンロード\n",
    "\n",
    "**Download directly from Hugging Face, Civitai, etc.**  \n",
    "Hugging Face、Civitai などから直接ダウンロード可能\n",
    "\n",
    "**How to use / 使い方:**\n",
    "1. Remove the `#` from the cell below  \n",
    "   下のセルの `#` を削除\n",
    "2. Replace URL and filename  \n",
    "   URLとファイル名を書き換え\n",
    "3. Run the cell  \n",
    "   セルを実行"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "download-custom",
   "metadata": {},
   "outputs": [],
   "source": [
    "# !python /workspace/scripts/model_downloader.py url 'https://huggingface.co/USER/MODEL/resolve/main/model.safetensors' 'my-custom-model.safetensors'"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "usage-guide",
   "metadata": {},
   "source": [
    "---\n",
    "## 📝 How to Use After Download / ダウンロード後の使い方\n",
    "\n",
    "### Using in Kohya_ss GUI / Kohya_ss GUIで使用:\n",
    "1. Open Kohya_ss GUI → **Source model** tab  \n",
    "   Kohya_ss GUIを開く → **Source model** タブ\n",
    "2. Click **Pretrained model name or path**  \n",
    "   **Pretrained model name or path** をクリック\n",
    "3. Select model from `models/Stable-diffusion/`  \n",
    "   `models/Stable-diffusion/` からモデルを選択\n",
    "\n",
    "### Using VAE (Optional) / VAEを使う場合（オプション）:\n",
    "- Go to **Model** tab → **VAE** field  \n",
    "  **Model** タブ → **VAE** 欄\n",
    "- Select `models/VAE/vae-ft-mse-840000-ema-pruned.safetensors`  \n",
    "  `models/VAE/vae-ft-mse-840000-ema-pruned.safetensors` を選択\n",
    "- Improves color quality  \n",
    "  色味の品質が向上します\n",
    "\n",
    "---\n",
    "## 💾 Save Location / 保存先\n",
    "\n",
    "All models are saved to `/workspace/models/`:  \n",
    "すべてのモデルは `/workspace/models/` に保存されます:\n",
    "\n",
    "```\n",
    "/workspace/models/\n",
    "├── Stable-diffusion/  ← Base models / ベースモデル\n",
    "├── VAE/              ← VAE files / VAEファイル\n",
    "├── Lora/             ← Trained LoRAs / 学習済みLoRA\n",
    "└── embeddings/       ← Textual Inversion\n",
    "```"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.10.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
NOTEBOOK_EOF
    echo "✓ Download_Models.ipynb created"
else
    echo "✓ Download_Models.ipynb exists - preserving download history"
    echo "  ダウンロード履歴を保持しています"
fi

# WD14_Tagger.ipynb - 毎回新規作成（実行状態をリセット）
echo "📝 Creating fresh WD14_Tagger.ipynb (resetting execution state)..."
echo "  WD14タガーをリセットしています..."
cat << 'WD14_EOF' > /workspace/WD14_Tagger.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "header",
   "metadata": {},
   "source": [
    "# 🏷️ WD14 Tagger - Automatic Image Captioning\n",
    "\n",
    "**Automatically generate captions for your training images**  \n",
    "学習画像のキャプションを自動生成します\n",
    "\n",
    "## 💡 Note / 注意\n",
    "- **This notebook is reset on each Pod startup for clean execution**  \n",
    "  **このノートブックはPod起動時に毎回リセットされます**\n",
    "- Previous tagging results are saved as `.txt` files next to your images  \n",
    "  以前のタグ付け結果は画像の隣の `.txt` ファイルに保存されています\n",
    "\n",
    "## 📦 Features / 機能\n",
    "- Anime/Manga optimized tagging  \n",
    "  Anime/Manga最適化タグ付け\n",
    "- Character, style, and composition tags  \n",
    "  キャラクター、スタイル、構図のタグ\n",
    "- Batch processing support  \n",
    "  バッチ処理対応\n",
    "\n",
    "---"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "setup",
   "metadata": {},
   "source": [
    "## ⚙️ Setup / セットアップ\n",
    "\n",
    "**Run this cell first to check WD14 Tagger availability**  \n",
    "最初にこのセルを実行してWD14タガーが使用可能か確認"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "check-wd14",
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "\n",
    "wd14_script = '/workspace/kohya_ss/sd-scripts/finetune/tag_images_by_wd14_tagger.py'\n",
    "\n",
    "if os.path.exists(wd14_script):\n",
    "    print('✅ WD14 Tagger is available!')\n",
    "    print('✅ WD14タガーが利用可能です！')\n",
    "    print(f'\\nScript location / スクリプトの場所: {wd14_script}')\n",
    "else:\n",
    "    print('❌ WD14 Tagger not found')\n",
    "    print('❌ WD14タガーが見つかりません')"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "basic-usage",
   "metadata": {},
   "source": [
    "---\n",
    "## 🚀 Basic Usage / 基本的な使い方\n",
    "\n",
    "**Replace `/workspace/datasets/your_images` with your image folder path**  \n",
    "`/workspace/datasets/your_images` を画像フォルダのパスに変更してください"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "basic-tagging",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Basic tagging with default settings\n",
    "# デフォルト設定でタグ付け\n",
    "!cd /workspace/kohya_ss/sd-scripts && \\\n",
    "python finetune/tag_images_by_wd14_tagger.py \\\n",
    "    --batch_size 4 \\\n",
    "    --thresh 0.35 \\\n",
    "    --repo_id SmilingWolf/wd-v1-4-convnextv2-tagger-v2 \\\n",
    "    /workspace/datasets/your_images"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "advanced-usage",
   "metadata": {},
   "source": [
    "---\n",
    "## 🎛️ Advanced Options / 高度なオプション\n",
    "\n",
    "### Option 1: Custom threshold / カスタム閾値\n",
    "Lower threshold = More tags (may include noise)  \n",
    "閾値を下げる = タグ数増加（ノイズも含む可能性）"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "custom-threshold",
   "metadata": {},
   "outputs": [],
   "source": [
    "# More tags with lower threshold (0.25)\n",
    "# 閾値を下げてタグ数を増やす (0.25)\n",
    "!cd /workspace/kohya_ss/sd-scripts && \\\n",
    "python finetune/tag_images_by_wd14_tagger.py \\\n",
    "    --batch_size 4 \\\n",
    "    --thresh 0.25 \\\n",
    "    --repo_id SmilingWolf/wd-v1-4-convnextv2-tagger-v2 \\\n",
    "    /workspace/datasets/your_images"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "option2",
   "metadata": {},
   "source": [
    "### Option 2: Append to existing captions / 既存キャプションに追加"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "append-captions",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Append tags to existing .txt files\n",
    "# 既存の.txtファイルにタグを追加\n",
    "!cd /workspace/kohya_ss/sd-scripts && \\\n",
    "python finetune/tag_images_by_wd14_tagger.py \\\n",
    "    --batch_size 4 \\\n",
    "    --thresh 0.35 \\\n",
    "    --append_tags \\\n",
    "    --repo_id SmilingWolf/wd-v1-4-convnextv2-tagger-v2 \\\n",
    "    /workspace/datasets/your_images"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "option3",
   "metadata": {},
   "source": [
    "### Option 3: Remove specific tags / 特定タグを削除"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "remove-tags",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Remove unwanted tags (e.g., ratings)\n",
    "# 不要なタグを削除（例：レーティング）\n",
    "!cd /workspace/kohya_ss/sd-scripts && \\\n",
    "python finetune/tag_images_by_wd14_tagger.py \\\n",
    "    --batch_size 4 \\\n",
    "    --thresh 0.35 \\\n",
    "    --remove_underscore \\\n",
    "    --undesired_tags \"rating:safe,rating:questionable,rating:explicit\" \\\n",
    "    --repo_id SmilingWolf/wd-v1-4-convnextv2-tagger-v2 \\\n",
    "    /workspace/datasets/your_images"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "all-options",
   "metadata": {},
   "source": [
    "---\n",
    "## 📚 All Available Options / 利用可能なオプション一覧\n",
    "\n",
    "**View all options / すべてのオプションを表示:**"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "show-help",
   "metadata": {},
   "outputs": [],
   "source": [
    "!cd /workspace/kohya_ss/sd-scripts && \\\n",
    "python finetune/tag_images_by_wd14_tagger.py --help"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "tips",
   "metadata": {},
   "source": [
    "---\n",
    "## 💡 Tips / ヒント\n",
    "\n",
    "### Recommended Settings / 推奨設定:\n",
    "\n",
    "**For Anime/Manga / Anime・Manga用:**\n",
    "- Threshold: `0.35` (balanced)  \n",
    "  閾値: `0.35`（バランス重視）\n",
    "- Remove underscores for better readability  \n",
    "  アンダースコア削除で読みやすく\n",
    "\n",
    "**For Character training / キャラクター学習用:**\n",
    "- Threshold: `0.25` (more details)  \n",
    "  閾値: `0.25`（詳細重視）\n",
    "- Use `--character_threshold 0.85` for character tags  \n",
    "  `--character_threshold 0.85` でキャラクタータグ精度向上\n",
    "\n",
    "**For Style training / スタイル学習用:**\n",
    "- Threshold: `0.4` (fewer tags)  \n",
    "  閾値: `0.4`（タグ少なめ）\n",
    "- Focus on composition and style tags  \n",
    "  構図・スタイルタグに注目\n",
    "\n",
    "---\n",
    "## 📝 Output / 出力\n",
    "\n",
    "Generated `.txt` files will be saved next to each image:  \n",
    "生成された `.txt` ファイルは各画像の隣に保存されます:\n",
    "\n",
    "```\n",
    "/workspace/datasets/your_images/\n",
    "├── image1.png\n",
    "├── image1.txt  ← Generated tags / 生成されたタグ\n",
    "├── image2.jpg\n",
    "└── image2.txt  ← Generated tags / 生成されたタグ\n",
    "```\n",
    "\n",
    "### You can also use Kohya_ss GUI / Kohya_ss GUIも使用可能:\n",
    "- Open Kohya_ss GUI  \n",
    "  Kohya_ss GUIを開く\n",
    "- Go to **Utilities** → **Captioning** → **WD14 Captioning**  \n",
    "  **Utilities** → **Captioning** → **WD14 Captioning** へ\n",
    "- Configure settings and click **Caption images**  \n",
    "  設定を調整して **Caption images** をクリック"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.10.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
WD14_EOF
echo "✓ WD14_Tagger.ipynb reset complete"

# --- venv 作成・有効化 ---
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv --system-site-packages venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

pip install --upgrade pip --quiet

# --- 依存関係インストール（初回のみ） ---
if [ ! -f ".deps_installed" ]; then
    echo "Installing Kohya_ss dependencies..."
    
    # Step 1: システムパッケージと競合しやすいものを先に処理
    echo "📦 Updating core packages..."
    pip install --upgrade --ignore-installed \
        typing-extensions \
        packaging \
        "huggingface-hub>=0.23.2,<1.0" \
        filelock \
        requests \
        tqdm 2>&1 | grep -v "Not uninstalling" || true
    
    # Step 2: requirements をインストール
    if [ -f "requirements.txt" ]; then
        echo "📦 Installing Kohya requirements..."
        pip install -r requirements.txt 2>&1 | grep -v "Not uninstalling\|Can't uninstall" || true
    elif [ -f "requirements_runpod.txt" ]; then
        echo "📦 Installing RunPod requirements..."
        pip install -r requirements_runpod.txt 2>&1 | grep -v "Not uninstalling\|Can't uninstall" || true
    else
        echo "⚠️  Warning: No requirements file found"
    fi
    
    # Step 3: WD14 Tagger用の依存関係
echo "📦 Installing WD14 Tagger dependencies..."
pip install onnxruntime 2>&1 | grep -v "Not uninstalling" || true

echo "📦 Fixing huggingface-hub version..."
pip install "huggingface-hub>=0.23.2,<1.0" --force-reinstall 2>&1 || true

touch .deps_installed
echo "✅ Dependencies installed!"
else
echo "✅ Dependencies already installed, skipping..."
fi
# --- JupyterLab 起動 ---
if [ "$ENABLE_JUPYTER" = "1" ]; then
echo "Starting JupyterLab on port $JUPYTER_PORT..."
    
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
    echo "✓ JupyterLab is running on port $JUPYTER_PORT"
else
    echo "✗ JupyterLab failed to start, check $LOG_DIR/jupyter.log"
    cat "$LOG_DIR/jupyter.log"
fi
else
echo "JupyterLab disabled"
fi
# --- Kohya_ss 起動 ---
echo "Starting Kohya_ss on port $KOHYA_PORT..."
exec bash gui.sh \
    --listen 0.0.0.0 \
    --server_port "$KOHYA_PORT" \
    > >(tee "$LOG_DIR/kohya_ss.log") 2>&1

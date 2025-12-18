# 🎨 Kohya_ss Training Studio

**Professional LoRA training environment with WD14 Tagger and one-click model management**

[![Docker Image](https://img.shields.io/badge/docker-sakasa15%2Fkohya--runpod-blue)](https://hub.docker.com/r/sakasa15/kohya-runpod)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Easy-to-use Kohya_ss template for RunPod with integrated WD14 Tagger (latest ConvNextV2), built-in model downloader, and beginner-friendly Jupyter notebooks.

[English](#english) | [日本語](#japanese)

---

<a name="english"></a>

## ✨ Features

### 🏷️ **WD14 Tagger Integration**
- Latest **ConvNextV2** model (`SmilingWolf/wd-v1-4-convnextv2-tagger-v2`)
- Automatic anime-style image captioning
- GUI and CLI support
- Batch processing ready

### 📦 **One-Click Model Downloader**
- Pre-configured popular models (SD 1.5, SDXL, Waifu Diffusion, etc.)
- Custom URL support (Hugging Face, Civitai)
- Download history preserved across sessions
- Interactive Jupyter notebook interface

### 🚀 **Fast & Reliable**
- ~60 second startup time
- Network volume robustness with retry logic
- Automatic error recovery
- Smart symlink management

### 🌍 **Bilingual Support**
- Full English + Japanese UI
- Bilingual documentation
- Beginner-friendly guidance in both languages

### 📓 **JupyterLab Included**
- Interactive model management
- WD14 tagging workflows
- Persistent download logs
- Clean execution environment

---

## 🚀 Quick Start

### 1. Deploy on RunPod

**Docker Image:**
```
sakasa15/kohya-runpod:v30
```

**Recommended Specifications:**
- **GPU:** RTX 4090 or RTX A6000 (24GB VRAM minimum)
- **Container Disk:** 50GB
- **Network Volume:** 80GB+ mounted to `/workspace`

**Ports:**
- `3013` - Kohya_ss GUI
- `8888` - JupyterLab

### 2. Access Your Services

Once the pod starts, you'll see two URLs:

- **Kohya_ss GUI:** `https://xxxxx-3013.proxy.runpod.net`
- **JupyterLab:** `https://xxxxx-8888.proxy.runpod.net`

### 3. Download Training Models

1. Open **JupyterLab** (port 8888)
2. Open `Download_Models.ipynb`
3. Run cells to download models:
   - SD 1.5 (4.27 GB)
   - SDXL Base (6.94 GB)
   - Waifu Diffusion 1.5 (2.0 GB)
   - Custom models via URL

**Note:** Download history is preserved across pod restarts!

### 4. Prepare Your Dataset

Upload your training images to `/workspace/datasets/your_project/`

### 5. Generate Captions with WD14 Tagger

**Option A: JupyterLab (Recommended for beginners)**
1. Open `WD14_Tagger.ipynb`
2. Update the image path in the cell
3. Run the cell to generate captions

**Option B: Kohya_ss GUI**
1. Go to **Utilities** → **Captioning** → **WD14 Captioning**
2. Select your image folder
3. Click **Caption images**

### 6. Start Training

1. Open **Kohya_ss GUI** (port 3013)
2. Configure your training parameters:
   - **Source model:** Select from `models/Stable-diffusion/`
   - **Image folder:** Your dataset path
   - **Output folder:** `/workspace/outputs/`
3. Click **Start training**

---

## 📦 Available Models

### Pre-configured Downloads

| Model | Size | Description |
|-------|------|-------------|
| **SD 1.5** | 4.27 GB | Most popular for LoRA training |
| **SD 1.5 EMA** | 4.27 GB | More stable training variant |
| **SDXL Base** | 6.94 GB | High resolution training |
| **SDXL Refiner** | 6.08 GB | Quality enhancement |
| **Waifu Diffusion 1.5** | 2.0 GB | Anime/Manga specialized |
| **Anything V5** | 2.13 GB | General purpose anime |
| **Realistic Vision V5.1** | 2.13 GB | Photorealistic |
| **VAE (SD 1.5)** | 335 MB | Better colors (optional) |
| **VAE (SDXL)** | 335 MB | SDXL VAE (optional) |

### Custom Models
Download any model from Hugging Face, Civitai, or other sources using the custom URL feature in `Download_Models.ipynb`.

---

## 🏷️ WD14 Tagger Details

### What is WD14 Tagger?
An AI model trained on anime/manga images for automatic tagging. Generates accurate captions for:
- Characters and their features
- Art styles and aesthetics
- Composition and framing
- Colors and lighting

### Model Version
This template uses the latest **ConvNextV2** architecture:
- Model: `SmilingWolf/wd-v1-4-convnextv2-tagger-v2`
- Better accuracy than previous versions
- Optimized for anime/manga content

### Usage Examples

**Basic tagging:**
```bash
python tag_images_by_wd14_tagger.py \
    --batch_size 4 \
    --thresh 0.35 \
    /workspace/datasets/your_images
```

**Character-focused:**
```bash
python tag_images_by_wd14_tagger.py \
    --batch_size 4 \
    --thresh 0.25 \
    --character_threshold 0.85 \
    /workspace/datasets/character_training
```

**Remove unwanted tags:**
```bash
python tag_images_by_wd14_tagger.py \
    --batch_size 4 \
    --thresh 0.35 \
    --remove_underscore \
    --undesired_tags "rating:safe,rating:questionable,rating:explicit" \
    /workspace/datasets/your_images
```

---

## 💾 Network Volume Structure

```
/workspace/
├── models/                    # Shared models (symlinked to Kohya)
│   ├── Stable-diffusion/     # Base models
│   ├── Lora/                 # Trained LoRAs
│   ├── VAE/                  # VAE files
│   └── embeddings/           # Textual Inversion
├── datasets/                  # Your training images
│   └── project_name/
│       ├── image1.png
│       ├── image1.txt        # Generated captions
│       └── ...
├── outputs/                   # Training outputs
├── logs/                      # System logs
├── scripts/                   # Utility scripts
├── Download_Models.ipynb      # Model downloader
└── WD14_Tagger.ipynb         # Tagging notebook
```

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_JUPYTER` | `1` | Enable JupyterLab (1=enabled, 0=disabled) |
| `JUPYTER_PORT` | `8888` | JupyterLab port |
| `KOHYA_PORT` | `3013` | Kohya_ss GUI port |

---

## 🔧 Advanced Configuration

### Using VAE for Better Quality

1. Download VAE using `Download_Models.ipynb`
2. In Kohya_ss GUI → **Model** tab → **VAE** field
3. Select: `models/VAE/vae-ft-mse-840000-ema-pruned.safetensors`

### Network Volume Best Practices

- **First pod:** Download all models to network volume
- **Subsequent pods:** Models are instantly available
- **Sharing:** Use same network volume across different templates (ComfyUI, SD WebUI, etc.)

### Notebook Management

- **Download_Models.ipynb:** Preserves download history across pod restarts
- **WD14_Tagger.ipynb:** Resets on each startup for clean execution

---

## 🐛 Troubleshooting

### Models not visible in Kohya_ss GUI

**Symptom:** Cannot select models in dropdown

**Solution:**
```bash
cd /workspace/kohya_ss
rm -rf models
ln -s /workspace/models models
```
Then restart the pod.

### WD14 Tagger button grayed out

**Symptom:** "Caption images" button is not clickable in Kohya GUI

**Solution:**
```bash
cd /workspace/kohya_ss
source venv/bin/activate
pip install onnxruntime
```
Then reload Kohya_ss GUI in browser (Ctrl+Shift+R).

### Slow startup

**Symptom:** Pod takes longer than 2 minutes to start

**Possible causes:**
- Network volume is slow (wait 1-2 minutes)
- First-time dependency installation (normal)

**Solution:** Wait for startup to complete. Subsequent startups will be faster.

### JupyterLab kernel issues

**Symptom:** Cannot execute cells or "No Kernel" error

**Solution:**
1. In JupyterLab: **Kernel** → **Restart Kernel**
2. Or: **Kernel** → **Change Kernel** → **Python 3**

---

## 📖 Documentation

- [Kohya_ss Official Documentation](https://github.com/bmaltais/kohya_ss)
- [LoRA Training Guide](https://rentry.org/lora_train)
- [WD14 Tagger Model Card](https://huggingface.co/SmilingWolf/wd-v1-4-convnextv2-tagger-v2)

---

## 📝 Changelog

### v30 (Current)
- ✨ Updated WD14 Tagger to ConvNextV2 (`wd-v1-4-convnextv2-tagger-v2`)
- 🛡️ Network volume robustness improvements with retry logic
- 🌍 Full bilingual support (English + Japanese)
- 📓 Smart notebook management (Download history preserved, WD14 reset)
- 🔧 Automatic error recovery

### v29
- 🛡️ Added network volume response checking
- 🔄 Added retry logic for directory creation
- 📝 Improved error messages

### v28
- 🌍 Bilingual support added
- 📓 Two Jupyter notebooks included

---

## 🙏 Credits

- **Kohya_ss:** [bmaltais/kohya_ss](https://github.com/bmaltais/kohya_ss)
- **WD14 Tagger:** [SmilingWolf](https://huggingface.co/SmilingWolf)
- **Base Image:** [RunPod PyTorch](https://github.com/runpod/containers)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/your-username/kohya-training-studio/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-username/kohya-training-studio/discussions)

---

## ⭐ Star History

If you find this template useful, please consider giving it a star! ⭐

---

<a name="japanese"></a>

# 🎨 Kohya_ss Training Studio（日本語）

**WD14タガーとワンクリックモデル管理を統合したプロフェッショナルなLoRA学習環境**

---

## ✨ 機能

### 🏷️ **WD14タガー統合**
- 最新の**ConvNextV2**モデル (`SmilingWolf/wd-v1-4-convnextv2-tagger-v2`)
- Anime/Manga特化の自動キャプション生成
- GUIとCLIの両方に対応
- バッチ処理対応

### 📦 **ワンクリックモデルダウンローダー**
- 人気モデルを事前設定（SD 1.5、SDXL、Waifu Diffusionなど）
- カスタムURL対応（Hugging Face、Civitai）
- ダウンロード履歴をセッション間で保持
- インタラクティブなJupyterノートブックインターフェース

### 🚀 **高速・安定**
- 約60秒で起動
- リトライロジックによるネットワークボリュームの堅牢性
- 自動エラー復旧
- スマートなシンボリックリンク管理

### 🌍 **バイリンガル対応**
- 完全な英語+日本語UI
- バイリンガルドキュメント
- 両言語での初心者向けガイド

### 📓 **JupyterLab搭載**
- インタラクティブなモデル管理
- WD14タグ付けワークフロー
- 永続的なダウンロードログ
- クリーンな実行環境

---

## 🚀 クイックスタート

### 1. RunPodでデプロイ

**Dockerイメージ:**
```
sakasa15/kohya-runpod:v30
```

**推奨スペック:**
- **GPU:** RTX 4090 または RTX A6000（最小24GB VRAM）
- **Container Disk:** 50GB
- **Network Volume:** 80GB以上、`/workspace`にマウント

**ポート:**
- `3013` - Kohya_ss GUI
- `8888` - JupyterLab

### 2. サービスにアクセス

Podが起動すると、2つのURLが表示されます:

- **Kohya_ss GUI:** `https://xxxxx-3013.proxy.runpod.net`
- **JupyterLab:** `https://xxxxx-8888.proxy.runpod.net`

### 3. 学習モデルをダウンロード

1. **JupyterLab**（ポート8888）を開く
2. `Download_Models.ipynb`を開く
3. セルを実行してモデルをダウンロード:
   - SD 1.5（4.27 GB）
   - SDXL Base（6.94 GB）
   - Waifu Diffusion 1.5（2.0 GB）
   - カスタムモデル（URL経由）

**注意:** ダウンロード履歴はPod再起動後も保持されます！

### 4. データセットを準備

学習画像を`/workspace/datasets/your_project/`にアップロード

### 5. WD14タガーでキャプション生成

**方法A: JupyterLab（初心者推奨）**
1. `WD14_Tagger.ipynb`を開く
2. セル内の画像パスを更新
3. セルを実行してキャプションを生成

**方法B: Kohya_ss GUI**
1. **Utilities** → **Captioning** → **WD14 Captioning**へ
2. 画像フォルダを選択
3. **Caption images**をクリック

### 6. 学習開始

1. **Kohya_ss GUI**（ポート3013）を開く
2. 学習パラメータを設定:
   - **Source model:** `models/Stable-diffusion/`から選択
   - **Image folder:** データセットパス
   - **Output folder:** `/workspace/outputs/`
3. **Start training**をクリック

---

## 📝 変更履歴

### v30（現在）
- ✨ WD14タガーをConvNextV2に更新（`wd-v1-4-convnextv2-tagger-v2`）
- 🛡️ リトライロジックによるネットワークボリュームの堅牢性向上
- 🌍 完全なバイリンガル対応（英語+日本語）
- 📓 スマートなノートブック管理（ダウンロード履歴保持、WD14リセット）
- 🔧 自動エラー復旧

---

## 📄 ライセンス

MITライセンス - 詳細は[LICENSE](LICENSE)ファイルを参照

---

**Made with ❤️ for the AI art community**
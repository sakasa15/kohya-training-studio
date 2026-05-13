#!/usr/bin/env python3
"""
Kohya_ss Model Downloader - Bilingual Edition
Easy model download for Kohya_ss training
学習用モデルを簡単にダウンロードするツール
"""

import os
import sys
import requests
from tqdm import tqdm
from pathlib import Path

# Model save directory / モデル保存先ディレクトリ
MODELS_DIR = Path("/workspace/models")

# Hugging Face Token / Hugging Faceトークン
HF_TOKEN = os.environ.get("HF_TOKEN", "")

# Model catalog / モデルカタログ
AVAILABLE_MODELS = {
    # ========================================
    # 🔥 Required Models / 必須モデル
    # ========================================
    "sd15": {
        "url": "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors",
        "filename": "v1-5-pruned.safetensors",
        "dest": "Stable-diffusion",
        "size": "4.27 GB",
        "priority": "HIGH",
        "requires_token": False,
        "description": "Stable Diffusion 1.5 - Most popular for LoRA training",
        "description_ja": "Stable Diffusion 1.5 - LoRA学習の定番"
    },
    "sd15-ema": {
        "url": "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors",
        "filename": "v1-5-pruned-emaonly.safetensors",
        "dest": "Stable-diffusion",
        "size": "4.27 GB",
        "priority": "HIGH",
        "requires_token": False,
        "description": "SD 1.5 EMA Only - More stable training",
        "description_ja": "SD 1.5 EMA Only版 - より安定した学習"
    },
    "sdxl-base": {
        "url": "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors",
        "filename": "sd_xl_base_1.0.safetensors",
        "dest": "Stable-diffusion",
        "size": "6.94 GB",
        "priority": "HIGH",
        "requires_token": False,
        "description": "SDXL Base 1.0 - High resolution training",
        "description_ja": "SDXL Base 1.0 - 高解像度学習用"
    },
    "sdxl-refiner": {
        "url": "https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors",
        "filename": "sd_xl_refiner_1.0.safetensors",
        "dest": "Stable-diffusion",
        "size": "6.08 GB",
        "priority": "MEDIUM",
        "requires_token": False,
        "description": "SDXL Refiner 1.0 - Quality enhancement",
        "description_ja": "SDXL Refiner 1.0 - 高品質化用"
    },

    # ========================================
    # 🚀 New Models / 新モデル (要HF Token)
    # ========================================
    "flux-dev": {
        "url": "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors",
        "filename": "flux1-dev.safetensors",
        "dest": "Stable-diffusion",
        "size": "23.8 GB",
        "priority": "HIGH",
        "requires_token": True,
        "description": "FLUX.1 Dev - Latest high quality model (Requires HF Token, 24GB+ VRAM recommended)",
        "description_ja": "FLUX.1 Dev - 最新高品質モデル (HFトークン必要、VRAM 24GB以上推奨)"
    },
    "flux-schnell": {
        "url": "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors",
        "filename": "flux1-schnell.safetensors",
        "dest": "Stable-diffusion",
        "size": "23.8 GB",
        "priority": "MEDIUM",
        "requires_token": True,
        "description": "FLUX.1 Schnell - Fast inference version (Requires HF Token, 24GB+ VRAM recommended)",
        "description_ja": "FLUX.1 Schnell - 高速推論版 (HFトークン必要、VRAM 24GB以上推奨)"
    },
    "sd35-large": {
        "url": "https://huggingface.co/stabilityai/stable-diffusion-3.5-large/resolve/main/sd3.5_large.safetensors",
        "filename": "sd3.5_large.safetensors",
        "dest": "Stable-diffusion",
        "size": "16.0 GB",
        "priority": "HIGH",
        "requires_token": True,
        "description": "SD 3.5 Large - Stability AI latest (Requires HF Token, 16GB+ VRAM recommended)",
        "description_ja": "SD 3.5 Large - Stability AI最新モデル (HFトークン必要、VRAM 16GB以上推奨)"
    },
    "sd35-medium": {
        "url": "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors",
        "filename": "sd3.5_medium.safetensors",
        "dest": "Stable-diffusion",
        "size": "8.9 GB",
        "priority": "HIGH",
        "requires_token": True,
        "description": "SD 3.5 Medium - Balanced size and quality (Requires HF Token, 10GB+ VRAM recommended)",
        "description_ja": "SD 3.5 Medium - サイズと品質のバランス型 (HFトークン必要、VRAM 10GB以上推奨)"
    },

    # ========================================
    # ⭐ VAE (Optional / オプション)
    # ========================================
    "vae-mse": {
        "url": "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors",
        "filename": "vae-ft-mse-840000-ema-pruned.safetensors",
        "dest": "VAE",
        "size": "335 MB",
        "priority": "MEDIUM",
        "requires_token": False,
        "description": "SD 1.5 VAE - Better colors (Optional)",
        "description_ja": "SD 1.5用 高品質VAE - 色味が鮮やかに（オプション）"
    },
    "sdxl-vae": {
        "url": "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors",
        "filename": "sdxl_vae.safetensors",
        "dest": "VAE",
        "size": "335 MB",
        "priority": "MEDIUM",
        "requires_token": False,
        "description": "SDXL VAE (Optional)",
        "description_ja": "SDXL用 VAE（オプション）"
    },

    # ========================================
    # 🎨 Specialized Models / 特化モデル
    # ========================================
    "wd15-beta3": {
        "url": "https://huggingface.co/SmilingWolf/wd-v1-4-convnextv2-tagger-v2/resolve/main/model.safetensors",
        "filename": "wd-v1-4-convnextv2-tagger-v2.safetensors",
        "dest": "Stable-diffusion",
        "size": "2.0 GB",
        "priority": "MEDIUM",
        "requires_token": False,
        "description": "Waifu Diffusion 1.5 Beta 3 - Anime/Manga specialized",
        "description_ja": "Waifu Diffusion 1.5 Beta 3 - Anime/Manga特化"
    },
    "realisticvision": {
        "url": "https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors",
        "filename": "realisticvision_v51.safetensors",
        "dest": "Stable-diffusion",
        "size": "2.13 GB",
        "priority": "LOW",
        "requires_token": False,
        "description": "Realistic Vision V5.1 - Photorealistic",
        "description_ja": "Realistic Vision V5.1 - 写実的な画像生成"
    },
    "anythingv5": {
        "url": "https://huggingface.co/genai-archive/anything-v5/resolve/main/anything-v5.safetensors",
        "filename": "anythingv5.safetensors",
        "dest": "Stable-diffusion",
        "size": "2.13 GB",
        "priority": "MEDIUM",
        "requires_token": False,
        "description": "Anything V5 - General purpose anime model",
        "description_ja": "Anything V5 - 汎用Animeモデル"
    },
}


def download_file(url: str, dest_path: Path, requires_token: bool = False):
    """
    Download file with progress bar
    プログレスバー付きでファイルをダウンロード
    """
    print(f"\n📥 Downloading from / ダウンロード元: {url}")
    print(f"💾 Saving to / 保存先: {dest_path}")

    headers = {}
    if requires_token:
        if not HF_TOKEN:
            raise Exception(
                "HF_TOKEN is required for this model.\n"
                "このモデルにはHugging FaceのAccess Tokenが必要です。\n"
                "Set HF_TOKEN environment variable or pass it via Runpod settings.\n"
                "環境変数 HF_TOKEN を設定してください。"
            )
        headers["Authorization"] = f"Bearer {HF_TOKEN}"
        print("🔑 Using Hugging Face Token / HFトークンを使用中")

    try:
        response = requests.get(url, stream=True, timeout=30, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to connect / 接続失敗: {e}")

    total_size = int(response.headers.get('content-length', 0))

    # Create directory / ディレクトリ作成
    dest_path.parent.mkdir(parents=True, exist_ok=True)

    # Download / ダウンロード実行
    with open(dest_path, 'wb') as f, tqdm(
        total=total_size,
        unit='B',
        unit_scale=True,
        unit_divisor=1024,
        desc=dest_path.name
    ) as pbar:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
                pbar.update(len(chunk))

    print(f"✅ Download complete / ダウンロード完了: {dest_path.name}")


def list_models():
    """
    Display available models
    利用可能なモデルを表示
    """
    print("\n" + "="*80)
    print("📦 Kohya_ss Model Downloader - Available Models")
    print("="*80)

    if HF_TOKEN:
        print("🔑 HF Token detected - Flux/SD3.5 downloads enabled")
        print("   HFトークン検出済み - Flux/SD3.5ダウンロード可能")
    else:
        print("⚠️  No HF Token - Flux/SD3.5 require token (set HF_TOKEN)")
        print("   HFトークン未設定 - Flux/SD3.5は要トークン (HF_TOKEN を設定)")

    high_priority = []
    medium_priority = []
    low_priority = []

    for model_id, info in AVAILABLE_MODELS.items():
        priority = info.get('priority', 'LOW')
        if priority == 'HIGH':
            high_priority.append((model_id, info))
        elif priority == 'MEDIUM':
            medium_priority.append((model_id, info))
        else:
            low_priority.append((model_id, info))

    if high_priority:
        print("\n🔥 Required Models / 必須モデル (Basic training / 基本学習用):")
        print("-" * 80)
        for model_id, info in high_priority:
            token_mark = "🔑" if info.get('requires_token') else "  "
            print(f"  {token_mark} {model_id:<20} [{info['size']:<10}] {info['filename']}")
            print(f"     └─ {info['description']}")
            print(f"        {info['description_ja']}")

    if medium_priority:
        print("\n⭐ Recommended Models / 推奨モデル:")
        print("-" * 80)
        for model_id, info in medium_priority:
            token_mark = "🔑" if info.get('requires_token') else "  "
            print(f"  {token_mark} {model_id:<20} [{info['size']:<10}] {info['filename']}")
            print(f"     └─ {info['description']}")
            print(f"        {info['description_ja']}")

    if low_priority:
        print("\n💡 Other Models / その他モデル:")
        print("-" * 80)
        for model_id, info in low_priority:
            token_mark = "🔑" if info.get('requires_token') else "  "
            print(f"  {token_mark} {model_id:<20} [{info['size']:<10}] {info['filename']}")
            print(f"     └─ {info['description']}")
            print(f"        {info['description_ja']}")

    print("\n" + "="*80)
    print("🔑 = Requires Hugging Face Token / HFトークンが必要")
    print(f"💾 Save location / 保存先: {MODELS_DIR}/")
    print("="*80)
    print("\nUsage / 使い方:")
    print("  python model_downloader.py download <model_id>")
    print("  python model_downloader.py download flux-dev")
    print("  python model_downloader.py url <url> <filename>")
    print()


def download_model(model_id: str):
    """
    Download model
    モデルをダウンロード
    """
    if model_id not in AVAILABLE_MODELS:
        print(f"\n❌ Error: Unknown model ID '{model_id}'")
        print("エラー: 不明なモデルID")
        print("Run 'python model_downloader.py list' to see available models")
        sys.exit(1)

    info = AVAILABLE_MODELS[model_id]
    dest_dir = MODELS_DIR / info['dest']
    dest_path = dest_dir / info['filename']

    if dest_path.exists():
        print(f"\n⚠️  File already exists / ファイルが既に存在します: {dest_path}")
        print(f"   Size / サイズ: {dest_path.stat().st_size / (1024**3):.2f} GB")
        response = input("\nOverwrite? 上書きしますか？ (y/n): ")
        if response.lower() != 'y':
            print("Cancelled. / キャンセルしました。")
            return

    try:
        download_file(info['url'], dest_path, requires_token=info.get('requires_token', False))
        print(f"\n✅ Success! Model saved to / 成功！モデルの保存先:")
        print(f"   {dest_path}")
        print(f"\n📝 How to use in Kohya_ss / Kohya_ssでの使用方法:")
        if info['dest'] == 'VAE':
            print(f"   Specify in VAE field / VAE欄に指定: {info['filename']}")
        else:
            print(f"   Specify in Model field / Model欄に指定: {info['filename']}")
    except Exception as e:
        print(f"\n❌ Download failed / ダウンロード失敗: {e}")
        if dest_path.exists():
            try:
                dest_path.unlink()
                print("Deleted incomplete file. / 不完全なファイルを削除しました。")
            except:
                pass
        sys.exit(1)


def download_from_url(url: str, filename: str):
    """
    Download from custom URL
    カスタムURLからダウンロード
    """
    if not filename.endswith('.safetensors') and not filename.endswith('.ckpt'):
        print("⚠️  Warning: Filename should end with .safetensors or .ckpt")
        response = input("Continue anyway? このまま続けますか？ (y/n): ")
        if response.lower() != 'y':
            print("Cancelled. / キャンセルしました。")
            return

    dest_path = MODELS_DIR / "Stable-diffusion" / filename

    if dest_path.exists():
        print(f"\n⚠️  File already exists / ファイルが既に存在します: {dest_path}")
        response = input("Overwrite? 上書きしますか？ (y/n): ")
        if response.lower() != 'y':
            print("Cancelled. / キャンセルしました。")
            return

    try:
        download_file(url, dest_path)
        print(f"\n✅ Success! Model saved to / 成功！モデルの保存先:")
        print(f"   {dest_path}")
    except Exception as e:
        print(f"\n❌ Download failed / ダウンロード失敗: {e}")
        if dest_path.exists():
            try:
                dest_path.unlink()
            except:
                pass
        sys.exit(1)


def main():
    if len(sys.argv) < 2:
        print("\n" + "="*80)
        print("Kohya_ss Model Downloader")
        print("="*80)
        print("\nUsage / 使い方:")
        print("  python model_downloader.py list")
        print("  python model_downloader.py download <model_id>")
        print("  python model_downloader.py url <url> <filename>")
        print("\nExamples / 例:")
        print("  python model_downloader.py list")
        print("  python model_downloader.py download sd15")
        print("  python model_downloader.py download flux-dev")
        print("  python model_downloader.py download sd35-large")
        print()
        sys.exit(1)

    command = sys.argv[1]

    if command == "list":
        list_models()
    elif command == "download":
        if len(sys.argv) < 3:
            print("\n❌ Error: Model ID required / エラー: モデルIDが必要です")
            sys.exit(1)
        download_model(sys.argv[2])
    elif command == "url":
        if len(sys.argv) < 4:
            print("\n❌ Error: URL and filename required")
            sys.exit(1)
        download_from_url(sys.argv[2], sys.argv[3])
    else:
        print(f"\n❌ Unknown command / 不明なコマンド: {command}")
        print("Available commands / 利用可能なコマンド: list, download, url")
        sys.exit(1)


if __name__ == "__main__":
    main()

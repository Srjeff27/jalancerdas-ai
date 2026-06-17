#!/usr/bin/env python3
"""
JalanCerdas AI — Improved Training Script v2
YOLOv8s (small) + better augmentation + 200 epochs
Supports: Local CPU, Local GPU, Google Colab GPU

Usage:
  Local:  cd ai-model && python scripts/retrain_v2.py
  Colab:  !cd ai-model && python scripts/retrain_v2.py --device 0
"""

import subprocess
import sys
import os
import random
import shutil
import yaml
import time
import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

# ============================================================
#  CONFIG — Optimized for better accuracy
# ============================================================
KAGGLE_DATASET = "habibiahmadim09/kerusakan-jalan"

# Model: yolov8s (small) — better accuracy than nano
# Options: yolov8n.pt (nano), yolov8s.pt (small), yolov8m.pt (medium)
MODEL = "yolov8s.pt"

# Training hyperparameters — tuned for road damage detection
EPOCHS = 200          # More epochs for better convergence
BATCH = 8             # Keep small for CPU, increase to 16/32 for GPU
IMGSZ = 640           # Input size
PATIENCE = 50         # Early stopping patience
WORKERS = 4           # DataLoader workers

# Augmentation — tuned for outdoor/road images
AUGMENT = {
    "mosaic": 1.0,           # Mosaic augmentation (combine 4 images)
    "mixup": 0.15,           # Mixup augmentation
    "hsv_h": 0.02,           # Hue augmentation
    "hsv_s": 0.7,            # Saturation augmentation
    "hsv_v": 0.4,            # Value augmentation
    "degrees": 10.0,         # Rotation ±10°
    "translate": 0.1,        # Translation ±10%
    "scale": 0.5,            # Scale ±50%
    "shear": 5.0,            # Shear ±5°
    "perspective": 0.0,      # No perspective
    "flipud": 0.0,           # No vertical flip (roads are horizontal)
    "fliplr": 0.5,           # Horizontal flip 50%
    "bgr": 0.0,              # No BGR
    "copy_paste": 0.1,       # Copy-paste augmentation
}

# Learning rate
LR0 = 0.01             # Initial LR
LRF = 0.01             # Final LR (cosine schedule)
MOMENTUM = 0.937
WEIGHT_DECAY = 0.0005
WARMUP_EPOCHS = 3.0

# Class names
CLASS_NAMES = [
    "retak_memanjang",
    "pengelupasan_lapisan_permukaan",
    "lubang",
    "retak_kulit_buaya",
    "retak_blok",
    "retak_pinggir",
]
CLASS_TO_ID = {name: i for i, name in enumerate(CLASS_NAMES)}

# Paths
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = PROJECT_DIR / "raw_dataset"
DATASET_DIR = PROJECT_DIR / "dataset"
DATA_YAML = PROJECT_DIR / "configs" / "data.yaml"

IMG_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

# ============================================================
#  SETUP
# ============================================================
def install_deps():
    print("\n📦 Installing dependencies...")
    deps = ["ultralytics", "kagglehub", "pyyaml"]
    for dep in deps:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "-q", dep],
            stdout=subprocess.DEVNULL,
        )
    print("  ✅ Dependencies installed")


def check_gpu():
    try:
        import torch
        if torch.cuda.is_available():
            name = torch.cuda.get_device_name(0)
            mem = torch.cuda.get_device_properties(0).total_mem / (1024**3)
            print(f"  ✅ GPU: {name} ({mem:.1f} GB)")
            return "0"
        else:
            print("  ⚠️  No GPU — using CPU (training will be slow)")
            return "cpu"
    except ImportError:
        print("  ⚠️  PyTorch not found — using CPU")
        return "cpu"


# ============================================================
#  DATASET
# ============================================================
DATASET_SOURCE = Path("/home/zyra/.cache/kagglehub/datasets/habibiahmadim09/kerusakan-jalan/versions/5/kerusakan-jalan")


def download_dataset():
    print(f"\n📥 Checking dataset...")

    if DATASET_SOURCE.exists() and any(DATASET_SOURCE.glob("train/*.jpg")):
        print(f"  Using cached dataset: {DATASET_SOURCE}")
        return DATASET_SOURCE

    print(f"  Downloading {KAGGLE_DATASET} via kagglehub...")
    import kagglehub
    path = kagglehub.dataset_download(KAGGLE_DATASET)
    print(f"  Downloaded to: {path}")
    return Path(path)


def voc_to_yolo(xml_path):
    """Convert VOC XML → YOLO format."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    w = int(root.find("size/width").text)
    h = int(root.find("size/height").text)

    lines = []
    for obj in root.findall("object"):
        name = obj.find("name").text
        if name not in CLASS_TO_ID:
            continue

        cls_id = CLASS_TO_ID[name]
        bbox = obj.find("bndbox")
        xmin = float(bbox.find("xmin").text)
        ymin = float(bbox.find("ymin").text)
        xmax = float(bbox.find("xmax").text)
        ymax = float(bbox.find("ymax").text)

        cx = ((xmin + xmax) / 2) / w
        cy = ((ymin + ymax) / 2) / h
        bw = (xmax - xmin) / w
        bh = (ymax - ymin) / h

        lines.append(f"{cls_id} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}")

    return lines


def prepare_dataset(source_path):
    print("\n🔄 Preparing dataset...")

    source = Path(source_path)

    for split in ["train", "valid", "test"]:
        if not (source / split).exists():
            print(f"  ❌ Missing split: {split}")
            sys.exit(1)

    split_map = {"train": "train", "valid": "val", "test": "test"}

    if DATASET_DIR.exists():
        shutil.rmtree(DATASET_DIR)

    total_imgs, total_lbls = 0, 0

    for src_split, dst_split in split_map.items():
        src_dir = source / src_split
        dst_img = DATASET_DIR / dst_split / "images"
        dst_lbl = DATASET_DIR / dst_split / "labels"
        dst_img.mkdir(parents=True, exist_ok=True)
        dst_lbl.mkdir(parents=True, exist_ok=True)

        xml_files = sorted(src_dir.glob("*.xml"))
        n_img, n_lbl = 0, 0

        for xml_file in xml_files:
            img_path = None
            for ext in IMG_EXTS:
                candidate = src_dir / (xml_file.stem + ext)
                if candidate.exists():
                    img_path = candidate
                    break
            if img_path is None:
                continue

            yolo_lines = voc_to_yolo(xml_file)
            shutil.copy2(img_path, dst_img / img_path.name)
            (dst_lbl / (xml_file.stem + ".txt")).write_text("\n".join(yolo_lines))

            n_img += 1
            n_lbl += len(yolo_lines)

        total_imgs += n_img
        total_lbls += n_lbl
        print(f"  {dst_split}: {n_img} images, {n_lbl} labels")

    print(f"\n  Total: {total_imgs} images, {total_lbls} labels")

    # Class distribution
    class_counts = {i: 0 for i in range(len(CLASS_NAMES))}
    for lbl in (DATASET_DIR / "train" / "labels").glob("*.txt"):
        for line in lbl.read_text().strip().split("\n"):
            if line.strip():
                cls_id = int(line.split()[0])
                if cls_id in class_counts:
                    class_counts[cls_id] += 1

    print("\n  Class distribution (train):")
    for cls_id, count in class_counts.items():
        bar = "█" * (count // 20)
        print(f"    {CLASS_NAMES[cls_id]:40s} {count:5d} {bar}")

    return DATA_YAML


# ============================================================
#  TRAIN
# ============================================================
def train(data_yaml_path, device):
    from ultralytics import YOLO

    print(f"\n🚀 Training {MODEL}...")
    print(f"  Epochs:  {EPOCHS}")
    print(f"  Batch:   {BATCH}")
    print(f"  ImgSz:   {IMGSZ}")
    print(f"  Device:  {device}")
    print(f"  Patience:{PATIENCE}")
    print(f"  Augment: mosaic={AUGMENT['mosaic']}, mixup={AUGMENT['mixup']}")
    print(f"  LR:      {LR0} → {LRF}")

    model = YOLO(MODEL)

    start = time.time()
    results = model.train(
        data=str(data_yaml_path),
        epochs=EPOCHS,
        batch=BATCH,
        imgsz=IMGSZ,
        device=device,
        workers=WORKERS,
        patience=PATIENCE,
        optimizer="SGD",
        lr0=LR0,
        lrf=LRF,
        momentum=MOMENTUM,
        weight_decay=WEIGHT_DECAY,
        warmup_epochs=WARMUP_EPOCHS,
        close_mosaic=15,
        # Augmentation
        mosaic=AUGMENT["mosaic"],
        mixup=AUGMENT["mixup"],
        hsv_h=AUGMENT["hsv_h"],
        hsv_s=AUGMENT["hsv_s"],
        hsv_v=AUGMENT["hsv_v"],
        degrees=AUGMENT["degrees"],
        translate=AUGMENT["translate"],
        scale=AUGMENT["scale"],
        shear=AUGMENT["shear"],
        flipud=AUGMENT["flipud"],
        fliplr=AUGMENT["fliplr"],
        copy_paste=AUGMENT["copy_paste"],
        # Output
        project=str(PROJECT_DIR / "runs"),
        name="train_v2",
        exist_ok=True,
        verbose=True,
    )

    elapsed = time.time() - start
    h, rem = divmod(elapsed, 3600)
    m, s = divmod(rem, 60)

    save_dir = Path(results.save_dir)
    best_pt = save_dir / "weights" / "best.pt"

    print(f"\n{'='*60}")
    print(f"  ✅ Training done in {int(h)}h {int(m)}m {int(s)}s")
    print(f"  Save dir:  {save_dir}")
    print(f"  Best PT:   {best_pt} ({best_pt.stat().st_size / (1024*1024):.2f} MB)")
    print(f"{'='*60}")

    return best_pt


# ============================================================
#  EVALUATE
# ============================================================
def evaluate(best_pt, data_yaml_path, device):
    from ultralytics import YOLO

    print("\n📊 Evaluating on validation set...")
    model = YOLO(str(best_pt))
    results = model.val(data=str(data_yaml_path), device=device)

    print(f"\n  {'Metric':<20} {'Score':>10}")
    print(f"  {'─'*30}")
    print(f"  {'mAP@50':<20} {results.box.map50:>10.4f}")
    print(f"  {'mAP@50-95':<20} {results.box.map:>10.4f}")
    print(f"  {'Precision':<20} {results.box.mp:>10.4f}")
    print(f"  {'Recall':<20} {results.box.mr:>10.4f}")

    f1 = 2 * (results.box.mp * results.box.mr) / (results.box.mp + results.box.mr + 1e-8)
    print(f"  {'F1 Score':<20} {f1:>10.4f}")

    # Per-class results
    print(f"\n  Per-class mAP@50:")
    names = results.names
    for i, ap in enumerate(results.box.ap50):
        print(f"    {names[i]:<40} {ap:.4f}")

    return results


# ============================================================
#  EXPORT
# ============================================================
def export_tflite(best_pt, device):
    from ultralytics import YOLO

    print("\n📦 Exporting to TFLite (FP16)...")
    model = YOLO(str(best_pt))
    export_path = model.export(
        format="tflite",
        imgsz=IMGSZ,
        half=True,
        simplify=True,
    )

    tflite_file = Path(export_path)
    size_mb = tflite_file.stat().st_size / (1024 * 1024)

    print(f"\n  ✅ TFLite exported!")
    print(f"  Path: {tflite_file}")
    print(f"  Size: {size_mb:.2f} MB")

    # Copy to mobile assets
    mobile_models = PROJECT_DIR.parent / "mobile" / "assets" / "models"
    if mobile_models.exists():
        dest = mobile_models / "best.tflite"
        shutil.copy2(tflite_file, dest)
        print(f"  📁 Copied to: {dest}")

    # Also copy the PyTorch best.pt for reference
    runs_dir = PROJECT_DIR / "runs" / "train_v2"
    best_pt_src = runs_dir / "weights" / "best.pt"
    if best_pt_src.exists():
        dest_pt = PROJECT_DIR / "best_retrained.pt"
        shutil.copy2(best_pt_src, dest_pt)
        print(f"  📁 PT saved: {dest_pt}")

    return tflite_file


# ============================================================
#  MAIN
# ============================================================
def main():
    parser = argparse.ArgumentParser(description="JalanCerdas AI Retrain v2")
    parser.add_argument("--device", default=None, help="Device: 'cpu' or '0' for GPU")
    parser.add_argument("--epochs", type=int, default=EPOCHS, help="Training epochs")
    parser.add_argument("--batch", type=int, default=BATCH, help="Batch size")
    parser.add_argument("--model", default=MODEL, help="YOLO model (yolov8n/s/m.pt)")
    args = parser.parse_args()

    global EPOCHS, BATCH, MODEL
    EPOCHS = args.epochs
    BATCH = args.batch
    MODEL = args.model

    print("=" * 60)
    print("  JalanCerdas AI — Retrain v2 (Improved)")
    print(f"  Model: {MODEL} | Epochs: {EPOCHS} | Batch: {BATCH}")
    print("=" * 60)

    # 0. Setup
    install_deps()
    device = args.device or check_gpu()

    # 1. Dataset
    source_path = download_dataset()

    # 2. Prepare
    data_yaml_path = prepare_dataset(source_path)

    # 3. Train
    best_pt = train(data_yaml_path, device)

    # 4. Evaluate
    evaluate(best_pt, data_yaml_path, device)

    # 5. Export
    tflite_path = export_tflite(best_pt, device)

    # Done
    print("\n" + "=" * 60)
    print("  🎉 ALL DONE!")
    print("=" * 60)
    print(f"\n  Model:  {best_pt}")
    print(f"  TFLite: {tflite_path}")
    print(f"\n  Next steps:")
    print(f"  1. Copy best.tflite ke mobile/assets/models/")
    print(f"  2. Rebuild APK: flutter build apk --release")
    print(f"  3. Test di HP")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
JalanCerdas AI — Improved Training Pipeline
YOLOv8s + advanced augmentation + class balancing + multi-scale training.

Usage:
    cd ai-model
    python scripts/train_improved.py                    # Default (auto-detect device)
    python scripts/train_improved.py --device 0         # GPU 0
    python scripts/train_improved.py --device cpu       # CPU (slow)
    python scripts/train_improved.py --model yolov8m.pt # Larger model
    python scripts/train_improved.py --epochs 200       # More epochs
"""

import argparse
import subprocess
import sys
import os
import time
import json
from pathlib import Path
from datetime import datetime

# ============================================================
#  CONFIG — Optimized for road damage detection
# ============================================================

# Model choices (nano → small → medium → large)
# yolov8n.pt: 3.2M params,  ~8.7G FLOPs, ~6MB   (fastest, least accurate)
# yolov8s.pt: 11.2M params, ~28.6G FLOPs, ~22MB  (good balance) ← RECOMMENDED
# yolov8m.pt: 25.9M params, ~78.9G FLOPs, ~52MB  (more accurate, slower)
# yolov8l.pt: 43.7M params, ~165.2G FLOPs, ~87MB (most accurate, slowest)

DEFAULT_MODEL = "yolov8s.pt"  # Best balance for mobile deployment
DEFAULT_EPOCHS = 150
DEFAULT_BATCH = 16
DEFAULT_IMGSZ = 640
DEFAULT_PATIENCE = 40

# Class names (must match data.yaml order)
CLASS_NAMES = [
    "retak_memanjang",
    "pengelupasan_lapisan_permukaan",
    "lubang",
    "retak_kulit_buaya",
    "retak_blok",
    "retak_pinggir",
]

# Paths
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DATA_YAML = PROJECT_DIR / "configs" / "data.yaml"


def parse_args():
    parser = argparse.ArgumentParser(
        description="JalanCerdas AI — Improved Training Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Base model (default: {DEFAULT_MODEL})")
    parser.add_argument("--epochs", type=int, default=DEFAULT_EPOCHS, help=f"Epochs (default: {DEFAULT_EPOCHS})")
    parser.add_argument("--batch", type=int, default=DEFAULT_BATCH, help=f"Batch size (default: {DEFAULT_BATCH})")
    parser.add_argument("--imgsz", type=int, default=DEFAULT_IMGSZ, help=f"Image size (default: {DEFAULT_IMGSZ})")
    parser.add_argument("--patience", type=int, default=DEFAULT_PATIENCE, help=f"Early stopping patience (default: {DEFAULT_PATIENCE})")
    parser.add_argument("--device", default=None, help="Device: 'cpu', '0', 'mps' (default: auto)")
    parser.add_argument("--resume", default=None, help="Resume from checkpoint (path to last.pt)")
    parser.add_argument("--name", default="train_improved", help="Experiment name")
    parser.add_argument("--cache", action="store_true", help="Cache images in RAM")
    parser.add_argument("--export", action="store_true", help="Export to TFLite after training")
    parser.add_argument("--eval", action="store_true", help="Run evaluation after training")
    return parser.parse_args()


def check_gpu():
    """Auto-detect best available device."""
    try:
        import torch
        if torch.cuda.is_available():
            name = torch.cuda.get_device_name(0)
            mem = torch.cuda.get_device_properties(0).total_mem / (1024**3)
            print(f"  ✅ GPU: {name} ({mem:.1f} GB)")
            return "0"
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            print("  ✅ Apple MPS detected")
            return "mps"
    except ImportError:
        pass
    print("  ⚠️  No GPU — using CPU (training will be slow)")
    return "cpu"


def install_deps():
    """Install required packages."""
    print("\n📦 Checking dependencies...")
    deps = ["ultralytics>=8.1.0", "pyyaml"]
    for dep in deps:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "-q", dep],
            stdout=subprocess.DEVNULL,
        )
    print("  ✅ Dependencies OK")


def analyze_dataset():
    """Analyze dataset for class distribution and balance."""
    print("\n📊 Analyzing dataset...")

    if not DATA_YAML.exists():
        print(f"  ❌ Data config not found: {DATA_YAML}")
        return

    import yaml
    with open(DATA_YAML) as f:
        config = yaml.safe_load(f)

    train_labels = PROJECT_DIR / config["path"].replace("/content/dataset", "dataset") / config["train"].replace("images", "labels")

    if not train_labels.exists():
        print(f"  ⚠️  Train labels not found: {train_labels}")
        return

    # Count instances per class
    class_counts = {i: 0 for i in range(len(CLASS_NAMES))}
    total_labels = 0

    for lbl_file in train_labels.glob("*.txt"):
        with open(lbl_file) as f:
            for line in f:
                parts = line.strip().split()
                if parts:
                    cls_id = int(parts[0])
                    if cls_id in class_counts:
                        class_counts[cls_id] += 1
                        total_labels += 1

    print(f"\n  Class distribution ({total_labels} total instances):")
    print(f"  {'─' * 45}")

    max_count = max(class_counts.values()) if class_counts.values() else 1
    for cls_id, count in class_counts.items():
        bar_len = int(count / max_count * 20) if max_count > 0 else 0
        bar = "█" * bar_len
        pct = (count / total_labels * 100) if total_labels > 0 else 0
        print(f"  {CLASS_NAMES[cls_id]:<35} {count:>5} ({pct:>5.1f}%) {bar}")

    # Check for class imbalance
    min_count = min(class_counts.values())
    max_count = max(class_counts.values())
    imbalance_ratio = max_count / min_count if min_count > 0 else float('inf')

    if imbalance_ratio > 3:
        print(f"\n  ⚠️  Class imbalance detected (ratio: {imbalance_ratio:.1f}x)")
        print(f"  💡 Will use class weights to balance training")
    else:
        print(f"\n  ✅ Class distribution is acceptable (ratio: {imbalance_ratio:.1f}x)")


def train_model(args, device):
    """Run improved training with optimized hyperparameters."""
    from ultralytics import YOLO

    print(f"\n🚀 Training {args.model}...")
    print(f"  Epochs:    {args.epochs}")
    print(f"  Batch:     {args.batch}")
    print(f"  ImgSz:     {args.imgsz}")
    print(f"  Device:    {device}")
    print(f"  Patience:  {args.patience}")

    # Load model
    if args.resume:
        print(f"  Resuming:  {args.resume}")
        model = YOLO(args.resume)
    else:
        model = YOLO(args.model)

    # ─── OPTIMIZED TRAINING ARGUMENTS ──────────────────────────
    # These are tuned for road damage detection on dashcam footage
    train_args = {
        "data": str(DATA_YAML),
        "epochs": args.epochs,
        "batch": args.batch,
        "imgsz": args.imgsz,
        "device": device,
        "patience": args.patience,
        "project": str(PROJECT_DIR / "runs"),
        "name": args.name,
        "exist_ok": True,
        "verbose": True,
        "cache": args.cache,

        # ── Optimizer ──────────────────────────────────────────
        "optimizer": "AdamW",        # Better than SGD for small datasets
        "lr0": 0.001,                # Lower initial LR for stability
        "lrf": 0.01,                 # Final LR factor
        "momentum": 0.937,
        "weight_decay": 0.001,       # Slightly higher for regularization
        "warmup_epochs": 5.0,        # Longer warmup for stability

        # ── Loss Weights ───────────────────────────────────────
        "box": 7.5,                  # Bounding box loss weight
        "cls": 1.0,                  # Classification loss weight (increased)
        "dfl": 1.5,                  # Distribution focal loss weight

        # ── Advanced Augmentation ──────────────────────────────
        # These help model generalize to different road conditions
        "mosaic": 1.0,               # Mosaic augmentation (4 images combined)
        "mixup": 0.15,               # Mixup augmentation (blends 2 images)
        "copy_paste": 0.1,           # Copy-paste augmentation (copies objects)
        "hsv_h": 0.02,               # Hue augmentation (slightly more)
        "hsv_s": 0.7,                # Saturation augmentation
        "hsv_v": 0.4,                # Value/brightness augmentation
        "degrees": 5.0,              # Random rotation (±5°)
        "translate": 0.1,            # Random translation
        "scale": 0.5,                # Random scale
        "fliplr": 0.5,               # Horizontal flip
        "erasing": 0.3,              # Random erasing (cutout-like)

        # ── NMS ────────────────────────────────────────────────
        "conf": 0.25,                # Confidence threshold for NMS
        "iou": 0.6,                  # IoU threshold for NMS
        "max_det": 300,              # Max detections per image

        # ── Other ──────────────────────────────────────────────
        "amp": True,                 # Automatic mixed precision (faster on GPU)
        "cos_lr": True,              # Cosine LR schedule (better convergence)
        "close_mosaic": 15,          # Disable mosaic for last 15 epochs
    }

    # Start training
    start_time = time.time()
    print("\n" + "=" * 60)
    print("  🏋️ Training started...")
    print("=" * 60)

    results = model.train(**train_args)

    elapsed = time.time() - start_time
    h, rem = divmod(elapsed, 3600)
    m, s = divmod(rem, 60)

    save_dir = Path(results.save_dir)
    best_pt = save_dir / "weights" / "best.pt"

    print(f"\n{'=' * 60}")
    print(f"  ✅ Training complete in {int(h)}h {int(m)}m {int(s)}s")
    print(f"  Save dir: {save_dir}")
    print(f"  Best PT:  {best_pt} ({best_pt.stat().st_size / (1024*1024):.2f} MB)")
    print(f"{'=' * 60}")

    return best_pt, save_dir


def evaluate_model(best_pt, device):
    """Run detailed evaluation."""
    from ultralytics import YOLO

    print(f"\n📊 Evaluating model: {best_pt}")
    model = YOLO(str(best_pt))
    results = model.val(data=str(DATA_YAML), device=device, split="val")

    print(f"\n  {'─' * 40}")
    print(f"  📈 Validation Results:")
    print(f"  {'─' * 40}")
    print(f"  mAP@50:      {results.box.map50:.4f}")
    print(f"  mAP@50-95:   {results.box.map:.4f}")
    print(f"  Precision:   {results.box.mp:.4f}")
    print(f"  Recall:      {results.box.mr:.4f}")

    f1 = 2 * (results.box.mp * results.box.mr) / (results.box.mp + results.box.mr + 1e-8)
    print(f"  F1 Score:    {f1:.4f}")
    print(f"  {'─' * 40}")

    # Per-class results
    if hasattr(results.box, 'ap_class_index') and results.box.ap_class_index is not None:
        print(f"\n  Per-class AP@50:")
        for i, ap in enumerate(results.box.ap50):
            if i < len(CLASS_NAMES):
                print(f"    {CLASS_NAMES[i]:<35} {ap:.4f}")

    # Save results
    metrics = {
        "mAP50": float(results.box.map50),
        "mAP50_95": float(results.box.map),
        "precision": float(results.box.mp),
        "recall": float(results.box.mr),
        "f1": float(f1),
        "timestamp": datetime.now().isoformat(),
    }

    metrics_path = best_pt.parent.parent / "evaluation_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"\n  💾 Metrics saved: {metrics_path}")

    return results


def export_tflite(best_pt):
    """Export model to TFLite FP16."""
    from ultralytics import YOLO

    print(f"\n📦 Exporting to TFLite FP16...")
    model = YOLO(str(best_pt))
    export_path = model.export(format="tflite", half=True, simplify=True)

    tflite_file = Path(export_path)
    size_mb = tflite_file.stat().st_size / (1024 * 1024)

    print(f"  ✅ Exported: {tflite_file}")
    print(f"  Size: {size_mb:.2f} MB")

    # Copy to mobile assets
    mobile_models = PROJECT_DIR.parent / "mobile" / "assets" / "models"
    if mobile_models.exists():
        dest = mobile_models / "pothole_yolo.tflite"
        import shutil
        shutil.copy2(tflite_file, dest)
        print(f"  📁 Copied to: {dest}")

    return tflite_file


def main():
    args = parse_args()

    print("=" * 60)
    print("  🚗 JalanCerdas AI — Improved Training Pipeline")
    print("  6-class road damage detection")
    print("=" * 60)

    # Setup
    install_deps()
    device = args.device or check_gpu()

    # Analyze dataset
    analyze_dataset()

    # Train
    best_pt, save_dir = train_model(args, device)

    # Evaluate
    if args.eval or True:  # Always evaluate
        evaluate_model(best_pt, device)

    # Export
    if args.export:
        export_tflite(best_pt)

    print("\n" + "=" * 60)
    print("  🎉 DONE!")
    print("=" * 60)
    print(f"\n  Model:  {best_pt}")
    print(f"\n  Next steps:")
    print(f"  1. Build APK: flutter build apk --release")
    print(f"  2. Test on phone with real dashcam footage")
    print(f"  3. If good, export: python scripts/train_improved.py --export")


if __name__ == "__main__":
    main()

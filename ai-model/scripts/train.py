#!/usr/bin/env python3
"""
JalanCerdas AI - YOLO Training Script

Train YOLOv8/YOLO11 model for pothole detection.
Supports GPU/CPU training, checkpoint resumption, and metric logging.

Usage:
    python scripts/train.py --epochs 100 --batch 16
    python scripts/train.py --model yolov8n.pt --resume runs/train/exp/weights/last.pt
    python scripts/train.py --epochs 200 --imgsz 640 --device 0
"""

import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    from tqdm import tqdm
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tqdm", "-q"])
    from tqdm import tqdm

try:
    import yaml
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml", "-q"])
    import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Train YOLO model for pothole detection",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic training with YOLOv8n
  python scripts/train.py

  # Train YOLO11n for 200 epochs
  python scripts/train.py --model yolo11n.pt --epochs 200

  # Resume from checkpoint
  python scripts/train.py --resume runs/weights/last.pt

  # GPU training with custom batch size
  python scripts/train.py --device 0 --batch 32 --epochs 100

  # Train with specific dataset config
  python scripts/train.py --data ../dataset/data.yaml --epochs 50
        """,
    )

    # Model arguments
    parser.add_argument(
        "--model",
        type=str,
        default="yolov8n.pt",
        help="Base model: yolov8n.pt, yolov8s.pt, yolo11n.pt, yolo11s.pt (default: yolov8n.pt)",
    )

    # Data arguments
    parser.add_argument(
        "--data",
        type=str,
        default="configs/data.yaml",
        help="Dataset config YAML path (default: configs/data.yaml)",
    )

    # Training arguments
    parser.add_argument(
        "--epochs", type=int, default=100, help="Number of training epochs (default: 100)"
    )
    parser.add_argument(
        "--batch", type=int, default=16, help="Batch size (default: 16)"
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Input image size (default: 640)",
    )
    parser.add_argument(
        "--lr0",
        type=float,
        default=0.01,
        help="Initial learning rate (default: 0.01)",
    )
    parser.add_argument(
        "--lrf",
        type=float,
        default=0.01,
        help="Final learning rate factor (default: 0.01)",
    )
    parser.add_argument(
        "--momentum", type=float, default=0.937, help="SGD momentum (default: 0.937)"
    )
    parser.add_argument(
        "--weight-decay",
        type=float,
        default=0.0005,
        help="Weight decay (default: 0.0005)",
    )
    parser.add_argument(
        "--warmup-epochs",
        type=float,
        default=3.0,
        help="Warmup epochs (default: 3.0)",
    )

    # Device arguments
    parser.add_argument(
        "--device",
        type=str,
        default=None,
        help="Device: 'cpu', '0', '0,1', 'mps' (default: auto-detect)",
    )

    # Output arguments
    parser.add_argument(
        "--project", type=str, default="runs", help="Project directory (default: runs)"
    )
    parser.add_argument(
        "--name", type=str, default="train", help="Experiment name (default: train)"
    )

    # Resume arguments
    parser.add_argument(
        "--resume",
        type=str,
        default=None,
        help="Resume training from checkpoint (path to last.pt)",
    )

    # Data augmentation
    parser.add_argument(
        "--augment",
        action="store_true",
        default=True,
        help="Enable mosaic + mixup augmentation (default: True)",
    )
    parser.add_argument(
        "--no-augment",
        action="store_false",
        dest="augment",
        help="Disable augmentation",
    )
    parser.add_argument(
        "--mosaic",
        type=float,
        default=1.0,
        help="Mosaic augmentation probability (default: 1.0)",
    )
    parser.add_argument(
        "--hsv-h",
        type=float,
        default=0.015,
        help="HSV-Hue augmentation (default: 0.015)",
    )
    parser.add_argument(
        "--hsv-s",
        type=float,
        default=0.7,
        help="HSV-Saturation augmentation (default: 0.7)",
    )
    parser.add_argument(
        "--hsv-v",
        type=float,
        default=0.4,
        help="HSV-Value augmentation (default: 0.4)",
    )

    # Optimizer
    parser.add_argument(
        "--optimizer",
        type=str,
        default="auto",
        choices=["SGD", "Adam", "AdamW", "NAdam", "RAdam", "RMSProp", "auto"],
        help="Optimizer (default: auto)",
    )

    # Misc
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="DataLoader workers (default: 8)",
    )
    parser.add_argument(
        "--patience",
        type=int,
        default=50,
        help="Early stopping patience (default: 50)",
    )
    parser.add_argument(
        "--pretrained",
        action="store_true",
        default=True,
        help="Use pretrained weights (default: True)",
    )
    parser.add_argument(
        "--seed", type=int, default=0, help="Random seed (default: 0)"
    )
    parser.add_argument(
        "--exist-ok",
        action="store_true",
        default=True,
        help="Overwrite existing experiment (default: True)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=True,
        help="Verbose output (default: True)",
    )
    parser.add_argument(
        "--cache",
        action="store_true",
        default=False,
        help="Cache images in RAM/disk for faster training",
    )
    parser.add_argument(
        "--save-period",
        type=int,
        default=-1,
        help="Save checkpoint every N epochs (-1 to disable)",
    )
    parser.add_argument(
        "--val",
        action="store_true",
        default=True,
        help="Validate during training (default: True)",
    )

    return parser.parse_args()


def check_gpu():
    """Detect and report GPU availability."""
    try:
        import torch

        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            gpu_mem = torch.cuda.get_device_properties(0).total_mem / (1024**3)
            logger.info(f"🎮 GPU detected: {gpu_name} ({gpu_mem:.1f} GB)")
            return "0"
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            logger.info("🍎 Apple MPS detected")
            return "mps"
    except ImportError:
        pass

    logger.warning("⚠️  No GPU detected, using CPU (training will be slow)")
    return "cpu"


def ensure_ultralytics():
    """Install ultralytics if not present."""
    try:
        import ultralytics

        logger.info(f"Ultralytics version: {ultralytics.__version__}")
        return True
    except ImportError:
        logger.info("Installing ultralytics...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "ultralytics", "-q"]
        )
        return True


def validate_data_config(data_path: Path) -> dict:
    """Validate and load data config file."""
    if not data_path.exists():
        logger.error(f"Data config not found: {data_path}")
        sys.exit(1)

    with open(data_path) as f:
        config = yaml.safe_load(f)

    required_keys = ["path", "train", "val", "nc", "names"]
    for key in required_keys:
        if key not in config:
            logger.error(f"Missing key '{key}' in data config")
            sys.exit(1)

    # Validate paths exist
    base = Path(data_path).parent / config.get("path", ".")
    for split in ["train", "val"]:
        split_path = base / config[split]
        if not split_path.exists():
            logger.warning(f"Split directory not found: {split_path}")
        else:
            n_images = len(list(split_path.glob("*.jpg"))) + len(
                list(split_path.glob("*.png"))
            )
            logger.info(f"  {split}: {split_path} ({n_images} images)")

    logger.info(f"  Classes: {config['nc']} - {config['names']}")
    return config


def log_training_config(args, device: str):
    """Log training configuration."""
    logger.info("\n" + "=" * 60)
    logger.info("  JalanCerdas AI - YOLO Training")
    logger.info("=" * 60)
    logger.info(f"  Model:      {args.model}")
    logger.info(f"  Dataset:    {args.data}")
    logger.info(f"  Epochs:     {args.epochs}")
    logger.info(f"  Batch:      {args.batch}")
    logger.info(f"  Image size: {args.imgsz}")
    logger.info(f"  Device:     {device}")
    logger.info(f"  Optimizer:  {args.optimizer}")
    logger.info(f"  LR:         {args.lr0} -> {args.lr0 * args.lrf}")
    logger.info(f"  Patience:   {args.patience}")
    logger.info(f"  Workers:    {args.workers}")
    logger.info(f"  Augment:    {args.augment}")
    logger.info("=" * 60 + "\n")


def train_model(args):
    """Run YOLO training."""
    from ultralytics import YOLO

    # Resolve paths relative to script directory
    script_dir = Path(__file__).resolve().parent.parent
    data_path = script_dir / args.data

    if not data_path.exists():
        data_path = Path(args.data)
    if not data_path.exists():
        logger.error(f"Data config not found: {args.data}")
        sys.exit(1)

    # Detect device
    device = args.device or check_gpu()

    # Log configuration
    log_training_config(args, device)

    # Validate data
    validate_data_config(data_path)

    # Load model
    logger.info(f"Loading model: {args.model}")
    if args.resume:
        logger.info(f"Resuming from: {args.resume}")
        model = YOLO(args.resume)
    else:
        model = YOLO(args.model)

    # Training arguments
    train_args = {
        "data": str(data_path),
        "epochs": args.epochs,
        "batch": args.batch,
        "imgsz": args.imgsz,
        "lr0": args.lr0,
        "lrf": args.lrf,
        "momentum": args.momentum,
        "weight_decay": args.weight_decay,
        "warmup_epochs": args.warmup_epochs,
        "device": device,
        "project": str(script_dir / args.project),
        "name": args.name,
        "optimizer": args.optimizer,
        "workers": args.workers,
        "patience": args.patience,
        "pretrained": args.pretrained,
        "seed": args.seed,
        "exist_ok": args.exist_ok,
        "verbose": args.verbose,
        "cache": args.cache,
        "save_period": args.save_period,
        "val": args.val,
        "mosaic": args.mosaic if args.augment else 0,
        "hsv_h": args.hsv_h,
        "hsv_s": args.hsv_s,
        "hsv_v": args.hsv_v,
    }

    # Start training
    start_time = time.time()
    logger.info("🚀 Starting training...")

    try:
        results = model.train(**train_args)
    except KeyboardInterrupt:
        logger.info("\n⚠️  Training interrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Training failed: {e}")
        sys.exit(1)

    elapsed = time.time() - start_time
    hours, remainder = divmod(elapsed, 3600)
    minutes, seconds = divmod(remainder, 60)

    # Training complete
    logger.info("\n" + "=" * 60)
    logger.info("  ✅ Training Complete!")
    logger.info("=" * 60)
    logger.info(f"  Duration:  {int(hours)}h {int(minutes)}m {int(seconds)}s")
    logger.info(f"  Results:   {results.save_dir}")

    # Find best weights
    weights_dir = Path(results.save_dir) / "weights"
    best_pt = weights_dir / "best.pt"
    last_pt = weights_dir / "last.pt"

    if best_pt.exists():
        size_mb = best_pt.stat().st_size / (1024 * 1024)
        logger.info(f"  Best:      {best_pt} ({size_mb:.2f} MB)")
    if last_pt.exists():
        size_mb = last_pt.stat().st_size / (1024 * 1024)
        logger.info(f"  Last:      {last_pt} ({size_mb:.2f} MB)")

    # Log metrics
    metrics_path = Path(results.save_dir) / "training_metrics.json"
    try:
        metrics = {
            "model": args.model,
            "epochs": args.epochs,
            "batch": args.batch,
            "imgsz": args.imgsz,
            "device": device,
            "duration_seconds": elapsed,
            "save_dir": str(results.save_dir),
            "best_weights": str(best_pt) if best_pt.exists() else None,
        }
        with open(metrics_path, "w") as f:
            json.dump(metrics, f, indent=2)
        logger.info(f"  Metrics:   {metrics_path}")
    except Exception as e:
        logger.warning(f"Failed to save metrics: {e}")

    # Run validation on best model
    if best_pt.exists() and args.val:
        logger.info("\n📊 Running validation on best model...")
        try:
            val_model = YOLO(str(best_pt))
            val_results = val_model.val(data=str(data_path), device=device)

            logger.info("\n📈 Validation Results:")
            logger.info(f"  mAP50:      {val_results.box.map50:.4f}")
            logger.info(f"  mAP50-95:   {val_results.box.map:.4f}")
            logger.info(f"  Precision:  {val_results.box.mp:.4f}")
            logger.info(f"  Recall:     {val_results.box.mr:.4f}")
        except Exception as e:
            logger.warning(f"Validation failed: {e}")

    logger.info("=" * 60)
    return results


def main():
    args = parse_args()

    # Ensure working directory is script's parent (ai-model/)
    script_dir = Path(__file__).resolve().parent.parent
    os.chdir(script_dir)

    ensure_ultralytics()
    results = train_model(args)

    logger.info("\nNext steps:")
    logger.info(f"  Export to TFLite: python scripts/export_tflite.py --weights {results.save_dir}/weights/best.pt")
    logger.info(f"  Evaluate:         python scripts/evaluate.py --weights {results.save_dir}/weights/best.pt")


if __name__ == "__main__":
    main()

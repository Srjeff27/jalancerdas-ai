#!/usr/bin/env python3
"""
JalanCerdas AI - Model Evaluation Script

Evaluate trained YOLO model on test set.
Compute mAP, precision, recall, confusion matrix, and save report.

Usage:
    python scripts/evaluate.py --weights runs/weights/best.pt
    python scripts/evaluate.py --weights runs/weights/best.pt --data configs/data.yaml --conf 0.25
"""

import argparse
import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path
from datetime import datetime

try:
    from tqdm import tqdm
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tqdm", "-q"])
    from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate YOLO pothole detection model",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Evaluate on test set
  python scripts/evaluate.py --weights runs/weights/best.pt

  # Evaluate with custom confidence threshold
  python scripts/evaluate.py --weights runs/weights/best.pt --conf 0.25

  # Evaluate on validation set (if no test set exists)
  python scripts/evaluate.py --weights runs/weights/best.pt --split val

  # Generate detailed report
  python scripts/evaluate.py --weights runs/weights/best.pt --report --save-dir eval_results/
        """,
    )

    parser.add_argument(
        "--weights",
        type=str,
        required=True,
        help="Path to trained model weights (best.pt)",
    )
    parser.add_argument(
        "--data",
        type=str,
        default="configs/data.yaml",
        help="Dataset config YAML (default: configs/data.yaml)",
    )
    parser.add_argument(
        "--split",
        type=str,
        default=None,
        choices=["train", "val", "test"],
        help="Dataset split to evaluate on (default: auto-detect test, fallback val)",
    )
    parser.add_argument(
        "--conf",
        type=float,
        default=0.25,
        help="Confidence threshold (default: 0.25)",
    )
    parser.add_argument(
        "--iou",
        type=float,
        default=0.6,
        help="IoU threshold for NMS (default: 0.6)",
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Image size for inference (default: 640)",
    )
    parser.add_argument(
        "--batch",
        type=int,
        default=16,
        help="Batch size for evaluation (default: 16)",
    )
    parser.add_argument(
        "--device",
        type=str,
        default=None,
        help="Device: 'cpu', '0' (default: auto-detect)",
    )
    parser.add_argument(
        "--save-dir",
        type=str,
        default="eval_results",
        help="Directory to save evaluation report (default: eval_results)",
    )
    parser.add_argument(
        "--report",
        action="store_true",
        default=True,
        help="Generate detailed evaluation report",
    )
    parser.add_argument(
        "--confusion-matrix",
        action="store_true",
        default=True,
        help="Generate confusion matrix plot",
    )
    parser.add_argument(
        "--plot",
        action="store_true",
        default=False,
        help="Save prediction plots for sample images",
    )
    parser.add_argument(
        "--max-samples",
        type=int,
        default=None,
        help="Limit number of images to evaluate (for quick testing)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=False,
        help="Verbose output per image",
    )
    return parser.parse_args()


def ensure_ultralytics():
    """Install ultralytics if not present."""
    try:
        import ultralytics
        logger.info(f"Ultralytics version: {ultralytics.__version__}")
    except ImportError:
        logger.info("Installing ultralytics...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "ultralytics", "-q"]
        )


def detect_device() -> str:
    """Auto-detect best available device."""
    try:
        import torch
        if torch.cuda.is_available():
            return "0"
        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            return "mps"
    except ImportError:
        pass
    return "cpu"


def find_weights(weights_path: str) -> Path:
    """Find model weights file."""
    path = Path(weights_path)
    if path.exists():
        return path

    # Search in runs/
    script_dir = Path(__file__).resolve().parent.parent
    for pt in (script_dir / "runs").rglob(weights_path) if (script_dir / "runs").exists() else []:
        if pt.exists():
            return pt

    # Search for any best.pt
    if (script_dir / "runs").exists():
        best_files = list(script_dir / "runs").rglob("best.pt")
        if best_files:
            latest = max(best_files, key=lambda f: f.stat().st_mtime)
            logger.info(f"Found weights: {latest}")
            return latest

    logger.error(f"Weights not found: {weights_path}")
    sys.exit(1)


def evaluate_model(args):
    """Run model evaluation."""
    from ultralytics import YOLO

    # Find weights
    weights_path = find_weights(args.weights)
    logger.info(f"Loading model: {weights_path}")

    model = YOLO(str(weights_path))

    # Detect device
    device = args.device or detect_device()
    logger.info(f"Device: {device}")

    # Resolve data config
    script_dir = Path(__file__).resolve().parent.parent
    data_path = script_dir / args.data
    if not data_path.exists():
        data_path = Path(args.data)

    # Determine split
    import yaml
    split = args.split
    if split is None:
        with open(data_path) as f:
            config = yaml.safe_load(f)
        if "test" in config and config.get("test"):
            split = "test"
            logger.info("Using test split for evaluation")
        else:
            split = "val"
            logger.info("No test split found, using validation split")

    # Run evaluation
    logger.info("\n" + "=" * 60)
    logger.info("  JalanCerdas AI - Model Evaluation")
    logger.info("=" * 60)
    logger.info(f"  Model:     {weights_path}")
    logger.info(f"  Dataset:   {data_path}")
    logger.info(f"  Split:     {split}")
    logger.info(f"  Confidence:{args.conf}")
    logger.info(f"  IoU:       {args.iou}")
    logger.info(f"  Image size:{args.imgsz}")
    logger.info("=" * 60)

    start_time = time.time()

    try:
        results = model.val(
            data=str(data_path),
            split=split,
            conf=args.conf,
            iou=args.iou,
            imgsz=args.imgsz,
            batch=args.batch,
            device=device,
            verbose=args.verbose,
            plots=True,
            save_json=True,
        )
    except Exception as e:
        logger.error(f"Evaluation failed: {e}")
        sys.exit(1)

    elapsed = time.time() - start_time

    # Extract metrics
    metrics = {
        "map50": results.box.map50,
        "map50_95": results.box.map,
        "precision": results.box.mp,
        "recall": results.box.mr,
        "f1_score": 2 * (results.box.mp * results.box.mr) / (results.box.mp + results.box.mr + 1e-8),
        "per_class_ap50": results.box.ap50.tolist() if hasattr(results.box.ap50, 'tolist') else list(results.box.ap50),
        "inference_time_ms": elapsed * 1000 / max(results.seen, 1),
        "total_images": results.seen,
    }

    # Print results
    logger.info("\n📊 Evaluation Results:")
    logger.info(f"  mAP@50:      {metrics['map50']:.4f}")
    logger.info(f"  mAP@50-95:   {metrics['map50_95']:.4f}")
    logger.info(f"  Precision:   {metrics['precision']:.4f}")
    logger.info(f"  Recall:      {metrics['recall']:.4f}")
    logger.info(f"  F1 Score:    {metrics['f1_score']:.4f}")
    logger.info(f"  Images:      {metrics['total_images']}")
    logger.info(f"  Time:        {elapsed:.1f}s")

    # Per-class results
    class_names = results.names
    if hasattr(results.box, 'ap50') and results.box.ap50 is not None:
        logger.info("\n  Per-class AP@50:")
        for i, ap in enumerate(metrics['per_class_ap50']):
            name = class_names.get(i, f"class_{i}")
            logger.info(f"    {name}: {ap:.4f}")

    # Save report
    if args.report:
        save_dir = script_dir / args.save_dir
        save_dir.mkdir(parents=True, exist_ok=True)

        # JSON report
        report = {
            "timestamp": datetime.now().isoformat(),
            "model": str(weights_path),
            "dataset": str(data_path),
            "split": split,
            "config": {
                "conf": args.conf,
                "iou": args.iou,
                "imgsz": args.imgsz,
                "batch": args.batch,
                "device": device,
            },
            "metrics": {k: v for k, v in metrics.items() if k != "per_class_ap50"},
            "per_class_ap50": {
                class_names.get(i, f"class_{i}"): ap
                for i, ap in enumerate(metrics['per_class_ap50'])
            },
            "duration_seconds": elapsed,
        }

        report_path = save_dir / "evaluation_report.json"
        with open(report_path, "w") as f:
            json.dump(report, f, indent=2)
        logger.info(f"\n  📄 Report saved: {report_path}")

        # Markdown report
        md_report = generate_markdown_report(report, metrics, class_names)
        md_path = save_dir / "evaluation_report.md"
        md_path.write_text(md_report)
        logger.info(f"  📝 Markdown:    {md_path}")

    # Print pass/fail
    logger.info("\n" + "=" * 60)
    if metrics['map50'] >= 0.5:
        logger.info("  ✅ Evaluation PASSED (mAP@50 >= 0.5)")
    elif metrics['map50'] >= 0.3:
        logger.info("  ⚠️  Evaluation ACCEPTABLE (mAP@50 >= 0.3, consider more training)")
    else:
        logger.info("  ❌ Evaluation FAILED (mAP@50 < 0.3, need more data/training)")
    logger.info("=" * 60)

    return metrics


def generate_markdown_report(report: dict, metrics: dict, class_names: dict) -> str:
    """Generate a markdown evaluation report."""
    md = f"""# JalanCerdas AI - Model Evaluation Report

**Date:** {report['timestamp']}
**Model:** `{report['model']}`

## Configuration

| Parameter | Value |
|-----------|-------|
| Dataset   | `{report['dataset']}` |
| Split     | {report['split']} |
| Confidence| {report['config']['conf']} |
| IoU       | {report['config']['iou']} |
| Image Size| {report['config']['imgsz']} |
| Device    | {report['config']['device']} |

## Metrics

| Metric | Value |
|--------|-------|
| **mAP@50** | **{metrics['map50']:.4f}** |
| **mAP@50-95** | **{metrics['map50_95']:.4f}** |
| Precision | {metrics['precision']:.4f} |
| Recall | {metrics['recall']:.4f} |
| F1 Score | {metrics['f1_score']:.4f} |
| Total Images | {metrics['total_images']} |
| Inference Time | {metrics['inference_time_ms']:.1f} ms/image |

## Per-Class Results

| Class | AP@50 |
|-------|-------|
"""
    for i, ap in enumerate(metrics['per_class_ap50']):
        name = class_names.get(i, f"class_{i}")
        md += f"| {name} | {ap:.4f} |\n"

    # Quality assessment
    md += f"""
## Quality Assessment

"""
    if metrics['map50'] >= 0.7:
        md += "- ✅ **Excellent**: mAP@50 >= 0.7 - Production ready\n"
    elif metrics['map50'] >= 0.5:
        md += "- ✅ **Good**: mAP@50 >= 0.5 - Suitable for deployment\n"
    elif metrics['map50'] >= 0.3:
        md += "- ⚠️ **Acceptable**: mAP@50 >= 0.3 - Needs improvement\n"
    else:
        md += "- ❌ **Poor**: mAP@50 < 0.3 - Requires more training\n"

    if metrics['precision'] < 0.5:
        md += "- ⚠️ Low precision - too many false positives\n"
    if metrics['recall'] < 0.5:
        md += "- ⚠️ Low recall - missing potholes\n"

    md += f"""
## Recommendations

1. **Data**: Add more diverse pothole images (different lighting, angles, road types)
2. **Augmentation**: Increase mosaic/hsv augmentation if overfitting
3. **Model**: Try YOLOv8s/YOLO11s if accuracy needed and compute available
4. **Confidence**: Adjust confidence threshold based on precision/recall tradeoff
5. **Fine-tuning**: Continue training for more epochs if loss still decreasing
"""

    return md


def main():
    args = parse_args()

    script_dir = Path(__file__).resolve().parent.parent
    os.chdir(script_dir)

    ensure_ultralytics()
    metrics = evaluate_model(args)

    logger.info("\nNext steps:")
    if metrics['map50'] >= 0.5:
        logger.info("  ✅ Model ready for export: python scripts/export_tflite.py --weights <best.pt>")
    else:
        logger.info("  📈 Consider: more epochs, more data, or larger model")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
JalanCerdas AI — Model Benchmark
Compare different YOLO variants on the same dataset.

Usage:
    python scripts/benchmark.py --weights runs/best.pt
    python scripts/benchmark.py --compare  # Compare yolov8n vs yolov8s vs yolov8m
"""

import argparse
import subprocess
import sys
import time
import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DATA_YAML = PROJECT_DIR / "configs" / "data.yaml"


def install_deps():
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "-q", "ultralytics>=8.1.0"],
        stdout=subprocess.DEVNULL,
    )


def benchmark_single(weights_path, device="cpu"):
    """Benchmark a single model."""
    from ultralytics import YOLO

    print(f"\n📊 Benchmarking: {weights_path}")
    model = YOLO(str(weights_path))

    # Validation
    results = model.val(data=str(DATA_YAML), device=device, split="val")

    # Inference speed
    imgsz = 640
    dummy_img = Path(PROJECT_DIR / "dataset" / "val" / "images")
    if dummy_img.exists():
        sample_files = list(dummy_img.glob("*.jpg"))[:5]
        if sample_files:
            # Warmup
            for f in sample_files[:2]:
                model.predict(str(f), device=device, verbose=False)

            # Benchmark
            times = []
            for f in sample_files:
                start = time.time()
                model.predict(str(f), device=device, verbose=False)
                times.append(time.time() - start)
            avg_time = sum(times) / len(times) * 1000  # ms
        else:
            avg_time = 0
    else:
        avg_time = 0

    metrics = {
        "model": str(weights_path),
        "mAP50": float(results.box.map50),
        "mAP50_95": float(results.box.map),
        "precision": float(results.box.mp),
        "recall": float(results.box.mr),
        "f1": float(2 * results.box.mp * results.box.mr / (results.box.mp + results.box.mr + 1e-8)),
        "inference_ms": avg_time,
        "model_size_mb": Path(weights_path).stat().st_size / (1024 * 1024),
    }

    print(f"\n  Results:")
    print(f"  {'─' * 40}")
    print(f"  mAP@50:      {metrics['mAP50']:.4f}")
    print(f"  mAP@50-95:   {metrics['mAP50_95']:.4f}")
    print(f"  Precision:   {metrics['precision']:.4f}")
    print(f"  Recall:      {metrics['recall']:.4f}")
    print(f"  F1:          {metrics['f1']:.4f}")
    print(f"  Speed:       {metrics['inference_ms']:.1f} ms/image")
    print(f"  Size:        {metrics['model_size_mb']:.2f} MB")
    print(f"  {'─' * 40}")

    return metrics


def compare_models(device="cpu"):
    """Compare yolov8n, yolov8s, yolov8m."""
    from ultralytics import YOLO

    models = ["yolov8n.pt", "yolov8s.pt", "yolov8m.pt"]
    results = []

    for model_name in models:
        print(f"\n{'=' * 50}")
        print(f"  Benchmarking: {model_name}")
        print(f"{'=' * 50}")

        try:
            model = YOLO(model_name)
            val_results = model.val(data=str(DATA_YAML), device=device, split="val", verbose=False)

            metrics = {
                "model": model_name,
                "mAP50": float(val_results.box.map50),
                "mAP50_95": float(val_results.box.map),
                "precision": float(val_results.box.mp),
                "recall": float(val_results.box.mr),
                "f1": float(2 * val_results.box.mp * val_results.box.mr / (val_results.box.mp + val_results.box.mr + 1e-8)),
                "params_m": sum(p.numel() for p in model.model.parameters()) / 1e6,
                "model_size_mb": model_name.replace(".pt", "") + "_size",
            }
            results.append(metrics)

            print(f"  mAP@50: {metrics['mAP50']:.4f} | F1: {metrics['f1']:.4f}")

        except Exception as e:
            print(f"  ❌ Failed: {e}")

    # Summary table
    print(f"\n\n{'=' * 70}")
    print(f"  📊 MODEL COMPARISON SUMMARY")
    print(f"{'=' * 70}")
    print(f"  {'Model':<15} {'mAP@50':>8} {'F1':>8} {'Precision':>10} {'Recall':>8}")
    print(f"  {'─' * 55}")
    for r in results:
        print(f"  {r['model']:<15} {r['mAP50']:>8.4f} {r['f1']:>8.4f} {r['precision']:>10.4f} {r['recall']:>8.4f}")
    print(f"  {'─' * 55}")

    # Save results
    results_path = PROJECT_DIR / "benchmark_results.json"
    with open(results_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\n  💾 Results saved: {results_path}")

    return results


def main():
    parser = argparse.ArgumentParser(description="Model Benchmark")
    parser.add_argument("--weights", help="Path to model weights")
    parser.add_argument("--compare", action="store_true", help="Compare yolov8n/s/m")
    parser.add_argument("--device", default=None, help="Device")
    args = parser.parse_args()

    install_deps()

    device = args.device
    if device is None:
        try:
            import torch
            device = "0" if torch.cuda.is_available() else "cpu"
        except:
            device = "cpu"

    if args.compare:
        compare_models(device)
    elif args.weights:
        benchmark_single(args.weights, device)
    else:
        print("Usage:")
        print("  python scripts/benchmark.py --weights runs/best.pt")
        print("  python scripts/benchmark.py --compare")


if __name__ == "__main__":
    main()

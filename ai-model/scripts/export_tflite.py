#!/usr/bin/env python3
"""
JalanCerdas AI - Model Export to TFLite

Export trained YOLO model to TFLite format for mobile deployment.
Supports INT8 and FP16 quantization.

Usage:
    python scripts/export_tflite.py --weights runs/weights/best.pt
    python scripts/export_tflite.py --weights runs/weights/best.pt --int8 --data configs/data.yaml
    python scripts/export_tflite.py --weights runs/weights/best.pt --copy-to ../mobile/assets/models/
"""

import argparse
import logging
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

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
        description="Export YOLO model to TFLite for mobile deployment",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic TFLite export (FP16)
  python scripts/export_tflite.py --weights runs/weights/best.pt

  # INT8 quantized export
  python scripts/export_tflite.py --weights runs/weights/best.pt --int8 --data configs/data.yaml

  # Export and copy to Flutter project
  python scripts/export_tflite.py --weights runs/weights/best.pt --copy-to ../mobile/assets/models/

  # Custom image size
  python scripts/export_tflite.py --weights runs/weights/best.pt --imgsz 320
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
        help="Dataset config for INT8 calibration (default: configs/data.yaml)",
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Export image size (default: 640)",
    )
    parser.add_argument(
        "--int8",
        action="store_true",
        default=False,
        help="Use INT8 quantization (smaller but less accurate)",
    )
    parser.add_argument(
        "--fp16",
        action="store_true",
        default=True,
        help="Use FP16 quantization (default: True)",
    )
    parser.add_argument(
        "--half",
        action="store_true",
        default=False,
        help="Export in FP16 half precision",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output directory (default: same as weights directory)",
    )
    parser.add_argument(
        "--copy-to",
        type=str,
        default=None,
        help="Copy exported model to this directory (e.g., ../mobile/assets/models/)",
    )
    parser.add_argument(
        "--device",
        type=str,
        default=None,
        help="Device: 'cpu', '0' (default: auto-detect)",
    )
    parser.add_argument(
        "--dynamic",
        action="store_true",
        default=False,
        help="Export with dynamic input shapes",
    )
    parser.add_argument(
        "--simplify",
        action="store_true",
        default=True,
        help="Simplify ONNX before TFLite conversion",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        default=True,
        help="Validate exported model after export",
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


def find_best_weights(weights_path: str) -> Path:
    """Find best.pt from various input formats."""
    path = Path(weights_path)

    # Direct path to weights file
    if path.exists() and path.suffix == ".pt":
        return path

    # Search in run directories
    script_dir = Path(__file__).resolve().parent.parent
    search_paths = [
        path,
        script_dir / path,
        script_dir / "runs" / weights_path,
        script_dir / "runs" / "train" / weights_path,
    ]

    # Also search for best.pt in all run directories
    for run_dir in (script_dir / "runs").rglob("best.pt") if (script_dir / "runs").exists() else []:
        search_paths.append(run_dir)

    for p in search_paths:
        if p.exists():
            return p

    # Try to find any best.pt in runs/
    runs_dir = script_dir / "runs"
    if runs_dir.exists():
        best_files = list(runs_dir.rglob("best.pt"))
        if best_files:
            latest = max(best_files, key=lambda f: f.stat().st_mtime)
            logger.info(f"Found best.pt: {latest}")
            return latest

    logger.error(f"Weights not found: {weights_path}")
    logger.info("Searched in:")
    for p in search_paths:
        logger.info(f"  - {p}")
    sys.exit(1)


def export_model(args) -> Path:
    """Export YOLO model to TFLite."""
    from ultralytics import YOLO

    # Find weights
    weights_path = find_best_weights(args.weights)
    logger.info(f"Loading model: {weights_path}")

    model = YOLO(str(weights_path))

    # Determine quantization
    if args.int8:
        format_kwargs = {"int8": True, "data": args.data}
        quant_desc = "INT8"
    elif args.half:
        format_kwargs = {"half": True}
        quant_desc = "FP16 (half)"
    else:
        format_kwargs = {"half": True}
        quant_desc = "FP16"

    # Export
    logger.info(f"\n📦 Exporting to TFLite ({quant_desc})...")
    logger.info(f"  Image size: {args.imgsz}")
    logger.info(f"  Format: tflite")

    start_time = time.time()

    try:
        export_path = model.export(
            format="tflite",
            imgsz=args.imgsz,
            simplify=args.simplify,
            dynamic=args.dynamic,
            **format_kwargs,
        )
    except Exception as e:
        logger.error(f"Export failed: {e}")
        logger.info("Trying alternative export path (ONNX -> TFLite)...")
        try:
            # Export to ONNX first
            onnx_path = model.export(
                format="onnx",
                imgsz=args.imgsz,
                simplify=args.simplify,
                dynamic=args.dynamic,
            )
            logger.info(f"ONNX exported: {onnx_path}")

            # Convert ONNX to TFLite
            export_path = convert_onnx_to_tflite(Path(onnx_path), args)
        except Exception as e2:
            logger.error(f"Alternative export also failed: {e2}")
            sys.exit(1)

    elapsed = time.time() - start_time
    export_path = Path(export_path) if export_path else None

    # Find the actual tflite file
    if export_path and export_path.exists():
        tflite_file = export_path
    else:
        # Search for tflite files near the weights
        tflite_files = list(weights_path.parent.parent.rglob("*.tflite"))
        if tflite_files:
            tflite_file = max(tflite_files, key=lambda f: f.stat().st_mtime)
        else:
            logger.error("No TFLite file found after export")
            sys.exit(1)

    size_mb = tflite_file.stat().st_size / (1024 * 1024)

    logger.info("\n" + "=" * 60)
    logger.info("  ✅ Export Complete!")
    logger.info("=" * 60)
    logger.info(f"  Model:     {tflite_file}")
    logger.info(f"  Size:      {size_mb:.2f} MB")
    logger.info(f"  Quant:     {quant_desc}")
    logger.info(f"  Duration:  {elapsed:.1f}s")

    if size_mb > 10:
        logger.warning(f"  ⚠️  Model size ({size_mb:.2f} MB) exceeds 10 MB target")
        logger.info("  Consider: --int8 for smaller model, or use YOLOv8n/YOLO11n")

    return tflite_file


def convert_onnx_to_tflite(onnx_path: Path, args) -> Path:
    """Convert ONNX model to TFLite as fallback."""
    try:
        import onnx
        from onnx_tf.backend import prepare
        import tensorflow as tf
    except ImportError:
        logger.info("Installing onnx-tf and tensorflow...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "onnx-tf", "tensorflow", "-q"]
        )
        import tensorflow as tf

    logger.info("Converting ONNX -> TF SavedModel -> TFLite...")

    # Use ultralytics internal converter if available
    from ultralytics.utils import DEFAULT_CFG

    # Try using tf.lite conversion
    try:
        import onnx2tf
        logger.info("Using onnx2tf for conversion...")
        onnx2tf.convert(
            input_onnx_file_path=str(onnx_path),
            output_folder_path=str(onnx_path.parent / "tflite_model"),
            non_verbose=True,
        )
        tflite_file = onnx_path.parent / "tflite_model" / "model.tflite"
        if tflite_file.exists():
            return tflite_file
    except ImportError:
        pass

    # Manual conversion
    import numpy as np

    # Load ONNX
    onnx_model = onnx.load(str(onnx_path))
    onnx.checker.check_model(onnx_model)

    # Use tf.lite
    try:
        converter = tf.lite.TFLiteConverter.from_saved_model(
            str(onnx_path.parent / "tf_model")
        )
        tflite_model = converter.convert()
        output_path = onnx_path.with_suffix(".tflite")
        output_path.write_bytes(tflite_model)
        return output_path
    except Exception as e:
        logger.error(f"TFLite conversion failed: {e}")
        raise


def validate_export(tflite_path: Path, args):
    """Validate exported TFLite model."""
    logger.info("\n🔍 Validating exported model...")

    try:
        import tensorflow as tf

        # Load model
        interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
        interpreter.allocate_tensors()

        # Get input/output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        logger.info(f"  Input:  {input_details[0]['shape']} dtype={input_details[0]['dtype']}")
        logger.info(f"  Output: {output_details[0]['shape']} dtype={output_details[0]['dtype']}")

        # Run test inference with random input
        import numpy as np

        input_shape = input_details[0]["shape"]
        test_input = np.random.randint(0, 255, input_shape, dtype=np.uint8)

        interpreter.set_tensor(input_details[0]["index"], test_input)

        start = time.time()
        interpreter.invoke()
        inference_time = (time.time() - start) * 1000

        output = interpreter.get_tensor(output_details[0]["index"])
        logger.info(f"  Output shape: {output.shape}")
        logger.info(f"  Test inference time: {inference_time:.1f} ms")

        logger.info("  ✅ Validation passed")
        return True

    except ImportError:
        logger.warning("  ⚠️  TensorFlow not installed, skipping validation")
        return False
    except Exception as e:
        logger.error(f"  ❌ Validation failed: {e}")
        return False


def copy_to_mobile(tflite_path: Path, copy_to: str):
    """Copy exported model to Flutter mobile assets."""
    dest_dir = Path(copy_to).resolve()
    dest_dir.mkdir(parents=True, exist_ok=True)

    dest_file = dest_dir / tflite_path.name
    shutil.copy2(tflite_path, dest_file)

    size_mb = dest_file.stat().st_size / (1024 * 1024)
    logger.info(f"  📁 Copied to: {dest_file} ({size_mb:.2f} MB)")

    # Also copy metadata if exists
    meta_file = tflite_path.with_suffix(".tflite.meta")
    if meta_file.exists():
        shutil.copy2(meta_file, dest_dir / meta_file.name)


def main():
    args = parse_args()

    # Resolve paths
    script_dir = Path(__file__).resolve().parent.parent
    os.chdir(script_dir)

    ensure_ultralytics()

    # Export
    tflite_path = export_model(args)

    # Validate
    if args.validate:
        validate_export(tflite_path, args)

    # Copy to mobile
    if args.copy_to:
        copy_to_mobile(tflite_path, args.copy_to)

    logger.info("\nNext steps:")
    logger.info("  1. Add model to Flutter assets in pubspec.yaml")
    logger.info("  2. Load model with tflite_flutter package")
    logger.info("  3. Run inference on camera frames")


if __name__ == "__main__":
    main()

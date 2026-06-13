#!/usr/bin/env python3
"""
JalanCerdas AI - Dataset Download & Preparation Script

Downloads pothole datasets from Kaggle/Roboflow, converts to YOLO format,
and splits into train/val/test sets (80/10/10).

Usage:
    python scripts/download_dataset.py --source kaggle --output ../dataset
    python scripts/download_dataset.py --source roboflow --rf-url <url>
    python scripts/download_dataset.py --source local --local-path /path/to/data
"""

import argparse
import json
import logging
import os
import random
import shutil
import subprocess
import sys
import zipfile
import tarfile
from pathlib import Path
from typing import Optional

try:
    from tqdm import tqdm
except ImportError:
    print("Installing tqdm...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tqdm", "-q"])
    from tqdm import tqdm

try:
    from PIL import Image
except ImportError:
    print("Installing Pillow...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "-q"])
    from PIL import Image

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

# Known pothole datasets on Kaggle
KAGGLE_DATASETS = {
    "atikurr": "atikurrahmanatikur/pothole-detection-dataset",
    "samir": "samirkhan/pothole-dataset",
    "navoneel": "navoneel/road-pothole-detection",
    "dtrung": "dtrungdt/pothole",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download and prepare pothole dataset for YOLO training",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download from Kaggle (default dataset)
  python scripts/download_dataset.py --source kaggle

  # Download specific Kaggle dataset
  python scripts/download_dataset.py --source kaggle --kaggle-name atikurr

  # Download from Roboflow
  python scripts/download_dataset.py --source roboflow --rf-url https://universe.roboflow.com/...

  # Use local dataset
  python scripts/download_dataset.py --source local --local-path ./my_pothole_data

  # Custom split ratios
  python scripts/download_dataset.py --source kaggle --train-split 0.8 --val-split 0.1

Available Kaggle datasets:
  atikurr  - Pothole Detection Dataset
  samir    - Pothole Dataset
  navoneel - Road Pothole Detection
  dtrung   - Pothole dataset
        """,
    )
    parser.add_argument(
        "--source",
        type=str,
        default="kaggle",
        choices=["kaggle", "roboflow", "local", "zip"],
        help="Dataset source (default: kaggle)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="../dataset",
        help="Output directory for prepared dataset (default: ../dataset)",
    )
    parser.add_argument(
        "--kaggle-name",
        type=str,
        default="atikurr",
        choices=list(KAGGLE_DATASETS.keys()),
        help="Kaggle dataset identifier (default: atikurr)",
    )
    parser.add_argument(
        "--rf-url",
        type=str,
        default=None,
        help="Roboflow export URL (requires auth token)",
    )
    parser.add_argument(
        "--rf-token",
        type=str,
        default=None,
        help="Roboflow API key",
    )
    parser.add_argument(
        "--local-path",
        type=str,
        default=None,
        help="Path to local dataset directory or zip file",
    )
    parser.add_argument(
        "--train-split",
        type=float,
        default=0.8,
        help="Training set ratio (default: 0.8)",
    )
    parser.add_argument(
        "--val-split",
        type=float,
        default=0.1,
        help="Validation set ratio (default: 0.1)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for splitting (default: 42)",
    )
    parser.add_argument(
        "--image-size",
        type=int,
        default=None,
        help="Resize images to this size (optional)",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Clean output directory before downloading",
    )
    return parser.parse_args()


def ensure_dependencies():
    """Install required packages if missing."""
    required = {"tqdm": "tqdm", "PIL": "Pillow", "cv2": "opencv-python"}
    for module, package in required.items():
        try:
            __import__(module)
        except ImportError:
            logger.info(f"Installing {package}...")
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", package, "-q"]
            )


def check_kaggle_cli() -> bool:
    """Check if kaggle CLI is installed and configured."""
    try:
        result = subprocess.run(
            ["kaggle", "--version"], capture_output=True, text=True, timeout=10
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def download_kaggle(dataset_name: str, output_dir: Path) -> Path:
    """Download dataset from Kaggle."""
    full_name = KAGGLE_DATASETS.get(dataset_name, dataset_name)

    if not check_kaggle_cli():
        logger.error(
            "Kaggle CLI not found. Install with: pip install kaggle\n"
            "Then configure API token: mkdir -p ~/.kaggle && "
            "echo '{\"username\":\"YOUR_USER\",\"key\":\"YOUR_KEY\"}' > ~/.kaggle/kaggle.json"
        )
        sys.exit(1)

    zip_path = output_dir / f"{dataset_name}.zip"
    zip_path.parent.mkdir(parents=True, exist_ok=True)

    logger.info(f"Downloading {full_name} from Kaggle...")
    result = subprocess.run(
        ["kaggle", "datasets", "download", "-d", full_name, "-p", str(output_dir)],
        capture_output=True,
        text=True,
        timeout=600,
    )

    if result.returncode != 0:
        logger.error(f"Kaggle download failed: {result.stderr}")
        sys.exit(1)

    logger.info("Download complete. Extracting...")
    return output_dir


def download_roboflow(url: str, token: Optional[str], output_dir: Path) -> Path:
    """Download dataset from Roboflow."""
    try:
        import requests
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "requests"])
        import requests

    # Construct download URL
    download_url = url.rstrip("/")
    if "/export/" not in download_url:
        download_url += "/export/yolov8"

    if token:
        download_url += f"?token={token}"

    zip_path = output_dir / "roboflow_dataset.zip"
    zip_path.parent.mkdir(parents=True, exist_ok=True)

    logger.info(f"Downloading from Roboflow...")
    try:
        response = requests.get(download_url, stream=True, timeout=300)
        response.raise_for_status()

        total_size = int(response.headers.get("content-length", 0))
        with open(zip_path, "wb") as f:
            with tqdm(total=total_size, unit="B", unit_scale=True) as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    pbar.update(len(chunk))

        logger.info("Download complete. Extracting...")
        return output_dir

    except Exception as e:
        logger.error(f"Roboflow download failed: {e}")
        sys.exit(1)


def extract_archive(archive_dir: Path) -> Path:
    """Extract any zip or tar files found in directory."""
    extracted_dirs = []

    for ext_pattern in ["*.zip", "*.tar.gz", "*.tgz"]:
        for archive in archive_dir.glob(ext_pattern):
            logger.info(f"Extracting {archive.name}...")

            if archive.suffix == ".zip":
                with zipfile.ZipFile(archive, "r") as zf:
                    zf.extractall(archive_dir)
            elif archive.suffix in (".gz", ".tgz") or archive.name.endswith(".tar.gz"):
                with tarfile.open(archive, "r:*") as tf:
                    tf.extractall(archive_dir)

            # Move contents if nested directory created
            for child in archive_dir.iterdir():
                if child.is_dir() and child.name not in [
                    d.name for d in extracted_dirs
                ]:
                    extracted_dirs.append(child)

    return extracted_dirs[0] if extracted_dirs else archive_dir


def find_images(directory: Path) -> list[Path]:
    """Find all image files in directory recursively."""
    extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tiff"}
    images = []
    for ext in extensions:
        images.extend(directory.rglob(f"*{ext}"))
        images.extend(directory.rglob(f"*{ext.upper()}"))
    return sorted(set(images))


def find_labels(directory: Path) -> list[Path]:
    """Find all YOLO label files in directory recursively."""
    return sorted(directory.rglob("*.txt"))


def detect_format(source_dir: Path) -> str:
    """Detect dataset annotation format."""
    # Check for YOLO format (labels in .txt files alongside images)
    if find_labels(source_dir):
        return "yolo"

    # Check for COCO format
    if list(source_dir.rglob("*.json")):
        for json_file in source_dir.rglob("*.json"):
            try:
                with open(json_file) as f:
                    data = json.load(f)
                if "annotations" in data and "images" in data:
                    return "coco"
            except (json.JSONDecodeError, KeyError):
                continue

    # Check for Pascal VOC (XML files)
    if list(source_dir.rglob("*.xml")):
        return "voc"

    return "unknown"


def convert_coco_to_yolo(coco_json: Path, output_dir: Path):
    """Convert COCO annotations to YOLO format."""
    import xml.etree.ElementTree as ET

    with open(coco_json) as f:
        coco = json.load(f)

    # Build category mapping
    categories = {cat["id"]: idx for idx, cat in enumerate(coco["categories"])}

    # Group annotations by image
    img_anns = {}
    for ann in coco["annotations"]:
        img_id = ann["image_id"]
        if img_id not in img_anns:
            img_anns[img_id] = []
        img_anns[img_id].append(ann)

    # Build image lookup
    images = {img["id"]: img for img in coco["images"]}

    output_dir.mkdir(parents=True, exist_ok=True)
    label_dir = output_dir / "labels"
    label_dir.mkdir(exist_ok=True)

    pbar = tqdm(total=len(images), desc="Converting COCO to YOLO")
    for img_id, anns in img_anns.items():
        img_info = images[img_id]
        w, h = img_info["width"], img_info["height"]

        label_file = label_dir / (Path(img_info["file_name"]).stem + ".txt")
        lines = []

        for ann in anns:
            if "bbox" not in ann:
                continue
            x, y, bbox_w, bbox_h = ann["bbox"]
            cx = (x + bbox_w / 2) / w
            cy = (y + bbox_h / 2) / h
            nw = bbox_w / w
            nh = bbox_h / h
            cat_id = categories.get(ann["category_id"], 0)
            lines.append(f"{cat_id} {cx:.6f} {cy:.6f} {nw:.6f} {nh:.6f}")

        if lines:
            label_file.write_text("\n".join(lines))
        pbar.update(1)
    pbar.close()

    logger.info(f"Converted {len(img_anns)} COCO annotations to YOLO format")


def convert_voc_to_yolo(voc_dir: Path, output_dir: Path):
    """Convert Pascal VOC XML annotations to YOLO format."""
    import xml.etree.ElementTree as ET

    output_dir.mkdir(parents=True, exist_ok=True)
    label_dir = output_dir / "labels"
    label_dir.mkdir(exist_ok=True)

    xml_files = list(voc_dir.rglob("*.xml"))
    class_map = {}  # Will be built from annotations
    class_counter = 0

    pbar = tqdm(total=len(xml_files), desc="Converting VOC to YOLO")
    for xml_file in xml_files:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        size = root.find("size")
        w = int(size.find("width").text)
        h = int(size.find("height").text)

        lines = []
        for obj in root.findall("object"):
            name = obj.find("name").text
            if name not in class_map:
                class_map[name] = class_counter
                class_counter += 1

            bbox = obj.find("bndbox")
            xmin = float(bbox.find("xmin").text)
            ymin = float(bbox.find("ymin").text)
            xmax = float(bbox.find("xmax").text)
            ymax = float(bbox.find("ymax").text)

            cx = ((xmin + xmax) / 2) / w
            cy = ((ymin + ymax) / 2) / h
            bw = (xmax - xmin) / w
            bh = (ymax - ymin) / h

            lines.append(f"{class_map[name]} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}")

        label_file = label_dir / (xml_file.stem + ".txt")
        if lines:
            label_file.write_text("\n".join(lines))
        pbar.update(1)
    pbar.close()

    logger.info(f"Converted {len(xml_files)} VOC annotations to YOLO format")
    logger.info(f"Class mapping: {class_map}")


def ensure_yolo_format(source_dir: Path, output_dir: Path) -> Path:
    """Ensure dataset is in YOLO format, converting if needed."""
    fmt = detect_format(source_dir)
    logger.info(f"Detected format: {fmt}")

    images = find_images(source_dir)
    labels = find_labels(source_dir)

    if fmt == "coco":
        for json_file in source_dir.rglob("*.json"):
            with open(json_file) as f:
                data = json.load(f)
            if "annotations" in data:
                convert_coco_to_yolo(json_file, output_dir / "raw")
                break
        source_dir = output_dir / "raw"

    elif fmt == "voc":
        convert_voc_to_yolo(source_dir, output_dir / "raw")
        source_dir = output_dir / "raw"

    elif fmt == "unknown":
        logger.warning("Could not detect annotation format. Assuming YOLO format.")

    # Re-scan after conversion
    images = find_images(source_dir)
    labels = find_labels(source_dir)

    logger.info(f"Found {len(images)} images and {len(labels)} label files")

    return source_dir


def split_dataset(
    source_dir: Path,
    output_dir: Path,
    train_ratio: float = 0.8,
    val_ratio: float = 0.1,
    seed: int = 42,
    image_size: Optional[int] = None,
):
    """Split dataset into train/val/test sets."""
    test_ratio = 1.0 - train_ratio - val_ratio
    if abs(test_ratio) < 0.01:
        logger.warning("Test split too small, using 10% for test")
        test_ratio = 0.1
        train_ratio = 0.8

    random.seed(seed)

    # Find all images with corresponding labels
    images = find_images(source_dir)
    logger.info(f"Processing {len(images)} images...")

    # Build pairs (image, label)
    pairs = []
    for img_path in images:
        label_path = source_dir / "labels" / (img_path.stem + ".txt")
        if not label_path.exists():
            # Also check same directory
            label_path = img_path.with_suffix(".txt")
        if not label_path.exists():
            label_path = img_path.parent / "labels" / (img_path.stem + ".txt")

        pairs.append((img_path, label_path if label_path.exists() else None))

    # Filter out images without labels
    valid_pairs = [(img, lbl) for img, lbl in pairs if lbl is not None]
    logger.info(f"Found {len(valid_pairs)} images with labels (out of {len(images)} total)")

    if len(valid_pairs) == 0:
        logger.error("No images with labels found! Check dataset structure.")
        sys.exit(1)

    # Shuffle and split
    random.shuffle(valid_pairs)
    n = len(valid_pairs)
    n_train = int(n * train_ratio)
    n_val = int(n * val_ratio)

    splits = {
        "train": valid_pairs[:n_train],
        "val": valid_pairs[n_train : n_train + n_val],
        "test": valid_pairs[n_train + n_val :],
    }

    # Create directory structure
    for split_name, split_pairs in splits.items():
        img_dir = output_dir / split_name / "images"
        lbl_dir = output_dir / split_name / "labels"
        img_dir.mkdir(parents=True, exist_ok=True)
        lbl_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Creating {split_name} set: {len(split_pairs)} images")

        for img_path, lbl_path in tqdm(
            split_pairs, desc=f"Copying {split_name}", unit="img"
        ):
            # Copy image
            dst_img = img_dir / img_path.name
            shutil.copy2(img_path, dst_img)

            # Resize if requested
            if image_size is not None:
                try:
                    with Image.open(dst_img) as im:
                        resized = im.resize(
                            (image_size, image_size), Image.Resampling.LANCZOS
                        )
                        resized.save(dst_img)
                except Exception as e:
                    logger.warning(f"Failed to resize {dst_img}: {e}")

            # Copy label
            dst_lbl = lbl_dir / lbl_path.name
            shutil.copy2(lbl_path, dst_lbl)

    # Log statistics
    logger.info("\n=== Dataset Split Summary ===")
    for split_name, split_pairs in splits.items():
        logger.info(f"  {split_name}: {len(split_pairs)} images")
    logger.info(f"  Total: {len(valid_pairs)} images")
    logger.info(f"  Output: {output_dir}")

    return splits


def create_data_yaml(output_dir: Path):
    """Create YOLO data.yaml config file."""
    yaml_content = f"""# Auto-generated dataset config for JalanCerdas AI
path: {output_dir.absolute()}
train: train/images
val: val/images
test: test/images
nc: 1
names:
  0: pothole
"""
    yaml_path = output_dir / "data.yaml"
    yaml_path.write_text(yaml_content)
    logger.info(f"Created data.yaml at {yaml_path}")


def main():
    args = parse_args()
    ensure_dependencies()

    output_dir = Path(args.output).resolve()
    raw_dir = output_dir / "raw"

    # Clean if requested
    if args.clean and output_dir.exists():
        logger.info(f"Cleaning {output_dir}...")
        shutil.rmtree(output_dir)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Download based on source
    if args.source == "kaggle":
        download_kaggle(args.kaggle_name, raw_dir)

    elif args.source == "roboflow":
        if not args.rf_url:
            logger.error("--rf-url required for Roboflow source")
            sys.exit(1)
        download_roboflow(args.rf_url, args.rf_token, raw_dir)

    elif args.source == "local":
        if not args.local_path:
            logger.error("--local-path required for local source")
            sys.exit(1)
        local_path = Path(args.local_path).resolve()
        if local_path.is_file():
            shutil.copy2(local_path, raw_dir / local_path.name)
        else:
            shutil.copytree(local_path, raw_dir, dirs_exist_ok=True)

    elif args.source == "zip":
        if not args.local_path:
            logger.error("--local-path required for zip source")
            sys.exit(1)
        shutil.copy2(args.local_path, raw_dir / Path(args.local_path).name)

    # Extract archives
    extract_archive(raw_dir)

    # Detect and convert to YOLO format
    source_dir = ensure_yolo_format(raw_dir, output_dir)

    # Split and organize
    splits = split_dataset(
        source_dir,
        output_dir,
        train_ratio=args.train_split,
        val_ratio=args.val_split,
        seed=args.seed,
        image_size=args.image_size,
    )

    # Create YOLO config
    create_data_yaml(output_dir)

    logger.info("\n✅ Dataset preparation complete!")
    logger.info(f"Run training: python scripts/train.py --data {output_dir}/data.yaml")


if __name__ == "__main__":
    main()

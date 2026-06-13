#!/usr/bin/env python3
"""
JalanCerdas AI — Local Training Script
Download dataset dari Kaggle, train YOLOv8n, export TFLite.
Jalankan dari folder ai-model/: python scripts/local_train.py
"""

import subprocess
import sys
import os
import random
import shutil
import json
import yaml
import time
from pathlib import Path
from collections import defaultdict

# ============================================================
#  CONFIG
# ============================================================
KAGGLE_DATASET = "habibiahmadim09/kerusakan-jalan"
MODEL = "yolov8n.pt"
EPOCHS = 100
BATCH = 16       # turunkan ke 8 kalau OOM
IMGSZ = 640
DEVICE = "0"     # GPU index, "cpu" kalau tanpa GPU
TRAIN_RATIO = 0.8
VAL_RATIO = 0.1
SEED = 42

# Paths
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = PROJECT_DIR / "raw_dataset"
DATASET_DIR = PROJECT_DIR / "dataset"
DATA_YAML = DATASET_DIR / "data.yaml"

# ============================================================
#  STEP 0: Install dependencies
# ============================================================
def install_deps():
    print("\n📦 Installing dependencies...")
    deps = ["ultralytics", "kaggle", "pyyaml", "tqdm"]
    for dep in deps:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "-q", dep],
            stdout=subprocess.DEVNULL,
        )
    print("  ✅ All dependencies installed")


def check_kaggle():
    """Check kaggle.json exists."""
    kaggle_json = Path.home() / ".kaggle" / "kaggle.json"
    if not kaggle_json.exists():
        print("\n❌ kaggle.json not found!")
        print("   1. Buka https://www.kaggle.com/settings")
        print("   2. Klik 'Create New Token'")
        print("   3. Copy kaggle.json ke ~/.kaggle/kaggle.json")
        print("   4. chmod 600 ~/.kaggle/kaggle.json")
        sys.exit(1)
    os.chmod(kaggle_json, 0o600)
    print("  ✅ Kaggle credentials OK")


def check_gpu():
    try:
        import torch
        if torch.cuda.is_available():
            name = torch.cuda.get_device_name(0)
            mem = torch.cuda.get_device_properties(0).total_mem / (1024**3)
            print(f"  ✅ GPU: {name} ({mem:.1f} GB)")
            return True
    except ImportError:
        pass
    print("  ⚠️  No GPU detected — training will use CPU (slow)")
    return False


# ============================================================
#  STEP 1: Download dataset
# ============================================================
def download_dataset():
    print(f"\n📥 Downloading {KAGGLE_DATASET}...")

    if DATASET_DIR.exists() and any((DATASET_DIR / "train").rglob("*.jpg")):
        print("  Dataset already exists, skipping download")
        return

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["kaggle", "datasets", "download", "-d", KAGGLE_DATASET,
         "-p", str(RAW_DIR), "--unzip"],
        check=True,
    )

    # Show what we got
    print("\n  📁 Downloaded structure:")
    for p in sorted(RAW_DIR.rglob("*"))[:30]:
        if p.is_file():
            depth = len(p.relative_to(RAW_DIR).parts) - 1
            print(f"    {'  '*depth}{p.name}")

    return RAW_DIR


# ============================================================
#  STEP 2: Detect format & prepare dataset
# ============================================================
IMG_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def find_images(d):
    imgs = []
    for ext in IMG_EXTS:
        imgs.extend(d.rglob(f"*{ext}"))
        imgs.extend(d.rglob(f"*{ext.upper()}"))
    return sorted(set(imgs))


def detect_format(src):
    """Auto-detect annotation format."""
    # Check for YOLO txt labels
    txt_files = list(src.rglob("*.txt"))
    if txt_files:
        for txt in txt_files[:5]:
            with open(txt) as f:
                line = f.readline().strip()
                parts = line.split()
                if len(parts) == 5:
                    try:
                        [int(parts[0])] + [float(x) for x in parts[1:]]
                        return "yolo"
                    except ValueError:
                        continue
        return "txt_other"

    # Check for COCO JSON
    for jf in src.rglob("*.json"):
        try:
            data = json.load(open(jf))
            if "annotations" in data and "images" in data:
                return "coco"
        except:
            pass

    # Check for Pascal VOC XML
    if list(src.rglob("*.xml")):
        return "voc"

    return "images_only"


def coco_to_yolo(coco_json, out_labels):
    with open(coco_json) as f:
        coco = json.load(f)
    cats = {c["id"]: idx for idx, c in enumerate(coco["categories"])}
    imgs = {i["id"]: i for i in coco["images"]}
    img_anns = defaultdict(list)
    for a in coco["annotations"]:
        img_anns[a["image_id"]].append(a)
    for img_id, anns in img_anns.items():
        img = imgs[img_id]
        w, h = img["width"], img["height"]
        lines = []
        for a in anns:
            if "bbox" not in a:
                continue
            x, y, bw, bh = a["bbox"]
            cx = (x + bw / 2) / w
            cy = (y + bh / 2) / h
            nw, nh = bw / w, bh / h
            lines.append(f"{cats[a['category_id']]} {cx:.6f} {cy:.6f} {nw:.6f} {nh:.6f}")
        if lines:
            lbl = out_labels / (Path(img["file_name"]).stem + ".txt")
            lbl.write_text("\n".join(lines))
    return cats


def voc_to_yolo(xml_file, out_labels, class_map):
    import xml.etree.ElementTree as ET
    tree = ET.parse(xml_file)
    root = tree.getroot()
    w = int(root.find("size/width").text)
    h = int(root.find("size/height").text)
    lines = []
    for obj in root.findall("object"):
        name = obj.find("name").text
        if name not in class_map:
            class_map[name] = len(class_map)
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
    if lines:
        lbl = out_labels / (Path(xml_file).stem + ".txt")
        lbl.write_text("\n".join(lines))


def prepare_dataset():
    print("\n🔄 Preparing dataset...")

    # Find data root (handle nested kaggle dirs)
    data_root = RAW_DIR
    if not find_images(data_root):
        subdirs = [d for d in data_root.iterdir() if d.is_dir()]
        if len(subdirs) == 1:
            data_root = subdirs[0]

    fmt = detect_format(data_root)
    print(f"  Format: {fmt}")
    print(f"  Root:   {data_root}")

    all_images = find_images(data_root)
    print(f"  Images: {len(all_images)}")

    pairs = []

    if fmt == "yolo":
        print("  ✅ YOLO format — using directly")
        for img in all_images:
            lbl = None
            for candidate in [
                img.parent.parent / "labels" / (img.stem + ".txt"),
                img.parent / "labels" / (img.stem + ".txt"),
                img.with_suffix(".txt"),
                img.parent / (img.stem + ".txt"),
            ]:
                if candidate.exists():
                    lbl = candidate
                    break
            pairs.append((img, lbl))

    elif fmt == "coco":
        print("  🔄 Converting COCO → YOLO...")
        out_labels = PROJECT_DIR / "converted_labels"
        out_labels.mkdir(exist_ok=True)
        for jf in data_root.rglob("*.json"):
            data = json.load(open(jf))
            if "annotations" in data:
                cats = coco_to_yolo(jf, out_labels)
                print(f"  Classes: {cats}")
                break
        for img in all_images:
            lbl = out_labels / (img.stem + ".txt")
            pairs.append((img, lbl if lbl.exists() else None))

    elif fmt == "voc":
        print("  🔄 Converting VOC → YOLO...")
        out_labels = PROJECT_DIR / "converted_labels"
        out_labels.mkdir(exist_ok=True)
        class_map = {}
        for xml_f in data_root.rglob("*.xml"):
            voc_to_yolo(xml_f, out_labels, class_map)
        print(f"  Classes: {class_map}")
        for img in all_images:
            lbl = out_labels / (img.stem + ".txt")
            pairs.append((img, lbl if lbl.exists() else None))

    elif fmt == "images_only":
        print("\n  ❌ No annotations found! Dataset has images only.")
        print("  Annotate first with Roboflow/CVAT/LabelImg.")
        sys.exit(1)

    else:
        print(f"  ⚠️  Unknown format: {fmt}")
        for img in all_images:
            lbl = img.with_suffix(".txt")
            pairs.append((img, lbl if lbl.exists() else None))

    # Filter valid pairs
    valid = [(img, lbl) for img, lbl in pairs if lbl is not None]
    print(f"  Labeled pairs: {len(valid)} / {len(pairs)}")

    if not valid:
        print("  ❌ No labeled images found!")
        sys.exit(1)

    # Split
    random.seed(SEED)
    random.shuffle(valid)
    n = len(valid)
    n_train = int(n * TRAIN_RATIO)
    n_val = int(n * VAL_RATIO)

    splits = {
        "train": valid[:n_train],
        "val": valid[n_train:n_train + n_val],
        "test": valid[n_train + n_val:],
    }

    # Organize
    if DATASET_DIR.exists():
        shutil.rmtree(DATASET_DIR)

    for split_name, items in splits.items():
        img_dir = DATASET_DIR / split_name / "images"
        lbl_dir = DATASET_DIR / split_name / "labels"
        img_dir.mkdir(parents=True, exist_ok=True)
        lbl_dir.mkdir(parents=True, exist_ok=True)

        for img_path, lbl_path in items:
            shutil.copy2(img_path, img_dir / img_path.name)
            shutil.copy2(lbl_path, lbl_dir / (img_path.stem + ".txt"))

        print(f"  {split_name}: {len(items)} images")

    # Detect classes
    class_ids = set()
    for lbl in (DATASET_DIR / "train" / "labels").glob("*.txt"):
        with open(lbl) as f:
            for line in f:
                parts = line.strip().split()
                if parts:
                    class_ids.add(int(parts[0]))

    nc = len(class_ids)
    NAMES = {
        0: "pothole", 1: "crack", 2: "breakage",
        3: "rutting", 4: "patching", 5: "void_fill",
        6: "surface_erosion",
    }
    names = {}
    for i in sorted(class_ids):
        names[i] = NAMES.get(i, f"class_{i}")
    for i in range(max(class_ids) + 1) if class_ids else []:
        if i not in names:
            names[i] = f"class_{i}"

    # Write data.yaml
    data_cfg = {
        "path": str(DATASET_DIR),
        "train": "train/images",
        "val": "val/images",
        "test": "test/images",
        "nc": nc,
        "names": names,
    }
    with open(DATA_YAML, "w") as f:
        yaml.dump(data_cfg, f, default_flow_style=False)

    print(f"\n  ✅ Dataset ready: {DATA_YAML}")
    print(f"  Classes ({nc}): {names}")

    return DATA_YAML


# ============================================================
#  STEP 3: Train
# ============================================================
def train(data_yaml_path):
    from ultralytics import YOLO

    print(f"\n🚀 Training YOLOv8n...")
    print(f"  Epochs: {EPOCHS}")
    print(f"  Batch:  {BATCH}")
    print(f"  ImgSz:  {IMGSZ}")
    print(f"  Device: {DEVICE}")

    model = YOLO(MODEL)

    start = time.time()
    results = model.train(
        data=str(data_yaml_path),
        epochs=EPOCHS,
        batch=BATCH,
        imgsz=IMGSZ,
        device=DEVICE,
        patience=30,
        optimizer="auto",
        lr0=0.01,
        lrf=0.01,
        mosaic=1.0,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        project=str(PROJECT_DIR / "runs"),
        name="train_local",
        exist_ok=True,
        verbose=True,
    )

    elapsed = time.time() - start
    h, rem = divmod(elapsed, 3600)
    m, s = divmod(rem, 60)

    save_dir = Path(results.save_dir)
    best_pt = save_dir / "weights" / "best.pt"

    print(f"\n{'='*50}")
    print(f"  ✅ Training done in {int(h)}h {int(m)}m {int(s)}s")
    print(f"  Save dir:  {save_dir}")
    print(f"  Best PT:   {best_pt} ({best_pt.stat().st_size / (1024*1024):.2f} MB)")
    print(f"{'='*50}")

    return best_pt


# ============================================================
#  STEP 4: Evaluate
# ============================================================
def evaluate(best_pt, data_yaml_path):
    from ultralytics import YOLO

    print("\n📊 Evaluating...")
    val_model = YOLO(str(best_pt))
    val_results = val_model.val(data=str(data_yaml_path), device=DEVICE)

    print(f"\n  mAP@50:    {val_results.box.map50:.4f}")
    print(f"  mAP@50-95: {val_results.box.map:.4f}")
    print(f"  Precision: {val_results.box.mp:.4f}")
    print(f"  Recall:    {val_results.box.mr:.4f}")

    f1 = 2 * (val_results.box.mp * val_results.box.mr) / (val_results.box.mp + val_results.box.mr + 1e-8)
    print(f"  F1 Score:  {f1:.4f}")

    return val_results


# ============================================================
#  STEP 5: Export TFLite
# ============================================================
def export_tflite(best_pt):
    from ultralytics import YOLO

    print("\n📦 Exporting to TFLite (FP16)...")
    export_model = YOLO(str(best_pt))
    export_path = export_model.export(
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

    return tflite_file


# ============================================================
#  MAIN
# ============================================================
def main():
    print("=" * 50)
    print("  JalanCerdas AI — Local Training Pipeline")
    print("=" * 50)

    # 0. Setup
    install_deps()
    check_kaggle()
    has_gpu = check_gpu()

    # 1. Download
    download_dataset()

    # 2. Prepare
    data_yaml_path = prepare_dataset()

    # 3. Train
    best_pt = train(data_yaml_path)

    # 4. Evaluate
    evaluate(best_pt, data_yaml_path)

    # 5. Export
    tflite_path = export_tflite(best_pt)

    # Done
    print("\n" + "=" * 50)
    print("  🎉 ALL DONE!")
    print("=" * 50)
    print(f"\n  Model:   {best_pt}")
    print(f"  TFLite:  {tflite_path}")
    print(f"\n  Next: Build Flutter APK & test on phone")


if __name__ == "__main__":
    main()

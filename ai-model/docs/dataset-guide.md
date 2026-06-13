# JalanCerdas AI - Dataset Preparation Guide

Complete guide for preparing pothole detection datasets for YOLO training.

## Supported Formats

### 1. YOLO Format (Recommended)

```
dataset/
├── train/
│   ├── images/
│   │   ├── img001.jpg
│   │   └── img002.jpg
│   └── labels/
│       ├── img001.txt
│       └── img002.txt
├── val/
│   ├── images/
│   └── labels/
├── test/
│   ├── images/
│   └── labels/
└── data.yaml
```

**Label file format** (`img001.txt`):
```
# Each line: class_id center_x center_y width height
# All values normalized to [0, 1]
0 0.456 0.523 0.120 0.089
0 0.782 0.341 0.095 0.067
```

**`data.yaml`**:
```yaml
path: ../dataset
train: train/images
val: val/images
test: test/images
nc: 1
names:
  0: pothole
```

### 2. COCO Format

JSON annotation file with structure:
```json
{
  "images": [{"id": 1, "file_name": "img001.jpg", "width": 1920, "height": 1080}],
  "annotations": [{"id": 1, "image_id": 1, "category_id": 1, "bbox": [x, y, w, h]}],
  "categories": [{"id": 1, "name": "pothole"}]
}
```

**Convert to YOLO:**
```bash
# Auto-detected by download_dataset.py
python scripts/download_dataset.py --source local --local-path /path/to/coco/data
```

### 3. Pascal VOC Format

XML annotation files:
```xml
<annotation>
  <filename>img001.jpg</filename>
  <size><width>1920</width><height>1080</height></size>
  <object>
    <name>pothole</name>
    <bndbox>
      <xmin>800</xmin><ymin>400</ymin>
      <xmax>1000</xmax><ymax>600</ymax>
    </bndbox>
  </object>
</annotation>
```

**Convert to YOLO:**
```bash
# Auto-detected and converted
python scripts/download_dataset.py --source local --local-path /path/to/voc/data
```

## Dataset Sources

### Kaggle Datasets

| Dataset | URL | Format | Size |
|---------|-----|--------|------|
| Pothole Detection | `kaggle datasets download -d atikurrahmanatikur/pothole-detection-dataset` | YOLO | ~200 images |
| Pothole Dataset | `kaggle datasets download -d samirkhan/pothole-dataset` | Mixed | ~500 images |
| Road Pothole Detection | `kaggle datasets download -d navoneel/road-pothole-detection` | VOC | ~800 images |
| Pothole | `kaggle datasets download -d dtrungdt/pothole` | Mixed | ~300 images |

**Setup Kaggle CLI:**
```bash
pip install kaggle
mkdir -p ~/.kaggle
echo '{"username":"YOUR_USER","key":"YOUR_KEY"}' > ~/.kaggle/kaggle.json
chmod 600 ~/.kaggle/kaggle.json
```

### Roboflow Universe

Search: https://universe.roboflow.com/search?q=pothole

**Download from Roboflow:**
```bash
# Via API
python scripts/download_dataset.py --source roboflow \
  --rf-url https://universe.roboflow.com/workspace/project/dataset/1 \
  --rf-token YOUR_API_KEY
```

### Manual Collection

Recommended approach for production-quality dataset:

1. **Capture**: 1000+ images from different roads, angles, lighting
2. **Label**: Use Roboflow, CVAT, or LabelImg
3. **Export**: YOLO format
4. **Organize**: Follow directory structure above
5. **Split**: 80/10/10 train/val/test

## Annotation Conversion

### COCO to YOLO

```python
import json
from pathlib import Path

def coco_to_yolo(coco_json_path, output_dir):
    with open(coco_json_path) as f:
        coco = json.load(f)

    categories = {cat['id']: idx for idx, cat in enumerate(coco['categories'])}
    images = {img['id']: img for img in coco['images']}

    img_anns = {}
    for ann in coco['annotations']:
        img_anns.setdefault(ann['image_id'], []).append(ann)

    output_dir.mkdir(parents=True, exist_ok=True)

    for img_id, anns in img_anns.items():
        img = images[img_id]
        w, h = img['width'], img['height']

        lines = []
        for ann in anns:
            x, y, bw, bh = ann['bbox']
            cx = (x + bw / 2) / w
            cy = (y + bh / 2) / h
            nw = bw / w
            nh = bh / h
            lines.append(f"{categories[ann['category_id']]} {cx:.6f} {cy:.6f} {nw:.6f} {nh:.6f}")

        label_file = output_dir / (Path(img['file_name']).stem + '.txt')
        label_file.write_text('\n'.join(lines))
```

### Pascal VOC to YOLO

```python
import xml.etree.ElementTree as ET
from pathlib import Path

def voc_to_yolo(xml_path, class_map, output_dir):
    tree = ET.parse(xml_path)
    root = tree.getroot()

    w = int(root.find('size/width').text)
    h = int(root.find('size/height').text)

    lines = []
    for obj in root.findall('object'):
        name = obj.find('name').text
        bbox = obj.find('bndbox')
        xmin, ymin = float(bbox.find('xmin').text), float(bbox.find('ymin').text)
        xmax, ymax = float(bbox.find('xmax').text), float(bbox.find('ymax').text)

        cx = ((xmin + xmax) / 2) / w
        cy = ((ymin + ymax) / 2) / h
        bw = (xmax - xmin) / w
        bh = (ymax - ymin) / h

        lines.append(f"{class_map[name]} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}")

    label_file = output_dir / (Path(xml_path).stem + '.txt')
    label_file.write_text('\n'.join(lines))
```

## Data Augmentation

YOLO training applies augmentations automatically. Configure in training:

| Augmentation | Parameter | Default | Description |
|-------------|-----------|---------|-------------|
| Mosaic | `mosaic` | 1.0 | 4-image mosaic拼接 |
| Mixup | `mixup` | 0.0 | Blend two images |
| HSV-Hue | `hsv_h` | 0.015 | Color hue variation |
| HSV-Sat | `hsv_s` | 0.7 | Color saturation variation |
| HSV-Val | `hsv_v` | 0.4 | Brightness variation |
| Flip-LR | `fliplr` | 0.5 | Horizontal flip |
| Scale | `scale` | 0.5 | Random scale ±50% |
| Translate | `translate` | 0.1 | Random translation |
| Rotation | `degrees` | 0.0 | Rotation (set > 0 carefully) |
| Perspective | `perspective` | 0.0 | 3D perspective |
| Copy-Paste | `copy_paste` | 0.0 | Copy objects between images |

**Recommended for pothole detection:**
```bash
python scripts/train.py \
  --mosaic 1.0 \
  --hsv-h 0.02 \
  --hsv-s 0.8 \
  --hsv-v 0.5
```

### Manual Augmentation (Pre-training)

```python
from albumentations import Compose, HorizontalFlip, RandomBrightnessContrast

transform = Compose([
    HorizontalFlip(p=0.5),
    RandomBrightnessContrast(p=0.3),
], bbox_params={'format': 'yolo', 'label_fields': ['class_labels']})
```

## Quality Control

### 1. Verify Annotations

```bash
# Check all labels are valid YOLO format
python -c "
from pathlib import Path
errors = []
for f in Path('dataset').rglob('*.txt'):
    for i, line in enumerate(f.open()):
        parts = line.strip().split()
        if len(parts) != 5:
            errors.append(f'{f}:{i+1} - expected 5 values, got {len(parts)}')
        cls = int(parts[0])
        vals = [float(x) for x in parts[1:]]
        if not all(0 <= v <= 1 for v in vals):
            errors.append(f'{f}:{i+1} - values out of [0,1] range')
if errors:
    print(f'{len(errors)} errors found:')
    for e in errors[:10]: print(f'  {e}')
else:
    print('All annotations valid ✓')
"
```

### 2. Check Image-Label Pairs

```python
from pathlib import Path

img_dir = Path('dataset/train/images')
lbl_dir = Path('dataset/train/labels')

# Images without labels
for img in img_dir.glob('*.jpg'):
    if not (lbl_dir / (img.stem + '.txt')).exists():
        print(f'Missing label: {img.name}')

# Labels without images
for lbl in lbl_dir.glob('*.txt'):
    if not any((img_dir / lbl.stem).with_suffix(ext).exists()
               for ext in ['.jpg', '.jpeg', '.png']):
        print(f'Orphan label: {lbl.name}')
```

### 3. Minimum Requirements

| Check | Minimum | Recommended |
|-------|---------|-------------|
| Images per class | 500 | 2000+ |
| Annotations per image | 0 (some empty) | 1-5 |
| Image resolution | 320×320 | 640×640+ |
| Class balance | 80/20 | 90/10 or better |
| Train/val/test split | Any ratio | 80/10/10 |
| Variety | 2+ conditions | 10+ (weather, lighting, road) |

### 4. Common Issues

- **Duplicate images**: Deduplicate with hash comparison
- **Misaligned labels**: Visually inspect with `data_exploration.ipynb`
- **Class imbalance**: Oversample minority class or use augmentation
- **Small objects**: Use mosaic augmentation for context
- **Blurry images**: Remove low-quality captures

## Full Pipeline Example

```bash
# 1. Download dataset
python scripts/download_dataset.py --source kaggle --output ../dataset

# 2. Explore dataset
# Open notebooks/data_exploration.ipynb

# 3. Verify quality
python -c "from pathlib import Path; ..."

# 4. Train
python scripts/train.py --data ../dataset/data.yaml --epochs 100

# 5. Evaluate
python scripts/evaluate.py --weights runs/weights/best.pt

# 6. Export
python scripts/export_tflite.py --weights runs/weights/best.pt

# 7. Deploy to Flutter
# Copy .tflite to mobile/assets/models/
```

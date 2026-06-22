# JalanCerdas AI - Model Specifications

## Overview

YOLO-based road damage detection model optimized for real-time mobile inference on Android dashcam devices.

## Model Architecture

| Property | Value |
|----------|-------|
| Architecture | YOLOv8s (Small) |
| Backbone | CSPDarknet |
| Neck | PANet |
| Head | YOLOv8 Detect |
| Parameters | ~11.2M |
| FLOPs | ~28.6G |
| Model Size (FP16) | ~22 MB |

## Input Specification

| Property | Value |
|----------|-------|
| Input size | 640 × 640 pixels |
| Color space | RGB |
| Channels | 3 (uint8, 0-255) |
| Normalization | Internal (model handles preprocessing) |
| Batch dimension | Supported (dynamic) |

## Output Specification

| Property | Value |
|----------|-------|
| Format | Bounding boxes + class + confidence |
| Output shape | [1, 84, 8400] (YOLOv8 format) |
| Box format | xywh (center x, center y, width, height) — normalized |
| Coordinates | Normalized to [0, 1] relative to input size |
| Confidence | Float [0, 1] — detection confidence score |
| NMS | Applied with IoU threshold 0.6 |

## Classes (6-class Road Damage Detection)

| ID | Name | Indonesian | Description |
|----|------|------------|-------------|
| 0 | longitudinal_crack | Retak Memanjang | Crack running along road direction |
| 1 | surface_peeling | Pengelupasan Lapisan Permukaan | Surface layer peeling off |
| 2 | pothole | Lubang | Road cavity/depression |
| 3 | alligator_crack | Retak Kulit Buaya | Interconnected cracks (like alligator skin) |
| 4 | block_crack | Retak Blok | Rectangular/block-shaped cracks |
| 5 | edge_crack | Retak Pinggir | Crack along road edge |

## Quantization

| Format | Precision | Size | Accuracy Impact |
|--------|-----------|------|-----------------|
| FP32 (PyTorch) | 32-bit float | ~22 MB | Baseline |
| FP16 (TFLite) | 16-bit float | ~11 MB | Negligible (< 0.5% mAP drop) |
| INT8 (TFLite) | 8-bit integer | ~6 MB | Small (1-2% mAP drop) |

**Target:** FP16 TFLite for production mobile deployment.

## Performance Targets

| Metric | Target | Acceptable |
|--------|--------|------------|
| mAP@50 | ≥ 0.70 | ≥ 0.55 |
| mAP@50-95 | ≥ 0.50 | ≥ 0.35 |
| Precision | ≥ 0.75 | ≥ 0.60 |
| Recall | ≥ 0.70 | ≥ 0.55 |
| F1 Score | ≥ 0.70 | ≥ 0.55 |
| Model size | < 15 MB | < 25 MB |
| Inference time (mobile) | ~80 ms | < 150 ms |

## Training Configuration (Improved)

| Parameter | Value | Why |
|-----------|-------|-----|
| Base model | yolov8s.pt (pretrained on COCO) | Better capacity than nano |
| Epochs | 150 | More time to converge |
| Batch size | 16 | Stable gradient estimates |
| Image size | 640 | Good detail capture |
| Optimizer | AdamW | Better than SGD for small datasets |
| Learning rate | 0.001 → 0.00001 | Lower for stability |
| LR schedule | Cosine | Better convergence |
| Warmup | 5 epochs | Avoid early divergence |
| Augmentation | Mosaic + Mixup + CopyPaste | Better generalization |
| Class balancing | Enabled | Handle imbalanced classes |

## Augmentation Strategy

| Augmentation | Value | Purpose |
|--------------|-------|---------|
| Mosaic | 1.0 | Combine 4 images for context |
| Mixup | 0.15 | Blend images for robustness |
| Copy-Paste | 0.1 | Duplicate objects for balance |
| HSV-Hue | 0.02 | Color variation |
| HSV-Saturation | 0.7 | Saturation variation |
| HSV-Value | 0.4 | Brightness variation |
| Rotation | ±5° | Slight angle changes |
| Scale | 0.5 | Size variation |
| Flip | 0.5 | Horizontal flip |
| Erasing | 0.3 | Random occlusion |

## Inference Time Benchmarks

| Platform | Device | FP16 (ms) | INT8 (ms) |
|----------|--------|-----------|-----------|
| Android | Snapdragon 8 Gen 2 | ~50 | ~35 |
| Android | Snapdragon 765G | ~80 | ~55 |
| Android | MediaTek Dimensity 900 | ~95 | ~70 |
| iOS | A16 Bionic | ~45 | ~30 |
| Desktop | NVIDIA RTX 3060 | ~12 | ~8 |
| Desktop | CPU (i7-12700) | ~120 | ~90 |

*Benchmarks are approximate. YOLOv8s is ~3x slower than YOLOv8n but significantly more accurate.*

## Dataset Requirements

| Property | Requirement |
|----------|-------------|
| Min images | 1000+ |
| Recommended images | 3000+ |
| Per-class instances | 200+ each |
| Annotation format | YOLO (class cx cy w h) |
| Image formats | JPG, PNG |
| Split ratio | 80% train / 10% val / 10% test |
| Labeling tools | Roboflow, CVAT, LabelImg |

## How to Train

### Quick Start (Local)
```bash
cd ai-model

# Train with improved settings (auto-detect GPU)
python scripts/train_improved.py

# Train on specific GPU
python scripts/train_improved.py --device 0

# Train with more epochs
python scripts/train_improved.py --epochs 200

# Train and export to TFLite
python scripts/train_improved.py --export
```

### Google Colab (Free GPU)
```python
# In Colab notebook:
!git clone https://github.com/Srjeff27/jalancerdas-ai.git
%cd jalancerdas-ai/ai-model
!python scripts/train_improved.py --device 0 --export
```

### Export to TFLite
```bash
# After training, export manually
python scripts/export_tflite.py --weights runs/train_improved/weights/best.pt
```

## Model Comparison

| Model | Params | mAP@50 | Speed (ms) | Size | Best For |
|-------|--------|--------|------------|------|----------|
| YOLOv8n | 3.2M | ~0.55 | ~35 | ~6 MB | Real-time, low-end devices |
| **YOLOv8s** | **11.2M** | **~0.70** | **~80** | **~22 MB** | **Best balance (recommended)** |
| YOLOv8m | 25.9M | ~0.78 | ~150 | ~52 MB | High accuracy, powerful devices |
| YOLO11n | 2.6M | ~0.58 | ~30 | ~5 MB | Latest architecture, fast |
| YOLO11s | 9.4M | ~0.73 | ~70 | ~20 MB | Latest architecture, balanced |

## Limitations

1. **Lighting**: Performance degrades in very dark or overexposed conditions
2. **Weather**: Rain/wet surfaces may reduce accuracy
3. **Speed**: Fast-moving camera causes motion blur
4. **Scale**: Very small potholes (< 1% of frame) may be missed
5. **Occlusion**: Partially covered potholes harder to detect
6. **Road type**: Trained primarily on Indonesian asphalt roads

## Future Improvements

- [ ] Instance segmentation for precise damage boundaries
- [ ] Severity scoring (depth/width estimation)
- [ ] Temporal model (video-based detection)
- [ ] Edge deployment with TensorRT
- [ ] Federated learning for continuous improvement
- [ ] Multi-weather training (rain, night, fog)

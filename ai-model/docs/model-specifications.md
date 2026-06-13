# JalanCerdas AI - Model Specifications

## Overview

YOLO-based pothole detection model optimized for real-time mobile inference on Android devices.

## Model Architecture

| Property | Value |
|----------|-------|
| Architecture | YOLOv8n / YOLO11n (Nano) |
| Backbone | CSPDarknet / EfficientRep |
| Neck | PANet / Rep-PAN |
| Head | YOLOv8 Detect |
| Parameters | ~3.2M (nano variant) |
| FLOPs | ~8.7G |

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
| Output shape | [1, N, 5+] where N = number of detections |
| Box format | xywh (center x, center y, width, height) — normalized |
| Coordinates | Normalized to [0, 1] relative to input size |
| Confidence | Float [0, 1] — detection confidence score |
| NMS | Applied with IoU threshold (default 0.6) |

## Classes

| ID | Name | Description |
|----|------|-------------|
| 0 | pothole | Road surface defect — depression, crack, or cavity |

Single-class detection model. Extensible to additional road defect types.

## Quantization

| Format | Precision | Size | Accuracy Impact |
|--------|-----------|------|-----------------|
| FP32 (PyTorch) | 32-bit float | ~12-15 MB | Baseline |
| FP16 (TFLite) | 16-bit float | ~6-8 MB | Negligible (< 0.5% mAP drop) |
| INT8 (TFLite) | 8-bit integer | ~3-4 MB | Small (1-2% mAP drop) |

**Target:** FP16 TFLite for production mobile deployment.

## Performance Targets

| Metric | Target | Acceptable |
|--------|--------|------------|
| mAP@50 | ≥ 0.70 | ≥ 0.50 |
| mAP@50-95 | ≥ 0.50 | ≥ 0.35 |
| Precision | ≥ 0.75 | ≥ 0.60 |
| Recall | ≥ 0.70 | ≥ 0.55 |
| F1 Score | ≥ 0.70 | ≥ 0.55 |
| Model size | < 10 MB | < 15 MB |
| Inference time (mobile) | ~50 ms | < 100 ms |

## Inference Time Benchmarks

| Platform | Device | FP16 (ms) | INT8 (ms) |
|----------|--------|-----------|-----------|
| Android | Snapdragon 8 Gen 2 | ~35 | ~25 |
| Android | Snapdragon 765G | ~55 | ~40 |
| Android | MediaTek Dimensity 900 | ~65 | ~50 |
| iOS | A16 Bionic | ~30 | ~20 |
| iOS | A14 Bionic | ~40 | ~30 |
| Desktop | NVIDIA RTX 3060 | ~8 | ~5 |
| Desktop | CPU (i7-12700) | ~80 | ~60 |

*Benchmarks are approximate. Actual performance depends on image content and concurrent processes.*

## Training Configuration

| Parameter | Value |
|-----------|-------|
| Base model | yolov8n.pt (pretrained on COCO) |
| Epochs | 100-200 |
| Batch size | 16 |
| Image size | 640 |
| Optimizer | Auto (SGD or AdamW) |
| Learning rate | 0.01 → 0.0001 (cosine) |
| Augmentation | Mosaic, HSV, flip, scale, mixup |
| Early stopping | 50 epochs patience |
| Hardware | GPU recommended (NVIDIA with CUDA) |

## Dataset Requirements

| Property | Requirement |
|----------|-------------|
| Min images | 500+ |
| Recommended images | 2000+ |
| Annotation format | YOLO (class cx cy w h) |
| Image formats | JPG, PNG |
| Split ratio | 80% train / 10% val / 10% test |
| Labeling tools | Roboflow, CVAT, LabelImg |

## Export Formats

| Format | Use Case | Command |
|--------|----------|---------|
| TFLite (FP16) | Android production | `--half` |
| TFLite (INT8) | Android size-constrained | `--int8` |
| ONNX | Cross-platform | `format=onnx` |
| TorchScript | PyTorch mobile | `format=torchscript` |
| CoreML | iOS production | `format=coreml` |

## Mobile Integration

### Android (Flutter)

```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.4
  camera: ^0.10.5

# assets
flutter:
  assets:
    - assets/models/pothole_detector.tflite
```

```dart
// Load model
final interpreter = await Interpreter.fromAsset('pothole_detector.tflite');

// Preprocess frame
final input = preprocessFrame(cameraFrame, 640, 640);

// Run inference
final output = List.filled(1 * N * 5, 0.0).reshape([1, N, 5]);
interpreter.run(input, output);

// Postprocess results
final detections = postprocess(output, confidenceThreshold: 0.25);
```

## Limitations

1. **Lighting**: Performance degrades in very dark or overexposed conditions
2. **Weather**: Rain/wet surfaces may reduce accuracy
3. **Speed**: Fast-moving camera causes motion blur
4. **Scale**: Very small potholes (< 1% of frame) may be missed
5. **Occlusion**: Partially covered potholes harder to detect
6. **Road type**: Trained primarily on asphalt roads

## Future Improvements

- Multi-class detection (cracks, bumps, debris)
- Instance segmentation for precise boundary
- Video-based temporal consistency
- Edge detection model for low-power devices
- Federated learning for continuous improvement

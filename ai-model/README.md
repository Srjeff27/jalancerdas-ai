# AI Model — JalanCerdas AI

Training & deployment pipeline untuk model YOLO deteksi pothole.

## Quick Start

```bash
pip install ultralytics
python scripts/download_dataset.py
python scripts/train.py --epochs 100
python scripts/export_tflite.py
```

## Struktur

```
scripts/
├── download_dataset.py    # Download & prepare dataset
├── train.py               # Training YOLO
├── export_tflite.py       # Export ke TFLite
└── evaluate.py            # Evaluasi model

notebooks/
├── train_yolo.ipynb       # Interactive training
└── data_exploration.ipynb # Dataset analysis

configs/
└── data.yaml              # YOLO dataset config
```

## Model

Target: YOLOv8n (nano) — lightweight, cocok untuk mobile.
Kelas: pothole
Input: 640×640 RGB
Output: bounding box + confidence

Lihat [Model Specifications](docs/model-specifications.md) untuk detail.

import 'package:hive/hive.dart';


@HiveType(typeId: 0)
enum DamageType implements Comparable<DamageType> {
  @HiveField(0)
  lubang,

  @HiveField(1)
  retak_memanjang,

  @HiveField(2)
  retak_kulit_buaya,

  @HiveField(3)
  retak_blok,

  @HiveField(4)
  retak_pinggir,

  @HiveField(5)
  pengelupasan_lapisan_permukaan;

  @override
  int compareTo(DamageType other) => index.compareTo(other.index);

  String get displayName {
    switch (this) {
      case DamageType.lubang:
        return 'Lubang';
      case DamageType.retak_memanjang:
        return 'Retak Memanjang';
      case DamageType.retak_kulit_buaya:
        return 'Retak Kulit Buaya';
      case DamageType.retak_blok:
        return 'Retak Blok';
      case DamageType.retak_pinggir:
        return 'Retak Pinggir';
      case DamageType.pengelupasan_lapisan_permukaan:
        return 'Pengelupasan Lapisan Permukaan';
    }
  }
}

@HiveType(typeId: 1)
enum DetectionStatus implements Comparable<DetectionStatus> {
  @HiveField(0)
  detected,

  @HiveField(1)
  uploaded,

  @HiveField(2)
  queued,

  @HiveField(3)
  failed;

  @override
  int compareTo(DetectionStatus other) => index.compareTo(other.index);
}

@HiveType(typeId: 2)
class DetectionRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DamageType damageType;

  @HiveField(2)
  double confidence;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  @HiveField(5)
  String? imageUrl;

  @HiveField(6)
  DateTime detectedAt;

  @HiveField(7)
  DetectionStatus status;

  @HiveField(8)
  bool uploaded;

  @HiveField(9)
  String? localImagePath;

  @HiveField(10)
  double? widthMeters;

  @HiveField(11)
  double? depthMeters;

  DetectionRecord({
    required this.id,
    required this.damageType,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.detectedAt,
    this.status = DetectionStatus.detected,
    this.uploaded = false,
    this.localImagePath,
    this.widthMeters,
    this.depthMeters,
  });

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'damage_type': damageType.name,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'detected_at': detectedAt.toIso8601String(),
      'status': status.name,
      'width_meters': widthMeters,
      'depth_meters': depthMeters,
    };
  }
}

import 'package:hive/hive.dart';

part 'detection_record.g.dart';

@HiveType(typeId: 0)
enum DamageType implements Comparable<DamageType> {
  @HiveField(0)
  pothole,

  @HiveField(1)
  crack,

  @HiveField(2)
  depression,

  @HiveField(3)
  bump,

  @HiveField(4)
  other;

  @override
  int compareTo(DamageType other) => index.compareTo(other.index);

  String get displayName {
    switch (this) {
      case DamageType.pothole:
        return 'Pothole';
      case DamageType.crack:
        return 'Crack';
      case DamageType.depression:
        return 'Depression';
      case DamageType.bump:
        return 'Bump';
      case DamageType.other:
        return 'Other';
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

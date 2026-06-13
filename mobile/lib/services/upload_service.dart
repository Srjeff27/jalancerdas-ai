import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/detection_record.dart';
import 'api_service.dart';

class UploadService {
  final ApiService _apiService;

  UploadService(this._apiService);

  /// Upload a detection record with image to the backend
  Future<bool> uploadDetection(DetectionRecord record) async {
    try {
      final dio = _apiService.dio;

      // Build multipart form data
      final formData = FormData.fromMap({
        'damage_type': record.damageType.name,
        'confidence': record.confidence.toStringAsFixed(4),
        'latitude': record.latitude.toStringAsFixed(6),
        'longitude': record.longitude.toStringAsFixed(6),
        'detected_at': record.detectedAt.toIso8601String(),
        'status': record.status.name,
        if (record.widthMeters != null) 'width_meters': record.widthMeters,
        if (record.depthMeters != null) 'depth_meters': record.depthMeters,
      });

      // Add image file if available
      if (record.localImagePath != null) {
        final file = File(record.localImagePath!);
        if (await file.exists()) {
          formData.fields.add(const MapEntry('has_image', 'true'));
          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(
              record.localImagePath!,
              filename: '${record.id}.jpg',
            ),
          ));
        }
      }

      final response = await dio.post(
        '/detections',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('UploadService: Detection uploaded successfully');

        // Update record with server URL if returned
        if (response.data is Map && response.data['image_url'] != null) {
          record.imageUrl = response.data['image_url'];
        }

        return true;
      }

      debugPrint('UploadService: Upload failed with status ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      debugPrint('UploadService: Dio error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('UploadService: Upload failed: $e');
      return false;
    }
  }

  /// Upload batch of detections
  Future<Map<String, bool>> uploadBatch(List<DetectionRecord> records) async {
    final results = <String, bool>{};

    for (final record in records) {
      results[record.id] = await uploadDetection(record);
    }

    return results;
  }

  /// Check if API is reachable
  Future<bool> checkConnectivity() async {
    try {
      final dio = _apiService.dio;
      final response = await dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

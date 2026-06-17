import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/detection_provider.dart';
import '../models/detection_record.dart';
import '../utils/helpers.dart';

class DetectionDetailScreen extends StatelessWidget {
  final String detectionId;

  const DetectionDetailScreen({super.key, required this.detectionId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        final detection = provider.getDetectionById(detectionId);

        if (detection == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detection Detail')),
            body: const Center(
              child: Text(
                'Detection not found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detection Detail'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () {
                  _showDeleteDialog(context, provider, detection);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or placeholder
                _buildImageSection(detection),

                // Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Damage type & confidence
                      Row(
                        children: [
                          _buildTypeChip(detection),
                          const Spacer(),
                          _buildConfidenceBadge(detection),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Status
                      _buildStatusSection(detection),

                      const SizedBox(height: 16),

                      // Location info
                      _buildLocationSection(detection),

                      const SizedBox(height: 16),

                      // Timestamp
                      _buildInfoRow(
                        'Detected At',
                        DateFormat('MMM dd, yyyy HH:mm:ss')
                            .format(detection.detectedAt),
                        Icons.access_time,
                      ),

                      const SizedBox(height: 16),

                      // Dimensions if available
                      if (detection.widthMeters != null ||
                          detection.depthMeters != null) ...[
                        _buildDimensionsSection(detection),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(DetectionRecord detection) {
    return Container(
      height: 300,
      width: double.infinity,
      color: const Color(0xFF0D1B2A),
      child: detection.localImagePath != null
          ? Image.file(
              File(detection.localImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            )
          : detection.imageUrl != null
              ? Image.network(
                  detection.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                )
              : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(DetectionRecord detection) {
    Color chipColor;
    switch (detection.damageType) {
      case DamageType.lubang:
        chipColor = const Color(0xFFFF5252);
        break;
      case DamageType.retak_memanjang:
        chipColor = const Color(0xFFFF9800);
        break;
      case DamageType.retak_kulit_buaya:
        chipColor = const Color(0xFF9C27B0);
        break;
      case DamageType.retak_blok:
        chipColor = const Color(0xFF2196F3);
        break;
      case DamageType.retak_pinggir:
        chipColor = const Color(0xFF00E676);
        break;
      case DamageType.pengelupasan_lapisan_permukaan:
        chipColor = const Color(0xFFE91E63);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        detection.damageType.displayName,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(DetectionRecord detection) {
    final color = detection.confidence > 0.8
        ? const Color(0xFFFF5252)
        : detection.confidence > 0.6
            ? const Color(0xFFFFEB3B)
            : const Color(0xFF00E676);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${(detection.confidence * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatusSection(DetectionRecord detection) {
    IconData icon;
    Color color;
    String text;

    switch (detection.status) {
      case DetectionStatus.detected:
        icon = Icons.search;
        color = Colors.grey;
        text = 'Detected';
        break;
      case DetectionStatus.uploaded:
        icon = Icons.cloud_done;
        color = const Color(0xFF00E676);
        text = 'Uploaded';
        break;
      case DetectionStatus.queued:
        icon = Icons.cloud_queue;
        color = const Color(0xFFFFEB3B);
        text = 'Queued for upload';
        break;
      case DetectionStatus.failed:
        icon = Icons.cloud_off;
        color = const Color(0xFFFF5252);
        text = 'Upload failed';
        break;
    }

    return _buildInfoRow('Status', text, icon, valueColor: color);
  }

  Widget _buildLocationSection(DetectionRecord detection) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF00E676),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatLatitude(detection.latitude),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Longitude',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatLongitude(detection.longitude),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsSection(DetectionRecord detection) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dimensions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (detection.widthMeters != null)
              _buildInfoRow(
                'Width',
                '${detection.widthMeters!.toStringAsFixed(2)}m',
                Icons.arrow_forward,
              ),
            if (detection.depthMeters != null)
              _buildInfoRow(
                'Depth',
                '${detection.depthMeters!.toStringAsFixed(2)}m',
                Icons.arrow_downward,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, DetectionProvider provider, DetectionRecord detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this detection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDetection(detection.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }
}

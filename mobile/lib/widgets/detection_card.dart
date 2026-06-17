import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection_record.dart';
import '../utils/helpers.dart';

class DetectionCard extends StatelessWidget {
  final DetectionRecord detection;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DetectionCard({
    super.key,
    required this.detection,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, HH:mm').format(
                              detection.detectedAt,
                            ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Confidence
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 14,
                          color: _getConfidenceColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(detection.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getConfidenceColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Coordinates
                    Text(
                      '${formatLatitude(detection.latitude)}, '
                      '${formatLongitude(detection.longitude)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Upload status
              const SizedBox(width: 8),
              _buildUploadStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _getDamageIcon(),
    );
  }

  Widget _getDamageIcon() {
    IconData icon;
    Color color;

    switch (detection.damageType) {
      case DamageType.lubang:
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFFF5252);
        break;
      case DamageType.retak_memanjang:
        icon = Icons.linear_scale;
        color = const Color(0xFFFF9800);
        break;
      case DamageType.retak_kulit_buaya:
        icon = Icons.trending_down;
        color = const Color(0xFF9C27B0);
        break;
      case DamageType.retak_blok:
        icon = Icons.trending_up;
        color = const Color(0xFF2196F3);
        break;
      case DamageType.retak_pinggir:
        icon = Icons.compare_arrows;
        color = const Color(0xFF00E676);
        break;
      case DamageType.pengelupasan_lapisan_permukaan:
        icon = Icons.layers_clear;
        color = const Color(0xFFE91E63);
        break;
    }

    return Icon(icon, color: color, size: 28);
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getDamageColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        detection.damageType.displayName,
        style: TextStyle(
          color: _getDamageColor(),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUploadStatus() {
    IconData icon;
    Color color;

    switch (detection.status) {
      case DetectionStatus.uploaded:
        icon = Icons.cloud_done;
        color = const Color(0xFF00E676);
        break;
      case DetectionStatus.queued:
        icon = Icons.cloud_queue;
        color = const Color(0xFFFFEB3B);
        break;
      case DetectionStatus.failed:
        icon = Icons.cloud_off;
        color = const Color(0xFFFF5252);
        break;
      default:
        icon = Icons.cloud_upload;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Color _getDamageColor() {
    switch (detection.damageType) {
      case DamageType.lubang:
        return const Color(0xFFFF5252);
      case DamageType.retak_memanjang:
        return const Color(0xFFFF9800);
      case DamageType.retak_kulit_buaya:
        return const Color(0xFF9C27B0);
      case DamageType.retak_blok:
        return const Color(0xFF2196F3);
      case DamageType.retak_pinggir:
        return const Color(0xFF00E676);
      case DamageType.pengelupasan_lapisan_permukaan:
        return const Color(0xFFE91E63);
    }
  }

  Color _getConfidenceColor() {
    if (detection.confidence > 0.8) return const Color(0xFFFF5252);
    if (detection.confidence > 0.6) return const Color(0xFFFFEB3B);
    return const Color(0xFF00E676);
  }
}

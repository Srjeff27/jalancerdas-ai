import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection_record.dart';
import '../utils/constants.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.bgCardLight,
                width: 0.5,
              ),
            ),
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
                          const Spacer(),
                          Text(
                            _formatTime(detection.detectedAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Confidence
                          Icon(
                            Icons.speed_rounded,
                            size: 13,
                            color: _getConfidenceColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(detection.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _getConfidenceColor(),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Coordinates
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${formatLatitude(detection.latitude)}, ${formatLongitude(detection.longitude)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Upload status + delete
                const SizedBox(width: 8),
                Column(
                  children: [
                    _buildUploadBadge(),
                    if (onDelete != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (detection.localImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Image.file(
            File(detection.localImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon();
            },
          ),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _getDamageColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getDamageColor().withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Icon(
        _getDamageIcon(),
        color: _getDamageColor(),
        size: 24,
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getDamageColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        detection.damageType.displayName,
        style: TextStyle(
          color: _getDamageColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUploadBadge() {
    IconData icon;
    Color color;

    switch (detection.status) {
      case DetectionStatus.uploaded:
        icon = Icons.cloud_done_rounded;
        color = AppColors.success;
        break;
      case DetectionStatus.queued:
        icon = Icons.cloud_queue_rounded;
        color = AppColors.warning;
        break;
      case DetectionStatus.failed:
        icon = Icons.cloud_off_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.cloud_upload_rounded;
        color = AppColors.textMuted;
    }

    return Icon(icon, color: color, size: 18);
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(date);
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  IconData _getDamageIcon() {
    switch (detection.damageType) {
      case DamageType.lubang:
        return Icons.warning_rounded;
      case DamageType.retak_memanjang:
        return Icons.linear_scale_rounded;
      case DamageType.retak_kulit_buaya:
        return Icons.grid_on_rounded;
      case DamageType.retak_blok:
        return Icons.view_quilt_rounded;
      case DamageType.retak_pinggir:
        return Icons.swap_horiz_rounded;
      case DamageType.pengelupasan_lapisan_permukaan:
        return Icons.layers_clear_rounded;
    }
  }

  Color _getDamageColor() {
    switch (detection.damageType) {
      case DamageType.lubang:
        return AppColors.damageLubang;
      case DamageType.retak_memanjang:
        return AppColors.damageRetakMemanjang;
      case DamageType.retak_kulit_buaya:
        return AppColors.damageRetakKulitBuaya;
      case DamageType.retak_blok:
        return AppColors.damageRetakBlok;
      case DamageType.retak_pinggir:
        return AppColors.damageRetakPinggir;
      case DamageType.pengelupasan_lapisan_permukaan:
        return AppColors.damagePengelupasan;
    }
  }

  Color _getConfidenceColor() {
    if (detection.confidence > 0.8) return AppColors.error;
    if (detection.confidence > 0.6) return AppColors.warning;
    return AppColors.success;
  }
}

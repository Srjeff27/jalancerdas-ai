import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/detection_provider.dart';
import '../models/detection_record.dart';
import '../utils/constants.dart';
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
            appBar: AppBar(title: const Text('Detail')),
            body: const Center(
              child: Text(
                'Data tidak ditemukan',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            title: const Text('Detail Deteksi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus',
                onPressed: () => _showDeleteDialog(context, provider, detection),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                _buildImageSection(detection),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type + confidence row
                      Row(
                        children: [
                          _buildTypeChip(detection),
                          const Spacer(),
                          _buildConfidenceBadge(detection),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Info cards
                      _buildInfoCard(
                        icon: Icons.access_time_rounded,
                        title: 'Waktu',
                        child: Text(
                          DateFormat('dd MMMM yyyy, HH:mm:ss')
                              .format(detection.detectedAt),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.location_on_rounded,
                        title: 'Lokasi',
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Latitude',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    formatLatitude(detection.latitude),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.bgCardLight,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Longitude',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      formatLongitude(detection.longitude),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.cloud_upload_rounded,
                        title: 'Status',
                        child: _buildStatusRow(detection),
                      ),

                      // Dimensions
                      if (detection.widthMeters != null ||
                          detection.depthMeters != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.straighten_rounded,
                          title: 'Dimensi',
                          child: Column(
                            children: [
                              if (detection.widthMeters != null)
                                _buildDimensionRow(
                                  'Lebar',
                                  '${detection.widthMeters!.toStringAsFixed(2)} m',
                                ),
                              if (detection.depthMeters != null)
                                _buildDimensionRow(
                                  'Kedalaman',
                                  '${detection.depthMeters!.toStringAsFixed(2)} m',
                                ),
                            ],
                          ),
                        ),
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
      height: 260,
      width: double.infinity,
      color: AppColors.bgCard,
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
          Icon(Icons.image_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'Tidak ada gambar',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(DetectionRecord detection) {
    final color = _getDamageColor(detection.damageType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        detection.damageType.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(DetectionRecord detection) {
    final color = detection.confidence > 0.8
        ? AppColors.error
        : detection.confidence > 0.6
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${(detection.confidence * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgCardLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusRow(DetectionRecord detection) {
    IconData icon;
    Color color;
    String text;

    switch (detection.status) {
      case DetectionStatus.detected:
        icon = Icons.search_rounded;
        color = AppColors.textSecondary;
        text = 'Terdeteksi';
        break;
      case DetectionStatus.uploaded:
        icon = Icons.cloud_done_rounded;
        color = AppColors.success;
        text = 'Terkirim';
        break;
      case DetectionStatus.queued:
        icon = Icons.cloud_queue_rounded;
        color = AppColors.warning;
        text = 'Dalam antrian';
        break;
      case DetectionStatus.failed:
        icon = Icons.cloud_off_rounded;
        color = AppColors.error;
        text = 'Gagal mengirim';
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDamageColor(DamageType type) {
    switch (type) {
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

  void _showDeleteDialog(
      BuildContext context, DetectionProvider provider, DetectionRecord detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Deteksi'),
        content: const Text(
          'Yakin ingin menghapus data ini?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDetection(detection.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

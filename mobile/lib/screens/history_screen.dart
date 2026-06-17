import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../models/detection_record.dart';
import '../utils/constants.dart';
import '../widgets/detection_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
        actions: [
          Consumer<DetectionProvider>(
            builder: (context, provider, child) {
              final count = provider.getAllDetections().length;
              if (count == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Hapus semua',
                onPressed: () => _showClearDialog(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, child) {
          final detections = provider.getAllDetections();

          if (detections.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Stats bar
              _buildStatsBar(detections),
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: detections.length,
                  itemBuilder: (context, index) {
                    final detection = detections[index];
                    return DetectionCard(
                      detection: detection,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/detection_detail',
                          arguments: {'detectionId': detection.id},
                        );
                      },
                      onDelete: () {
                        provider.deleteDetection(detection.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(List<DetectionRecord> detections) {
    final uploaded = detections.where((d) => d.status == DetectionStatus.uploaded).length;
    final queued = detections.where((d) => d.status == DetectionStatus.queued).length;
    final failed = detections.where((d) => d.status == DetectionStatus.failed).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgCardLight, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '${detections.length}', AppColors.primary),
          _buildStatItem('Terkirim', '$uploaded', AppColors.success),
          _buildStatItem('Antrian', '$queued', AppColors.warning),
          _buildStatItem('Gagal', '$failed', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bgCardLight,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Deteksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai deteksi kerusakan jalan\nuntuk melihat hasilnya di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, DetectionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua'),
        content: const Text(
          'Semua riwayat deteksi akan dihapus. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllDetections();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Semua riwayat dihapus'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
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

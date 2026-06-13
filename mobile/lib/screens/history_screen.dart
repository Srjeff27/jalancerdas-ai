import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/detection_provider.dart';
import '../models/detection_record.dart';
import '../widgets/detection_card.dart';
import '../utils/helpers.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () {
              _showClearDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, child) {
          final detections = provider.getAllDetections();

          if (detections.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No detections yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start detecting to see results here',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
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
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear All Detections'),
        content: const Text(
          'Are you sure you want to delete all detection records? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DetectionProvider>().clearAllDetections();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All detections cleared'),
                  backgroundColor: Color(0xFFFF5252),
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }
}

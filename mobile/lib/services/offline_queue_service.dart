import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/detection_record.dart';

class OfflineQueueService {
  static const String _boxName = 'upload_queue';
  late Box<DetectionRecord> _queueBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _initialized = false;
  bool _isUploading = false;

  // Callback for when connectivity returns
  Function(DetectionRecord)? _onRetryUpload;

  bool get isInitialized => _initialized;
  bool get isUploading => _isUploading;
  int get pendingCount => _queueBox.length;

  /// Initialize the queue and start monitoring connectivity
  Future<void> initialize({
    Function(DetectionRecord)? onRetryUpload,
  }) async {
    try {
      _queueBox = await Hive.openBox<DetectionRecord>(_boxName);
      _onRetryUpload = onRetryUpload;
      _initialized = true;

      // Start monitoring connectivity
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        if (result != ConnectivityResult.none) {
          debugPrint('OfflineQueueService: Connectivity restored, retrying uploads');
          _retryAllPending();
        }
      });

      debugPrint('OfflineQueueService: Initialized with ${_queueBox.length} pending items');
    } catch (e) {
      debugPrint('OfflineQueueService: Initialization failed: $e');
    }
  }

  /// Add a detection to the upload queue
  Future<void> enqueue(DetectionRecord record) async {
    if (!_initialized) return;

    record.status = DetectionStatus.queued;
    await _queueBox.put(record.id, record);

    debugPrint('OfflineQueueService: Queued detection ${record.id} (total: ${_queueBox.length})');
  }

  /// Remove a detection from the queue
  Future<void> dequeue(String recordId) async {
    if (!_initialized) return;

    await _queueBox.delete(recordId);
    debugPrint('OfflineQueueService: Dequeued detection $recordId');
  }

  /// Get all pending items
  List<DetectionRecord> getPendingItems() {
    if (!_initialized) return [];
    return _queueBox.values.toList();
  }

  /// Get a specific item from queue
  DetectionRecord? getItem(String recordId) {
    if (!_initialized) return null;
    return _queueBox.get(recordId);
  }

  /// Retry all pending uploads
  Future<void> _retryAllPending() async {
    if (_isUploading || !_initialized) return;
    if (_onRetryUpload == null) return;

    _isUploading = true;

    final pendingItems = getPendingItems();
    debugPrint('OfflineQueueService: Retrying ${pendingItems.length} pending uploads');

    for (final record in pendingItems) {
      try {
        await _onRetryUpload!(record);

        // Remove from queue on success
        await dequeue(record.id);
        debugPrint('OfflineQueueService: Successfully uploaded ${record.id}');
      } catch (e) {
        debugPrint('OfflineQueueService: Failed to upload ${record.id}: $e');
      }
    }

    _isUploading = false;
  }

  /// Clear all pending items
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _queueBox.clear();
    debugPrint('OfflineQueueService: Cleared all pending items');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

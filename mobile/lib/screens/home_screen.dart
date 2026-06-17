import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../utils/constants.dart';
import '../widgets/status_indicator.dart';
import '../widgets/detection_overlay.dart';
import '../utils/helpers.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Screens for IndexedStack — state preserved across tab switches
  late final List<Widget> _screens = [
    _CameraTab(key: const ValueKey('camera')),
    const HistoryScreen(key: ValueKey('history')),
    const SettingsScreen(key: ValueKey('settings')),
  ];

  @override
  void initState() {
    super.initState();
    // Detection auto-starts in DetectionProvider._initialize()
    // Fallback: if camera is ready but detection hasn't started, start it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DetectionProvider>();
      if (!provider.isDetecting && provider.hasCamera) {
        provider.startDetection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(
          top: BorderSide(color: AppColors.bgCardLight, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                label: 'Pengaturan',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Camera Tab — lives inside IndexedStack
// ──────────────────────────────────────────────────────────────────

class _CameraTab extends StatelessWidget {
  const _CameraTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            _buildCameraPreview(provider),

            // Detection overlay — persistent boxes
            if (provider.isDetecting)
              DetectionOverlay(
                detections: provider.lastPersistedDetections,
                imageWidth: provider.cameraController?.value.previewSize?.height?.toInt() ?? 640,
                imageHeight: provider.cameraController?.value.previewSize?.width?.toInt() ?? 480,
              ),

            // Detection preview thumbnail (annotated photo)
            if (provider.lastDetectedImagePath != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: _buildDetectionPreview(context, provider),
              ),

            // Top status bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildTopBar(provider),
            ),

            // Bottom control panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControlPanel(context, provider),
            ),

            // Mock mode badge
            if (provider.mockMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_rounded, size: 12, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'MOCK',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetectionPreview(BuildContext context, DetectionProvider provider) {
    final imagePath = provider.lastDetectedImagePath;
    if (imagePath == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(DetectionProvider provider) {
    if (!provider.hasCamera || provider.cameraController == null) {
      return Container(
        color: AppColors.bgDark,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded, size: 56, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text(
                'Kamera Tidak Tersedia',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Pastikan izin kamera telah diberikan',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: provider.cameraController!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: provider.cameraController!.value.previewSize!.height,
                  height: provider.cameraController!.value.previewSize!.width,
                  child: CameraPreview(provider.cameraController!),
                ),
              )
            : Container(
                color: AppColors.bgDark,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(DetectionProvider provider) {
    return Row(
      children: [
        StatusIndicator(
          label: 'GPS',
          isConnected: provider.hasGps,
          icon: Icons.location_on_rounded,
        ),
        const Spacer(),
        // Detection count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: provider.detectionCount > 0
                  ? AppColors.error.withOpacity(0.4)
                  : AppColors.bgCardLight,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '${provider.detectionCount}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        StatusIndicator(
          label: 'NET',
          isConnected: provider.isConnected,
          icon: Icons.wifi_rounded,
        ),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context, DetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info bar
          if (provider.lastDetection != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.bgCardLight.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoChip(
                    'Confidence',
                    '${(provider.currentConfidence * 100).toStringAsFixed(1)}%',
                    Icons.speed_rounded,
                    provider.currentConfidence > 0.7
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  _buildInfoChip(
                    'Lat',
                    formatLatitude(provider.lastDetection!.latitude),
                    Icons.my_location_rounded,
                    AppColors.accent,
                  ),
                  _buildInfoChip(
                    'Lng',
                    formatLongitude(provider.lastDetection!.longitude),
                    Icons.explore_rounded,
                    AppColors.accent,
                  ),
                ],
              ),
            ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(
                icon: Icons.cameraswitch_rounded,
                onTap: () => provider.switchCamera(),
              ),
              // Main play/stop button
              GestureDetector(
                onTap: () {
                  if (provider.isDetecting) {
                    provider.stopDetection();
                  } else {
                    provider.startDetection();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: provider.isDetecting
                          ? [AppColors.error, const Color(0xFFDC2626)]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isDetecting
                                ? AppColors.error
                                : AppColors.primary)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isDetecting ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              _buildIconButton(
                icon: Icons.camera_alt_rounded,
                onTap: () => _manualCapture(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _manualCapture(BuildContext context, DetectionProvider provider) async {
    final path = await provider.takePicture();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Foto tersimpan'),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgCard.withOpacity(0.7),
          border: Border.all(
            color: AppColors.bgCardLight,
            width: 0.5,
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

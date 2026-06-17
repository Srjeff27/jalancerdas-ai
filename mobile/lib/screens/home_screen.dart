import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../widgets/status_indicator.dart';
import '../widgets/detection_overlay.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start detection when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DetectionProvider>();
      if (!provider.isDetecting) {
        provider.startDetection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildCameraView() : const SizedBox(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) {
              Navigator.pushNamed(context, '/history');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/settings');
            }
          },
          backgroundColor: const Color(0xFF1A1A2E),
          indicatorColor: const Color(0xFF2196F3).withOpacity(0.3),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF2196F3)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: Color(0xFF2196F3)),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF2196F3)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            _buildCameraPreview(provider),

            // Detection overlay with image dimensions
            if (provider.isDetecting)
              DetectionOverlay(
                detections: provider.currentDetections,
                imageWidth: provider.cameraController?.value.previewSize?.height?.toInt() ?? 640,
                imageHeight: provider.cameraController?.value.previewSize?.width?.toInt() ?? 480,
              ),

            // Last detection photo preview
            if (provider.lastDetectedImagePath != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: _buildDetectionPreview(),
              ),

            // Top status bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _buildTopBar(provider),
            ),

            // Bottom control panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControlPanel(provider),
            ),

            // Mock mode indicator
            if (provider.mockMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '🔧 MOCK MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetectionPreview() {
    return GestureDetector(
      onTap: () {
        // Show full screen preview
        if (provider.lastDetectedImagePath != null) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(provider.lastDetectedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }
      },
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF5252),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(provider.lastDetectedImagePath!),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(DetectionProvider provider) {
    if (!provider.hasCamera || provider.cameraController == null) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Camera Preview',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Camera unavailable in this environment',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
                color: const Color(0xFF0D1B2A),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(DetectionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // GPS Status
        StatusIndicator(
          label: 'GPS',
          isConnected: provider.hasGps,
          icon: Icons.location_on,
        ),

        // Detection count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF5252),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${provider.detectionCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Internet Status
        StatusIndicator(
          label: 'NET',
          isConnected: provider.isConnected,
          icon: Icons.wifi,
        ),
      ],
    );
  }

  Widget _buildControlPanel(DetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confidence and location info
          if (provider.lastDetection != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    'Confidence',
                    '${(provider.currentConfidence * 100).toStringAsFixed(1)}%',
                    Icons.speed,
                    provider.currentConfidence > 0.7
                        ? const Color(0xFFFF5252)
                        : const Color(0xFFFFEB3B),
                  ),
                  _buildInfoChip(
                    'Lat',
                    formatLatitude(provider.lastDetection!.latitude),
                    Icons.location_on,
                    const Color(0xFF00E676),
                  ),
                  _buildInfoChip(
                    'Lng',
                    formatLongitude(provider.lastDetection!.longitude),
                    Icons.location_on,
                    const Color(0xFF00E676),
                  ),
                ],
              ),
            ),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Switch camera
              _buildCircleButton(
                icon: Icons.cameraswitch,
                color: Colors.white.withOpacity(0.2),
                onTap: () => provider.switchCamera(),
              ),

              // Start/Stop detection
              GestureDetector(
                onTap: () {
                  if (provider.isDetecting) {
                    provider.stopDetection();
                  } else {
                    provider.startDetection();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isDetecting
                        ? const Color(0xFFFF5252)
                        : const Color(0xFF2196F3),
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isDetecting
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF2196F3))
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isDetecting ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              // Manual capture
              _buildCircleButton(
                icon: Icons.camera,
                color: Colors.white.withOpacity(0.2),
                onTap: () => _manualCapture(provider),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _manualCapture(DetectionProvider provider) async {
    final path = await provider.takePicture();
    if (path != null && mounted) {
      setState(() {
        // Photo saved via provider
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved: $path'),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

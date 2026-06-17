import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiUrlController = TextEditingController(text: settings.apiUrl);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset defaults',
            onPressed: () {
              _showResetDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // Sync controller text if settings change externally
          if (_apiUrlController.text != settings.apiUrl) {
            _apiUrlController.text = settings.apiUrl;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // API Configuration
              _buildSectionHeader('API Configuration'),
              const SizedBox(height: 8),
              _buildTextField(
                label: 'API URL',
                controller: _apiUrlController,
                icon: Icons.link,
                onChanged: (value) => settings.setApiUrl(value),
              ),

              const SizedBox(height: 24),

              // Detection Settings
              _buildSectionHeader('Detection Settings'),
              const SizedBox(height: 8),

              // Confidence Threshold
              _buildSliderSetting(
                label: 'Confidence Threshold',
                value: settings.confidenceThreshold,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                icon: Icons.speed,
                displayValue:
                    '${(settings.confidenceThreshold * 100).toStringAsFixed(0)}%',
                onChanged: (value) => settings.setConfidenceThreshold(value),
              ),

              const SizedBox(height: 16),

              // Mock Mode
              _buildSwitchSetting(
                title: 'Mock Detection Mode',
                subtitle: 'Use simulated detections instead of real model',
                value: settings.mockDetectionMode,
                icon: Icons.science,
                onChanged: (_) => settings.toggleMockDetectionMode(),
              ),

              const SizedBox(height: 24),

              // Upload Settings
              _buildSectionHeader('Upload Settings'),
              const SizedBox(height: 8),

              _buildSwitchSetting(
                title: 'Auto Upload',
                subtitle: 'Automatically upload detections to server',
                value: settings.autoUpload,
                icon: Icons.cloud_upload,
                onChanged: (_) => settings.toggleAutoUpload(),
              ),

              _buildSwitchSetting(
                title: 'Offline Mode',
                subtitle: 'Disable all network operations',
                value: settings.offlineMode,
                icon: Icons.airplanemode_active,
                onChanged: (_) => settings.toggleOfflineMode(),
              ),

              const SizedBox(height: 24),

              // About
              _buildSectionHeader('About'),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JalanCerdas AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-powered pothole detection for road condition monitoring. '
                        'Uses camera and GPS to detect and report road damage.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: const Color(0xFF2196F3).withOpacity(0.8),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
            border: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF2196F3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required String displayValue,
    required Function(double) onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2196F3), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF2196F3),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                thumbColor: const Color(0xFF2196F3),
                overlayColor: const Color(0xFF2196F3).withOpacity(0.2),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? const Color(0xFF2196F3) : Colors.grey,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        value: value,
        activeColor: const Color(0xFF2196F3),
        onChanged: onChanged,
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsProvider>().resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Color(0xFF2196F3),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

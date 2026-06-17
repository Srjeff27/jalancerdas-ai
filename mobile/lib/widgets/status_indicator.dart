import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusIndicator extends StatelessWidget {
  final String label;
  final bool isConnected;
  final IconData icon;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.isConnected,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.error,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? AppColors.success : AppColors.error)
                      .withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            size: 12,
            color: isConnected ? AppColors.textPrimary : AppColors.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: isConnected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

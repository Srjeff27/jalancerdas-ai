import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF00E676).withOpacity(0.3)
              : const Color(0xFFFF5252).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252),
              boxShadow: [
                BoxShadow(
                  color: (isConnected
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252))
                      .withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            icon,
            size: 14,
            color: isConnected ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isConnected ? Colors.white : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

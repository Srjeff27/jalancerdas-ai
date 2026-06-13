import 'package:intl/intl.dart';

/// Format latitude to string
String formatLatitude(double latitude) {
  final direction = latitude >= 0 ? 'N' : 'S';
  return '${latitude.abs().toStringAsFixed(6)}° $direction';
}

/// Format longitude to string
String formatLongitude(double longitude) {
  final direction = longitude >= 0 ? 'E' : 'W';
  return '${longitude.abs().toStringAsFixed(6)}° $direction';
}

/// Format coordinates to compact string
String formatCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

/// Format confidence as percentage string
String formatConfidence(double confidence) {
  return '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Format date to readable string
String formatDate(DateTime date) {
  return DateFormat('MMM dd, yyyy').format(date);
}

/// Format time to readable string
String formatTime(DateTime date) {
  return DateFormat('HH:mm:ss').format(date);
}

/// Format date and time
String formatDateTime(DateTime date) {
  return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
}

/// Format relative time (e.g., "2 hours ago")
String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return formatDate(date);
  }
}

/// Format file size
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Get damage type color
String getDamageTypeColorName(int typeIndex) {
  switch (typeIndex) {
    case 0:
      return 'Red';
    case 1:
      return 'Orange';
    case 2:
      return 'Purple';
    case 3:
      return 'Blue';
    default:
      return 'Grey';
  }
}

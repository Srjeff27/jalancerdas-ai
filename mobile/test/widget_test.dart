import 'package:flutter_test/flutter_test.dart';
import 'package:jalancerdas_ai/utils/helpers.dart';
import 'package:jalancerdas_ai/utils/constants.dart';

void main() {
  test('Coordinate formatting works correctly', () {
    expect(formatLatitude(-6.2088), contains('S'));
    expect(formatLatitude(6.2088), contains('N'));
    expect(formatLongitude(106.8456), contains('E'));
    expect(formatLongitude(-106.8456), contains('W'));
  });

  test('Confidence formatting works correctly', () {
    expect(formatConfidence(0.856), equals('85.6%'));
    expect(formatConfidence(1.0), equals('100.0%'));
    expect(formatConfidence(0.0), equals('0.0%'));
  });

  test('Date formatting works correctly', () {
    final testDate = DateTime(2024, 6, 15, 14, 30, 0);
    expect(formatDate(testDate), equals('Jun 15, 2024'));
    expect(formatTime(testDate), equals('14:30:00'));
  });

  test('Relative time formatting works correctly', () {
    final now = DateTime.now();
    expect(formatRelativeTime(now), equals('Just now'));
    expect(formatRelativeTime(now.subtract(const Duration(minutes: 5))), equals('5 min ago'));
    expect(formatRelativeTime(now.subtract(const Duration(hours: 3))), equals('3 hours ago'));
  });

  test('Constants have correct default values', () {
    // 6 damage types: lubang, retak_memanjang, retak_kulit_buaya, retak_blok, retak_pinggir, pengelupasan_lapisan_permukaan
    expect(AppConstants.numDetectionClasses, equals(6));
    expect(AppConstants.damageTypeLabels.length, equals(6));
    expect(AppConstants.defaultApiUrl, equals('http://localhost:8000/api'));
  });

  test('Damage type labels are in correct order', () {
    expect(AppConstants.damageTypeLabels[0], equals('Lubang'));
    expect(AppConstants.damageTypeLabels[1], equals('Retak Memanjang'));
    expect(AppConstants.damageTypeLabels[2], equals('Retak Kulit Buaya'));
    expect(AppConstants.damageTypeLabels[3], equals('Retak Blok'));
    expect(AppConstants.damageTypeLabels[4], equals('Retak Pinggir'));
    expect(AppConstants.damageTypeLabels[5], equals('Pengelupasan Lapisan Permukaan'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:athar_app/core/utils/helpers.dart';
import 'package:athar_app/models/report_model.dart';
import 'package:athar_app/core/constants/app_colors.dart';

void main() {
  group('Helpers.hashPassword', () {
    test('returns consistent SHA-256 hash', () {
      final hash1 = Helpers.hashPassword('password123');
      final hash2 = Helpers.hashPassword('password123');
      expect(hash1, hash2);
      expect(hash1.length, 64); // SHA-256 hex length
    });
    test('different passwords produce different hashes', () {
      final hash1 = Helpers.hashPassword('password123');
      final hash2 = Helpers.hashPassword('password124');
      expect(hash1, isNot(hash2));
    });
  });

  group('Helpers.verifyPassword', () {
    test('returns true for correct password', () {
      final hash = Helpers.hashPassword('mySecret');
      expect(Helpers.verifyPassword('mySecret', hash), true);
    });
    test('returns false for wrong password', () {
      final hash = Helpers.hashPassword('mySecret');
      expect(Helpers.verifyPassword('wrongSecret', hash), false);
    });
  });

  group('Helpers.formatDate', () {
    test('formats date as dd/MM/yyyy', () {
      final date = DateTime(2025, 5, 14);
      expect(Helpers.formatDate(date), '14/05/2025');
    });
  });

  group('Helpers.formatDateTime', () {
    test('formats as dd/MM/yyyy HH:mm', () {
      final date = DateTime(2025, 5, 14, 9, 30);
      expect(Helpers.formatDateTime(date), '14/05/2025 09:30');
    });
  });

  group('Helpers.formatTime', () {
    test('formats as HH:mm', () {
      final date = DateTime(2025, 5, 14, 14, 45);
      expect(Helpers.formatTime(date), '14:45');
    });
  });

  group('Helpers.timeAgo', () {
    test('returns "Just now" for current time', () {
      expect(Helpers.timeAgo(DateTime.now()), 'Just now');
    });
    test('returns minutes ago', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(Helpers.timeAgo(date), '5 minutes ago');
    });
    test('returns hours ago', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(Helpers.timeAgo(date), '3 hours ago');
    });
    test('returns days ago', () {
      final date = DateTime.now().subtract(const Duration(days: 2));
      expect(Helpers.timeAgo(date), '2 days ago');
    });
  });

  group('Helpers.calculateDistance', () {
    test('calculates distance between Makkah and Jeddah ~ 65-70 km', () {
      const lat1 = 21.3891; // Makkah
      const lng1 = 39.8579;
      const lat2 = 21.4858; // Jeddah
      const lng2 = 39.1925;

      final distance = Helpers.calculateDistance(lat1, lng1, lat2, lng2);
      expect(distance, greaterThan(60));
      expect(distance, lessThan(80));
    });
    test('returns 0 for same coordinates', () {
      final distance = Helpers.calculateDistance(21.4, 39.8, 21.4, 39.8);
      expect(distance, closeTo(0, 0.001));
    });
  });

  group('Helpers.getStatusColor', () {
    test('returns success color for matched', () {
      expect(Helpers.getStatusColor(ReportStatus.matched), AppColors.statusMatched);
    });
    test('returns error color for rejected', () {
      expect(Helpers.getStatusColor(ReportStatus.rejected), AppColors.statusRejected);
    });
    test('returns warning color for inProgress', () {
      expect(Helpers.getStatusColor(ReportStatus.inProgress), AppColors.statusInProgress);
    });
  });

  group('Helpers.getStatusText', () {
    test('returns Matched', () {
      expect(Helpers.getStatusText(ReportStatus.matched), 'Matched');
    });
    test('returns Rejected', () {
      expect(Helpers.getStatusText(ReportStatus.rejected), 'Rejected');
    });
    test('returns In Progress', () {
      expect(Helpers.getStatusText(ReportStatus.inProgress), 'In Progress');
    });
  });

  group('Helpers.getNotificationIcon', () {
    test('returns check_circle for match', () {
      expect(Helpers.getNotificationIcon('match'), Icons.check_circle);
    });
    test('returns update for statusUpdate', () {
      expect(Helpers.getNotificationIcon('statusUpdate'), Icons.update);
    });
    test('returns notifications for unknown', () {
      expect(Helpers.getNotificationIcon('unknown'), Icons.notifications);
    });
  });

  group('Helpers.generateId', () {
    test('generates 20-character string', () {
      final id = Helpers.generateId();
      expect(id.length, 20);
    });
    test('generates unique IDs', () {
      final id1 = Helpers.generateId();
      final id2 = Helpers.generateId();
      expect(id1, isNot(id2));
    });
    test('contains only lowercase letters and numbers', () {
      final id = Helpers.generateId();
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(id), true);
    });
  });

  group('Helpers.generateReferenceId', () {
    test('starts with ATH- and current year', () {
      final ref = Helpers.generateReferenceId();
      final year = DateTime.now().year;
      expect(ref.startsWith('ATH-$year-'), true);
    });
    test('has correct format length', () {
      final ref = Helpers.generateReferenceId();
      final parts = ref.split('-');
      expect(parts.length, 3);
      expect(parts[2].length, 6); // 6-digit random number
    });
  });
}

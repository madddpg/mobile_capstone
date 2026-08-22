import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/core/services/unread_notifications.dart';

void main() {
  group('notificationCreatedAtMs', () {
    test('reads DateTime and int; null/unknown → 0', () {
      final at = DateTime.utc(2026, 8, 22, 12);
      expect(notificationCreatedAtMs(at), at.millisecondsSinceEpoch);
      expect(notificationCreatedAtMs(42), 42);
      expect(notificationCreatedAtMs(null), 0);
      expect(notificationCreatedAtMs('nope'), 0);
    });
  });

  group('sortNotificationsNewestFirst', () {
    test('orders newest createdAt first without a Firestore index', () {
      final rows = [
        {'id': 'old', 'createdAt': DateTime.utc(2026, 8, 1)},
        {'id': 'new', 'createdAt': DateTime.utc(2026, 8, 20)},
        {'id': 'mid', 'createdAt': DateTime.utc(2026, 8, 10)},
        {'id': 'missing'},
      ];

      final sorted = sortNotificationsNewestFirst(
        rows,
        (row) => row['createdAt'],
      );

      expect(sorted.map((r) => r['id']), ['new', 'mid', 'old', 'missing']);
    });
  });
}

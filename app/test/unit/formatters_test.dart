import 'package:fairfare/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters', () {
    test('price adds thousands separator and currency', () {
      expect(Formatters.price(0), '0 RWF');
      expect(Formatters.price(1500), '1,500 RWF');
      expect(Formatters.price(1234567), '1,234,567 RWF');
    });

    test('priceRange formats both ends', () {
      expect(Formatters.priceRange(1200, 1800), '1,200 – 1,800 RWF');
    });

    test('points', () {
      expect(Formatters.points(300), '300 pts');
    });

    test('date', () {
      expect(Formatters.date(DateTime(2026, 11, 14)), '14 Nov 2026');
    });

    test('relativeTime buckets', () {
      final now = DateTime(2026, 11, 14, 12);
      expect(Formatters.relativeTime(now, now: now), 'just now');
      expect(
        Formatters.relativeTime(now.add(const Duration(minutes: 5)), now: now),
        'just now',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5 min ago',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3 h ago',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(days: 2)),
          now: now,
        ),
        '2 d ago',
      );
      expect(
        Formatters.relativeTime(DateTime(2026, 10, 1), now: now),
        '1 Oct 2026',
      );
    });

    test('countdown', () {
      expect(
        Formatters.countdown(const Duration(hours: 47, minutes: 5)),
        '47h 05m',
      );
      expect(Formatters.countdown(Duration.zero), 'expired');
      expect(Formatters.countdown(const Duration(minutes: -1)), 'expired');
    });

    test('initials', () {
      expect(Formatters.initials('Benjamin Kettey'), 'BK');
      expect(Formatters.initials('  passenger  '), 'P');
      expect(Formatters.initials('a b c'), 'AB');
      expect(Formatters.initials(''), '?');
    });
  });
}

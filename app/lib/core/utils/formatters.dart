// Display formatters shared by every screen.
//
// Prices are whole numbers of RWF (see the shared contracts), so nothing here
// deals with decimals. Keep formatting out of widgets: screens call these.
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _thousands = NumberFormat.decimalPattern('en_US');

  /// 1500 -> "1,500 RWF".
  static String price(int amount) => '${_thousands.format(amount)} RWF';

  /// low 1200, high 1800 -> "1,200 – 1,800 RWF".
  static String priceRange(int low, int high) =>
      '${_thousands.format(low)} – ${_thousands.format(high)} RWF';

  /// 300 -> "300 pts".
  static String points(int amount) => '${_thousands.format(amount)} pts';

  /// 2026-11-14 -> "14 Nov 2026".
  static String date(DateTime value) =>
      DateFormat('d MMM y', 'en_US').format(value);

  /// Short relative time for "last updated" labels:
  /// "just now", "5 min ago", "3 h ago", "2 d ago", then a full date.
  static String relativeTime(DateTime value, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return date(value);
  }

  /// Time left on a pending report's 48 hour window: "47h 05m", or "expired".
  static String countdown(Duration remaining) {
    if (remaining <= Duration.zero) return 'expired';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  /// "Benjamin Kettey" -> "BK", "passenger" -> "P", "" -> "?".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

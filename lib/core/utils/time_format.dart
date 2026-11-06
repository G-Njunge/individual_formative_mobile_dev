import 'package:intl/intl.dart';

/// Human-friendly times used on cards and timelines. `now` is injectable so
/// the functions are easy to unit test.
class TimeFormat {
  TimeFormat._();

  /// "Just now", "5m ago", "2h ago", "Yesterday", "3 days ago", "12 Oct".
  static String relative(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (_isSameDay(time, current)) return '${diff.inHours}h ago';
    final days = _dayDiff(time, current);
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return DateFormat('d MMM').format(time);
  }

  /// "Today, 7:42 AM", "Yesterday, 9:30 AM", "12 Oct, 9:30 AM".
  static String dayAndTime(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final clock = DateFormat('h:mm a').format(time);
    final days = _dayDiff(time, current);
    if (days == 0) return 'Today, $clock';
    if (days == 1) return 'Yesterday, $clock';
    return '${DateFormat('d MMM').format(time)}, $clock';
  }

  /// "9:30 AM" today, otherwise "12 Oct".
  static String shortClock(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (_isSameDay(time, current)) return DateFormat('h:mm a').format(time);
    if (_dayDiff(time, current) == 1) return 'Yesterday';
    return DateFormat('d MMM').format(time);
  }

  static bool isToday(DateTime time, {DateTime? now}) =>
      _isSameDay(time, now ?? DateTime.now());

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _dayDiff(DateTime earlier, DateTime later) {
    final a = DateTime(earlier.year, earlier.month, earlier.day);
    final b = DateTime(later.year, later.month, later.day);
    return b.difference(a).inDays;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/utils/time_format.dart';

void main() {
  final now = DateTime(2026, 10, 25, 14, 0);

  test('relative', () {
    expect(TimeFormat.relative(now, now: now), 'Just now');
    expect(
      TimeFormat.relative(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
    expect(
      TimeFormat.relative(now.subtract(const Duration(hours: 2)), now: now),
      '2h ago',
    );
    expect(
      TimeFormat.relative(DateTime(2026, 10, 24, 22), now: now),
      'Yesterday',
    );
    expect(
      TimeFormat.relative(DateTime(2026, 10, 22, 9), now: now),
      '3 days ago',
    );
    expect(TimeFormat.relative(DateTime(2026, 10, 1), now: now), '1 Oct');
  });

  test('dayAndTime', () {
    expect(
      TimeFormat.dayAndTime(DateTime(2026, 10, 25, 7, 42), now: now),
      'Today, 7:42 AM',
    );
    expect(
      TimeFormat.dayAndTime(DateTime(2026, 10, 24, 9, 30), now: now),
      'Yesterday, 9:30 AM',
    );
  });
}

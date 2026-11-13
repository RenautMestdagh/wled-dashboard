/// The cron expressions the schedule editor makes: a time of day on some days of the week (1 = Monday, 7 = Sunday).
class WeeklyCron {
  const WeeklyCron({required this.hour, required this.minute, required this.weekdays});

  final int hour;
  final int minute;
  final Set<int> weekdays;

  static final _pattern = RegExp(r'^(\d{1,2}) (\d{1,2}) \* \* (\*|[0-7](?:[-,][0-7])*)$');

  /// Null for a cron expression the editor can't show, such as one with seconds or several times.
  static WeeklyCron? parse(String cron) {
    final match = _pattern.firstMatch(cron.trim());
    if (match == null) return null;
    final days = match[3]!;
    final weekdays = <int>{};
    if (days == '*') {
      weekdays.addAll([1, 2, 3, 4, 5, 6, 7]);
    } else {
      for (final part in days.split(',')) {
        final bounds = part.split('-').map(int.parse).toList();
        for (var day = bounds.first; day <= bounds.last; day++) {
          weekdays.add(day == 0 ? 7 : day);
        }
      }
    }
    return WeeklyCron(hour: int.parse(match[2]!), minute: int.parse(match[1]!), weekdays: weekdays);
  }

  bool get everyDay => weekdays.length == 7;

  @override
  String toString() {
    final days = everyDay ? '*' : (weekdays.toList()..sort()).join(',');
    return '$minute $hour * * $days';
  }
}

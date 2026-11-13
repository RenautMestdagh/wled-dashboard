import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/weekly_cron.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/scope.dart';
import 'schedule_editor_screen.dart';

class SchedulesView extends StatelessWidget {
  const SchedulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.store;
    if (!store.isConnected) return const NotConnectedView();
    if (store.schedules.isEmpty) {
      return loadStateView(context, loading: store.loading, error: store.error, retry: store.refresh) ??
          MessageView(icon: Icons.schedule, title: s.noSchedulesTitle, message: s.noSchedulesMessage);
    }

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: store.schedules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ScheduleCard(schedule: store.schedules[index]),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final Schedule schedule;

  Future<void> _setEnabled(BuildContext context, bool enabled) async {
    try {
      await context.store.saveSchedule(schedule.copyWith(enabled: enabled));
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final period = switch ((schedule.startDate, schedule.stopDate)) {
      (null, null) => null,
      (final start?, null) => s.fromDate(dates.format(start)),
      (null, final stop?) => s.untilDate(dates.format(stop)),
      (final start?, final stop?) => s.dateRange(dates.format(start), dates.format(stop)),
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(schedule.name),
        subtitle: Text([schedule.presetName, describeCron(context, schedule.cron), ?period].join('\n')),
        isThreeLine: period != null,
        trailing: Switch(value: schedule.enabled, onChanged: (enabled) => _setEnabled(context, enabled)),
        onTap: () => openScheduleEditor(context, schedule),
      ),
    );
  }
}

/// "07:30 · Mon, Wed" for the cron expressions the editor makes, the expression itself for others.
String describeCron(BuildContext context, String cron) {
  final s = S.of(context);
  final weekly = WeeklyCron.parse(cron);
  if (weekly == null) return cron;
  final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: weekly.hour, minute: weekly.minute));
  final days = weekly.everyDay
      ? s.everyDay
      : (weekly.weekdays.toList()..sort()).map((day) => weekdayName(context, day)).join(', ');
  return '$time · $days';
}

/// The short name of a weekday, 1 = Monday.
String weekdayName(BuildContext context, int weekday) =>
    DateFormat.E(Localizations.localeOf(context).toLanguageTag()).format(DateTime(2024, 1, weekday));

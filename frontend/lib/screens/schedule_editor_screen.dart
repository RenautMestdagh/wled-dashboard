import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/weekly_cron.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/readable_width.dart';
import '../widgets/scope.dart';
import 'schedules_view.dart';

Future<void> openScheduleEditor(BuildContext context, [Schedule? schedule]) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ScheduleEditorScreen(schedule: schedule)));

class ScheduleEditorScreen extends StatefulWidget {
  const ScheduleEditorScreen({super.key, this.schedule});

  final Schedule? schedule;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.schedule?.name);
  late int? _presetId = widget.schedule?.presetId;
  late final WeeklyCron? _existing = widget.schedule == null ? null : WeeklyCron.parse(widget.schedule!.cron);
  late TimeOfDay _time = TimeOfDay(hour: _existing?.hour ?? 20, minute: _existing?.minute ?? 0);
  late final Set<int> _weekdays = {...?_existing?.weekdays};
  late DateTime? _startDate = widget.schedule?.startDate;
  late DateTime? _stopDate = widget.schedule?.stopDate;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      showMessage(context, s.chooseWeekday);
      return;
    }
    if (_startDate case final start? when _stopDate?.isBefore(start) ?? false) {
      showMessage(context, s.stopBeforeStart);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.store.saveSchedule(
        Schedule(
          id: widget.schedule?.id ?? 0,
          name: _name.text.trim(),
          cron: WeeklyCron(hour: _time.hour, minute: _time.minute, weekdays: _weekdays).toString(),
          presetId: _presetId!,
          startDate: _startDate,
          stopDate: _stopDate,
          enabled: widget.schedule?.enabled ?? true,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final store = context.store;
    final confirmed = await confirm(
      context,
      title: s.deleteScheduleTitle,
      message: s.deleteScheduleMessage(widget.schedule!.name),
      action: s.delete,
    );
    if (!confirmed) return;
    try {
      await store.deleteSchedule(widget.schedule!.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null) setState(() => _time = time);
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final presets = context.store.presets;
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? s.newSchedule : s.editSchedule),
        actions: [
          if (widget.schedule != null)
            IconButton(tooltip: s.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
          TextButton(onPressed: _saving || presets.isEmpty ? null : _save, child: Text(s.save)),
        ],
      ),
      body: SafeArea(
        child: presets.isEmpty
            ? MessageView(icon: Icons.palette_outlined, title: s.noPresetsTitle, message: s.presetNeededForSchedule)
            : ReadableWidth(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_saving) const LinearProgressIndicator(),
                      if (widget.schedule != null && _existing == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            s.cronReplaced(widget.schedule!.cron),
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(labelText: s.name),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) => value == null || value.trim().isEmpty ? s.nameRequired : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: presets.any((preset) => preset.id == _presetId) ? _presetId : null,
                        decoration: InputDecoration(labelText: s.preset),
                        isExpanded: true,
                        items: [
                          for (final preset in presets) DropdownMenuItem(value: preset.id, child: Text(preset.name)),
                        ],
                        onChanged: (id) => setState(() => _presetId = id),
                        validator: (id) => id == null ? s.choosePreset : null,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(s.time),
                          trailing: Text(_time.format(context), style: theme.textTheme.titleMedium),
                          onTap: _pickTime,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(s.days, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var day = 1; day <= 7; day++)
                            FilterChip(
                              label: Text(weekdayName(context, day)),
                              selected: _weekdays.contains(day),
                              onSelected: (selected) =>
                                  setState(() => selected ? _weekdays.add(day) : _weekdays.remove(day)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(s.period, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _DateTile(
                              label: s.startDate,
                              date: _startDate,
                              format: dates,
                              onPick: () async {
                                final date = await _pickDate(_startDate);
                                if (date != null) setState(() => _startDate = date);
                              },
                              onClear: () => setState(() => _startDate = null),
                            ),
                            _DateTile(
                              label: s.stopDate,
                              date: _stopDate,
                              format: dates,
                              onPick: () async {
                                final date = await _pickDate(_stopDate ?? _startDate);
                                if (date != null) setState(() => _stopDate = date);
                              },
                              onClear: () => setState(() => _stopDate = null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(s.periodHelp, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.format,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final DateFormat format;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final date = this.date;
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(label),
      subtitle: Text(date == null ? s.noDate : format.format(date)),
      onTap: onPick,
      trailing: date == null ? null : IconButton(tooltip: s.clear, icon: const Icon(Icons.clear), onPressed: onClear),
    );
  }
}

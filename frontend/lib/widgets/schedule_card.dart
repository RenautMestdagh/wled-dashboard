import 'package:flutter/material.dart';
import '../models/schedule.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleEnabled;
  final GlobalKey _moreButtonKey = GlobalKey();

  ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  Future<void> _showOptionsMenu(BuildContext context) async {
    final renderBox = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    const menuWidth = 180.0;

    final result = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx - menuWidth + renderBox.size.width,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.edit, size: 22),
            title: Text('Edit Schedule'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.delete, size: 22, color: Colors.red),
            title: Text('Delete Schedule', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
      elevation: 4,
    );

    if (result == 'edit') {
      onEdit();
    } else if (result == 'delete') {
      onDelete();
    }
  }

  String _parseCronExpression(String cron) {
    try {
      final parts = cron.split(' ');
      if (parts.length < 5) return cron;

      final minute = parts[0];
      final hour = parts[1];
      final dayOfMonth = parts[2];
      final month = parts[3];
      final dayOfWeek = parts[4];

      // Parse time
      final time = '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')}';

      // Parse days
      if (dayOfWeek == '*') return 'At $time, every day';

      final dayNumbers = dayOfWeek.split(',').map((d) => int.tryParse(d) ?? 0).toList();
      final dayNames = _convertDayNumbersToNames(dayNumbers);

      return 'At $time, on $dayNames';
    } catch (e) {
      return cron; // Return original if parsing fails
    }
  }

  String _convertDayNumbersToNames(List<int> dayNumbers) {
    const dayMap = {
      0: 'sun',
      1: 'mon',
      2: 'tue',
      3: 'wed',
      4: 'thu',
      5: 'fri',
      6: 'sat',
    };

    // Sort and remove duplicates
    dayNumbers.sort();
    dayNumbers = dayNumbers.toSet().toList();

    // Find consecutive days
    final ranges = <String>[];
    int? start;
    int? end;

    for (int i = 0; i < dayNumbers.length; i++) {
      if (start == null) {
        start = dayNumbers[i];
        end = dayNumbers[i];
      } else if (dayNumbers[i] == end! + 1) {
        end = dayNumbers[i];
      } else {
        ranges.add(start == end
            ? dayMap[start]!
            : '${dayMap[start]}-${dayMap[end]}');
        start = dayNumbers[i];
        end = dayNumbers[i];
      }
    }

    if (start != null) {
      ranges.add(start == end
          ? dayMap[start]!
          : '${dayMap[start]}-${dayMap[end]}');
    }

    return ranges.join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = schedule.enabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor.withAlpha(77), width: 1),
      ),
      color: theme.cardColor.withAlpha(179),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        schedule.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: onToggleEnabled,
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _parseCronExpression(schedule.cronExpression),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    schedule.presetName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (schedule.startDate != null || schedule.stopDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _buildDateRangeText(schedule),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: _moreButtonKey,
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showOptionsMenu(context),
                  tooltip: 'More options',
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDateRangeText(Schedule schedule) {
    final start = schedule.startDate;
    final end = schedule.stopDate;

    if (start != null && end != null) {
      return 'Active from $start to $end';
    } else if (start != null) {
      return 'Starts on $start';
    } else if (end != null) {
      return 'Ends on $end';
    }
    return 'Active indefinitely';
  }
}
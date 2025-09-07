import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';
import '../widgets/schedule_card.dart';
import 'schedules_edit_screen.dart';

class SchedulesScreen extends StatelessWidget {
  final List<Schedule> schedules;

  const SchedulesScreen({super.key, required this.schedules});

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await apiService.deleteSchedule(schedule.id);
    }
  }

  void _navigateToEditSchedule(BuildContext context, Schedule schedule) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleEditScreen(schedule: schedule),
      ),
    );
  }

  void _navigateToAddSchedule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScheduleEditScreen(),
      ),
    );
  }

  void _updateScheduleEnabledState(BuildContext context, Schedule schedule, bool state) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    apiService.updateSchedule(
        scheduleId: schedule.id,
        enabled: state,
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final schedules = apiService.schedules;

        return Scaffold(
          appBar: AppBar(
            title: Text('Schedule Presets'),
          ),
          body: RefreshIndicator(
            onRefresh: apiService.fetchSchedules,
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    return ScheduleCard(
                      schedule: schedules[index],
                      onEdit: () => _navigateToEditSchedule(context, schedules[index]),
                      onDelete: () => _confirmDelete(context, schedules[index]),
                      onToggleEnabled: (bool state) => _updateScheduleEnabledState(context, schedules[index], state),
                    );
                  },
                ),
                if (schedules.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No schedules yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Create schedules to automatically apply presets at specific times',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddSchedule(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: schedules.isNotEmpty
              ? FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            onPressed: () => _navigateToAddSchedule(context),
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
    );
  }
}
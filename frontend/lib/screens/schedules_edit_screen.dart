import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';

class ScheduleEditScreen extends StatefulWidget {
  final Schedule? schedule;

  const ScheduleEditScreen({super.key, this.schedule});

  @override
  State<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends State<ScheduleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cronController;
  int? _selectedPresetId;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 0, minute: 0);
  final Map<String, bool> _selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule?.name ?? '');
    _cronController = TextEditingController();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isInitializing = true);

    try {
      // If editing an existing schedule, load its data
      if (widget.schedule != null) {
        await _loadScheduleDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _loadScheduleDetails() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final scheduleDetails = await apiService.getScheduleDetails(widget.schedule!.id);

      setState(() {
        _selectedPresetId = scheduleDetails['preset_id'];

        // Parse days and time from cron expression
        final cronExpression = scheduleDetails['cron_expression'] as String;
        _parseTimeAndDaysFromCron(cronExpression);

        // Parse dates
        if (scheduleDetails['start_date'] != null) {
          _startDate = DateTime.parse(scheduleDetails['start_date']);
        }
        if (scheduleDetails['stop_date'] != null) {
          _endDate = DateTime.parse(scheduleDetails['stop_date']);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  void _parseTimeAndDaysFromCron(String cronExpression) {
    // Parse cron format: minute hour day month dayofweek
    final parts = cronExpression.split(' ');
    if (parts.length >= 5) {
      // Parse time (minute and hour)
      final minute = int.tryParse(parts[0]) ?? 0;
      final hour = int.tryParse(parts[1]) ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);

      // Parse days
      final daysPart = parts[4];
      _parseDaysFromCron(daysPart);
    }
  }

  void _parseDaysFromCron(String daysPart) {
    // Reset all days
    _selectedDays.updateAll((key, value) => false);

    // Handle wildcard (all days)
    if (daysPart == '*') {
      _selectedDays.updateAll((key, value) => true);
      return;
    }

    // Split by commas to handle multiple ranges/individual days
    final segments = daysPart.split(',');

    for (final segment in segments) {
      if (segment.contains('-')) {
        // Handle range (e.g., "1-3")
        final range = segment.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]);
          final end = int.tryParse(range[1]);
          if (start != null && end != null) {
            for (int i = start; i <= end; i++) {
              _updateDaySelection(i, true);
            }
          }
        }
      } else {
        // Handle individual day (e.g., "5")
        final dayNum = int.tryParse(segment);
        if (dayNum != null) {
          _updateDaySelection(dayNum, true);
        }
      }
    }
  }

  void _updateDaySelection(int dayNumber, bool selected) {
    // Convert cron day number (1-7, 7=Sunday) to our day map
    switch (dayNumber) {
      case 1:
        _selectedDays['Monday'] = selected;
        break;
      case 2:
        _selectedDays['Tuesday'] = selected;
        break;
      case 3:
        _selectedDays['Wednesday'] = selected;
        break;
      case 4:
        _selectedDays['Thursday'] = selected;
        break;
      case 5:
        _selectedDays['Friday'] = selected;
        break;
      case 6:
        _selectedDays['Saturday'] = selected;
        break;
      case 7:
        _selectedDays['Sunday'] = selected;
        break;
    }
  }

  int _getCronDayNumber(String dayName) {
    switch (dayName) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      default:
        return 1;
    }
  }

  String _buildCronExpression() {
    final selectedDays = _selectedDays.entries
        .where((entry) => entry.value)
        .map((entry) => _getCronDayNumber(entry.key))
        .toList()
      ..sort(); // Sort the days numerically

    final minute = _selectedTime.minute;
    final hour = _selectedTime.hour;

    if (selectedDays.isEmpty) {
      return '$minute $hour * * *'; // Default: run at selected time every day
    } else if (selectedDays.length == 7) {
      return '$minute $hour * * *'; // Run daily at selected time
    } else {
      // Convert consecutive days to ranges
      final daysString = _convertToRanges(selectedDays);
      return '$minute $hour * * $daysString'; // Run at selected time on selected days
    }
  }

  String _convertToRanges(List<int> days) {
    if (days.isEmpty) return '';
    if (days.length == 1) return days[0].toString();

    final ranges = <String>[];
    int start = days[0];
    int end = days[0];

    for (int i = 1; i < days.length; i++) {
      if (days[i] == end + 1) {
        // Consecutive number, extend the range
        end = days[i];
      } else {
        // Non-consecutive number, add the current range and start a new one
        if (start == end) {
          ranges.add(start.toString());
        } else if (end - start == 1) {
          // For exactly 2 consecutive numbers, keep them separate (1,2)
          ranges.add(start.toString());
          ranges.add(end.toString());
        } else {
          // For 3+ consecutive numbers, create a range (1-3)
          ranges.add('$start-$end');
        }
        start = days[i];
        end = days[i];
      }
    }

    // Add the last range
    if (start == end) {
      ranges.add(start.toString());
    } else if (end - start == 1) {
      ranges.add(start.toString());
      ranges.add(end.toString());
    } else {
      ranges.add('$start-$end');
    }

    return ranges.join(',');
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearStartDate() {
    setState(() {
      _startDate = null;
    });
  }

  void _clearEndDate() {
    setState(() {
      _endDate = null;
    });
  }

  String _getDayAbbreviation(String dayName) {
    switch (dayName) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      default:
        return dayName;
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one day is selected
    final hasSelectedDays = _selectedDays.values.any((selected) => selected);
    if (!hasSelectedDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    // Validate that a preset is selected
    if (_selectedPresetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a preset')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final cronExpression = _buildCronExpression();

    try {
      if (widget.schedule == null) {
        // Create new schedule
        await apiService.createSchedule(
          name: _nameController.text,
          cronExpression: cronExpression,
          presetId: _selectedPresetId!,
          startDate: _startDate?.toIso8601String().split('T')[0],
          stopDate: _endDate?.toIso8601String().split('T')[0],
        );
      } else {
        // Update existing schedule
        await apiService.updateSchedule(
          scheduleId: widget.schedule!.id,
          name: _nameController.text,
          cronExpression: cronExpression,
          presetId: _selectedPresetId,
          startDate: _startDate != null
              ? _startDate!.toIso8601String().split('T')[0]
              : 'CLEAR',
          stopDate: _endDate != null
              ? _endDate!.toIso8601String().split('T')[0]
              : 'CLEAR',
          enabled: widget.schedule!.enabled,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is handled by ApiService and shown via a SnackBar
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final theme = Theme.of(context);
    final presets = apiService.presets;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Create Schedule' : 'Edit Schedule'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Preset Selection
                  Text('Preset', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedPresetId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      isDense: true,
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                    ),
                    dropdownColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 500,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    items: presets.map((preset) {
                      return DropdownMenuItem<int>(
                        value: preset.id,
                        child: Text(preset.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPresetId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a preset';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Time Selection
                  Text('Time', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Days Selection
                  Text('Days', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedDays.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                _getDayAbbreviation(entry.key),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              selected: entry.value,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDays[entry.key] = selected;
                                });
                              },
                              selectedColor: theme.colorScheme.primary.withAlpha(50),
                              checkmarkColor: theme.colorScheme.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Range
                  Text('Date Range (Optional)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: Text(
                                'Start',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600, width: 1.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                borderRadius: BorderRadius.circular(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _startDate == null
                                              ? 'No start date'
                                              : '${_startDate!.toLocal().toString().split(' ')[0]}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: _startDate == null ? Colors.grey.shade500 : theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (_startDate != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: _clearStartDate,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: Text(
                                'End',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600, width: 1.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                borderRadius: BorderRadius.circular(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          _endDate == null
                                              ? 'No end date'
                                              : '${_endDate!.toLocal().toString().split(' ')[0]}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: _endDate == null ? Colors.grey.shade500 : theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (_endDate != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: _clearEndDate,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.save),
        label: Text(widget.schedule == null ? 'Create' : 'Save'),
        onPressed: _isLoading ? null : _saveSchedule,
      ),
    );
  }
}

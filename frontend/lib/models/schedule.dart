class Schedule {
  final int id;
  final String name;
  final String cronExpression;
  final String? startDate;
  final String? stopDate;
  final bool enabled;
  final int presetId;
  final String presetName;

  Schedule({
    required this.id,
    required this.name,
    required this.cronExpression,
    this.startDate,
    this.stopDate,
    required this.enabled,
    required this.presetId,
    required this.presetName,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      name: json['name'],
      cronExpression: json['cron_expression'],
      startDate: json['start_date'],
      stopDate: json['stop_date'],
      enabled: json['enabled'] == 1 || json['enabled'] == true,
      presetId: json['preset_id'],
      presetName: json['preset_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cron_expression': cronExpression,
      'start_date': startDate,
      'stop_date': stopDate,
      'enabled': enabled,
      'preset_id': presetId,
      'preset_name': presetName,
    };
  }
}
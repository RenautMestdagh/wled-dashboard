typedef Json = Map<String, Object?>;

class Instance {
  const Instance({required this.id, required this.ip, required this.name});

  factory Instance.fromJson(Json json) =>
      Instance(id: json['id']! as int, ip: json['ip']! as String, name: json['name'] as String? ?? '');

  final int id;
  final String ip;
  final String name;

  String get label => name.isEmpty ? ip : name;
}

class Preset {
  const Preset({required this.id, required this.name, required this.deviceCount});

  factory Preset.fromJson(Json json) =>
      Preset(id: json['id']! as int, name: json['name']! as String, deviceCount: json['instance_count']! as int);

  final int id;
  final String name;
  final int deviceCount;
}

/// What a preset does on one device: start one of the device's own WLED presets, or restore a saved state.
sealed class DeviceTarget {
  const DeviceTarget();

  factory DeviceTarget.fromJson(Object? json) => json is int ? WledPreset(json) : SavedState(json! as Json);

  Object toJson();
}

class WledPreset extends DeviceTarget {
  const WledPreset(this.number);

  final int number;

  @override
  Object toJson() => number;
}

class SavedState extends DeviceTarget {
  const SavedState(this.state);

  final Json state;

  @override
  Object toJson() => state;
}

class PresetDetail {
  const PresetDetail({required this.id, required this.name, required this.targets});

  factory PresetDetail.fromJson(Json json) => PresetDetail(
    id: json['id']! as int,
    name: json['name']! as String,
    targets: {
      for (final device in (json['instances']! as List<Object?>).cast<Json>())
        device['instance_id']! as int: DeviceTarget.fromJson(device['instance_preset']),
    },
  );

  final int id;
  final String name;

  /// By device id.
  final Map<int, DeviceTarget> targets;
}

class ApplyResult {
  const ApplyResult({required this.deviceName, required this.ok});

  factory ApplyResult.fromJson(Json json) =>
      ApplyResult(deviceName: json['instance_name']! as String, ok: json['ok']! as bool);

  final String deviceName;
  final bool ok;
}

class Schedule {
  const Schedule({
    this.id = 0,
    required this.name,
    required this.cron,
    required this.presetId,
    this.presetName = '',
    this.startDate,
    this.stopDate,
    this.enabled = true,
  });

  factory Schedule.fromJson(Json json) => Schedule(
    id: json['id']! as int,
    name: json['name']! as String,
    cron: json['cron_expression']! as String,
    presetId: json['preset_id']! as int,
    presetName: json['preset_name']! as String,
    startDate: _parseDate(json['start_date']),
    stopDate: _parseDate(json['stop_date']),
    enabled: json['enabled']! as bool,
  );

  final int id;
  final String name;
  final String cron;
  final int presetId;
  final String presetName;
  final DateTime? startDate;
  final DateTime? stopDate;
  final bool enabled;

  Schedule copyWith({bool? enabled}) => Schedule(
    id: id,
    name: name,
    cron: cron,
    presetId: presetId,
    presetName: presetName,
    startDate: startDate,
    stopDate: stopDate,
    enabled: enabled ?? this.enabled,
  );

  Json toJson() => {
    'name': name,
    'cron_expression': cron,
    'preset_id': presetId,
    'start_date': _formatDate(startDate),
    'stop_date': _formatDate(stopDate),
    'enabled': enabled,
  };

  static DateTime? _parseDate(Object? value) => value == null ? null : DateTime.parse(value as String);

  static String? _formatDate(DateTime? date) => date?.toIso8601String().substring(0, 10);
}

class DeviceInfo {
  const DeviceInfo({required this.name, required this.hasRgb, required this.hasWhite, required this.hasCct});

  /// WLED reports the light capabilities as bits in `leds.lc`.
  factory DeviceInfo.fromJson(Json json) {
    final capabilities = (json['leds']! as Json)['lc'] as int? ?? 0;
    return DeviceInfo(
      name: json['name'] as String? ?? '',
      hasRgb: capabilities & 1 != 0,
      hasWhite: capabilities & 2 != 0,
      hasCct: capabilities & 4 != 0,
    );
  }

  final String name;
  final bool hasRgb;
  final bool hasWhite;
  final bool hasCct;
}

class DeviceState {
  const DeviceState({required this.on, required this.brightness, this.preset = -1, this.color = const [], this.cct});

  factory DeviceState.fromJson(Json json) {
    final segments = (json['seg'] as List<Object?>? ?? const []).cast<Json>();
    final segment = segments.isEmpty ? const <String, Object?>{} : segments.first;
    final colors = (segment['col'] as List<Object?>? ?? const []).cast<List<Object?>>();
    return DeviceState(
      on: json['on'] as bool? ?? false,
      brightness: json['bri'] as int? ?? 0,
      preset: json['ps'] as int? ?? -1,
      color: colors.isEmpty ? const [] : colors.first.cast<int>(),
      cct: segment['cct'] as int?,
    );
  }

  DeviceState copyWith({bool? on}) =>
      DeviceState(on: on ?? this.on, brightness: brightness, preset: preset, color: color, cct: cct);

  final bool on;

  /// 0–255
  final int brightness;

  /// The active WLED preset, -1 for none.
  final int preset;

  /// The primary color of the main segment as RGB or RGBW, each 0–255.
  final List<int> color;

  /// Color temperature, 0 (warm) – 255 (cold).
  final int? cct;
}

class DevicePreset {
  const DevicePreset({required this.number, required this.name});

  final int number;
  final String name;

  /// presets.json maps each number to its definition; 0 is a placeholder and empty slots have no name.
  static List<DevicePreset> listFromJson(Json json) => [
    for (final MapEntry(:key, :value) in json.entries)
      if (int.tryParse(key) case final number? when number > 0 && value is Json && value['n'] is String)
        DevicePreset(number: number, name: value['n']! as String),
  ]..sort((a, b) => a.number.compareTo(b.number));
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'models.dart';
import 'settings.dart';

/// The devices, presets and schedules on the backend, shared by all screens.
class Store extends ChangeNotifier {
  Store({required this.settings, http.Client? client}) : _client = client ?? http.Client() {
    if (settings.isConfigured) {
      _api = ApiClient(serverUrl: settings.serverUrl, apiKey: settings.apiKey, client: _client);
    }
  }

  final Settings settings;
  final http.Client _client;
  ApiClient? _api;

  ApiClient get api => _api!;
  bool get isConnected => _api != null;

  List<Instance> instances = const [];
  List<Preset> presets = const [];
  List<Schedule> schedules = const [];
  bool loading = false;

  /// Why the last refresh failed.
  ApiException? error;

  /// The state of each device for its power switch: absent while loading, null when the device doesn't answer.
  final Map<int, DeviceState?> states = {};

  /// Checks the connection before saving it, so a wrong address or key never replaces a working one.
  Future<void> connect(String serverUrl, String apiKey) async {
    final api = ApiClient(serverUrl: serverUrl, apiKey: apiKey, client: _client);
    await api.instances();
    await settings.saveConnection(serverUrl, apiKey);
    _api = api;
    await refresh();
  }

  Future<void> refresh() async {
    if (!isConnected) return;
    loading = true;
    notifyListeners();
    try {
      instances = await api.instances();
      presets = await api.presets();
      schedules = await api.schedules();
      error = null;
    } on ApiException catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
    if (error == null) await loadStates();
  }

  Future<void> loadStates() => Future.wait(instances.map((instance) => loadState(instance.id)));

  Future<void> loadState(int id) async {
    try {
      states[id] = DeviceState.fromJson(await api.deviceState(id));
    } on ApiException {
      states[id] = null;
    }
    notifyListeners();
  }

  Future<void> setPower(int id, bool on) async {
    await api.setDeviceState(id, {'on': on});
    states[id] = states[id]?.copyWith(on: on);
    notifyListeners();
  }

  bool get anyOn => instances.any((instance) => states[instance.id]?.on ?? false);

  /// Turns every device off when any is on, else turns them all on. Returns the devices that didn't answer.
  Future<List<Instance>> toggleAll() async {
    final on = !anyOn;
    final failed = <Instance>[];
    await Future.wait(
      instances.map((instance) async {
        try {
          await setPower(instance.id, on);
        } on ApiException {
          failed.add(instance);
        }
      }),
    );
    return failed;
  }

  Future<void> addInstance(String ip, String name) async {
    final instance = await api.createInstance(ip, name);
    instances = await api.instances();
    notifyListeners();
    await loadState(instance.id);
  }

  Future<void> updateInstance(int id, String ip, String name) async {
    await api.updateInstance(id, ip, name);
    instances = await api.instances();
    notifyListeners();
  }

  Future<void> deleteInstance(int id) async {
    await api.deleteInstance(id);
    instances = await api.instances();
    presets = await api.presets();
    states.remove(id);
    notifyListeners();
  }

  /// Returns the devices that were found and added.
  Future<List<Instance>> discover() async {
    final added = await api.discover();
    instances = await api.instances();
    notifyListeners();
    await Future.wait(added.map((instance) => loadState(instance.id)));
    return added;
  }

  Future<void> reorderInstances(List<Instance> ordered) async {
    await api.reorderInstances([for (final instance in ordered) instance.id]);
    instances = ordered;
    notifyListeners();
  }

  Future<void> savePreset(int? id, String name, Map<int, DeviceTarget> targets) async {
    await api.savePreset(id, name, targets);
    presets = await api.presets();
    schedules = await api.schedules();
    notifyListeners();
  }

  Future<void> deletePreset(int id) async {
    await api.deletePreset(id);
    presets = await api.presets();
    schedules = await api.schedules();
    notifyListeners();
  }

  Future<void> reorderPresets(List<Preset> ordered) async {
    await api.reorderPresets([for (final preset in ordered) preset.id]);
    presets = ordered;
    notifyListeners();
  }

  /// Returns the devices that failed.
  Future<List<String>> applyPreset(int id) async {
    final results = await api.applyPreset(id);
    unawaited(loadStates());
    return [
      for (final result in results)
        if (!result.ok) result.deviceName,
    ];
  }

  Future<void> saveSchedule(Schedule schedule) async {
    await api.saveSchedule(schedule);
    schedules = await api.schedules();
    notifyListeners();
  }

  Future<void> deleteSchedule(int id) async {
    await api.deleteSchedule(id);
    schedules = await api.schedules();
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

enum ApiError { network, unauthorized, notFound, conflict, invalid, device, server }

class ApiException implements Exception {
  const ApiException(this.error, [this.message = '']);

  final ApiError error;
  final String message;

  @override
  String toString() => 'ApiException($error, $message)';
}

class ApiClient {
  ApiClient({required String serverUrl, required this.apiKey, http.Client? client})
    : serverUrl = serverUrl.replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  final String serverUrl;
  final String apiKey;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Future<List<Instance>> instances() async => _list(await _send('GET', '/api/instances'), Instance.fromJson);

  Future<Instance> createInstance(String ip, String name) async =>
      Instance.fromJson(await _send('POST', '/api/instances', {'ip': ip, 'name': name}) as Json);

  Future<void> updateInstance(int id, String ip, String name) =>
      _send('PUT', '/api/instances/$id', {'ip': ip, 'name': name});

  Future<void> deleteInstance(int id) => _send('DELETE', '/api/instances/$id');

  Future<void> reorderInstances(List<int> ids) => _send('POST', '/api/instances/reorder', {'orderedIds': ids});

  Future<List<Instance>> discover() async =>
      _list((await _send('POST', '/api/instances/discover') as Json)['added'], Instance.fromJson);

  Future<DeviceInfo> deviceInfo(int id) async =>
      DeviceInfo.fromJson(await _send('GET', '/api/instances/$id/info') as Json);

  Future<Json> deviceState(int id) async => await _send('GET', '/api/instances/$id/state') as Json;

  Future<void> setDeviceState(int id, Json state) => _send('POST', '/api/instances/$id/state', state);

  Future<List<DevicePreset>> devicePresets(int id) async =>
      DevicePreset.listFromJson(await _send('GET', '/api/instances/$id/presets') as Json);

  Future<List<Preset>> presets() async => _list(await _send('GET', '/api/presets'), Preset.fromJson);

  Future<PresetDetail> preset(int id) async => PresetDetail.fromJson(await _send('GET', '/api/presets/$id') as Json);

  Future<void> savePreset(int? id, String name, Map<int, DeviceTarget> targets) {
    final body = {
      'name': name,
      'instances': [
        for (final MapEntry(:key, :value) in targets.entries) {'instance_id': key, 'instance_preset': value.toJson()},
      ],
    };
    return id == null ? _send('POST', '/api/presets', body) : _send('PUT', '/api/presets/$id', body);
  }

  Future<void> deletePreset(int id) => _send('DELETE', '/api/presets/$id');

  Future<void> reorderPresets(List<int> ids) => _send('POST', '/api/presets/reorder', {'orderedIds': ids});

  Future<List<ApplyResult>> applyPreset(int id) async =>
      _list((await _send('POST', '/api/presets/$id/apply') as Json)['results'], ApplyResult.fromJson);

  Future<List<Schedule>> schedules() async => _list(await _send('GET', '/api/schedules'), Schedule.fromJson);

  Future<void> saveSchedule(Schedule schedule) => schedule.id == 0
      ? _send('POST', '/api/schedules', schedule.toJson())
      : _send('PUT', '/api/schedules/${schedule.id}', schedule.toJson());

  Future<void> deleteSchedule(int id) => _send('DELETE', '/api/schedules/$id');

  Future<Object?> _send(String method, String path, [Object? body]) async {
    final http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$serverUrl$path'))..headers['x-api-key'] = apiKey;
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      response = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on Exception {
      throw const ApiException(ApiError.network);
    }

    final json = _decode(response.body);
    if (response.statusCode < 300) {
      if (json == null && response.body.isNotEmpty) throw const ApiException(ApiError.server);
      return json;
    }

    final message = json is Json ? json['error'] as String? ?? '' : '';
    throw ApiException(switch (response.statusCode) {
      400 => ApiError.invalid,
      401 => ApiError.unauthorized,
      404 => ApiError.notFound,
      409 => ApiError.conflict,
      502 => ApiError.device,
      _ => ApiError.server,
    }, message);
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static List<T> _list<T>(Object? json, T Function(Json) fromJson) =>
      (json! as List<Object?>).cast<Json>().map(fromJson).toList();
}

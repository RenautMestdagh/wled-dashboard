import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wled_dashboard/data/settings.dart';
import 'package:wled_dashboard/main.dart';

typedef Json = Map<String, Object?>;

const apiKey = 'test-key';

class Sent {
  const Sent(this.method, this.path, this.body);

  final String method;
  final String path;
  final Object? body;
}

/// The backend API in memory, as a MockClient handler. Every request it receives is kept in [sent].
class FakeBackend {
  final instances = <Json>[];
  final presets = <Json>[];
  final schedules = <Json>[];
  final states = <int, Json>{};
  final capabilities = <int, int>{};
  final devicePresets = <int, Json>{};

  /// Devices that don't answer.
  final offline = <int>{};
  final sent = <Sent>[];
  bool down = false;
  int _nextId = 1;

  int addDevice(String name, {String? ip, bool on = false, int capabilities = 1}) {
    final id = _nextId++;
    instances.add({'id': id, 'ip': ip ?? '192.168.1.${10 + id}', 'name': name, 'display_order': instances.length});
    states[id] = {
      'on': on,
      'bri': 128,
      'ps': -1,
      'seg': [
        {
          'col': [
            [255, 160, 0],
          ],
          'cct': 127,
        },
      ],
    };
    this.capabilities[id] = capabilities;
    devicePresets[id] = {
      '0': <String, Object?>{},
      '1': {'n': 'Warm'},
      '2': {'n': 'Rainbow'},
    };
    return id;
  }

  int addPreset(String name, Map<int, Object> targets) {
    final id = _nextId++;
    presets.add({'id': id, 'name': name, 'targets': targets});
    return id;
  }

  int addSchedule(String name, int presetId, {String cron = '0 20 * * *', bool enabled = true}) {
    final id = _nextId++;
    schedules.add({
      'id': id,
      'name': name,
      'cron_expression': cron,
      'preset_id': presetId,
      'start_date': null,
      'stop_date': null,
      'enabled': enabled,
    });
    return id;
  }

  Iterable<Sent> sentTo(String method, String path) => sent.where((s) => s.method == method && s.path == path);

  Json _presetJson(Json preset, {bool detail = false}) {
    final targets = preset['targets']! as Map<int, Object>;
    return {
      'id': preset['id'],
      'name': preset['name'],
      'display_order': presets.indexOf(preset),
      'instance_count': targets.length,
      if (detail)
        'instances': [
          for (final MapEntry(:key, :value) in targets.entries) {'instance_id': key, 'instance_preset': value},
        ],
    };
  }

  Json _scheduleJson(Json schedule) => {
    ...schedule,
    'preset_name': presets.firstWhere((preset) => preset['id'] == schedule['preset_id'])['name'],
  };

  Future<http.Response> handle(http.Request request) async {
    final body = request.body.isEmpty ? null : jsonDecode(request.body);
    final path = request.url.path;
    sent.add(Sent(request.method, path, body));

    if (down) throw http.ClientException('Connection refused');
    if (request.headers['x-api-key'] != apiKey) return _json({'error': 'Unauthorized'}, 401);

    final segments = path.split('/').skip(2).toList();
    final id = segments.length > 1 ? int.tryParse(segments[1]) : null;
    final input = body is Json ? body : const <String, Object?>{};

    switch ((request.method, segments.first, segments.skip(1).join('/'))) {
      case ('GET', 'instances', ''):
        return _json(instances);
      case ('POST', 'instances', ''):
        final newId = addDevice(input['name']! as String, ip: input['ip']! as String);
        return _json(instances.firstWhere((i) => i['id'] == newId), 201);
      case ('PUT', 'instances', _):
        instances.firstWhere((i) => i['id'] == id).addAll({'ip': input['ip'], 'name': input['name']});
        return _json(instances.firstWhere((i) => i['id'] == id));
      case ('DELETE', 'instances', _):
        instances.removeWhere((i) => i['id'] == id);
        for (final preset in presets) {
          (preset['targets']! as Map<int, Object>).remove(id);
        }
        return http.Response('', 204);
      case ('POST', 'instances', 'discover'):
        return _json({'added': <Object>[]});
      case (_, 'instances', _) when offline.contains(id):
        return _json({'error': 'unreachable'}, 502);
      case ('GET', 'instances', final rest) when rest.endsWith('/info'):
        return _json({
          'ver': '0.15.3',
          'name': 'WLED',
          'leds': {'lc': capabilities[id]},
        });
      case ('GET', 'instances', final rest) when rest.endsWith('/state'):
        return _json(states[id]);
      case ('POST', 'instances', final rest) when rest.endsWith('/state'):
        if (input['on'] case final bool on) states[id]!['on'] = on;
        return _json({'success': true});
      case ('GET', 'instances', final rest) when rest.endsWith('/presets'):
        return _json(devicePresets[id]);
      case ('GET', 'presets', ''):
        return _json([for (final preset in presets) _presetJson(preset)]);
      case ('GET', 'presets', _):
        return _json(_presetJson(presets.firstWhere((p) => p['id'] == id), detail: true));
      case ('POST', 'presets', ''):
      case ('PUT', 'presets', _):
        final targets = {
          for (final target in (input['instances']! as List<Object?>).cast<Json>())
            target['instance_id']! as int: target['instance_preset']!,
        };
        if (request.method == 'POST') {
          addPreset(input['name']! as String, targets);
        } else {
          presets.firstWhere((p) => p['id'] == id).addAll({'name': input['name'], 'targets': targets});
        }
        return _json(<String, Object?>{}, request.method == 'POST' ? 201 : 200);
      case ('DELETE', 'presets', _):
        presets.removeWhere((p) => p['id'] == id);
        schedules.removeWhere((s) => s['preset_id'] == id);
        return http.Response('', 204);
      case ('POST', 'presets', final rest) when rest.endsWith('/apply'):
        final targets = presets.firstWhere((p) => p['id'] == id)['targets']! as Map<int, Object>;
        return _json({
          'results': [
            for (final deviceId in targets.keys)
              {
                'instance_id': deviceId,
                'instance_name': instances.firstWhere((i) => i['id'] == deviceId)['name'],
                'ok': !offline.contains(deviceId),
              },
          ],
        });
      case ('GET', 'schedules', ''):
        return _json([for (final schedule in schedules) _scheduleJson(schedule)]);
      case ('POST', 'schedules', ''):
        schedules.add({...input, 'id': _nextId++});
        return _json(_scheduleJson(schedules.last), 201);
      case ('PUT', 'schedules', _):
        schedules.firstWhere((s) => s['id'] == id).addAll(input);
        return _json(_scheduleJson(schedules.firstWhere((s) => s['id'] == id)));
      case ('DELETE', 'schedules', _):
        schedules.removeWhere((s) => s['id'] == id);
        return http.Response('', 204);
    }
    return _json({'error': 'Not found'}, 404);
  }

  static http.Response _json(Object? json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: {'content-type': 'application/json'});
}

/// Starts the app connected to [backend], on a screen of [size] logical pixels.
Future<Settings> pumpApp(
  WidgetTester tester,
  FakeBackend backend, {
  Size size = const Size(400, 800),
  bool connected = true,
  bool keepPreferences = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  if (!keepPreferences) {
    SharedPreferences.setMockInitialValues({
      if (connected) ...{'server_url': 'http://wled.test', 'api_key': apiKey},
    });
  }
  final settings = await Settings.load();
  await tester.pumpWidget(WledApp(settings: settings, client: MockClient(backend.handle)));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

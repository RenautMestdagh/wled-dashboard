import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  /// The web app is served by the backend itself, so it always talks to its own origin.
  String get serverUrl => kIsWeb ? Uri.base.origin : _prefs.getString('server_url') ?? '';

  String get apiKey => _prefs.getString('api_key') ?? '';

  bool get isConfigured => serverUrl.isNotEmpty && apiKey.isNotEmpty;

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_prefs.getString('theme_mode')] ?? ThemeMode.system;

  Future<void> saveConnection(String serverUrl, String apiKey) async {
    await _prefs.setString('server_url', serverUrl);
    await _prefs.setString('api_key', apiKey);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }
}

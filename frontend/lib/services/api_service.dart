import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/instance.dart';
import '../models/preset.dart';
import '../models/schedule.dart';

class ApiService with ChangeNotifier {
  static const String BASE_URL_KEY = 'base_url';
  static const String API_KEY_KEY = 'api_key';

  String _baseUrl = '';
  String _apiKey = '';
  bool _isLoading = false;
  List<WLEDInstance> _instances = [];
  Map<int, Map<String, dynamic>> _instanceStates = {};
  List<Preset> _presets = [];
  List<Schedule> _schedules = [];
  String? _errorMessage;
  String? _successMessage;
  bool _isInitialized = false;
  bool _isHealthy = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadStoredSettings();
    _isInitialized = true;
  }

  Future<void> _loadStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(BASE_URL_KEY) ?? '';
    _apiKey = prefs.getString(API_KEY_KEY) ?? '';

    if(_baseUrl == '' || _apiKey == ''){
      _errorMessage = 'Please configure API settings';
      return;
    }

    await fetchData(showAPISuccess: false);
  }

  Future<bool> _checkHealth(showAPISuccess) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final _authenticated = data['authenticated'] ?? false;
        _isHealthy = data['status'] == 'healthy' && _authenticated;

        if(_isHealthy && showAPISuccess)
          _successMessage = 'Connected to API';
        else if(!_authenticated)
          _errorMessage = 'API key is not valid';

        return _isHealthy;
      } else {
        _errorMessage = 'Unable to check API health';
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      notifyListeners();
    }
  }

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  bool get isHealthy => _isHealthy;
  bool get isLoading => _isLoading;
  List<WLEDInstance> get instances => _instances;
  List<Preset> get presets => _presets;
  List<Schedule> get schedules => _schedules;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> updateSettings(String baseUrl, String apiKey) async {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _errorMessage = null;
    _successMessage = null;

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BASE_URL_KEY, baseUrl);
    await prefs.setString(API_KEY_KEY, apiKey);

    _isHealthy = false;
    await fetchData();
    if(!_isHealthy)
      clearVariables();
  }

  void clearVariables() {
    _instances = [];
    _instanceStates = {};
    _presets = [];
  }

  Future<void> fetchData({bool showAPISuccess = true}) async {
    if(!_isHealthy)
      if(!await _checkHealth(showAPISuccess))
        return;

    if (_apiKey.isEmpty) {
      _errorMessage = 'API key is not configured';
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      await Future.wait([
        fetchInstances(),
        fetchPresets(),
        fetchSchedules(),
      ]);

      // After fetching instances, also fetch their states
      if (_instances.isNotEmpty) {
        await refreshDeviceStates();
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      _isLoading = false;
    }
  }

  void _handleApiError(dynamic error) {
    if (error is http.Response) {
      switch (error.statusCode) {
        case 400:
          _errorMessage = 'Invalid request - please check your input';
          break;
        case 401:
          _errorMessage = 'Unauthorized - invalid API key';
          break;
        case 404:
          _errorMessage = 'Resource not found';
          break;
        case 408:
          _errorMessage = 'Device timeout - check your connection';
          break;
        case 409:
          _errorMessage = 'Resource with this name already exists';
          break;
        case 500:
          _errorMessage = 'Server error - please try again later';
          break;
        case 502:
          _errorMessage = 'Device communication error';
          break;
        default:
          _errorMessage = 'Request failed with status ${error.statusCode}';
      }
    } else if (error is SocketException || error is TimeoutException) {
      _errorMessage = 'Network error - check your internet connection';
    } else if (error.toString().contains('XMLHttpRequest')) {
      _errorMessage = 'Connection failed - server might be offline or unreachable.\nPlease check your connection or try again later.';
    } else {
      _errorMessage = 'An unexpected error occurred: ${error.toString()}';
    }
    notifyListeners();
  }

  void setSuccessMessage(String message) {
    _errorMessage = null;
    _successMessage = message;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _successMessage = null;
    _errorMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    if (_errorMessage != null || _successMessage != null) {
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
    }
  }



  // ------------- INSTANCES -------------
  Future<void> fetchInstances() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/instances'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _instances = data.map((json) => WLEDInstance.fromJson(json)).toList();
        await Future.wait(_instances.map((instance) => getDeviceInfo(instance.id)));
      } else {
        throw response; // Throw the response to be handled by _handleApiError
      }
    } catch (e) {
      _instances = [];
      rethrow; // Re-throw to be handled by the caller
    }
  }

  // Future<bool> autodiscoverInstances() async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$_baseUrl/api/instances/autodiscover'),
  //       headers: {'X-API-Key': _apiKey},
  //     ).timeout(const Duration(seconds: 10));
  //
  //     Map<String, dynamic> jsonResponse = json.decode(response.body);
  //     if (response.statusCode == 200) {
  //       _successMessage = "${jsonResponse['message']}\n${jsonResponse['totalFound']} ${jsonResponse['totalFound'] == 1 ? 'instance' : 'instances'} found";
  //       return jsonResponse['newInstances'];
  //     } else {
  //       _errorMessage = "${jsonResponse['error']}";
  //       return false;
  //     }
  //   } catch (e) {
  //     rethrow; // Re-throw to be handled by the caller
  //   } finally {
  //     notifyListeners();
  //   }
  // }

  Future<WLEDInstance> createInstance(String ip, String name, {bool fromAutodiscover = false}) async {
    _isLoading = true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/instances'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ip': ip,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newInstance = WLEDInstance.fromJson(json.decode(response.body));
        _instances.add(newInstance);

        if(!fromAutodiscover)
          _successMessage = 'Instance created successfully';

        return newInstance;
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateInstance(WLEDInstance instance, String ip, String name) async {
    final id = instance.id;
    _isLoading = true;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/instances/$id'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ip': ip,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final updatedInstance = WLEDInstance.fromJson(json.decode(response.body));
        final index = _instances.indexWhere((i) => i.id == id);
        if (index != -1) {
          _instances[index] = updatedInstance;
          notifyListeners();
        }
        _successMessage = 'Instance updated successfully';
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteInstance(int id) async {
    _isLoading = true;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/instances/$id'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _instances.removeWhere((i) => i.id == id);
        _successMessage = 'Instance deleted successfully';
        await fetchPresets(); // Refresh the presets list. It's possible some presets are removed.
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> reorderInstances(List<int> orderedIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/instances/reorder'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orderedIds': orderedIds,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<int> responseIds = data.map((json) => json['id'] as int).toList();

        if (responseIds.length != orderedIds.length || responseIds.asMap().entries.any((entry) => entry.value != orderedIds[entry.key])) {
          _errorMessage = 'Failed to reorder instances';
        } else {
          _instances = orderedIds.map((id) => _instances.firstWhere((instance) => instance.id == id)).toList();
        }

      } else {
        throw response; // Throw the response to be handled by _handleApiError
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }



  // ------------- PRESETS -------------
  Future<void> fetchPresets() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/presets'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _presets = data.map((json) => Preset.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw response; // Throw the response to be handled by _handleApiError
      }
    } catch (e) {
      _presets = [];
      rethrow; // Re-throw to be handled by the caller
    }
  }

  Future<Map<String, dynamic>> getPresetDetails(int presetId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/presets/$presetId'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<void> createPreset(String name, List<Map<String, dynamic>> instances) async {
    _isLoading = true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/presets'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'instances': instances,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newPreset = Preset.fromJson(json.decode(response.body));
        _presets.add(newPreset);
        _successMessage = 'Preset created successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updatePreset(int presetId, String name, List<Map<String, dynamic>> instances) async {
    _isLoading = true;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/presets/$presetId'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'instances': instances,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {

        final index = _presets.indexWhere((preset) => preset.id == presetId);
        if (index == -1)
          throw Exception('Preset not found for id: $presetId');

        _presets[index] = Preset.fromJson(json.decode(response.body));
        _successMessage = 'Preset updated successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> applyPreset(int presetId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/presets/$presetId/apply'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to apply preset: ${response.statusCode}');
      }

      // Success case - update state and notify
      _successMessage = 'Preset applied successfully';

      // Optionally refresh device states to get updated values
      await Future.delayed(const Duration(milliseconds: 300)); // Small delay for device to apply
      refreshDeviceStates();

    } catch (e) {
      _errorMessage = 'Failed to apply preset: ${e is TimeoutException ? 'Timeout' : 'Server error'}';
      rethrow;
    }
  }

  Future<void> deletePreset(int presetId) async {
    _isLoading = true;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/presets/$presetId'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _presets.removeWhere((p) => p.id == presetId);
        _successMessage = 'Preset deleted successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> reorderPresets(List<int> orderedIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/presets/reorder'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orderedIds': orderedIds,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<int> responseIds = data.map((json) => json['id'] as int).toList();

        if (responseIds.length != orderedIds.length || responseIds.asMap().entries.any((entry) => entry.value != orderedIds[entry.key])) {
          _errorMessage = 'Failed to reorder presets';
        } else {
          _presets = orderedIds.map((id) => _presets.firstWhere((preset) => preset.id == id)).toList();
        }

      } else {
        throw response; // Throw the response to be handled by _handleApiError
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }



  // ------------- SCHEDULES -------------
  Future<void> fetchSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/schedules'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _schedules = data.map((json) => Schedule.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _schedules = [];
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getScheduleDetails(int scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/schedules/$scheduleId'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<void> createSchedule({
    required String name,
    required String cronExpression,
    required int presetId,
    String? startDate,
    String? stopDate,
    bool enabled = true,
  }) async {
    _isLoading = true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/schedules'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'cron_expression': cronExpression,
          'preset_id': presetId,
          'start_date': startDate,
          'stop_date': stopDate,
          'enabled': enabled,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newSchedule = Schedule.fromJson(json.decode(response.body));
        _schedules.add(newSchedule);
        _successMessage = 'Schedule created successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateSchedule({
    required int scheduleId,
    String? name,
    String? cronExpression,
    int? presetId,
    String? startDate,
    String? stopDate,
    bool? enabled,
  }) async {
    _isLoading = true;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/schedules/$scheduleId'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'cron_expression': cronExpression,
          'preset_id': presetId,
          'start_date': startDate,
          'stop_date': stopDate,
          'enabled': enabled,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final index = _schedules.indexWhere((schedule) => schedule.id == scheduleId);
        if (index == -1) {
          throw Exception('Schedule not found for id: $scheduleId');
        }

        _schedules[index] = Schedule.fromJson(json.decode(response.body));
        _successMessage = 'Schedule updated successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteSchedule(int scheduleId) async {
    _isLoading = true;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/schedules/$scheduleId'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _schedules.removeWhere((s) => s.id == scheduleId);
        _successMessage = 'Schedule deleted successfully';
        notifyListeners();
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }



  // ------------- DEVICE -------------
  Future<void> getDeviceInfo(int instanceId) async {
    try {
      final instance = _instances.firstWhere(
            (instance) => instance.id == instanceId,
        orElse: () => throw Exception('Instance not found'),
      );

      final response = await http.get(
        Uri.parse('$_baseUrl/wled/$instanceId/info'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(instance.name == '')
          instance.name = data['name'];

        // Assuming 'data' is a Map<String, dynamic> containing the light info
        final lc = data['leds']['lc'] as int; // Extract the capability byte

        instance.supportsRGB = (lc & 0x01) != 0;  // Check if bit 0 is set (RGB support)
        instance.supportsWhite = (lc & 0x02) != 0;  // Check if bit 1 is set (White channel)
        instance.supportsCCT = (lc & 0x04) != 0;  // Check if bit 2 is set (CCT support)
      } else {
        instance.error = true;
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      // rethrow;
    }
  }


  Future<Map<String, dynamic>> getDevicePresets(int instanceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wled/$instanceId/presets.json'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeviceState(int instanceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wled/$instanceId/state'),
        headers: {'X-API-Key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final state = json.decode(response.body);
        _instanceStates[instanceId] = state;
        notifyListeners(); // ← Notify here for immediate UI update
        return state;
      } else {
        throw response;
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Map<String, dynamic>? getDeviceStateCached(int instanceId) => _instanceStates[instanceId];

  Future<void> refreshDeviceStates() async {
    try {
      await Future.wait(_instances.map((instance) => getDeviceState(instance.id)));
    } catch (e) {
      _handleApiError(e);
    }
  }

  Future<void> updateDeviceState(int instanceId, Map<String, dynamic> state) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wled/$instanceId/state'),
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(state),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Failed to update device state (HTTP ${response.statusCode})',
          Uri.parse('$_baseUrl/wled/$instanceId/state'),
        );
      }

      // Merge new state with existing cached state
      final newState = {
        ...?_instanceStates[instanceId],
        ...state
      };
      _instanceStates[instanceId] = newState;

      // Success feedback
      // _successMessage = 'Device state updated successfully';
    } on TimeoutException {
      _errorMessage = 'Device update timed out';
      rethrow;
    } on http.ClientException catch (e) {
      _errorMessage = 'Device update failed: ${e.message}';
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to update device state: ${e.toString()}';
      rethrow;
    }
  }
}
// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WLED Dashboard';

  @override
  String get presets => 'Presets';

  @override
  String get devices => 'Devices';

  @override
  String get schedules => 'Schedules';

  @override
  String get settings => 'Settings';

  @override
  String get addDevice => 'Add device';

  @override
  String get editDevice => 'Edit device';

  @override
  String get findDevices => 'Find devices';

  @override
  String get allOn => 'All on';

  @override
  String get allOff => 'All off';

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderDevices => 'Reorder devices';

  @override
  String get reorderPresets => 'Reorder presets';

  @override
  String get newPreset => 'New preset';

  @override
  String get editPreset => 'Edit preset';

  @override
  String get newSchedule => 'New schedule';

  @override
  String get editSchedule => 'Edit schedule';

  @override
  String get apply => 'Apply';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get nameOptionalHelp => 'Leave empty to use the name from WLED';

  @override
  String get ipAddress => 'IP address';

  @override
  String get ipAddressInvalid => 'Enter a valid IPv4 address, such as 192.168.1.25';

  @override
  String get noWledAtAddress => 'No WLED device found at this address';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count devices', one: '1 device');
    return '$_temp0';
  }

  @override
  String presetApplied(String name) {
    return '$name applied';
  }

  @override
  String devicesDidNotAnswer(String names) {
    return 'No answer from: $names';
  }

  @override
  String devicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count new devices',
      one: 'Added 1 new device',
      zero: 'No new devices found',
    );
    return '$_temp0';
  }

  @override
  String notReachable(String ip) {
    return '$ip is not reachable';
  }

  @override
  String get noPresetsTitle => 'No presets yet';

  @override
  String get noPresetsMessage => 'A preset sets several devices just right in one go.';

  @override
  String get noDevicesTitle => 'No devices yet';

  @override
  String get noDevicesMessage => 'Add a WLED device by its IP address or find devices on the network.';

  @override
  String get noSchedulesTitle => 'No schedules yet';

  @override
  String get noSchedulesMessage => 'A schedule applies a preset automatically at set times.';

  @override
  String get notConnectedTitle => 'Not connected';

  @override
  String get notConnectedMessage => 'Enter the connection details under Settings.';

  @override
  String get loadFailed => 'Couldn\'t load';

  @override
  String get errorNetwork => 'The server can\'t be reached. Check the address and your connection.';

  @override
  String get errorUnauthorized => 'The API key is not valid.';

  @override
  String get errorNotFound => 'This no longer exists. Refresh the list.';

  @override
  String get errorConflict => 'This name or address is already in use.';

  @override
  String get errorInvalid => 'The server refused this input.';

  @override
  String get errorDevice => 'The device doesn\'t answer.';

  @override
  String get errorServer => 'Something went wrong on the server.';

  @override
  String get deleteDeviceTitle => 'Delete device';

  @override
  String deleteDeviceMessage(String name) {
    return 'Delete $name? Presets and schedules stay; the device is only removed from them.';
  }

  @override
  String get deletePresetTitle => 'Delete preset';

  @override
  String deletePresetMessage(String name) {
    return 'Delete $name? The schedules that apply this preset are deleted too.';
  }

  @override
  String get deleteScheduleTitle => 'Delete schedule';

  @override
  String deleteScheduleMessage(String name) {
    return 'Delete $name?';
  }

  @override
  String get wledPreset => 'WLED preset';

  @override
  String get wledPresets => 'WLED presets';

  @override
  String get currentState => 'Current state';

  @override
  String get savedState => 'Saved state';

  @override
  String get currentStateHelp => 'Saving stores the state the device is in right now.';

  @override
  String get savedStateHelp => 'The state that was stored when the preset was made.';

  @override
  String get choosePreset => 'Choose a preset';

  @override
  String get noDevicePresets => 'This device has no presets.';

  @override
  String get brightness => 'Brightness';

  @override
  String get color => 'Color';

  @override
  String get colorLevel => 'Color level';

  @override
  String get white => 'White';

  @override
  String get colorTemperature => 'Color temperature';

  @override
  String get preset => 'Preset';

  @override
  String get time => 'Time';

  @override
  String get days => 'Days';

  @override
  String get everyDay => 'every day';

  @override
  String get chooseWeekday => 'Choose at least one day';

  @override
  String get period => 'Period';

  @override
  String get periodHelp => 'The start and end day are both included. Without dates the schedule always runs.';

  @override
  String get startDate => 'From';

  @override
  String get stopDate => 'Until';

  @override
  String get noDate => 'No date';

  @override
  String get stopBeforeStart => 'The end date is before the start date';

  @override
  String fromDate(String date) {
    return 'from $date';
  }

  @override
  String untilDate(String date) {
    return 'until $date';
  }

  @override
  String dateRange(String start, String stop) {
    return '$start – $stop';
  }

  @override
  String get presetNeededForSchedule => 'Create a preset first; a schedule applies one.';

  @override
  String cronReplaced(String cron) {
    return 'This schedule uses the cron expression $cron. Saving replaces it with the time and days below.';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get connection => 'Connection';

  @override
  String get serverUrl => 'Server address';

  @override
  String get serverUrlInvalid => 'Enter a full address, such as https://leds.example.com';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyRequired => 'Enter the API key';

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';

  @override
  String get testAndSave => 'Test and save';

  @override
  String get connected => 'Connected';
}

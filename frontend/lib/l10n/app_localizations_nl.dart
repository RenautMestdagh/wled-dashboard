// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class SNl extends S {
  SNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'WLED Dashboard';

  @override
  String get presets => 'Presets';

  @override
  String get devices => 'Toestellen';

  @override
  String get schedules => 'Planningen';

  @override
  String get settings => 'Instellingen';

  @override
  String get addDevice => 'Toestel toevoegen';

  @override
  String get editDevice => 'Toestel bewerken';

  @override
  String get findDevices => 'Toestellen zoeken';

  @override
  String get allOn => 'Alles aan';

  @override
  String get allOff => 'Alles uit';

  @override
  String get reorder => 'Volgorde wijzigen';

  @override
  String get reorderDevices => 'Volgorde van toestellen';

  @override
  String get reorderPresets => 'Volgorde van presets';

  @override
  String get newPreset => 'Nieuwe preset';

  @override
  String get editPreset => 'Preset bewerken';

  @override
  String get newSchedule => 'Nieuwe planning';

  @override
  String get editSchedule => 'Planning bewerken';

  @override
  String get apply => 'Toepassen';

  @override
  String get save => 'Opslaan';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get retry => 'Opnieuw';

  @override
  String get clear => 'Wissen';

  @override
  String get name => 'Naam';

  @override
  String get nameRequired => 'Geef een naam';

  @override
  String get nameOptional => 'Naam (optioneel)';

  @override
  String get nameOptionalHelp => 'Leeg laten om de naam uit WLED te gebruiken';

  @override
  String get ipAddress => 'IP-adres';

  @override
  String get ipAddressInvalid => 'Geef een geldig IPv4-adres, zoals 192.168.1.25';

  @override
  String get noWledAtAddress => 'Geen WLED-toestel gevonden op dit adres';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count toestellen', one: '1 toestel');
    return '$_temp0';
  }

  @override
  String presetApplied(String name) {
    return '$name toegepast';
  }

  @override
  String devicesDidNotAnswer(String names) {
    return 'Geen antwoord van: $names';
  }

  @override
  String devicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe toestellen toegevoegd',
      one: '1 nieuw toestel toegevoegd',
      zero: 'Geen nieuwe toestellen gevonden',
    );
    return '$_temp0';
  }

  @override
  String notReachable(String ip) {
    return '$ip is niet bereikbaar';
  }

  @override
  String get noPresetsTitle => 'Nog geen presets';

  @override
  String get noPresetsMessage => 'Een preset zet meerdere toestellen in één keer in de juiste stand.';

  @override
  String get noDevicesTitle => 'Nog geen toestellen';

  @override
  String get noDevicesMessage => 'Voeg een WLED-toestel toe met zijn IP-adres of zoek toestellen op het netwerk.';

  @override
  String get noSchedulesTitle => 'Nog geen planningen';

  @override
  String get noSchedulesMessage => 'Een planning past een preset automatisch toe op vaste tijden.';

  @override
  String get notConnectedTitle => 'Niet verbonden';

  @override
  String get notConnectedMessage => 'Vul bij Instellingen de verbindingsgegevens in.';

  @override
  String get loadFailed => 'Laden mislukt';

  @override
  String get errorNetwork => 'De server is niet bereikbaar. Controleer het adres en je verbinding.';

  @override
  String get errorUnauthorized => 'De API-sleutel is ongeldig.';

  @override
  String get errorNotFound => 'Dit bestaat niet meer. Vernieuw de lijst.';

  @override
  String get errorConflict => 'Deze naam of dit adres is al in gebruik.';

  @override
  String get errorInvalid => 'De server weigerde deze gegevens.';

  @override
  String get errorDevice => 'Het toestel antwoordt niet.';

  @override
  String get errorServer => 'Er ging iets mis op de server.';

  @override
  String get deleteDeviceTitle => 'Toestel verwijderen';

  @override
  String deleteDeviceMessage(String name) {
    return '$name verwijderen? Presets en planningen blijven bestaan; het toestel verdwijnt er alleen uit.';
  }

  @override
  String get deletePresetTitle => 'Preset verwijderen';

  @override
  String deletePresetMessage(String name) {
    return '$name verwijderen? De planningen die deze preset toepassen, worden ook verwijderd.';
  }

  @override
  String get deleteScheduleTitle => 'Planning verwijderen';

  @override
  String deleteScheduleMessage(String name) {
    return '$name verwijderen?';
  }

  @override
  String get wledPreset => 'WLED-preset';

  @override
  String get wledPresets => 'WLED-presets';

  @override
  String get currentState => 'Huidige stand';

  @override
  String get savedState => 'Bewaarde stand';

  @override
  String get currentStateHelp => 'Bij het opslaan wordt de stand die het toestel nu heeft bewaard.';

  @override
  String get savedStateHelp => 'De stand die bij het aanmaken van de preset bewaard werd.';

  @override
  String get choosePreset => 'Kies een preset';

  @override
  String get noDevicePresets => 'Dit toestel heeft geen presets.';

  @override
  String get brightness => 'Helderheid';

  @override
  String get color => 'Kleur';

  @override
  String get colorLevel => 'Kleursterkte';

  @override
  String get white => 'Wit';

  @override
  String get colorTemperature => 'Kleurtemperatuur';

  @override
  String get preset => 'Preset';

  @override
  String get time => 'Tijd';

  @override
  String get days => 'Dagen';

  @override
  String get everyDay => 'elke dag';

  @override
  String get chooseWeekday => 'Kies minstens één dag';

  @override
  String get period => 'Periode';

  @override
  String get periodHelp => 'Begin- en einddag tellen allebei mee. Zonder datum loopt de planning altijd.';

  @override
  String get startDate => 'Vanaf';

  @override
  String get stopDate => 'Tot en met';

  @override
  String get noDate => 'Geen datum';

  @override
  String get stopBeforeStart => 'De einddatum ligt voor de begindatum';

  @override
  String fromDate(String date) {
    return 'vanaf $date';
  }

  @override
  String untilDate(String date) {
    return 'tot en met $date';
  }

  @override
  String dateRange(String start, String stop) {
    return '$start – $stop';
  }

  @override
  String get presetNeededForSchedule => 'Maak eerst een preset aan; een planning past er een toe.';

  @override
  String cronReplaced(String cron) {
    return 'Deze planning gebruikt de cron-expressie $cron. Opslaan vervangt die door de tijd en dagen hieronder.';
  }

  @override
  String get appearance => 'Weergave';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeDark => 'Donker';

  @override
  String get connection => 'Verbinding';

  @override
  String get serverUrl => 'Serveradres';

  @override
  String get serverUrlInvalid => 'Geef een volledig adres, zoals https://leds.example.com';

  @override
  String get apiKey => 'API-sleutel';

  @override
  String get apiKeyRequired => 'Geef de API-sleutel';

  @override
  String get showKey => 'Sleutel tonen';

  @override
  String get hideKey => 'Sleutel verbergen';

  @override
  String get testAndSave => 'Testen en opslaan';

  @override
  String get connected => 'Verbonden';
}

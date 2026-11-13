import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('nl')];

  /// No description provided for @appTitle.
  ///
  /// In nl, this message translates to:
  /// **'WLED Dashboard'**
  String get appTitle;

  /// No description provided for @presets.
  ///
  /// In nl, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @devices.
  ///
  /// In nl, this message translates to:
  /// **'Toestellen'**
  String get devices;

  /// No description provided for @schedules.
  ///
  /// In nl, this message translates to:
  /// **'Planningen'**
  String get schedules;

  /// No description provided for @settings.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get settings;

  /// No description provided for @addDevice.
  ///
  /// In nl, this message translates to:
  /// **'Toestel toevoegen'**
  String get addDevice;

  /// No description provided for @editDevice.
  ///
  /// In nl, this message translates to:
  /// **'Toestel bewerken'**
  String get editDevice;

  /// No description provided for @findDevices.
  ///
  /// In nl, this message translates to:
  /// **'Toestellen zoeken'**
  String get findDevices;

  /// No description provided for @allOn.
  ///
  /// In nl, this message translates to:
  /// **'Alles aan'**
  String get allOn;

  /// No description provided for @allOff.
  ///
  /// In nl, this message translates to:
  /// **'Alles uit'**
  String get allOff;

  /// No description provided for @reorder.
  ///
  /// In nl, this message translates to:
  /// **'Volgorde wijzigen'**
  String get reorder;

  /// No description provided for @reorderDevices.
  ///
  /// In nl, this message translates to:
  /// **'Volgorde van toestellen'**
  String get reorderDevices;

  /// No description provided for @reorderPresets.
  ///
  /// In nl, this message translates to:
  /// **'Volgorde van presets'**
  String get reorderPresets;

  /// No description provided for @newPreset.
  ///
  /// In nl, this message translates to:
  /// **'Nieuwe preset'**
  String get newPreset;

  /// No description provided for @editPreset.
  ///
  /// In nl, this message translates to:
  /// **'Preset bewerken'**
  String get editPreset;

  /// No description provided for @newSchedule.
  ///
  /// In nl, this message translates to:
  /// **'Nieuwe planning'**
  String get newSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In nl, this message translates to:
  /// **'Planning bewerken'**
  String get editSchedule;

  /// No description provided for @apply.
  ///
  /// In nl, this message translates to:
  /// **'Toepassen'**
  String get apply;

  /// No description provided for @save.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In nl, this message translates to:
  /// **'Wissen'**
  String get clear;

  /// No description provided for @name.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In nl, this message translates to:
  /// **'Geef een naam'**
  String get nameRequired;

  /// No description provided for @nameOptional.
  ///
  /// In nl, this message translates to:
  /// **'Naam (optioneel)'**
  String get nameOptional;

  /// No description provided for @nameOptionalHelp.
  ///
  /// In nl, this message translates to:
  /// **'Leeg laten om de naam uit WLED te gebruiken'**
  String get nameOptionalHelp;

  /// No description provided for @ipAddress.
  ///
  /// In nl, this message translates to:
  /// **'IP-adres'**
  String get ipAddress;

  /// No description provided for @ipAddressInvalid.
  ///
  /// In nl, this message translates to:
  /// **'Geef een geldig IPv4-adres, zoals 192.168.1.25'**
  String get ipAddressInvalid;

  /// No description provided for @noWledAtAddress.
  ///
  /// In nl, this message translates to:
  /// **'Geen WLED-toestel gevonden op dit adres'**
  String get noWledAtAddress;

  /// No description provided for @deviceCount.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 toestel} other{{count} toestellen}}'**
  String deviceCount(int count);

  /// No description provided for @presetApplied.
  ///
  /// In nl, this message translates to:
  /// **'{name} toegepast'**
  String presetApplied(String name);

  /// No description provided for @devicesDidNotAnswer.
  ///
  /// In nl, this message translates to:
  /// **'Geen antwoord van: {names}'**
  String devicesDidNotAnswer(String names);

  /// No description provided for @devicesFound.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =0{Geen nieuwe toestellen gevonden} =1{1 nieuw toestel toegevoegd} other{{count} nieuwe toestellen toegevoegd}}'**
  String devicesFound(int count);

  /// No description provided for @notReachable.
  ///
  /// In nl, this message translates to:
  /// **'{ip} is niet bereikbaar'**
  String notReachable(String ip);

  /// No description provided for @noPresetsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen presets'**
  String get noPresetsTitle;

  /// No description provided for @noPresetsMessage.
  ///
  /// In nl, this message translates to:
  /// **'Een preset zet meerdere toestellen in één keer in de juiste stand.'**
  String get noPresetsMessage;

  /// No description provided for @noDevicesTitle.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen toestellen'**
  String get noDevicesTitle;

  /// No description provided for @noDevicesMessage.
  ///
  /// In nl, this message translates to:
  /// **'Voeg een WLED-toestel toe met zijn IP-adres of zoek toestellen op het netwerk.'**
  String get noDevicesMessage;

  /// No description provided for @noSchedulesTitle.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen planningen'**
  String get noSchedulesTitle;

  /// No description provided for @noSchedulesMessage.
  ///
  /// In nl, this message translates to:
  /// **'Een planning past een preset automatisch toe op vaste tijden.'**
  String get noSchedulesMessage;

  /// No description provided for @notConnectedTitle.
  ///
  /// In nl, this message translates to:
  /// **'Niet verbonden'**
  String get notConnectedTitle;

  /// No description provided for @notConnectedMessage.
  ///
  /// In nl, this message translates to:
  /// **'Vul bij Instellingen de verbindingsgegevens in.'**
  String get notConnectedMessage;

  /// No description provided for @loadFailed.
  ///
  /// In nl, this message translates to:
  /// **'Laden mislukt'**
  String get loadFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In nl, this message translates to:
  /// **'De server is niet bereikbaar. Controleer het adres en je verbinding.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In nl, this message translates to:
  /// **'De API-sleutel is ongeldig.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In nl, this message translates to:
  /// **'Dit bestaat niet meer. Vernieuw de lijst.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In nl, this message translates to:
  /// **'Deze naam of dit adres is al in gebruik.'**
  String get errorConflict;

  /// No description provided for @errorInvalid.
  ///
  /// In nl, this message translates to:
  /// **'De server weigerde deze gegevens.'**
  String get errorInvalid;

  /// No description provided for @errorDevice.
  ///
  /// In nl, this message translates to:
  /// **'Het toestel antwoordt niet.'**
  String get errorDevice;

  /// No description provided for @errorServer.
  ///
  /// In nl, this message translates to:
  /// **'Er ging iets mis op de server.'**
  String get errorServer;

  /// No description provided for @deleteDeviceTitle.
  ///
  /// In nl, this message translates to:
  /// **'Toestel verwijderen'**
  String get deleteDeviceTitle;

  /// No description provided for @deleteDeviceMessage.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen? Presets en planningen blijven bestaan; het toestel verdwijnt er alleen uit.'**
  String deleteDeviceMessage(String name);

  /// No description provided for @deletePresetTitle.
  ///
  /// In nl, this message translates to:
  /// **'Preset verwijderen'**
  String get deletePresetTitle;

  /// No description provided for @deletePresetMessage.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen? De planningen die deze preset toepassen, worden ook verwijderd.'**
  String deletePresetMessage(String name);

  /// No description provided for @deleteScheduleTitle.
  ///
  /// In nl, this message translates to:
  /// **'Planning verwijderen'**
  String get deleteScheduleTitle;

  /// No description provided for @deleteScheduleMessage.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen?'**
  String deleteScheduleMessage(String name);

  /// No description provided for @wledPreset.
  ///
  /// In nl, this message translates to:
  /// **'WLED-preset'**
  String get wledPreset;

  /// No description provided for @wledPresets.
  ///
  /// In nl, this message translates to:
  /// **'WLED-presets'**
  String get wledPresets;

  /// No description provided for @currentState.
  ///
  /// In nl, this message translates to:
  /// **'Huidige stand'**
  String get currentState;

  /// No description provided for @savedState.
  ///
  /// In nl, this message translates to:
  /// **'Bewaarde stand'**
  String get savedState;

  /// No description provided for @currentStateHelp.
  ///
  /// In nl, this message translates to:
  /// **'Bij het opslaan wordt de stand die het toestel nu heeft bewaard.'**
  String get currentStateHelp;

  /// No description provided for @savedStateHelp.
  ///
  /// In nl, this message translates to:
  /// **'De stand die bij het aanmaken van de preset bewaard werd.'**
  String get savedStateHelp;

  /// No description provided for @choosePreset.
  ///
  /// In nl, this message translates to:
  /// **'Kies een preset'**
  String get choosePreset;

  /// No description provided for @noDevicePresets.
  ///
  /// In nl, this message translates to:
  /// **'Dit toestel heeft geen presets.'**
  String get noDevicePresets;

  /// No description provided for @brightness.
  ///
  /// In nl, this message translates to:
  /// **'Helderheid'**
  String get brightness;

  /// No description provided for @color.
  ///
  /// In nl, this message translates to:
  /// **'Kleur'**
  String get color;

  /// No description provided for @colorLevel.
  ///
  /// In nl, this message translates to:
  /// **'Kleursterkte'**
  String get colorLevel;

  /// No description provided for @white.
  ///
  /// In nl, this message translates to:
  /// **'Wit'**
  String get white;

  /// No description provided for @colorTemperature.
  ///
  /// In nl, this message translates to:
  /// **'Kleurtemperatuur'**
  String get colorTemperature;

  /// No description provided for @preset.
  ///
  /// In nl, this message translates to:
  /// **'Preset'**
  String get preset;

  /// No description provided for @time.
  ///
  /// In nl, this message translates to:
  /// **'Tijd'**
  String get time;

  /// No description provided for @days.
  ///
  /// In nl, this message translates to:
  /// **'Dagen'**
  String get days;

  /// No description provided for @everyDay.
  ///
  /// In nl, this message translates to:
  /// **'elke dag'**
  String get everyDay;

  /// No description provided for @chooseWeekday.
  ///
  /// In nl, this message translates to:
  /// **'Kies minstens één dag'**
  String get chooseWeekday;

  /// No description provided for @period.
  ///
  /// In nl, this message translates to:
  /// **'Periode'**
  String get period;

  /// No description provided for @periodHelp.
  ///
  /// In nl, this message translates to:
  /// **'Begin- en einddag tellen allebei mee. Zonder datum loopt de planning altijd.'**
  String get periodHelp;

  /// No description provided for @startDate.
  ///
  /// In nl, this message translates to:
  /// **'Vanaf'**
  String get startDate;

  /// No description provided for @stopDate.
  ///
  /// In nl, this message translates to:
  /// **'Tot en met'**
  String get stopDate;

  /// No description provided for @noDate.
  ///
  /// In nl, this message translates to:
  /// **'Geen datum'**
  String get noDate;

  /// No description provided for @stopBeforeStart.
  ///
  /// In nl, this message translates to:
  /// **'De einddatum ligt voor de begindatum'**
  String get stopBeforeStart;

  /// No description provided for @fromDate.
  ///
  /// In nl, this message translates to:
  /// **'vanaf {date}'**
  String fromDate(String date);

  /// No description provided for @untilDate.
  ///
  /// In nl, this message translates to:
  /// **'tot en met {date}'**
  String untilDate(String date);

  /// No description provided for @dateRange.
  ///
  /// In nl, this message translates to:
  /// **'{start} – {stop}'**
  String dateRange(String start, String stop);

  /// No description provided for @presetNeededForSchedule.
  ///
  /// In nl, this message translates to:
  /// **'Maak eerst een preset aan; een planning past er een toe.'**
  String get presetNeededForSchedule;

  /// No description provided for @cronReplaced.
  ///
  /// In nl, this message translates to:
  /// **'Deze planning gebruikt de cron-expressie {cron}. Opslaan vervangt die door de tijd en dagen hieronder.'**
  String cronReplaced(String cron);

  /// No description provided for @appearance.
  ///
  /// In nl, this message translates to:
  /// **'Weergave'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In nl, this message translates to:
  /// **'Systeem'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In nl, this message translates to:
  /// **'Donker'**
  String get themeDark;

  /// No description provided for @connection.
  ///
  /// In nl, this message translates to:
  /// **'Verbinding'**
  String get connection;

  /// No description provided for @serverUrl.
  ///
  /// In nl, this message translates to:
  /// **'Serveradres'**
  String get serverUrl;

  /// No description provided for @serverUrlInvalid.
  ///
  /// In nl, this message translates to:
  /// **'Geef een volledig adres, zoals https://leds.example.com'**
  String get serverUrlInvalid;

  /// No description provided for @apiKey.
  ///
  /// In nl, this message translates to:
  /// **'API-sleutel'**
  String get apiKey;

  /// No description provided for @apiKeyRequired.
  ///
  /// In nl, this message translates to:
  /// **'Geef de API-sleutel'**
  String get apiKeyRequired;

  /// No description provided for @showKey.
  ///
  /// In nl, this message translates to:
  /// **'Sleutel tonen'**
  String get showKey;

  /// No description provided for @hideKey.
  ///
  /// In nl, this message translates to:
  /// **'Sleutel verbergen'**
  String get hideKey;

  /// No description provided for @testAndSave.
  ///
  /// In nl, this message translates to:
  /// **'Testen en opslaan'**
  String get testAndSave;

  /// No description provided for @connected.
  ///
  /// In nl, this message translates to:
  /// **'Verbonden'**
  String get connected;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'nl':
      return SNl();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

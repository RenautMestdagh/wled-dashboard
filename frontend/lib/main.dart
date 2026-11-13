import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'data/settings.dart';
import 'data/store.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
import 'widgets/scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WledApp(settings: await Settings.load()));
}

class WledApp extends StatefulWidget {
  const WledApp({super.key, required this.settings, this.client});

  final Settings settings;
  final http.Client? client;

  @override
  State<WledApp> createState() => _WledAppState();
}

class _WledAppState extends State<WledApp> {
  late final _store = Store(settings: widget.settings, client: widget.client);

  @override
  void initState() {
    super.initState();
    unawaited(_store.refresh());
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scope(
      value: widget.settings,
      child: Scope(
        value: _store,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => MaterialApp(
            onGenerateTitle: (context) => S.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            themeMode: widget.settings.themeMode,
            localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
            supportedLocales: S.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}

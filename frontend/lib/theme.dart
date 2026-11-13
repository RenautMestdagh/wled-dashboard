import 'package:material_ui/material_ui.dart';

ThemeData appTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF388E3C), brightness: brightness),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'models/instance.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize ApiService first and load settings
  final apiService = ApiService();
  await apiService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: apiService),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );

  // Wait for both initialization and first frame
  await Future.wait([
    apiService.initialize(),
    _waitForFirstFrame(widgetsBinding),
  ]);

  // Now remove splash screen
  FlutterNativeSplash.remove();
}

Future<void> _waitForFirstFrame(WidgetsBinding binding) async {
  final completer = Completer<void>();
  binding.addPostFrameCallback((_) => completer.complete());
  return completer.future;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define your custom colors
  static const Color _lightPrimary = Color(0xFF388E3C); // Green
  static const Color _lightSecondary = Color(0xFFFFA000); // Amber
  static const Color _lightSurface = Color(0xFFF5F5F5); // Light gray surface
  static const Color _lightSurfaceContainer = Color(0xFFE0E0E0); // Slightly darker for containers
  static const Color _lightOutline = Color(0xFFBDBDBD); // Medium gray for outlines

  static const Color _darkPrimary = Color(0xFF4CAF50); // Light Green
  static const Color _darkSecondary = Color(0xFFFFC107); // Amber
  static const Color _darkSurface = Color(0xFF303030); // Dark surface
  static const Color _darkSurfaceContainer = Color(0xFF424242); // Slightly lighter for containers
  static const Color _darkOutline = Color(0xFF757575); // Medium gray for outlines

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {

        return MaterialApp(
          title: 'WLED Controller',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(
              primary: _lightPrimary,
              secondary: _lightSecondary,
              surface: _lightSurface,
              surfaceContainerHighest: _lightSurfaceContainer,
              outline: _lightOutline,
              onSurface: Colors.black87,
              onPrimary: Colors.white,
              onSecondary: Colors.black87,
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(_lightSurfaceContainer),
                elevation: WidgetStateProperty.all(8),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _lightSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _lightOutline, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _lightOutline, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _lightPrimary, width: 2),
              ),
              hintStyle: TextStyle(
                color: Colors.black87.withAlpha(153), // Apply opacity to the normal text color
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(
              primary: _darkPrimary,
              secondary: _darkSecondary,
              surface: _darkSurface,
              surfaceContainerHighest: _darkSurfaceContainer,
              outline: _darkOutline,
              onSurface: Colors.white,
              onPrimary: Colors.black87,
              onSecondary: Colors.black87,
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(_darkSurfaceContainer),
                elevation: WidgetStateProperty.all(8),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _darkOutline, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _darkOutline, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _darkPrimary, width: 2),
              ),
              hintStyle: TextStyle(
                color: Colors.white.withAlpha(153), // Apply opacity to the normal text color
              ),
            ),
          ),
          themeMode: themeService.themeMode,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
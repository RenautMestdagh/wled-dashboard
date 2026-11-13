import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

void main() {
  testWidgets('choosing the dark theme applies it and remembers it', (tester) async {
    // Arrange
    final backend = FakeBackend();
    await pumpApp(tester, backend);
    await openTab(tester, 'Settings');

    // Act
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Assert
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness, Brightness.dark);
    expect((await SharedPreferences.getInstance()).getString('theme_mode'), 'dark');
  });

  testWidgets('it starts in the theme that was chosen before', (tester) async {
    // Arrange
    final backend = FakeBackend();
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    // Act
    await pumpApp(tester, backend, connected: false, keepPreferences: true);

    // Assert
    expect(Theme.of(tester.element(find.text('Not connected').first)).brightness, Brightness.dark);
  });

  testWidgets('without a connection the screens say how to connect', (tester) async {
    // Arrange
    final backend = FakeBackend();

    // Act
    await pumpApp(tester, backend, connected: false);

    // Assert
    expect(find.text('Not connected'), findsOneWidget);
    expect(backend.sent, isEmpty);
  });

  testWidgets('connecting with a valid key saves it and loads the data', (tester) async {
    // Arrange
    final backend = FakeBackend();
    backend.addPreset('Evening', {});
    await pumpApp(tester, backend, connected: false);
    await openTab(tester, 'Settings');

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'Server address'), 'http://wled.test');
    await tester.enterText(find.widgetWithText(TextFormField, 'API key'), apiKey);
    await tester.tap(find.text('Test and save'));
    await tester.pumpAndSettle();
    await openTab(tester, 'Presets');

    // Assert
    expect(find.text('Evening'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('api_key'), apiKey);
  });

  testWidgets('connecting with a wrong key says so and saves nothing', (tester) async {
    // Arrange
    final backend = FakeBackend();
    await pumpApp(tester, backend, connected: false);
    await openTab(tester, 'Settings');

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'Server address'), 'http://wled.test');
    await tester.enterText(find.widgetWithText(TextFormField, 'API key'), 'wrong');
    await tester.tap(find.text('Test and save'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('The API key is not valid.'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('api_key'), isNull);
  });
}

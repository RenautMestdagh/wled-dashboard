import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  testWidgets('it lists the presets with their number of devices', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    backend.addPreset('Evening', {desk: 1});

    // Act
    await pumpApp(tester, backend);

    // Assert
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('1 device'), findsOneWidget);
  });

  testWidgets('applying a preset reports that it was applied', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    final evening = backend.addPreset('Evening', {desk: 1});
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/presets/$evening/apply'), hasLength(1));
    expect(find.text('Evening applied'), findsOneWidget);
  });

  testWidgets('applying a preset names the devices that did not answer', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    final window = backend.addDevice('Window');
    backend.addPreset('Evening', {desk: 1, window: 2});
    backend.offline.add(window);
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('No answer from: Window'), findsOneWidget);
  });

  testWidgets('it explains what presets are when there are none', (tester) async {
    // Arrange
    final backend = FakeBackend();

    // Act
    await pumpApp(tester, backend);

    // Assert
    expect(find.text('No presets yet'), findsOneWidget);
  });

  testWidgets('it shows why loading failed and loads again on retry', (tester) async {
    // Arrange
    final backend = FakeBackend()..down = true;
    backend.addPreset('Evening', {});
    await pumpApp(tester, backend);
    expect(find.text("The server can't be reached. Check the address and your connection."), findsOneWidget);
    backend.down = false;

    // Act
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Evening'), findsOneWidget);
  });

  testWidgets('it creates a preset that starts a WLED preset on a device', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.byTooltip('New preset'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Reading');
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WLED preset'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rainbow').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/presets').single.body, {
      'name': 'Reading',
      'instances': [
        {'instance_id': desk, 'instance_preset': 2},
      ],
    });
    expect(find.text('Reading'), findsOneWidget);
  });

  testWidgets('it creates a preset that restores the current state of a device', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk', on: true);
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.byTooltip('New preset'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Like now');
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/presets').single.body, {
      'name': 'Like now',
      'instances': [
        {'instance_id': desk, 'instance_preset': backend.states[desk]},
      ],
    });
  });

  testWidgets('it does not save a preset without a name', (tester) async {
    // Arrange
    final backend = FakeBackend();
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.byTooltip('New preset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Enter a name'), findsOneWidget);
    expect(backend.sentTo('POST', '/api/presets'), isEmpty);
  });

  testWidgets('editing a preset keeps the saved state of a device', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    final saved = {'on': true, 'bri': 10};
    final evening = backend.addPreset('Evening', {desk: saved});
    await pumpApp(tester, backend);

    // Act
    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Late evening');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('PUT', '/api/presets/$evening').single.body, {
      'name': 'Late evening',
      'instances': [
        {'instance_id': desk, 'instance_preset': saved},
      ],
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  testWidgets('the switch of a device turns it on', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/instances/$desk/state').single.body, {'on': true});
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('a device that does not answer is marked as not reachable', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk', ip: '192.168.1.20');
    backend.offline.add(desk);

    // Act
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Assert
    expect(find.text('192.168.1.20 is not reachable'), findsOneWidget);
  });

  testWidgets('the power button turns all devices off when one is on', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk', on: true);
    final window = backend.addDevice('Window');
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.byTooltip('All off'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/instances/$desk/state').single.body, {'on': false});
    expect(backend.sentTo('POST', '/api/instances/$window/state').single.body, {'on': false});
  });

  testWidgets('choosing a WLED preset on the device screen starts it on the device', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Rainbow'), 100);
    await tester.tap(find.text('Rainbow'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/instances/$desk/state').single.body, {'ps': 2});
  });

  testWidgets('the device screen only shows the controls the device supports', (tester) async {
    // Arrange
    final backend = FakeBackend();
    backend.addDevice('Desk', capabilities: 1);
    backend.addDevice('Shelf', capabilities: 2 | 4);
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.text('Shelf'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Color'), findsNothing);
    expect(find.byTooltip('Color temperature'), findsOneWidget);
  });

  testWidgets('it adds a device by its IP address', (tester) async {
    // Arrange
    final backend = FakeBackend();
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.byTooltip('Add device'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'IP address'), '192.168.1.40');
    await tester.enterText(find.widgetWithText(TextFormField, 'Name (optional)'), 'Kitchen');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/instances').single.body, {'ip': '192.168.1.40', 'name': 'Kitchen'});
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('it refuses an address that is not IPv4 without asking the backend', (tester) async {
    // Arrange
    final backend = FakeBackend();
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');

    // Act
    await tester.tap(find.byTooltip('Add device'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'IP address'), '999.1.1.1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Enter a valid IPv4 address, such as 192.168.1.25'), findsOneWidget);
    expect(backend.sentTo('POST', '/api/instances'), isEmpty);
  });

  testWidgets('dismissing the edit dialog by tapping outside it leaves the device screen working', (tester) async {
    // Arrange
    final backend = FakeBackend();
    backend.addDevice('Desk');
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit device'));
    await tester.pumpAndSettle();

    // Act
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byTooltip('Brightness'), findsOneWidget);
  });

  testWidgets('deleting a device keeps the presets it was in', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    final window = backend.addDevice('Window');
    backend.addPreset('Evening', {desk: 1, window: 1});
    await pumpApp(tester, backend);
    await openTab(tester, 'Devices');
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete device'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await openTab(tester, 'Presets');

    // Assert
    expect(backend.sentTo('DELETE', '/api/instances/$desk'), hasLength(1));
    expect(find.text('Desk'), findsNothing);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('1 device'), findsOneWidget);
  });
}

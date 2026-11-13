import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  testWidgets('it lists a schedule with its preset, time and days', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final evening = backend.addPreset('Evening', {});
    backend.addSchedule('Weekdays', evening, cron: '30 19 * * 1-5');

    // Act
    await pumpApp(tester, backend);
    await openTab(tester, 'Schedules');

    // Assert
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Evening\n7:30 PM · Mon, Tue, Wed, Thu, Fri'), findsOneWidget);
  });

  testWidgets('it creates a schedule on the chosen days', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final evening = backend.addPreset('Evening', {});
    await pumpApp(tester, backend);
    await openTab(tester, 'Schedules');

    // Act
    await tester.tap(find.byTooltip('New schedule'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mondays and Fridays');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mon'));
    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(backend.sentTo('POST', '/api/schedules').single.body, {
      'name': 'Mondays and Fridays',
      'cron_expression': '0 20 * * 1,5',
      'preset_id': evening,
      'start_date': null,
      'stop_date': null,
      'enabled': true,
    });
    expect(find.text('Mondays and Fridays'), findsOneWidget);
  });

  testWidgets('it asks for a day before saving a schedule', (tester) async {
    // Arrange
    final backend = FakeBackend();
    backend.addPreset('Evening', {});
    await pumpApp(tester, backend);
    await openTab(tester, 'Schedules');

    // Act
    await tester.tap(find.byTooltip('New schedule'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Never');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Choose at least one day'), findsOneWidget);
    expect(backend.sentTo('POST', '/api/schedules'), isEmpty);
  });

  testWidgets('the switch of a schedule disables it', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final evening = backend.addPreset('Evening', {});
    final daily = backend.addSchedule('Daily', evening);
    await pumpApp(tester, backend);
    await openTab(tester, 'Schedules');

    // Act
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Assert
    expect((backend.sentTo('PUT', '/api/schedules/$daily').single.body! as Json)['enabled'], isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('editing a schedule keeps its time and days', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final evening = backend.addPreset('Evening', {});
    final weekend = backend.addSchedule('Weekend', evening, cron: '15 9 * * 6,7');
    await pumpApp(tester, backend);
    await openTab(tester, 'Schedules');

    // Act
    await tester.tap(find.text('Weekend'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Saturday and Sunday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Assert
    final body = backend.sentTo('PUT', '/api/schedules/$weekend').single.body! as Json;
    expect(body['name'], 'Saturday and Sunday');
    expect(body['cron_expression'], '15 9 * * 6,7');
  });
}

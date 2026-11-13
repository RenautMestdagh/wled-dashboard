import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  testWidgets('a phone gets a navigation bar', (tester) async {
    // Arrange
    final backend = FakeBackend();

    // Act
    await pumpApp(tester, backend, size: const Size(400, 800));

    // Assert
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('a tablet gets a navigation rail and content at a readable width', (tester) async {
    // Arrange
    final backend = FakeBackend();
    final desk = backend.addDevice('Desk');
    backend.addPreset('Evening', {desk: 1});

    // Act
    await pumpApp(tester, backend, size: const Size(1280, 800));

    // Assert
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.getSize(find.byType(Card)).width, lessThanOrEqualTo(720));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('it renders the presets tab and asks for api settings on first start', (WidgetTester tester) async {
    // Arrange
    SharedPreferences.setMockInitialValues({});
    final apiService = ApiService();
    await apiService.initialize();

    // Act
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: apiService),
          ChangeNotifierProvider(create: (_) => ThemeService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.text('WLED Controller'), findsOneWidget);
    expect(find.text('No presets yet'), findsOneWidget);
    expect(find.text('Please configure API settings'), findsOneWidget);
  });
}

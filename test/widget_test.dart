import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmasales/main.dart';
import 'package:pharmasales/services/locale_provider.dart';

void main() {
  testWidgets('Shows the login screen when no session is stored', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(PharmaSalesApp(localeProvider: LocaleProvider()));
    // The splash screen holds for a fixed minimum duration before
    // navigating, independent of any widget animation, so pump past it
    // explicitly before settling the route transition.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your workspace'), findsOneWidget);
  });
}

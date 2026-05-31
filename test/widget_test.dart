import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/main.dart';

void main() {
  testWidgets('SquadFill App Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SquadFillApp(),
      ),
    );

    // Verify that the SquadFill branding text is rendered on the Splash screen
    expect(find.text('Squad'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('AI-Driven Sports Coordination'), findsOneWidget);
  });
}

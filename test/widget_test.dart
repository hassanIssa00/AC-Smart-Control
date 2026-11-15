import 'package:flutter_test/flutter_test.dart';
import 'package:ac_smart_control/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AcSmartApp());
    expect(find.byType(AcSmartApp), findsOneWidget);
  });
}

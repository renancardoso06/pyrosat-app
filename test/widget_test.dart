import 'package:flutter_test/flutter_test.dart';
import 'package:firewatch_app/main.dart';

void main() {
  testWidgets('PyroSat smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PyroSatApp());
    expect(find.text('PyroSat'), findsWidgets);
  });
}
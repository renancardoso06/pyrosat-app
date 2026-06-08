import 'package:flutter_test/flutter_test.dart';
import 'package:firewatch_app/main.dart';

void main() {
  testWidgets('VigIA smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VigIAApp());
    expect(find.text('VigIA'), findsWidgets);
  });
}
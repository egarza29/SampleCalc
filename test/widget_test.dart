import 'package:flutter_test/flutter_test.dart';
import 'package:sample_calc/main.dart';

void main() {
  testWidgets('App loads and shows calculator UI', (WidgetTester tester) async {
    await tester.pumpWidget(const SampleCalcApp());
    await tester.pumpAndSettle();

    expect(find.text('SampleCalc'), findsWidgets);
    expect(find.text('DEG'), findsOneWidget);
  });
}

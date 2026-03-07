import 'package:flutter_test/flutter_test.dart';
import 'package:mathpad/main.dart';

void main() {
  testWidgets('App renders MathPad title', (WidgetTester tester) async {
    await tester.pumpWidget(const MathPadApp());
    expect(find.text('MathPad'), findsOneWidget);
  });
}

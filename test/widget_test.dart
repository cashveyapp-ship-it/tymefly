import 'package:flutter_test/flutter_test.dart';
import 'package:tymefly/main.dart';

void main() {
  testWidgets('TYMEFLY app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const TymeFlyApp());
    expect(find.text('tymefly'), findsOneWidget);
  });
}

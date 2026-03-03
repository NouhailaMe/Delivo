import 'package:flutter_test/flutter_test.dart';

import 'package:delivo/main.dart';

void main() {
  testWidgets('App boots to root widget', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('DELIVO'), findsOneWidget);
  });
}

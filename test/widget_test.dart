import 'package:flutter_test/flutter_test.dart';
import 'package:resq/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ResQApp());
    expect(find.byType(ResQApp), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:resq/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ResQApp());

    expect(find.text('ResQ'), findsOneWidget);
    expect(find.text('Start Emergency'), findsOneWidget);
  });
}

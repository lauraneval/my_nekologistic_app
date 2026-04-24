import 'package:flutter_test/flutter_test.dart';

import 'package:my_nekologistic_app/app.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const NekoLogisticApp());
    expect(find.text('NekoLogistic Courier'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:balbodh/app.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BalBodhApp());
    expect(find.text('बालबोध'), findsOneWidget);
  });
}

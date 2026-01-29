import 'package:flutter_test/flutter_test.dart';

import 'package:serifu/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SerifuApp());

    expect(find.text('Quiz + SNS'), findsOneWidget);
    expect(find.text("📅 Today's Quiz - January 30"), findsOneWidget);
  });
}

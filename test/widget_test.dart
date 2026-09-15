import 'package:flutter_test/flutter_test.dart';

import 'package:mombiz/main.dart';

void main() {
  testWidgets('Shows the Firebase startup result', (WidgetTester tester) async {
    await tester.pumpWidget(const MomBizApp());

    expect(find.text('MomBiz Firebase Connected'), findsNothing);
    expect(
      find.text('MomBiz could not start.\nPlease close and reopen the app.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const MomBizApp());

    expect(find.text('MomBiz Firebase Connected'), findsOneWidget);
    expect(find.textContaining('MomBiz could not start.'), findsNothing);
  });
}

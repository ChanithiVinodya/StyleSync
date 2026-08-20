import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/main.dart';

void main() {
  testWidgets('App renders bottom navigation with all 4 module tabs', (tester) async {
    await tester.pumpWidget(const StyleSyncApp());

    expect(find.text('Request'), findsOneWidget);
    expect(find.text('Designers'), findsOneWidget);
    expect(find.text('Quotes'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
  });
}

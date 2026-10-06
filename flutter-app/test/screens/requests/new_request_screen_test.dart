import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylesync/screens/requests/new_request_screen.dart';
import 'package:stylesync/modules/requests/providers/requests_provider.dart';
import 'package:stylesync/modules/requests/repositories/requests_repository.dart';

class MockRequestsRepository implements RequestsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('renders Length, Width, and Height input fields', (tester) async {
    final mockRepo = MockRequestsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestsRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: NewRequestScreen(),
        ),
      ),
    );

    // Verify the 3 dimension fields are displayed instead of old 'Room size (sq ft)'
    expect(find.text('Length (ft)'), findsOneWidget);
    expect(find.text('Width (ft)'), findsOneWidget);
    expect(find.text('Height (ft)'), findsOneWidget);
    expect(find.text('Room size (sq ft)'), findsNothing);

    // Enter length and width and verify estimated room size calculation
    final lengthFinder = find.widgetWithText(TextFormField, 'Length (ft)');
    final widthFinder = find.widgetWithText(TextFormField, 'Width (ft)');
    final heightFinder = find.widgetWithText(TextFormField, 'Height (ft)');

    await tester.enterText(lengthFinder, '20');
    await tester.enterText(widthFinder, '15');
    await tester.enterText(heightFinder, '10');
    await tester.pump();

    // 20 * 15 = 300.0 sq ft
    expect(find.text('Estimated Room Size: 300.0 sq ft'), findsOneWidget);
  });
}

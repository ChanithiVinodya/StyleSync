import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylesync/screens/requests/new_request_screen.dart';
import 'package:stylesync/modules/requests/providers/requests_provider.dart';
import 'package:stylesync/modules/requests/repositories/requests_repository.dart';
import 'package:stylesync/modules/requests/models/request_models.dart';

class MockRequestsRepository implements RequestsRepository {
  Map<String, dynamic>? lastCreatedDraftData;

  @override
  Future<RequestDetail> createDraft(Map<String, dynamic> data) async {
    lastCreatedDraftData = data;
    return RequestDetail(
      id: 'mock-draft-1',
      referenceNumber: 'REQ-123456',
      clientId: 'mock-client',
      roomType: RoomType.livingRoom,
      budget: 50000,
      status: RequestStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFlagged: false,
      palette: [],
      moodboard: [],
      statusHistory: [],
      requestedStyleTags: (data['requestedStyleTags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

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
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const NewRequestScreen(),
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

  testWidgets('renders style picker and validates at least one style selection on submit', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockRequestsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestsRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const NewRequestScreen(initialRoomType: 'livingRoom'),
        ),
      ),
    );

    // Verify style cards are rendered
    expect(find.text('Preferred Design Styles'), findsOneWidget);
    expect(find.text('Modern Minimalist'), findsOneWidget);
    expect(find.text('Scandinavian'), findsOneWidget);

    // Fill in valid dimensions, budget, description
    await tester.enterText(find.widgetWithText(TextFormField, 'Length (ft)'), '15');
    await tester.enterText(find.widgetWithText(TextFormField, 'Width (ft)'), '12');
    await tester.enterText(find.widgetWithText(TextFormField, 'Height (ft)'), '9');
    await tester.enterText(find.widgetWithText(TextFormField, 'Budget (LKR)'), '50000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Valid project description for testing');
    await tester.pump();

    // Attempt to submit without selecting any style
    final submitButton = find.widgetWithText(ElevatedButton, 'Submit Request');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Inline validation message should appear
    expect(find.text('Pick at least one style you like'), findsWidgets);

    // Scroll up to style cards
    final scandinavianCard = find.text('Scandinavian');
    await tester.ensureVisible(scandinavianCard);
    await tester.pumpAndSettle();
    await tester.tap(scandinavianCard);
    await tester.pumpAndSettle();

    // Select another style
    final industrialCard = find.text('Industrial');
    await tester.ensureVisible(industrialCard);
    await tester.pumpAndSettle();
    await tester.tap(industrialCard);
    await tester.pumpAndSettle();

    // Verify 2 selected badge
    expect(find.text('2 selected'), findsOneWidget);

    // Dismiss any active SnackBar
    ScaffoldMessenger.of(tester.element(find.byType(NewRequestScreen))).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    // Save draft
    final saveDraftButton = find.widgetWithText(OutlinedButton, 'Save draft');
    await tester.ensureVisible(saveDraftButton);
    await tester.pumpAndSettle();
    await tester.tap(saveDraftButton);
    await tester.pumpAndSettle();

    // Verify requestedStyleTags were included in draft creation payload
    expect(mockRepo.lastCreatedDraftData, isNotNull);
    expect(mockRepo.lastCreatedDraftData!['requestedStyleTags'], containsAll(['Scandinavian', 'Industrial']));
  });

  testWidgets('automatically saves draft when leaving screen if more than 1 section is filled', (tester) async {
    final mockRepo = MockRequestsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestsRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewRequestScreen(initialRoomType: 'livingRoom'),
                      ),
                    );
                  },
                  child: const Text('Open Request Form'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Open form
    await tester.tap(find.text('Open Request Form'));
    await tester.pumpAndSettle();

    // Currently 1 section is filled (roomType). Repo should not have created a draft yet.
    expect(mockRepo.lastCreatedDraftData, isNull);

    // Fill another section (Budget) -> now 2 sections filled
    await tester.enterText(find.widgetWithText(TextFormField, 'Budget (LKR)'), '75000');
    await tester.pump();

    // Pop the screen (simulate user leaving / back button)
    final navigator = Navigator.of(tester.element(find.byType(NewRequestScreen)));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    // Verify draft was automatically created
    expect(mockRepo.lastCreatedDraftData, isNotNull);
    expect(mockRepo.lastCreatedDraftData!['budget'], 75000.0);
    expect(mockRepo.lastCreatedDraftData!['roomType'], 'livingRoom');
  });
}

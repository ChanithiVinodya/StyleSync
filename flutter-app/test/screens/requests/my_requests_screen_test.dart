import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylesync/screens/requests/my_requests_screen.dart';
import 'package:stylesync/modules/requests/providers/requests_provider.dart';
import 'package:stylesync/modules/requests/repositories/requests_repository.dart';
import 'package:stylesync/modules/requests/models/request_models.dart';

class MockRequestsRepository implements RequestsRepository {
  bool failList = false;
  Map<String, dynamic>? lastQuery;
  List<RequestSummary> mockRequests = [];
  bool failDelete = false;
  String? deletedId;

  @override
  Future<PagedResult<RequestSummary>> listRequests({Map<String, dynamic>? query}) async {
    lastQuery = query;
    if (failList) throw Exception('Failed to fetch');
    final page = query?['page'] ?? 1;
    return PagedResult(
      items: mockRequests.skip((page - 1) * 10).take(10).toList(),
      totalCount: mockRequests.length,
      page: page,
      pageSize: 10,
      totalPages: 1,
    );
  }

  @override
  Future<void> deleteDraft(String id) async {
    if (failDelete) throw Exception('Failed to delete');
    deletedId = id;
    mockRequests.removeWhere((r) => r.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRequestsRepository mockRepo;

  setUp(() {
    mockRepo = MockRequestsRepository();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        requestsRepositoryProvider.overrideWithValue(mockRepo as dynamic),
      ],
      child: const MaterialApp(
        home: MyRequestsScreen(),
      ),
    );
  }

  testWidgets('shows empty state when no requests', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('You have no requests yet'), findsOneWidget);
    expect(find.text('Create your first request'), findsOneWidget);
  });

  testWidgets('shows error state when fetch fails', (tester) async {
    mockRepo.failList = true;
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Failed to load requests'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('debounces search and builds correct query', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Type something
    await tester.enterText(find.byType(TextField), 'bedroom');
    
    // Immediate query shouldn't have search yet because of 400ms debounce
    expect(mockRepo.lastQuery?['search'], isNull);

    // Wait for debounce
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockRepo.lastQuery?['search'], 'bedroom');
    // Also tests filter empty state since no results:
    expect(find.text('No results for your filters'), findsOneWidget);
  });

  testWidgets('filter + sort + page query building', (tester) async {
    mockRepo.mockRequests = List.generate(15, (i) => RequestSummary(
      id: 'req_$i',
      referenceNumber: 'REF-$i',
      status: RequestStatus.draft,
      roomType: RoomType.livingRoom,
      budget: 1000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Null thumbnail to avoid Image.network crashes in tests
      thumbnailUrl: null,
    ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Page 1 should be fetched
    expect(mockRepo.lastQuery?['page'], 1);
    expect(mockRepo.lastQuery?['sortBy'], 'createdAt');
    expect(mockRepo.lastQuery?['sortDir'], 'desc');

    // Change sort to Oldest
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest').last);
    await tester.pumpAndSettle();

    expect(mockRepo.lastQuery?['sortBy'], 'createdAt');
    expect(mockRepo.lastQuery?['sortDir'], 'asc');

    // Change status filter
    await tester.tap(find.text('Submitted')); // 'Submitted' is a displayLabel
    await tester.pumpAndSettle();
    expect(mockRepo.lastQuery?['status'].first, 'submitted');
    
    // Check pagination by dragging list to bottom
    // We only have 10 on screen initially
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(mockRepo.lastQuery?['page'], 2);
  });

  testWidgets('delete confirmation for drafts', (tester) async {
    mockRepo.mockRequests = [
      RequestSummary(
        id: 'draft_1',
        referenceNumber: 'REF-1',
        status: RequestStatus.draft,
        roomType: RoomType.livingRoom,
        budget: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailUrl: null,
      )
    ];

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Tap popup menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    // Tap delete
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete Draft'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(mockRepo.deletedId, 'draft_1');
    expect(find.text('You have no requests yet'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylesync/screens/requests/request_detail_screen.dart';
import 'package:stylesync/modules/requests/providers/requests_provider.dart';
import 'package:stylesync/modules/requests/repositories/requests_repository.dart';
import 'package:stylesync/modules/requests/models/request_models.dart';

class MockRequestsRepository implements RequestsRepository {
  bool submitThrows400 = false;
  bool submitThrows409 = false;
  int submitCount = 0;
  int fetchCount = 0;
  String? mockRoomPhotoUrl;

  @override
  Future<RequestDetail> getRequest(String id) async {
    fetchCount++;
    return RequestDetail(
      id: id,
      referenceNumber: 'REF-1',
      clientId: 'client1',
      status: submitCount > 0 ? RequestStatus.submitted : RequestStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFlagged: false,
      palette: const [],
      moodboard: const [],
      statusHistory: const [],
      roomPhotoUrl: mockRoomPhotoUrl,
    );
  }

  @override
  Future<void> submit(String id) async {
    if (submitThrows400) {
      throw const ApiProblem(
        title: 'Validation Error',
        status: 400,
        errors: [ApiFieldError(field: 'budget', message: 'Budget is required')],
      );
    }
    if (submitThrows409) {
      throw const ApiProblem(
        title: 'Conflict',
        status: 409,
        errors: [],
      );
    }
    submitCount++;
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
        home: RequestDetailScreen(id: 'draft_1'),
      ),
    );
  }

  testWidgets('missing-photo path on submit', (tester) async {
    mockRepo.mockRoomPhotoUrl = null;

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Tap submit
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    // Should show snackbar
    expect(find.text('Missing required room photo to submit.'), findsOneWidget);
    expect(mockRepo.submitCount, 0);
  });

  testWidgets('submit with server errors (400)', (tester) async {
    mockRepo.mockRoomPhotoUrl = 'https://mock.com/photo.jpg';
    mockRepo.submitThrows400 = true;

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    // Should show dialog with budget error
    expect(find.text('Cannot Submit'), findsOneWidget);
    expect(find.text('• Budget is required'), findsOneWidget);
    // The error message comes from ApiFieldError.message
    expect(mockRepo.submitCount, 0);
  });

  testWidgets('submit success and timeline updates', (tester) async {
    mockRepo.mockRoomPhotoUrl = 'https://mock.com/photo.jpg';

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Verify it's draft initially
    expect(mockRepo.fetchCount, 1);
    expect(find.text('Submit Request'), findsOneWidget);

    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    // Submit count should be 1
    expect(mockRepo.submitCount, 1);
    
    // It should have re-fetched (fetchCount = 2)
    expect(mockRepo.fetchCount, 2);

    // Because mockRepo sets status to submitted if submitCount > 0
    // "Submit Request" button should disappear because it's no longer a draft
    expect(find.text('Submit Request'), findsNothing);
  });
}

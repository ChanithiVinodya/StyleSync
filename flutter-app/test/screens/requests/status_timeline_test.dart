import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/requests/models/request_models.dart';
import 'package:stylesync/screens/requests/widgets/status_timeline.dart';

void main() {
  Widget buildTimeline(RequestStatus currentStatus, List<StatusHistoryEntry> history, {String? cancelReason}) {
    return MaterialApp(
      home: Scaffold(
        body: StatusTimeline(
          currentStatus: currentStatus,
          history: history,
          cancelReason: cancelReason,
        ),
      ),
    );
  }

  testWidgets('normal timeline states', (tester) async {
    final history = [
      StatusHistoryEntry(status: RequestStatus.submitted, timestamp: DateTime.now(), note: ''),
      StatusHistoryEntry(status: RequestStatus.aiAnalysis, timestamp: DateTime.now(), note: 'Analysis completed'),
    ];

    await tester.pumpWidget(buildTimeline(RequestStatus.proposalReady, history));
    
    // Finds all standard steps up to Proposal Ready + the upcoming ones
    expect(find.text(RequestStatus.submitted.label), findsOneWidget);
    expect(find.text(RequestStatus.aiAnalysis.label), findsOneWidget);
    expect(find.text(RequestStatus.proposalReady.label), findsOneWidget);
    expect(find.text(RequestStatus.awaitingApproval.label), findsOneWidget);
    
    // Check note
    expect(find.text('Analysis completed'), findsOneWidget);
  });

  testWidgets('rejected state cuts off upcoming steps', (tester) async {
    final history = [
      StatusHistoryEntry(status: RequestStatus.submitted, timestamp: DateTime.now(), note: ''),
      StatusHistoryEntry(status: RequestStatus.rejected, timestamp: DateTime.now(), note: 'Budget too low'),
    ];

    await tester.pumpWidget(buildTimeline(RequestStatus.rejected, history));
    
    // Finds submitted and rejected
    expect(find.text(RequestStatus.submitted.label), findsOneWidget);
    expect(find.text(RequestStatus.rejected.label), findsOneWidget);
    expect(find.text('Budget too low'), findsOneWidget);
    
    // Should NOT find Awaiting Approval or Proposal Ready
    expect(find.text(RequestStatus.proposalReady.label), findsNothing);
  });

  testWidgets('cancelled state shows cancel reason', (tester) async {
    final history = [
      StatusHistoryEntry(status: RequestStatus.submitted, timestamp: DateTime.now(), note: ''),
    ];

    await tester.pumpWidget(buildTimeline(RequestStatus.cancelled, history, cancelReason: 'Changed my mind'));
    
    expect(find.text(RequestStatus.submitted.label), findsOneWidget);
    expect(find.text(RequestStatus.cancelled.label), findsOneWidget);
    expect(find.text('Changed my mind'), findsOneWidget);
  });
}

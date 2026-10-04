import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../modules/requests/models/request_models.dart';

class StatusTimeline extends StatelessWidget {
  final RequestStatus currentStatus;
  final List<StatusHistoryEntry> history;
  final String? cancelReason;
  final String? flagReason;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
    required this.history,
    this.cancelReason,
    this.flagReason,
  });

  static const List<RequestStatus> _orderedSteps = [
    RequestStatus.submitted,
    RequestStatus.aiAnalysis,
    RequestStatus.proposalReady,
    RequestStatus.awaitingApproval,
    RequestStatus.approved,
    RequestStatus.designerAssigned,
    RequestStatus.inProgress,
    RequestStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == RequestStatus.draft) {
      return const SizedBox.shrink(); // Drafts don't show the timeline (or just show Draft state)
    }

    final isTerminal = currentStatus == RequestStatus.rejected || currentStatus == RequestStatus.cancelled;
    final List<_TimelineStep> steps = [];

    // Find the max completed index
    int maxCompletedIdx = -1;
    for (int i = 0; i < _orderedSteps.length; i++) {
      if (history.any((h) => h.status == _orderedSteps[i])) {
        maxCompletedIdx = i;
      }
    }

    // Build standard steps up to maxCompletedIdx (or current if terminal)
    for (int i = 0; i < _orderedSteps.length; i++) {
      final stepStatus = _orderedSteps[i];
      final historyEntry = history.cast<StatusHistoryEntry?>().firstWhere(
        (h) => h?.status == stepStatus,
        orElse: () => null,
      );

      // If terminal, stop showing upcoming steps after the last completed one
      if (isTerminal && historyEntry == null && i > maxCompletedIdx) {
        break;
      }

      steps.add(_TimelineStep(
        status: stepStatus,
        label: stepStatus.label,
        timestamp: historyEntry?.timestamp,
        note: historyEntry?.note,
        isCompleted: historyEntry != null,
        isCurrent: !isTerminal && stepStatus == currentStatus,
      ));
    }

    // Append terminal step if applicable
    if (isTerminal) {
      final historyEntry = history.cast<StatusHistoryEntry?>().firstWhere(
        (h) => h?.status == currentStatus,
        orElse: () => null,
      );
      steps.add(_TimelineStep(
        status: currentStatus,
        label: currentStatus.label,
        timestamp: historyEntry?.timestamp,
        note: currentStatus == RequestStatus.cancelled ? (cancelReason ?? historyEntry?.note) : historyEntry?.note,
        isCompleted: true,
        isCurrent: true,
        isError: true,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isError
                        ? Colors.red
                        : step.isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : step.isCompleted
                                ? Colors.green
                                : Colors.grey.shade300,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40, // rough height for line
                    color: step.isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: step.isError
                            ? Colors.red
                            : step.isCompleted
                                ? Colors.black87
                                : Colors.grey,
                      ),
                    ),
                    if (step.timestamp != null)
                      Text(
                        DateFormat.yMd().add_Hm().format(step.timestamp!),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    if (step.note != null && step.note!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: step.isError ? Colors.red.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          step.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: step.isError ? Colors.red.shade900 : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TimelineStep {
  final RequestStatus status;
  final String label;
  final DateTime? timestamp;
  final String? note;
  final bool isCompleted;
  final bool isCurrent;
  final bool isError;

  _TimelineStep({
    required this.status,
    required this.label,
    this.timestamp,
    this.note,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isError = false,
  });
}

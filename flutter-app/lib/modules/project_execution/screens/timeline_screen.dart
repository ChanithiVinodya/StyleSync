import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_execution_providers.dart';
import '../models/project_execution_models.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  final String projectId;
  const TimelineScreen({super.key, required this.projectId});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  Future<void> _showEventDialog({TimelineEvent? event}) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    String eventType = event?.eventType ?? 'Update';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event == null ? 'New Event' : 'Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  onChanged: (val) => eventType = val,
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    hintText: eventType,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final service = ref.read(projectExecutionServiceProvider);
                final data = {
                  'eventType': eventType.isEmpty ? 'Update' : eventType,
                  'title': titleController.text,
                  'description': descriptionController.text,
                };
                try {
                  if (event == null) {
                    await service.createTimelineEvent(widget.projectId, data);
                  } else {
                    await service.updateTimelineEvent(widget.projectId, event.eventId, data);
                  }
                  if (context.mounted) Navigator.pop(context);
                  ref.invalidate(projectTimelineProvider(widget.projectId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(TimelineEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        await service.deleteTimelineEvent(widget.projectId, event.eventId);
        ref.invalidate(projectTimelineProvider(widget.projectId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(projectTimelineProvider(widget.projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Project Timeline', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: timelineAsync.when(
        data: (events) {
          final sortedEvents = List<TimelineEvent>.from(events)
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          if (sortedEvents.isEmpty) {
            return _buildEmptyState(isDark, textEspresso);
          }
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              ref.invalidate(projectTimelineProvider(widget.projectId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
                return _buildTimelineItem(event, isDark, textEspresso, terracotta, index == sortedEvents.length - 1);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        backgroundColor: terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getIconForEventType(String eventType) {
    final lower = eventType.toLowerCase();
    if (lower.contains('photo')) return Icons.add_photo_alternate_outlined;
    if (lower.contains('task')) return Icons.check_box_outlined;
    if (lower.contains('milestone')) return Icons.flag_outlined;
    if (lower.contains('material')) return Icons.inventory_2_outlined;
    if (lower.contains('delay')) return Icons.warning_amber_rounded;
    if (lower.contains('update')) return Icons.edit_note;
    return Icons.circle;
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isDark, Color textEspresso, Color terracotta, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF18110E) : Colors.white, width: 2),
                ),
                child: Icon(
                  _getIconForEventType(event.eventType),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF221915) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showEventDialog(event: event),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              onPressed: () => _deleteEvent(event),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.timestamp.toLocal().toString().split('.')[0],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
                      ),
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textEspresso) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline_outlined, size: 64, color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          const SizedBox(height: 16),
          Text(
            'No timeline events available.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO(Student 4): implement this screen — see PRD Section 4.1
import 'package:flutter/material.dart';

class ProjectTimelineScreen extends StatelessWidget {
  final String? projectId;
  const ProjectTimelineScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Timeline & Progress')),
      body: const Center(
        child: Text('Coming soon — build owned by Student 4'),
      ),
    );
  }
}

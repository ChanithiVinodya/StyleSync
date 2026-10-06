import 'package:flutter/material.dart';
import 'package:stylesync/modules/project_execution/project_execution_page.dart';

class ProjectTimelineScreen extends StatelessWidget {
  final String? projectId;
  const ProjectTimelineScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) {
    // Render the fully fleshed out ProjectExecutionPage from the student's module
    return ProjectExecutionPage(projectId: projectId ?? '123e4567-e89b-12d3-a456-426614174000');
  }
}

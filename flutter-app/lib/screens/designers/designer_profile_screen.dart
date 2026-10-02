// TODO(Student 1): implement this screen — see PRD Section 1.2
import 'package:flutter/material.dart';

class DesignerProfileScreen extends StatelessWidget {
  final String? id;
  const DesignerProfileScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Designer Profile & Portfolio')),
      body: const Center(
        child: Text('Coming soon — build owned by Student 1'),
      ),
    );
  }
}

// TODO(Student 2): implement this screen — see PRD Section 2.1
import 'package:flutter/material.dart';

class NewRequestScreen extends StatelessWidget {
  final String? initialRoomType;
  final String? roomType;

  const NewRequestScreen({
    super.key,
    this.initialRoomType,
    this.roomType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Request / Upload Photos')),
      body: const Center(
        child: Text('Coming soon — build owned by Student 2'),
      ),
    );
  }
}

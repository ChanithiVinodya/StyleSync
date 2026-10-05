// TODO(Student 3): implement this screen — see PRD Section 3.1
import 'package:flutter/material.dart';

class QuoteDetailScreen extends StatelessWidget {
  final String? id;
  const QuoteDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Detail & Approve/Reject')),
      body: const Center(
        child: Text('Coming soon — build owned by Student 3'),
      ),
    );
  }
}

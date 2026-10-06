// TODO(Student 3): implement this screen — see PRD Section 3.2
import 'package:flutter/material.dart';
import '../../shared/widgets/main_bottom_nav_bar.dart';

class ContractStatusScreen extends StatelessWidget {
  final String? id;
  const ContractStatusScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Status')),
      body: const Center(
        child: Text('Coming soon — build owned by Student 3'),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
    );
  }
}

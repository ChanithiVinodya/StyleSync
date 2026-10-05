import 'package:flutter/material.dart';
import '../../modules/designers/screens/designer_profile_screen.dart' as module_profile;

class DesignerProfileScreen extends StatelessWidget {
  final String? id;
  const DesignerProfileScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(id ?? '') ?? 1;
    return module_profile.DesignerProfileScreen(designerId: parsedId);
  }
}

import 'package:flutter/material.dart';
import 'screens/project_request_list_screen.dart';

void main() {
  runApp(const StyleSyncApp());
}

class StyleSyncApp extends StatelessWidget {
  const StyleSyncApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleSync - Room Makeovers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ProjectRequestListScreen(),
    );
  }
}

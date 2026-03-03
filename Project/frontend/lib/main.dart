import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const VisionQuestApp());
}

class VisionQuestApp extends StatelessWidget {
  const VisionQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
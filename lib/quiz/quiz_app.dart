import 'package:flutter/material.dart';
import 'screens/quiz_home_screen.dart';

/// 知识竞答应用入口
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '知识竞答',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const QuizHomeScreen(),
    );
  }
}

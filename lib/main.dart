import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quiz/quiz_app.dart';
import 'quiz/data/question_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置系统UI模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  await QuestionRepository.loadQuestions();
  runApp(const ProviderScope(child: QuizApp()));
}

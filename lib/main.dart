import 'package:flutter/material.dart';
import 'quiz/quiz_app.dart';
import 'quiz/data/question_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuestionRepository.loadQuestions();
  runApp(const QuizApp());
}

import 'package:flutter/material.dart';

class Lesson {
  final String title;
  final String subtitle;
  final String content;
  final String icon; // store as string (e.g. "visibility")
  final int progress;
  final List<Question> questions;
  final Color? color; // Added color property

  Lesson({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.progress,
    required this.questions,
    this.color,
  });

  // Helper method to convert questions to maps for QuizScreen
  List<Map<String, Object>> get questionsAsMap {
    return questions
        .map(
          (q) => {
            "question": q.question,
            "options": q.options,
            "answer": q.answer,
          },
        )
        .toList();
  }
}

class Question {
  final String question;
  final List<String> options;
  final int answer;

  Question({
    required this.question,
    required this.options,
    required this.answer,
  });
}

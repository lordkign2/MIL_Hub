import 'package:flutter/material.dart';

class LearnScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.all(24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text("📚 Learn"),
        ),
        body: const Center(
          child: Text(
            "Gamified lessons, quizzes, and badges will go here.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
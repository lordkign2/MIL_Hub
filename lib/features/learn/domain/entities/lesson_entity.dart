/// Lesson entity representing a learning module in the domain layer
class LessonEntity {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String icon;
  final int progress;
  final List<QuestionEntity> questions;
  final String? color; // Store as string representation

  const LessonEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.progress,
    required this.questions,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() {
    return 'LessonEntity{id: $id, title: $title, progress: $progress}';
  }
}

/// Question entity for quiz questions
class QuestionEntity {
  final String id;
  final String question;
  final List<String> options;
  final int answer;

  const QuestionEntity({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuestionEntity{id: $id, question: $question}';
  }
}

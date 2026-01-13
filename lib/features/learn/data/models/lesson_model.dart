import '../../domain/entities/lesson_entity.dart';

/// Lesson model for data layer that extends the domain entity
class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.content,
    required super.icon,
    required super.progress,
    required super.questions,
    super.color,
  });

  /// Create LessonModel from Lesson entity
  factory LessonModel.fromEntity(LessonEntity entity) {
    return LessonModel(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      content: entity.content,
      icon: entity.icon,
      progress: entity.progress,
      questions: entity.questions
          .map((q) => QuestionModel.fromEntity(q))
          .toList(),
      color: entity.color,
    );
  }

  /// Create LessonModel from JSON
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      content: json['content'] as String,
      icon: json['icon'] as String,
      progress: json['progress'] as int,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String?,
    );
  }

  /// Convert LessonModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'icon': icon,
      'progress': progress,
      'questions': questions.map((q) => (q as QuestionModel).toJson()).toList(),
      'color': color,
    };
  }

  /// Convert to LessonEntity
  LessonEntity toEntity() {
    return LessonEntity(
      id: id,
      title: title,
      subtitle: subtitle,
      content: content,
      icon: icon,
      progress: progress,
      questions: questions.map((q) => (q as QuestionModel).toEntity()).toList(),
      color: color,
    );
  }
}

/// Question model for data layer that extends the domain entity
class QuestionModel extends QuestionEntity {
  const QuestionModel({
    required super.id,
    required super.question,
    required super.options,
    required super.answer,
  });

  /// Create QuestionModel from Question entity
  factory QuestionModel.fromEntity(QuestionEntity entity) {
    return QuestionModel(
      id: entity.id,
      question: entity.question,
      options: entity.options,
      answer: entity.answer,
    );
  }

  /// Create QuestionModel from JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as int,
    );
  }

  /// Convert QuestionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answer': answer,
    };
  }

  /// Convert to QuestionEntity
  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      question: question,
      options: options,
      answer: answer,
    );
  }
}

import '../../domain/entities/lesson_entity.dart';

/// Base class for all lesson states
abstract class LessonState {
  const LessonState();
}

/// Initial state
class LessonInitial extends LessonState {
  const LessonInitial();
}

/// Loading state
class LessonLoading extends LessonState {
  const LessonLoading();
}

/// Loaded state with lessons
class LessonsLoaded extends LessonState {
  final List<LessonEntity> lessons;
  final Map<String, int> progress; // lessonId -> progress mapping

  const LessonsLoaded({required this.lessons, required this.progress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonsLoaded &&
          runtimeType == other.runtimeType &&
          lessons == other.lessons &&
          progress == other.progress;

  @override
  int get hashCode => lessons.hashCode ^ progress.hashCode;
}

/// Loaded state with a single lesson
class LessonLoaded extends LessonState {
  final LessonEntity lesson;
  final int progress;

  const LessonLoaded({required this.lesson, required this.progress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonLoaded &&
          runtimeType == other.runtimeType &&
          lesson == other.lesson &&
          progress == other.progress;

  @override
  int get hashCode => lesson.hashCode ^ progress.hashCode;
}

/// Error state
class LessonError extends LessonState {
  final String message;

  const LessonError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Success state for actions that don't return data
class LessonActionSuccess extends LessonState {
  final String message;

  const LessonActionSuccess({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonActionSuccess &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

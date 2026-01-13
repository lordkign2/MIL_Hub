
/// Base class for all lesson events
abstract class LessonEvent {
  const LessonEvent();
}

/// Event to load all lessons
class LoadLessonsEvent extends LessonEvent {
  const LoadLessonsEvent();
}

/// Event to load a specific lesson by ID
class LoadLessonByIdEvent extends LessonEvent {
  final String id;

  const LoadLessonByIdEvent({required this.id});
}

/// Event to update lesson progress
class UpdateLessonProgressEvent extends LessonEvent {
  final String lessonId;
  final int progress;

  const UpdateLessonProgressEvent({
    required this.lessonId,
    required this.progress,
  });
}

/// Event to complete a lesson
class CompleteLessonEvent extends LessonEvent {
  final String lessonId;

  const CompleteLessonEvent({required this.lessonId});
}

/// Event to refresh lessons
class RefreshLessonsEvent extends LessonEvent {
  const RefreshLessonsEvent();
}

/// Event to filter lessons
class FilterLessonsEvent extends LessonEvent {
  final String? category;
  final String? searchQuery;

  const FilterLessonsEvent({this.category, this.searchQuery});
}

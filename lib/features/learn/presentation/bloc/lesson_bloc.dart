import 'dart:async';
import '../../domain/usecases/get_all_lessons.dart';
import '../../domain/usecases/get_lesson_by_id.dart';
import '../../domain/usecases/get_user_progress.dart';
import '../../domain/usecases/update_lesson_progress.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

/// BLoC for handling lesson logic
class LessonBloc {
  final GetAllLessonsUseCase _getAllLessons;
  final GetLessonByIdUseCase _getLessonById;
  final GetUserProgressUseCase _getUserProgress;
  final UpdateLessonProgressUseCase _updateLessonProgress;

  // State management
  LessonState _state = const LessonInitial();
  final _stateController = StreamController<LessonState>.broadcast();

  // Event handling
  final _eventController = StreamController<LessonEvent>();
  late StreamSubscription _eventSubscription;

  LessonBloc({
    required GetAllLessonsUseCase getAllLessons,
    required GetLessonByIdUseCase getLessonById,
    required GetUserProgressUseCase getUserProgress,
    required UpdateLessonProgressUseCase updateLessonProgress,
  }) : _getAllLessons = getAllLessons,
       _getLessonById = getLessonById,
       _getUserProgress = getUserProgress,
       _updateLessonProgress = updateLessonProgress {
    // Initialize event handling
    _eventSubscription = _eventController.stream.listen(_handleEvent);
  }

  /// Current state
  LessonState get state => _state;

  /// State stream
  Stream<LessonState> get stream => _stateController.stream;

  /// Add event
  void add(LessonEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Handle events
  Future<void> _handleEvent(LessonEvent event) async {
    try {
      if (event is LoadLessonsEvent) {
        await _handleLoadLessons(event);
      } else if (event is LoadLessonByIdEvent) {
        await _handleLoadLessonById(event);
      } else if (event is UpdateLessonProgressEvent) {
        await _handleUpdateLessonProgress(event);
      } else if (event is CompleteLessonEvent) {
        await _handleCompleteLesson(event);
      } else if (event is RefreshLessonsEvent) {
        await _handleRefreshLessons(event);
      }
    } catch (e) {
      _emitState(LessonError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _handleLoadLessons(LoadLessonsEvent event) async {
    _emitState(const LessonLoading());

    // Get lessons and progress in parallel
    final lessonsResult = await _getAllLessons();
    final progressResult = await _getUserProgress();

    if (lessonsResult.lessons != null && progressResult.progress != null) {
      _emitState(
        LessonsLoaded(
          lessons: lessonsResult.lessons!,
          progress: progressResult.progress!,
        ),
      );
    } else {
      final errorMessage =
          lessonsResult.failure?.message ??
          progressResult.failure?.message ??
          'Failed to load lessons';
      _emitState(LessonError(message: errorMessage));
    }
  }

  Future<void> _handleLoadLessonById(LoadLessonByIdEvent event) async {
    _emitState(const LessonLoading());

    final lessonResult = await _getLessonById(event.id);
    final progressResult = await _getUserProgress();

    if (lessonResult.lesson != null && progressResult.progress != null) {
      final progress = progressResult.progress![event.id] ?? 0;
      _emitState(
        LessonLoaded(lesson: lessonResult.lesson!, progress: progress),
      );
    } else {
      final errorMessage =
          lessonResult.failure?.message ??
          progressResult.failure?.message ??
          'Failed to load lesson';
      _emitState(LessonError(message: errorMessage));
    }
  }

  Future<void> _handleUpdateLessonProgress(
    UpdateLessonProgressEvent event,
  ) async {
    final result = await _updateLessonProgress(
      lessonId: event.lessonId,
      progress: event.progress,
    );

    if (result.success) {
      // Reload lessons to update progress
      add(const LoadLessonsEvent());
      _emitState(const LessonActionSuccess(message: 'Progress updated'));
    } else {
      _emitState(
        LessonError(
          message: result.failure?.message ?? 'Failed to update progress',
        ),
      );
    }
  }

  Future<void> _handleCompleteLesson(CompleteLessonEvent event) async {
    final result = await _updateLessonProgress(
      lessonId: event.lessonId,
      progress: 100,
    );

    if (result.success) {
      // Reload lessons to update progress
      add(const LoadLessonsEvent());
      _emitState(const LessonActionSuccess(message: 'Lesson completed'));
    } else {
      _emitState(
        LessonError(
          message: result.failure?.message ?? 'Failed to complete lesson',
        ),
      );
    }
  }

  Future<void> _handleRefreshLessons(RefreshLessonsEvent event) async {
    // Force refresh by clearing any cache and reloading
    add(const LoadLessonsEvent());
  }

  void _emitState(LessonState newState) {
    if (_state != newState && !_stateController.isClosed) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription.cancel();
    _eventController.close();
    _stateController.close();
  }
}

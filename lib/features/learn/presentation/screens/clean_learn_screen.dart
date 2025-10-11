import 'package:flutter/material.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_display.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson_entity.dart';
import '../bloc/lesson_bloc.dart';
import '../bloc/lesson_event.dart';
import '../bloc/lesson_state.dart';
import '../widgets/lesson_card_widget.dart';

class CleanLearnScreen extends StatefulWidget {
  const CleanLearnScreen({super.key});

  @override
  State<CleanLearnScreen> createState() => _CleanLearnScreenState();
}

class _CleanLearnScreenState extends State<CleanLearnScreen> {
  late final LessonBloc _lessonBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _lessonBloc = sl.get<LessonBloc>();
    // Load lessons when screen initializes
    _lessonBloc.add(const LoadLessonsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lessonBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _lessonBloc.add(const RefreshLessonsEvent());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lessons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _lessonBloc.add(const LoadLessonsEvent());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // In a real app, you might want to debounce this
                if (value.isEmpty) {
                  _lessonBloc.add(const LoadLessonsEvent());
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _lessonBloc.add(FilterLessonsEvent(searchQuery: value));
                }
              },
            ),
          ),
          // Lessons list
          Expanded(
            child: StreamBuilder<LessonState>(
              stream: _lessonBloc.stream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? _lessonBloc.state;

                return switch (state) {
                  LessonInitial() || LessonLoading() => const Center(
                    child: LoadingIndicator(message: 'Loading lessons...'),
                  ),
                  LessonsLoaded() => _buildLessonsList(state),
                  LessonError() => ErrorDisplay(
                    message: state.message,
                    onRetry: () {
                      _lessonBloc.add(const LoadLessonsEvent());
                    },
                  ),
                  LessonLoaded() => _buildSingleLessonView(state),
                  LessonActionSuccess() => const Center(
                    child: LoadingIndicator(message: 'Updating...'),
                  ),
                  _ => const Center(
                    child: LoadingIndicator(message: 'Loading...'),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(LessonsLoaded state) {
    if (state.lessons.isEmpty) {
      return EmptyStateWidget(
        title: 'No Lessons Available',
        message: 'Check back later for new lessons on media literacy.',
        icon: Icons.school_outlined,
        action: ElevatedButton.icon(
          onPressed: () {
            _lessonBloc.add(const LoadLessonsEvent());
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      );
    }

    // Filter lessons based on search query
    List<LessonEntity> filteredLessons = state.lessons;
    if (_searchQuery.isNotEmpty) {
      filteredLessons = state.lessons.where((lesson) {
        return lesson.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            lesson.subtitle.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            lesson.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (filteredLessons.isEmpty) {
      return EmptyStateWidget(
        title: 'No Matching Lessons',
        message: 'Try adjusting your search terms.',
        icon: Icons.search_off_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: filteredLessons.length,
      itemBuilder: (context, index) {
        final lesson = filteredLessons[index];
        final progress = state.progress[lesson.id] ?? 0;

        return LessonCardWidget(
          lesson: lesson,
          progress: progress,
          onTap: () {
            // Navigate to lesson detail screen
            // In a real implementation, you would navigate to a detail screen
            _showLessonDetailDialog(context, lesson, progress);
          },
        );
      },
    );
  }

  Widget _buildSingleLessonView(LessonLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: LessonCardWidget(
        lesson: state.lesson,
        progress: state.progress,
        onTap: () {
          // Handle lesson tap
          _showLessonDetailDialog(context, state.lesson, state.progress);
        },
      ),
    );
  }

  void _showLessonDetailDialog(
    BuildContext context,
    LessonEntity lesson,
    int progress,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lesson.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.subtitle),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                const SizedBox(height: 8),
                Text('$progress% complete'),
                const SizedBox(height: 16),
                Text(lesson.content),
                const SizedBox(height: 16),
                Text(
                  'Questions: ${lesson.questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...lesson.questions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('• ${question.question}'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Update progress when "Start" is pressed
                _lessonBloc.add(
                  UpdateLessonProgressEvent(
                    lessonId: lesson.id,
                    progress: (progress + 20).clamp(0, 100),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
}

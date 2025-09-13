import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonDifficulty { beginner, intermediate, advanced, expert }

enum LessonType { article, video, interactive, assessment, workshop }

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  matching,
  essay,
  slider,
}

enum LessonStatus { locked, available, inProgress, completed, mastered }

class EnhancedLesson {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String content;
  final String? videoUrl;
  final List<String> imageUrls;
  final String iconName;
  final Color themeColor;
  final LessonDifficulty difficulty;
  final LessonType type;
  final List<String> tags;
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final int estimatedDuration; // in minutes
  final int order;
  final bool isActive;
  final bool isFeatured;
  final bool isNew;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<EnhancedQuestion> questions;
  final List<LessonResource> resources;
  final LessonAnalytics analytics;
  final Map<String, dynamic>? metadata;

  EnhancedLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    this.videoUrl,
    this.imageUrls = const [],
    required this.iconName,
    required this.themeColor,
    this.difficulty = LessonDifficulty.beginner,
    this.type = LessonType.article,
    this.tags = const [],
    this.learningObjectives = const [],
    this.prerequisites = const [],
    required this.estimatedDuration,
    required this.order,
    this.isActive = true,
    this.isFeatured = false,
    this.isNew = false,
    required this.createdAt,
    this.updatedAt,
    this.questions = const [],
    this.resources = const [],
    required this.analytics,
    this.metadata,
  });

  factory EnhancedLesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EnhancedLesson(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      videoUrl: data['videoUrl'],
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : [],
      iconName: data['iconName'] ?? 'book',
      themeColor: Color(data['themeColor'] ?? 0xFF9C27B0),
      difficulty: LessonDifficulty.values.firstWhere(
        (d) => d.toString() == 'LessonDifficulty.${data['difficulty']}',
        orElse: () => LessonDifficulty.beginner,
      ),
      type: LessonType.values.firstWhere(
        (t) => t.toString() == 'LessonType.${data['type']}',
        orElse: () => LessonType.article,
      ),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      learningObjectives: data['learningObjectives'] != null
          ? List<String>.from(data['learningObjectives'])
          : [],
      prerequisites: data['prerequisites'] != null
          ? List<String>.from(data['prerequisites'])
          : [],
      estimatedDuration: data['estimatedDuration'] ?? 15,
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isNew: data['isNew'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      questions: data['questions'] != null
          ? (data['questions'] as List)
                .map((q) => EnhancedQuestion.fromMap(q))
                .toList()
          : [],
      resources: data['resources'] != null
          ? (data['resources'] as List)
                .map((r) => LessonResource.fromMap(r))
                .toList()
          : [],
      analytics: LessonAnalytics.fromMap(data['analytics'] ?? {}),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'content': content,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'iconName': iconName,
      'themeColor': themeColor.value,
      'difficulty': difficulty.toString().split('.').last,
      'type': type.toString().split('.').last,
      'tags': tags,
      'learningObjectives': learningObjectives,
      'prerequisites': prerequisites,
      'estimatedDuration': estimatedDuration,
      'order': order,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'questions': questions.map((q) => q.toMap()).toList(),
      'resources': resources.map((r) => r.toMap()).toList(),
      'analytics': analytics.toMap(),
      'metadata': metadata,
    };
  }

  EnhancedLesson copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? content,
    String? videoUrl,
    List<String>? imageUrls,
    String? iconName,
    Color? themeColor,
    LessonDifficulty? difficulty,
    LessonType? type,
    List<String>? tags,
    List<String>? learningObjectives,
    List<String>? prerequisites,
    int? estimatedDuration,
    int? order,
    bool? isActive,
    bool? isFeatured,
    bool? isNew,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EnhancedQuestion>? questions,
    List<LessonResource>? resources,
    LessonAnalytics? analytics,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      iconName: iconName ?? this.iconName,
      themeColor: themeColor ?? this.themeColor,
      difficulty: difficulty ?? this.difficulty,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      prerequisites: prerequisites ?? this.prerequisites,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
      resources: resources ?? this.resources,
      analytics: analytics ?? this.analytics,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters for UI
  String get difficultyLabel {
    switch (difficulty) {
      case LessonDifficulty.beginner:
        return 'Beginner';
      case LessonDifficulty.intermediate:
        return 'Intermediate';
      case LessonDifficulty.advanced:
        return 'Advanced';
      case LessonDifficulty.expert:
        return 'Expert';
    }
  }

  String get typeLabel {
    switch (type) {
      case LessonType.article:
        return 'Article';
      case LessonType.video:
        return 'Video';
      case LessonType.interactive:
        return 'Interactive';
      case LessonType.assessment:
        return 'Assessment';
      case LessonType.workshop:
        return 'Workshop';
    }
  }

  String get durationText {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}m';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  bool get hasQuiz => questions.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasResources => resources.isNotEmpty;
}

class EnhancedQuestion {
  final String id;
  final String question;
  final String? explanation;
  final QuestionType type;
  final List<QuestionOption> options;
  final dynamic correctAnswer; // Can be int, List<int>, String, etc.
  final int points;
  final int timeLimit; // in seconds, 0 for no limit
  final String? hint;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  EnhancedQuestion({
    required this.id,
    required this.question,
    this.explanation,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.points = 1,
    this.timeLimit = 0,
    this.hint,
    this.tags = const [],
    this.metadata,
  });

  factory EnhancedQuestion.fromMap(Map<String, dynamic> data) {
    return EnhancedQuestion(
      id: data['id'] ?? '',
      question: data['question'] ?? '',
      explanation: data['explanation'],
      type: QuestionType.values.firstWhere(
        (t) => t.toString() == 'QuestionType.${data['type']}',
        orElse: () => QuestionType.multipleChoice,
      ),
      options: data['options'] != null
          ? (data['options'] as List)
                .map((o) => QuestionOption.fromMap(o))
                .toList()
          : [],
      correctAnswer: data['correctAnswer'],
      points: data['points'] ?? 1,
      timeLimit: data['timeLimit'] ?? 0,
      hint: data['hint'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'explanation': explanation,
      'type': type.toString().split('.').last,
      'options': options.map((o) => o.toMap()).toList(),
      'correctAnswer': correctAnswer,
      'points': points,
      'timeLimit': timeLimit,
      'hint': hint,
      'tags': tags,
      'metadata': metadata,
    };
  }
}

class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? imageUrl;
  final String? explanation;

  QuestionOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
    this.imageUrl,
    this.explanation,
  });

  factory QuestionOption.fromMap(Map<String, dynamic> data) {
    return QuestionOption(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
      imageUrl: data['imageUrl'],
      explanation: data['explanation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
      'imageUrl': imageUrl,
      'explanation': explanation,
    };
  }
}

class LessonResource {
  final String id;
  final String title;
  final String type; // 'link', 'download', 'video', 'document'
  final String url;
  final String? description;
  final String? thumbnailUrl;

  LessonResource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    this.description,
    this.thumbnailUrl,
  });

  factory LessonResource.fromMap(Map<String, dynamic> data) {
    return LessonResource(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      type: data['type'] ?? 'link',
      url: data['url'] ?? '',
      description: data['description'],
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'url': url,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class LessonAnalytics {
  final int viewCount;
  final int completionCount;
  final double averageScore;
  final double averageRating;
  final int ratingCount;
  final double completionRate;
  final int averageTimeSpent; // in seconds

  LessonAnalytics({
    this.viewCount = 0,
    this.completionCount = 0,
    this.averageScore = 0.0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.completionRate = 0.0,
    this.averageTimeSpent = 0,
  });

  factory LessonAnalytics.fromMap(Map<String, dynamic> data) {
    return LessonAnalytics(
      viewCount: data['viewCount'] ?? 0,
      completionCount: data['completionCount'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      averageTimeSpent: data['averageTimeSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewCount': viewCount,
      'completionCount': completionCount,
      'averageScore': averageScore,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'completionRate': completionRate,
      'averageTimeSpent': averageTimeSpent,
    };
  }
}

class StepTimer {
  final int stepIndex;
  final int durationSeconds;
  final bool isRunning;
  final int elapsedSeconds;

  const StepTimer({
    required this.stepIndex,
    required this.durationSeconds,
    this.isRunning = false,
    this.elapsedSeconds = 0,
  });

  StepTimer copyWith({
    int? stepIndex,
    int? durationSeconds,
    bool? isRunning,
    int? elapsedSeconds,
  }) {
    return StepTimer(
      stepIndex: stepIndex ?? this.stepIndex,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRunning: isRunning ?? this.isRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'step_index': stepIndex,
        'duration_seconds': durationSeconds,
        'is_running': isRunning,
        'elapsed_seconds': elapsedSeconds,
      };

  factory StepTimer.fromJson(Map<String, dynamic> json) {
    return StepTimer(
      stepIndex: json['step_index'] as int,
      durationSeconds: json['duration_seconds'] as int,
      isRunning: json['is_running'] as bool? ?? false,
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
    );
  }
}

class CookingSession {
  final String id;
  final String recipeId;
  final int currentStep;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<String> userNotes;
  final List<StepTimer> stepTimers;
  final List<Map<String, String>> chatHistory;

  CookingSession({
    required this.id,
    required this.recipeId,
    required this.currentStep,
    required this.startedAt,
    this.completedAt,
    this.userNotes = const [],
    this.stepTimers = const [],
    this.chatHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'current_step': currentStep,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_notes': userNotes.join('|'),
      'step_timers': stepTimers.map((t) => t.toJson()).toList(),
      'chat_history': chatHistory,
    };
  }

  factory CookingSession.fromMap(Map<String, dynamic> map) {
    return CookingSession(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      currentStep: map['current_step'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      userNotes: (map['user_notes'] as String?)?.isNotEmpty == true
          ? (map['user_notes'] as String).split('|')
          : [],
      stepTimers: (map['step_timers'] as List?)
              ?.map((e) => StepTimer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chatHistory: (map['chat_history'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
    );
  }

  CookingSession copyWith({
    String? id,
    String? recipeId,
    int? currentStep,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? userNotes,
    List<StepTimer>? stepTimers,
    List<Map<String, String>>? chatHistory,
  }) {
    return CookingSession(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      currentStep: currentStep ?? this.currentStep,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userNotes: userNotes ?? this.userNotes,
      stepTimers: stepTimers ?? this.stepTimers,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }
}

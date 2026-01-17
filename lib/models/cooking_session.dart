

class CookingSession {
  final String id;
  final String recipeId;
  final int currentStep;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<String> userNotes;

  CookingSession({
    required this.id,
    required this.recipeId,
    required this.currentStep,
    required this.startedAt,
    this.completedAt,
    this.userNotes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'current_step': currentStep,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_notes': userNotes.join('|'),
    };
  }

  factory CookingSession.fromMap(Map<String, dynamic> map) {
    return CookingSession(
      id: map['id'],
      recipeId: map['recipe_id'],
      currentStep: map['current_step'],
      startedAt: DateTime.parse(map['started_at']),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : null,
      userNotes: (map['user_notes'] as String).split('|'),
    );
  }

  CookingSession copyWith({
    String? id,
    String? recipeId,
    int? currentStep,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? userNotes,
  }) {
    return CookingSession(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      currentStep: currentStep ?? this.currentStep,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userNotes: userNotes ?? this.userNotes,
    );
  }
}
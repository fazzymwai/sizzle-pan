class Recipe {
  final String id;
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final String? notes;
  final int cookingTime;
  final int servings;
  final String difficulty;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    this.notes,
    required this.cookingTime,
    required this.servings,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients.join('|'),
      'steps': steps.join('|'),
      'notes': notes,
      'cooking_time': cookingTime,
      'servings': servings,
      'difficulty': difficulty,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      ingredients: (map['ingredients'] as String).split('|'),
      steps: (map['steps'] as String).split('|'),
      notes: map['notes'],
      cookingTime: map['cooking_time'],
      servings: map['servings'],
      difficulty: map['difficulty'],
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  Recipe copyWith({
    String? id,
    String? title,
    List<String>? ingredients,
    List<String>? steps,
    String? notes,
    int? cookingTime,
    int? servings,
    String? difficulty,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
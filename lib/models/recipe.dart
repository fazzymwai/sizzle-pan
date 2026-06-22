class RecipeIngredient {
  final String name;
  final String amount;
  final bool owned;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.owned = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'owned': owned,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: json['amount'] as String? ?? '',
      owned: json['owned'] as bool? ?? false,
    );
  }

  RecipeIngredient copyWith({String? name, String? amount, bool? owned}) {
    return RecipeIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      owned: owned ?? this.owned,
    );
  }
}

class Substitution {
  final String swap;
  final String ratio;
  final String? notes;

  const Substitution({
    required this.swap,
    required this.ratio,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'swap': swap,
        'ratio': ratio,
        'notes': notes,
      };

  factory Substitution.fromJson(Map<String, dynamic> json) {
    return Substitution(
      swap: json['swap'] as String,
      ratio: json['ratio'] as String? ?? 'same amount',
      notes: json['notes'] as String?,
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String? notes;
  final int cookingTime;
  final int servings;
  final String difficulty;
  final String category;
  final List<String> dietaryInfo;
  final Map<String, List<Substitution>> substitutions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    this.description = '',
    required this.ingredients,
    required this.steps,
    this.notes,
    required this.cookingTime,
    required this.servings,
    required this.difficulty,
    required this.category,
    this.dietaryInfo = const [],
    this.substitutions = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  List<String> get ingredientNames => ingredients.map((i) => i.name).toList();

  List<String> get ownedIngredients =>
      ingredients.where((i) => i.owned).map((i) => i.name).toList();

  List<String> get missingIngredients =>
      ingredients.where((i) => !i.owned).map((i) => i.name).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.join('|'),
      'notes': notes,
      'cooking_time': cookingTime,
      'servings': servings,
      'difficulty': difficulty,
      'category': category,
      'dietary_info': dietaryInfo.join(','),
      'substitutions': substitutions
          .map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      description: map['description'] as String? ?? '',
      ingredients: (map['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (map['steps'] as String).split('|'),
      notes: map['notes'] as String?,
      cookingTime: map['cooking_time'] as int,
      servings: map['servings'] as int,
      difficulty: map['difficulty'] as String,
      category: map['category'] as String,
      dietaryInfo: (map['dietary_info'] as String?)?.isNotEmpty == true
          ? (map['dietary_info'] as String).split(',')
          : [],
      substitutions: (map['substitutions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              (v as List).map((e) => Substitution.fromJson(e)).toList(),
            ),
          ) ??
          {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  /// Parse from Anthropic API JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String?,
      cookingTime: json['cookingTime'] as int? ?? 30,
      servings: json['servings'] as int? ?? 2,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      category: json['category'] as String? ?? 'General',
      dietaryInfo:
          (json['dietaryInfo'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      substitutions: (json['substitutions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              (v as List)
                  .map((e) => Substitution.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    String? notes,
    int? cookingTime,
    int? servings,
    String? difficulty,
    String? category,
    List<String>? dietaryInfo,
    Map<String, List<Substitution>>? substitutions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      dietaryInfo: dietaryInfo ?? this.dietaryInfo,
      substitutions: substitutions ?? this.substitutions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

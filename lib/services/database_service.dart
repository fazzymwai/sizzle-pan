import 'dart:convert';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/models/cooking_session.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'sizzle_pan.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recipes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            ingredients TEXT NOT NULL,
            steps TEXT NOT NULL,
            notes TEXT,
            cooking_time INTEGER NOT NULL,
            servings INTEGER NOT NULL,
            difficulty TEXT NOT NULL,
            category TEXT NOT NULL,
            dietary_info TEXT DEFAULT '',
            substitutions TEXT DEFAULT '{}',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_favorite INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE cooking_sessions (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            current_step INTEGER NOT NULL,
            started_at TEXT NOT NULL,
            completed_at TEXT,
            user_notes TEXT DEFAULT '',
            step_timers TEXT DEFAULT '[]',
            chat_history TEXT DEFAULT '[]',
            FOREIGN KEY (recipe_id) REFERENCES recipes (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Drop old tables and recreate with new schema
          await db.execute('DROP TABLE IF EXISTS cooking_sessions');
          await db.execute('DROP TABLE IF EXISTS recipes');
          await db.execute('''
            CREATE TABLE recipes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT DEFAULT '',
              ingredients TEXT NOT NULL,
              steps TEXT NOT NULL,
              notes TEXT,
              cooking_time INTEGER NOT NULL,
              servings INTEGER NOT NULL,
              difficulty TEXT NOT NULL,
              category TEXT NOT NULL,
              dietary_info TEXT DEFAULT '',
              substitutions TEXT DEFAULT '{}',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_favorite INTEGER DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE cooking_sessions (
              id TEXT PRIMARY KEY,
              recipe_id TEXT NOT NULL,
              current_step INTEGER NOT NULL,
              started_at TEXT NOT NULL,
              completed_at TEXT,
              user_notes TEXT DEFAULT '',
              step_timers TEXT DEFAULT '[]',
              chat_history TEXT DEFAULT '[]',
              FOREIGN KEY (recipe_id) REFERENCES recipes (id)
            )
          ''');
        }
      },
    );
  }

  // Recipe operations
  static Future<String> createRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert('recipes', _recipeToRow(recipe));
    return recipe.id;
  }

  static Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'updated_at DESC');
    return maps.map((m) => _recipeFromRow(m)).toList();
  }

  static Future<Recipe?> getRecipeById(String id) async {
    final db = await database;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return _recipeFromRow(maps.first);
    return null;
  }

  static Future<List<Recipe>> searchRecipes(String query) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'title LIKE ? OR ingredients LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => _recipeFromRow(m)).toList();
  }

  static Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => _recipeFromRow(m)).toList();
  }

  static Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update(
      'recipes',
      _recipeToRow(recipe.copyWith(updatedAt: DateTime.now())),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  static Future<int> deleteRecipe(String id) async {
    final db = await database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'recipes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cooking session operations
  static Future<String> createCookingSession(CookingSession session) async {
    final db = await database;
    await db.insert('cooking_sessions', _sessionToRow(session));
    return session.id;
  }

  static Future<CookingSession?> getActiveSession(String recipeId) async {
    final db = await database;
    final maps = await db.query(
      'cooking_sessions',
      where: 'recipe_id = ? AND completed_at IS NULL',
      whereArgs: [recipeId],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return _sessionFromRow(maps.first);
    return null;
  }

  static Future<int> updateCookingSession(CookingSession session) async {
    final db = await database;
    return await db.update(
      'cooking_sessions',
      _sessionToRow(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<int> completeCookingSession(String sessionId) async {
    final db = await database;
    return await db.update(
      'cooking_sessions',
      {'completed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ─── Row mappers ────────────────────────────────────────────────────

  static Map<String, dynamic> _recipeToRow(Recipe r) {
    return {
      'id': r.id,
      'title': r.title,
      'description': r.description,
      'ingredients': jsonEncode(r.ingredients.map((i) => i.toJson()).toList()),
      'steps': r.steps.join('|'),
      'notes': r.notes,
      'cooking_time': r.cookingTime,
      'servings': r.servings,
      'difficulty': r.difficulty,
      'category': r.category,
      'dietary_info': r.dietaryInfo.join(','),
      'substitutions': jsonEncode(r.substitutions
          .map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()))),
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'is_favorite': r.isFavorite ? 1 : 0,
    };
  }

  static Recipe _recipeFromRow(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      ingredients: (jsonDecode(map['ingredients'] as String) as List)
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
      substitutions: (jsonDecode(map['substitutions'] as String? ?? '{}')
              as Map<String, dynamic>)
          .map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => Substitution.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  static Map<String, dynamic> _sessionToRow(CookingSession s) {
    return {
      'id': s.id,
      'recipe_id': s.recipeId,
      'current_step': s.currentStep,
      'started_at': s.startedAt.toIso8601String(),
      'completed_at': s.completedAt?.toIso8601String(),
      'user_notes': s.userNotes.join('|'),
      'step_timers': jsonEncode(s.stepTimers.map((t) => t.toJson()).toList()),
      'chat_history': jsonEncode(s.chatHistory),
    };
  }

  static CookingSession _sessionFromRow(Map<String, dynamic> map) {
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
      stepTimers: (jsonDecode(map['step_timers'] as String? ?? '[]') as List)
          .map((e) => StepTimer.fromJson(e as Map<String, dynamic>))
          .toList(),
      chatHistory: (jsonDecode(map['chat_history'] as String? ?? '[]') as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
    );
  }
}

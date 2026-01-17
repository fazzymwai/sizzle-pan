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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recipes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            ingredients TEXT NOT NULL,
            steps TEXT NOT NULL,
            notes TEXT,
            cooking_time INTEGER NOT NULL,
            servings INTEGER NOT NULL,
            difficulty TEXT NOT NULL,
            category TEXT NOT NULL,
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
            user_notes TEXT,
            FOREIGN KEY (recipe_id) REFERENCES recipes (id)
          )
        ''');
      },
    );
  }

  // Recipe operations
  static Future<String> createRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert('recipes', recipe.toMap());
    return recipe.id;
  }

  static Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  static Future<Recipe?> getRecipeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Recipe>> searchRecipes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'title LIKE ? OR ingredients LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  static Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  static Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update(
      'recipes',
      recipe.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  static Future<int> deleteRecipe(String id) async {
    final db = await database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
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
    await db.insert('cooking_sessions', session.toMap());
    return session.id;
  }

  static Future<CookingSession?> getActiveSession(String recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cooking_sessions',
      where: 'recipe_id = ? AND completed_at IS NULL',
      whereArgs: [recipeId],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CookingSession.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateCookingSession(CookingSession session) async {
    final db = await database;
    return await db.update(
      'cooking_sessions',
      session.toMap(),
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
}
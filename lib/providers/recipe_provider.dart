import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/models/shopping_item.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/anthropic_service.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _favorites = [];
  List<Recipe> _generatedRecipes = [];
  List<ShoppingItem> _shoppingList = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _favorites;
  List<Recipe> get generatedRecipes => _generatedRecipes;
  List<ShoppingItem> get shoppingList => _shoppingList;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  bool get hasApiKey => AnthropicService.apiKey != null;

  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await DatabaseService.getAllRecipes();
    } catch (e) {
      _error = 'Failed to load recipes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await DatabaseService.getFavoriteRecipes();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load favorites';
      notifyListeners();
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      await DatabaseService.createRecipe(recipe);
      _recipes.insert(0, recipe);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save recipe';
      notifyListeners();
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await DatabaseService.deleteRecipe(id);
      _recipes.removeWhere((r) => r.id == id);
      _favorites.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete recipe';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final idx = _recipes.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final recipe = _recipes[idx];
    final newFav = !recipe.isFavorite;
    try {
      await DatabaseService.toggleFavorite(id, newFav);
      _recipes[idx] = recipe.copyWith(isFavorite: newFav);
      await loadFavorites();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update favorite';
      notifyListeners();
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      return await DatabaseService.searchRecipes(query);
    } catch (e) {
      _error = 'Search failed';
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      return await DatabaseService.getRecipeById(id);
    } catch (e) {
      return null;
    }
  }

  // ─── AI-Powered Generation ──────────────────────────────────────────

  Future<void> generateRecipesFromAI({
    required List<String> ingredients,
    String? dietaryPreference,
    int? maxTime,
    String? skillLevel,
    String? cuisine,
    int? servings,
  }) async {
    _isGenerating = true;
    _error = null;
    _generatedRecipes = [];
    notifyListeners();

    try {
      final response = await AnthropicService.generateRecipes(
        ingredients: ingredients,
        dietaryPreference: dietaryPreference,
        maxTime: maxTime,
        skillLevel: skillLevel,
        cuisine: cuisine,
        servings: servings,
      );

      final List<dynamic> jsonList = jsonDecode(response) as List<dynamic>;
      _generatedRecipes = jsonList
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> saveGeneratedRecipe(Recipe recipe) async {
    final saved = recipe.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await saveRecipe(saved);
  }

  // ─── Shopping List ──────────────────────────────────────────────────

  Future<void> generateShoppingList(
      List<String> allIngredients, List<String> ownedIngredients) async {
    try {
      final response = await AnthropicService.generateShoppingList(
        allIngredients,
        ownedIngredients,
      );
      final List<dynamic> jsonList = jsonDecode(response) as List<dynamic>;
      _shoppingList = jsonList
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void toggleShoppingItem(int index) {
    if (index >= 0 && index < _shoppingList.length) {
      _shoppingList[index] = _shoppingList[index].copyWith(
        purchased: !_shoppingList[index].purchased,
      );
      notifyListeners();
    }
  }
}

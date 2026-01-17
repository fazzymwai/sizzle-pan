import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class IngredientGeneratorScreen extends StatefulWidget {
  const IngredientGeneratorScreen({super.key});

  @override
  State<IngredientGeneratorScreen> createState() => _IngredientGeneratorScreenState();
}

class _IngredientGeneratorScreenState extends State<IngredientGeneratorScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  List<Recipe> _generatedRecipes = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty && !_ingredients.contains(ingredient)) {
      setState(() {
        _ingredients.add(ingredient);
      });
      _ingredientController.clear();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  Future<void> _generateRecipes() async {
    if (_ingredients.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final recipes = AIService.generateRecipesFromIngredients(_ingredients);

    setState(() {
      _generatedRecipes = recipes;
      _isGenerating = false;
    });
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    try {
      await DatabaseService.createRecipe(recipe);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save recipe')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What I Have'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add ingredients you have',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: 'Enter ingredient',
                      prefixIcon: Icon(Icons.add),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addIngredient,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ingredients.isNotEmpty) ...[
              Text(
                'Your ingredients:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _ingredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient),
                    onDeleted: () => _removeIngredient(ingredient),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateRecipes,
                  child: _isGenerating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate Recipes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: _generatedRecipes.isEmpty
                  ? Center(
                      child: Text(
                        _ingredients.isEmpty
                            ? 'Add ingredients to get started'
                            : 'Generate recipes to see results',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _generatedRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _generatedRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => context.go('/recipe/${recipe.id}'),
                          onSave: () => _saveRecipe(recipe),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
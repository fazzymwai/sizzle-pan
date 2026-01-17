import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class MoodGeneratorScreen extends StatefulWidget {
  const MoodGeneratorScreen({super.key});

  @override
  State<MoodGeneratorScreen> createState() => _MoodGeneratorScreenState();
}

class _MoodGeneratorScreenState extends State<MoodGeneratorScreen> {
  String _selectedMood = '';
  String _selectedOccasion = '';
  List<Recipe> _generatedRecipes = [];
  bool _isGenerating = false;

  final List<String> _moods = [
    'Tired',
    'Lazy',
    'Excited',
    'Romantic',
    'Stressed',
    'Happy',
    'Hungry',
  ];

  final List<String> _occasions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Date Night',
    'Family Meal',
    'Quick Meal',
    'Comfort Food',
  ];

  Future<void> _generateRecipes() async {
    if (_selectedMood.isEmpty || _selectedOccasion.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final recipes = AIService.generateRecipesFromMood(_selectedMood, _selectedOccasion);

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
        title: const Text('How I Feel'),
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
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return FilterChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = selected ? mood : '';
                    });
                  },
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'What kind of meal?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _occasions.map((occasion) {
                final isSelected = _selectedOccasion == occasion;
                return FilterChip(
                  label: Text(occasion),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedOccasion = selected ? occasion : '';
                    });
                  },
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_selectedMood.isNotEmpty && _selectedOccasion.isNotEmpty)
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
            Expanded(
              child: _generatedRecipes.isEmpty
                  ? Center(
                      child: Text(
                        _selectedMood.isEmpty || _selectedOccasion.isEmpty
                            ? 'Select your mood and meal type'
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
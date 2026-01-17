import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _remixOptions = ['Original', 'Healthier', 'Faster', 'Creative'];
  String _selectedRemix = 'Original';
  List<Recipe> _searchResults = [];
  List<Recipe> _allRecipes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await DatabaseService.getAllRecipes();
      setState(() {
        _allRecipes = recipes;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // First search local recipes
    final localResults = await DatabaseService.searchRecipes(query);

    // Then get AI-generated recipes
    final aiResults = AIService.searchAndRemixRecipes(query, _selectedRemix);

    setState(() {
      _searchResults = [...localResults, ...aiResults];
      _isSearching = false;
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
        title: const Text('Search Recipes'),
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _searchRecipes(),
            ),
            const SizedBox(height: 16),
            Text(
              'Recipe Style:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _remixOptions.map((option) {
                final isSelected = _selectedRemix == option;
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRemix = option;
                    });
                    if (_searchController.text.isNotEmpty) {
                      _searchRecipes();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchRecipes,
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'Search for recipes to see results',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final recipe = _searchResults[index];
                        final isLocal = _allRecipes.any((r) => r.id == recipe.id);
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => context.go('/recipe/${recipe.id}'),
                          onSave: isLocal ? null : () => _saveRecipe(recipe),
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
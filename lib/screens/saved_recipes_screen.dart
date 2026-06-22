import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/theme_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
    });
  }

  Future<void> _deleteRecipe(String recipeId) async {
    await context.read<RecipeProvider>().deleteRecipe(recipeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted')),
      );
    }
  }

  void _showDeleteDialog(Recipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline,
                color: ThemeService.fieryRed, size: 26),
            const SizedBox(width: 10),
            Text(
              'Delete Recipe',
              style: GoogleFonts.luckiestGuy(
                fontSize: 22,
                color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${recipe.title}"? This sizzle can\'t be uncooked! 🔥',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: isDark ? const Color(0xFFE0D6CC) : ThemeService.warmGrey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep It',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ThemeService.warmGrey,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeService.fieryRed, ThemeService.deepRed],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecipe(recipe.id);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Recipe Collection',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3D322A).withValues(alpha: 0.5)
                  : ThemeService.softCoral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ),
              onPressed: () => context.read<RecipeProvider>().loadRecipes(),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? ThemeService.warmOrange
                            : ThemeService.fieryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Gathering your recipes... 📖',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: ThemeService.warmGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? ThemeService.warmOrange.withValues(alpha: 0.15)
                            : ThemeService.softCoral,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('📭', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No recipes yet!',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: isDark
                            ? const Color(0xFFF5EDE6)
                            : ThemeService.charcoal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate some recipes from your\ningredients or mood!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: ThemeService.warmGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDark
                                  ? ThemeService.warmOrange
                                  : ThemeService.fieryRed,
                              ThemeService.goldenYellow,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Start Cooking! 🔥',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? ThemeService.charcoal
                                : ThemeService.pureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<RecipeProvider>().loadRecipes(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: provider.recipes.length,
              itemBuilder: (context, index) {
                final recipe = provider.recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () => context.push('/recipe/${recipe.id}'),
                  onDelete: () => _showDeleteDialog(recipe),
                  onToggleFavorite: () {
                    context.read<RecipeProvider>().toggleFavorite(recipe.id);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

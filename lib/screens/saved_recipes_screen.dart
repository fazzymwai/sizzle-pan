import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  List<Recipe> _savedRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await DatabaseService.getAllRecipes();
      setState(() {
        _savedRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      await DatabaseService.toggleFavorite(recipeId, isFavorite);
      _loadSavedRecipes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      await DatabaseService.deleteRecipe(recipeId);
      _loadSavedRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete recipe')),
        );
      }
    }
  }

  void _showDeleteDialog(Recipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: ThemeService.fieryRed, size: 26),
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
          'Are you sure you want to delete "${recipe.title}"? This sizzle can\'t be uncooked! ðŸ”¥',
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? const Color(0xFFE0D6CC) : ThemeService.charcoal,
          ),
          onPressed: () => context.go('/'),
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
              onPressed: _loadSavedRecipes,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fetching your recipes...',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                    ),
                  ),
                ],
              ),
            )
          : _savedRecipes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ThemeService.fieryRed.withValues(alpha: 0.1),
                                ThemeService.goldenYellow.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              'ðŸ‘¨â€ðŸ³',
                              style: GoogleFonts.nunito(fontSize: 44),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No recipes yet!',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 24,
                            color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Start cooking and save your favorites! ðŸ”¥',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ThemeService.fieryRed, ThemeService.deepRed],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeService.fieryRed.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('ðŸ³', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Text(
                                  'Start Cooking',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _savedRecipes[index];
                    return _buildRecipeItem(recipe, isDark);
                  },
                ),
    );
  }

  Widget _buildRecipeItem(Recipe recipe, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => context.go('/recipe/${recipe.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : ThemeService.fieryRed.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ThemeService.fieryRed.withValues(alpha: 0.15),
                            ThemeService.goldenYellow.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, color: ThemeService.fieryRed, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recipe.category,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: ThemeService.warmGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleFavorite(recipe.id, !recipe.isFavorite),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: recipe.isFavorite
                              ? ThemeService.fieryRed.withValues(alpha: 0.12)
                              : (isDark
                                  ? const Color(0xFF3D322A).withValues(alpha: 0.5)
                                  : ThemeService.softCoral),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite
                              ? ThemeService.fieryRed
                              : (isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3D322A).withValues(alpha: 0.5)
                            : ThemeService.softCoral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(recipe);
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, color: ThemeService.fieryRed, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete Recipe',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatChip(Icons.schedule_outlined, '${recipe.cookingTime} min', isDark),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.people_outline, '${recipe.servings} servings', isDark),
                    const SizedBox(width: 12),
                    _buildDifficultyBadge(recipe.difficulty, isDark),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'ðŸ¥˜ ${recipe.ingredients.take(3).join(", ")}${recipe.ingredients.length > 3 ? "..." : ""}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3D322A).withValues(alpha: 0.4)
                          : ThemeService.warmCream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ðŸ“', style: GoogleFonts.nunito(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recipe.notes!,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty, bool isDark) {
    Color badgeColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = const Color(0xFF4CAF50);
        break;
      case 'medium':
        badgeColor = ThemeService.goldenYellow;
        break;
      default:
        badgeColor = ThemeService.fieryRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: badgeColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class IngredientGeneratorScreen extends StatefulWidget {
  const IngredientGeneratorScreen({super.key});

  @override
  State<IngredientGeneratorScreen> createState() =>
      _IngredientGeneratorScreenState();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'What I Have',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
            letterSpacing: 1.2,
          ),
        ),
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3D322A)
                  : ThemeService.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3D322A)
                    : ThemeService.warmCream,
              ),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chef intro card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          ThemeService.warmOrange.withValues(alpha: 0.12),
                          ThemeService.goldenYellow.withValues(alpha: 0.05),
                        ]
                      : [
                          ThemeService.fieryRed.withValues(alpha: 0.08),
                          ThemeService.goldenYellow.withValues(alpha: 0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? ThemeService.warmOrange.withValues(alpha: 0.15)
                      : ThemeService.fieryRed.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? ThemeService.warmOrange.withValues(alpha: 0.2)
                          : ThemeService.fieryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('\u{1F468}\u{200D}\u{1F373}', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Got ingredients? Let\'s see what we can whip up! \u{1F525}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF5EDE6)
                                : ThemeService.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ThemeService.randomChefTip(),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: ThemeService.warmGrey,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input row
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A221C)
                    : ThemeService.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3D322A)
                      : ThemeService.warmCream,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : ThemeService.fieryRed.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      decoration: InputDecoration(
                        hintText: 'Add an ingredient...',
                        prefixIcon: Icon(
                          Icons.add_circle_outline,
                          color: isDark
                              ? const Color(0xFFB0A79E)
                              : ThemeService.warmGrey,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintStyle: GoogleFonts.nunito(
                          color: isDark
                              ? const Color(0xFFB0A79E).withValues(alpha: 0.5)
                              : ThemeService.warmGrey.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF5EDE6)
                            : ThemeService.charcoal,
                      ),
                      onSubmitted: (_) => _addIngredient(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addIngredient,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ThemeService.fieryRed,
                            ThemeService.fieryRed.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeService.fieryRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 18,
                            color: ThemeService.pureWhite,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
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
            const SizedBox(height: 16),

            // Ingredient chips
            if (_ingredients.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '\u{1F9C2} Your Pantry',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFF5EDE6)
                          : ThemeService.charcoal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeService.goldenYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${_ingredients.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.goldenYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients.map((ingredient) {
                  return GestureDetector(
                    onTap: () => _removeIngredient(ingredient),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.softCoral,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF4A3D34)
                              : ThemeService.fieryRed.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '\u{1F358} ',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            ingredient,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFF5EDE6)
                                  : ThemeService.charcoal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFB0A79E)
                                : ThemeService.warmGrey,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Generate button
              GestureDetector(
                onTap: _isGenerating ? null : _generateRecipes,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _ingredients.isEmpty
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ThemeService.fieryRed,
                              ThemeService.fieryRed.withValues(alpha: 0.85),
                            ],
                          ),
                    color: _ingredients.isEmpty
                        ? (isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.warmGrey.withValues(alpha: 0.3))
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _ingredients.isEmpty
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  ThemeService.fieryRed.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isGenerating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ThemeService.pureWhite,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '\u{1F52E} ',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Generate Recipes',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _ingredients.isEmpty
                                      ? (isDark
                                          ? const Color(0xFFB0A79E)
                                              .withValues(alpha: 0.4)
                                          : ThemeService.pureWhite)
                                      : ThemeService.pureWhite,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Results / Empty state
            Expanded(
              child: _generatedRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? ThemeService.warmOrange
                                      .withValues(alpha: 0.1)
                                  : ThemeService.fieryRed
                                      .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                _ingredients.isEmpty ? '\u{1F957}' : '\u{1F373}',
                                style: const TextStyle(fontSize: 38),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _ingredients.isEmpty
                                ? 'Add some ingredients to start!'
                                : 'Hit generate to see magic happen!',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF5EDE6)
                                  : ThemeService.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ingredients.isEmpty
                                ? 'Tell us what you\'ve got in the kitchen \u{1F9D1}\u{200D}\u{1F373}'
                                : 'Our AI chef is ready to work its magic \u{1F525}',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: ThemeService.warmGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 80,
                      ),
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

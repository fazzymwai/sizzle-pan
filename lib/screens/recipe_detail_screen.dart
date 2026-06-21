import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recipe = await DatabaseService.getRecipeById(widget.recipeId);
      if (recipe != null) {
        setState(() {
          _recipe = recipe;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null) return;
    try {
      await DatabaseService.toggleFavorite(
        _recipe!.id,
        !_recipe!.isFavorite,
      );
      _loadRecipe();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
          ),
        ),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? ThemeService.warmOrange.withValues(alpha: 0.15)
                        : ThemeService.fieryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('\u{1F622}', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Recipe vanished!',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 24,
                    color:
                        isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This recipe must have run off to the market!',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: ThemeService.warmGrey,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                          ThemeService.goldenYellow,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Go Home',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? ThemeService.charcoal : ThemeService.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final recipe = _recipe!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar with gradient
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            floating: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? ThemeService.charcoal.withValues(alpha: 0.6)
                        : ThemeService.pureWhite.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                    size: 22,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? ThemeService.charcoal.withValues(alpha: 0.6)
                          : ThemeService.pureWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavorite
                          ? ThemeService.fieryRed
                          : ThemeService.warmGrey,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeService.goldenYellow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recipe.category,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.title,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 28,
                      color: ThemeService.pureWhite,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? ThemeService.deepRed : ThemeService.fieryRed,
                      isDark ? ThemeService.warmOrange : ThemeService.goldenYellow,
                    ],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: const Text(
                      '\u{1F373}',
                      style: TextStyle(fontSize: 120),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? ThemeService.darkBg : ThemeService.warmCream,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(isDark),
                    const SizedBox(height: 28),
                    _buildChefTip(isDark),
                    const SizedBox(height: 28),
                    _buildIngredientsSection(isDark),
                    const SizedBox(height: 28),
                    _buildStepsSection(isDark),
                    const SizedBox(height: 28),
                    if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                      _buildNotesSection(isDark),
                      const SizedBox(height: 28),
                    ],
                    _buildStartCookingButton(isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoChip(
            Icons.schedule_rounded, 'Time',
            '${_recipe!.cookingTime} min', isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoChip(
            Icons.people_rounded, 'Serves',
            '${_recipe!.servings}', isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoChip(
            Icons.trending_up_rounded, 'Level',
            _recipe!.difficulty, isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A221C)
            : ThemeService.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D322A)
              : ThemeService.warmCream,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : ThemeService.fieryRed.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? ThemeService.warmOrange.withValues(alpha: 0.15)
                  : ThemeService.fieryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: ThemeService.warmGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color:
                  isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  ThemeService.goldenYellow.withValues(alpha: 0.1),
                  ThemeService.warmOrange.withValues(alpha: 0.05),
                ]
              : [
                  ThemeService.fieryRed.withValues(alpha: 0.06),
                  ThemeService.goldenYellow.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ThemeService.goldenYellow.withValues(alpha: 0.2)
              : ThemeService.fieryRed.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? ThemeService.goldenYellow.withValues(alpha: 0.2)
                  : ThemeService.fieryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('\u{1F468}\u{200D}\u{1F373}',
                  style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pro tip: ${ThemeService.randomChefTip()}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFFB0A79E) : ThemeService.warmGrey,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeService.warmOrange.withValues(alpha: 0.2)
                    : ThemeService.fieryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_basket_rounded,
                size: 18,
                color:
                    isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Ingredients',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...(_recipe!.ingredients.map((ingredient) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ThemeService.goldenYellow
                        : ThemeService.fieryRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A221C)
                          : ThemeService.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.warmCream,
                      ),
                    ),
                    child: Text(
                      ingredient,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFE0D6CC)
                            : ThemeService.charcoal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildStepsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeService.warmOrange.withValues(alpha: 0.2)
                    : ThemeService.fieryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 18,
                color:
                    isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Steps',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...(_recipe!.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark
                            ? ThemeService.warmOrange
                            : ThemeService.fieryRed,
                        ThemeService.goldenYellow,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? ThemeService.charcoal
                            : ThemeService.pureWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A221C)
                          : ThemeService.pureWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.warmCream,
                      ),
                    ),
                    child: Text(
                      step,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFE0D6CC)
                            : ThemeService.charcoal,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeService.goldenYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.sticky_note_2_rounded,
                size: 18,
                color: ThemeService.goldenYellow,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Chef's Notes",
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      ThemeService.goldenYellow.withValues(alpha: 0.08),
                      ThemeService.warmOrange.withValues(alpha: 0.04),
                    ]
                  : [
                      ThemeService.goldenYellow.withValues(alpha: 0.06),
                      ThemeService.fieryRed.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? ThemeService.goldenYellow.withValues(alpha: 0.15)
                  : ThemeService.goldenYellow.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('\u{1F4DD} ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _recipe!.notes!,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFE0D6CC)
                        : ThemeService.charcoal,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartCookingButton(bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/cooking/${_recipe!.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ThemeService.goldenYellow,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? ThemeService.warmOrange : ThemeService.fieryRed)
                      .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F373} ', style: TextStyle(fontSize: 20)),
            Text(
              'Start Cooking',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? ThemeService.charcoal : ThemeService.pureWhite,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: isDark ? ThemeService.charcoal : ThemeService.pureWhite,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

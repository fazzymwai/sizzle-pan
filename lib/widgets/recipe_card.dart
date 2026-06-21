import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A221C)
                : ThemeService.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3D322A)
                  : ThemeService.warmCream,
              width: 1,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe icon
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
                        child: Icon(
                          Icons.restaurant_menu,
                          color: ThemeService.fieryRed,
                          size: 22,
                        ),
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
                              color: isDark
                                  ? const Color(0xFFF5EDE6)
                                  : ThemeService.charcoal,
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
                    if (onSave != null)
                      GestureDetector(
                        onTap: onSave,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeService.softCoral,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bookmark_add_outlined,
                            color: ThemeService.fieryRed,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      Icons.schedule_outlined,
                      '${recipe.cookingTime} min',
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.people_outline,
                      '${recipe.servings} servings',
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildDifficultyBadge(recipe.difficulty, isDark),
                  ],
                ),
                const SizedBox(height: 10),
                // Ingredients preview
                Text(
                  '🥘 ${recipe.ingredients.take(3).join(", ")}${recipe.ingredients.length > 3 ? "..." : ""}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFB0A79E)
                        : ThemeService.warmGrey,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
          color: isDark
              ? const Color(0xFFB0A79E)
              : ThemeService.warmGrey,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: isDark
                ? const Color(0xFFB0A79E)
                : ThemeService.warmGrey,
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

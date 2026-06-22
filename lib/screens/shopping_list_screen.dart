import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecipeProvider>();
    final items = provider.shoppingList;

    // Group by category
    final grouped = <String, List<int>>{};
    for (int i = 0; i < items.length; i++) {
      grouped.putIfAbsent(items[i].category, () => []).add(i);
    }
    final categories = grouped.keys.toList()..sort();

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.canPop() ? context.pop() : context.go('/');
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
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
                      const SizedBox(width: 12),
                      Text(
                        'Shopping List',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 22,
                          color: isDark
                              ? ThemeService.warmOrange
                              : ThemeService.fieryRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${items.where((i) => !i.purchased).length} items',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: ThemeService.warmGrey,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🛒', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text('No shopping list yet',
                              style: GoogleFonts.nunito(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Generate one from a recipe!',
                              style: GoogleFonts.nunito(
                                  fontSize: 14, color: ThemeService.warmGrey)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: categories
                          .map((cat) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(_categoryIcon(cat),
                                            size: 16,
                                            color: ThemeService.warmGrey),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat,
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: ThemeService.warmGrey,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...grouped[cat]!.map((idx) => _buildItem(
                                      items[idx], idx, isDark, context)),
                                  const SizedBox(height: 16),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget _buildItem(item, int index, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<RecipeProvider>().toggleShoppingItem(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: item.purchased
              ? (isDark
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.green.withValues(alpha: 0.05))
              : (isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.purchased
                ? Colors.green.withValues(alpha: 0.2)
                : (isDark ? const Color(0xFF3D322A) : ThemeService.warmCream),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.purchased ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: item.purchased
                      ? Colors.green
                      : ThemeService.warmGrey.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: item.purchased
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE0D6CC)
                          : ThemeService.charcoal,
                      decoration:
                          item.purchased ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.green,
                    ),
                  ),
                  if (item.amount.isNotEmpty)
                    Text(
                      item.amount,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: ThemeService.warmGrey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'produce':
        return Icons.eco_outlined;
      case 'dairy':
        return Icons.egg_outlined;
      case 'meat':
        return Icons.restaurant_outlined;
      case 'pantry':
        return Icons.inventory_2_outlined;
      case 'spices':
        return Icons.grass_outlined;
      case 'frozen':
        return Icons.ac_unit_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      default:
        return Icons.shopping_cart_outlined;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/theme_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

// Quick-add ingredient suggestions
const _suggestedIngredients = [
  'Pasta',
  'Rice',
  'Eggs',
  'Chicken',
  'Tomato',
  'Onion',
  'Garlic',
  'Cheese',
  'Butter',
  'Olive Oil',
  'Bread',
  'Potato',
  'Carrot',
  'Mushroom',
  'Spinach',
  'Lemon',
  'Bell Pepper',
  'Milk',
];

class IngredientGeneratorScreen extends StatefulWidget {
  const IngredientGeneratorScreen({super.key});

  @override
  State<IngredientGeneratorScreen> createState() =>
      _IngredientGeneratorScreenState();
}

class _IngredientGeneratorScreenState extends State<IngredientGeneratorScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final List<String> _ingredients = [];

  // Filters
  String? _dietary;
  int? _maxTime;
  String? _skillLevel;
  String? _cuisine;
  int _servings = 2;
  bool _showFilters = false;

  final List<String> _dietOptions = [
    'Any',
    'Vegan',
    'Vegetarian',
    'Halal',
    'Gluten-Free',
    'Dairy-Free',
    'Keto'
  ];
  final List<String> _skillOptions = ['Any', 'Easy', 'Medium', 'Hard'];
  final List<String> _cuisineOptions = [
    'Any',
    'Italian',
    'Mexican',
    'Asian',
    'Indian',
    'American',
    'Mediterranean',
    'French'
  ];
  final List<int> _timeOptions = [15, 30, 45, 60, 90];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _addIngredient(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_ingredients.contains(trimmed)) {
      setState(() => _ingredients.add(trimmed));
      _inputCtrl.clear();
    }
  }

  void _removeIngredient(String name) {
    setState(() => _ingredients.remove(name));
  }

  Future<void> _generate() async {
    if (_ingredients.isEmpty) return;
    final provider = context.read<RecipeProvider>();
    await provider.generateRecipesFromAI(
      ingredients: _ingredients,
      dietaryPreference:
          _dietary != null && _dietary != 'Any' ? _dietary : null,
      maxTime: _maxTime,
      skillLevel:
          _skillLevel != null && _skillLevel != 'Any' ? _skillLevel : null,
      cuisine: _cuisine != null && _cuisine != 'Any' ? _cuisine : null,
      servings: _servings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecipeProvider>();
    final hasApiKey = provider.hasApiKey;

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.canPop() ? context.pop() : context.go('/');
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // ─── App Bar ─────────────────────────────────────────────
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
                        'What I Have',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 22,
                          color: isDark
                              ? ThemeService.warmOrange
                              : ThemeService.fieryRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // API key indicator
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasApiKey ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasApiKey ? 'AI Ready' : 'No API Key',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: ThemeService.warmGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Scrollable Content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chef intro
                        _buildChefIntro(isDark),

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
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Add an ingredient...',
                                    hintStyle: GoogleFonts.nunito(fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  onSubmitted: _addIngredient,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _addIngredient(_inputCtrl.text),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ThemeService.fieryRed,
                                        ThemeService.warmOrange
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Quick-add chips
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _suggestedIngredients.map((item) {
                              final selected =
                                  _ingredients.contains(item.toLowerCase());
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    if (selected) {
                                      _removeIngredient(item.toLowerCase());
                                    } else {
                                      _addIngredient(item.toLowerCase());
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? (isDark
                                              ? ThemeService.warmOrange
                                                  .withValues(alpha: 0.3)
                                              : ThemeService.fieryRed
                                                  .withValues(alpha: 0.15))
                                          : (isDark
                                              ? const Color(0xFF2A221C)
                                              : ThemeService.pureWhite),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? (isDark
                                                ? ThemeService.warmOrange
                                                : ThemeService.fieryRed)
                                            : (isDark
                                                ? const Color(0xFF3D322A)
                                                : ThemeService.warmCream),
                                      ),
                                    ),
                                    child: Text(
                                      selected ? '✓ $item' : item,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? (isDark
                                                ? ThemeService.warmOrange
                                                : ThemeService.fieryRed)
                                            : (isDark
                                                ? const Color(0xFFE0D6CC)
                                                : ThemeService.charcoal),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Added ingredients chips
                        if (_ingredients.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _ingredients.map((item) {
                              return Chip(
                                label: Text(item,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeIngredient(item),
                                backgroundColor: isDark
                                    ? const Color(0xFF3D322A)
                                    : ThemeService.softCoral,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ─── Smart Filters ────────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          child: Row(
                            children: [
                              Icon(Icons.tune,
                                  size: 18, color: ThemeService.warmGrey),
                              const SizedBox(width: 6),
                              Text(
                                'Smart Filters',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.warmGrey,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _showFilters
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: ThemeService.warmGrey,
                              ),
                            ],
                          ),
                        ),

                        if (_showFilters) ...[
                          const SizedBox(height: 12),
                          _buildFilterSection(isDark),
                        ],

                        const SizedBox(height: 20),

                        // Generate button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: GestureDetector(
                            onTap: _ingredients.isNotEmpty ? _generate : null,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _ingredients.isNotEmpty
                                    ? const LinearGradient(colors: [
                                        ThemeService.fieryRed,
                                        ThemeService.warmOrange
                                      ])
                                    : null,
                                color: _ingredients.isEmpty
                                    ? (isDark
                                        ? const Color(0xFF3D322A)
                                        : ThemeService.warmCream)
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: provider.isGenerating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _ingredients.isEmpty
                                                ? 'Add some ingredients first'
                                                : '✨ Generate Recipes',
                                            style: GoogleFonts.nunito(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _ingredients.isEmpty
                                                  ? ThemeService.warmGrey
                                                  : Colors.white,
                                            ),
                                          ),
                                          if (_ingredients.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            const Text('🔪',
                                                style: TextStyle(fontSize: 18)),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // ─── Error ────────────────────────────────────────
                        if (provider.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.error!,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12, color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ─── Results ──────────────────────────────────────
                        if (provider.generatedRecipes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Results',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 18,
                                  color: isDark
                                      ? const Color(0xFFF5EDE6)
                                      : ThemeService.charcoal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ThemeService.fieryRed
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${provider.generatedRecipes.length} recipes',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.fieryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...provider.generatedRecipes.map((recipe) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RecipeCard(
                                  recipe: recipe,
                                  onTap: () =>
                                      context.push('/recipe/${recipe.id}'),
                                  onSave: () =>
                                      provider.saveGeneratedRecipe(recipe),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildChefIntro(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  ThemeService.warmOrange.withValues(alpha: 0.12),
                  ThemeService.goldenYellow.withValues(alpha: 0.05)
                ]
              : [
                  ThemeService.fieryRed.withValues(alpha: 0.08),
                  ThemeService.goldenYellow.withValues(alpha: 0.04)
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
                child: Text('👨‍🍳', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Got ingredients? Let's cook! 🔥",
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
                  'AI will suggest recipes you can make right now',
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
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dietary preference
          _filterLabel('Dietary'),
          const SizedBox(height: 6),
          _filterChips(
              _dietOptions, _dietary, (v) => setState(() => _dietary = v)),
          const SizedBox(height: 14),

          // Cuisine
          _filterLabel('Cuisine'),
          const SizedBox(height: 6),
          _filterChips(
              _cuisineOptions, _cuisine, (v) => setState(() => _cuisine = v)),
          const SizedBox(height: 14),

          // Skill level
          _filterLabel('Skill Level'),
          const SizedBox(height: 6),
          _filterChips(_skillOptions, _skillLevel,
              (v) => setState(() => _skillLevel = v)),
          const SizedBox(height: 14),

          // Max time
          _filterLabel('Max Time'),
          const SizedBox(height: 6),
          _filterChips(
              _timeOptions.map((t) => '$t min').toList(),
              _maxTime?.toString().replaceAll(' min', ''),
              (v) => setState(() => _maxTime =
                  v == 'Any' ? null : int.tryParse(v.replaceAll(' min', '')))),
          const SizedBox(height: 14),

          // Servings
          _filterLabel('Servings'),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (_servings > 1) _servings--;
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.softCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove, size: 18),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_servings',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF5EDE6)
                        : ThemeService.charcoal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _servings++),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.softCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'servings',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: ThemeService.warmGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ThemeService.warmGrey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _filterChips(
      List<String> options, String? selected, void Function(String) onTap) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final sel = selected == opt || (selected == null && opt == 'Any');
        return GestureDetector(
          onTap: () => onTap(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? ThemeService.warmOrange.withValues(alpha: 0.3)
                      : ThemeService.fieryRed.withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? ThemeService.warmOrange
                        : ThemeService.fieryRed)
                    : ThemeService.warmGrey.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? ThemeService.warmOrange
                        : ThemeService.fieryRed)
                    : ThemeService.warmGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

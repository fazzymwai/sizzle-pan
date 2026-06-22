import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';
import 'package:sizzle_pan/widgets/recipe_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _remixOptions = [
    'Original',
    'Healthier',
    'Faster',
    'Creative'
  ];
  final List<String> _remixEmojis = ['ðŸ½ï¸', 'ðŸ¥—', 'âš¡', 'ðŸŽ¨'];
  String _selectedRemix = 'Original';
  List<Recipe> _searchResults = [];
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
    // Pre-load recipes for faster local search
  }

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    final localResults =
        await context.read<RecipeProvider>().searchRecipes(query);
    final aiResults = AIService.searchAndRemixRecipes(query, _selectedRemix);
    setState(() {
      _searchResults = [...localResults, ...aiResults];
      _isSearching = false;
    });
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    try {
      await context.read<RecipeProvider>().saveRecipe(recipe);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('\u2705 '),
                Text('Recipe saved!'),
              ],
            ),
            backgroundColor: ThemeService.fieryRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save recipe'),
            backgroundColor: ThemeService.warmGrey,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          'Search & Remix',
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
              color: isDark ? const Color(0xFF2A221C) : ThemeService.warmCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chef intro
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF2A221C),
                                  const Color(0xFF3D322A),
                                ]
                              : [
                                  ThemeService.softCoral,
                                  ThemeService.warmCream,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D322A)
                              : ThemeService.fieryRed.withValues(alpha: 0.1),
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ThemeService.goldenYellow
                                      .withValues(alpha: 0.2),
                                  ThemeService.fieryRed.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('\u{1F50D}',
                                  style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Looking for something specific?',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFF5EDE6)
                                        : ThemeService.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Let's remix it! \u{1F39B}\u{FE0F}",
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: ThemeService.warmGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search field
                    Container(
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
                                : ThemeService.fieryRed.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: isDark
                              ? const Color(0xFFF5EDE6)
                              : ThemeService.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search recipes, ingredients...',
                          hintStyle: GoogleFonts.nunito(
                            color: ThemeService.warmGrey.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: ThemeService.fieryRed,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults.clear();
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: ThemeService.warmGrey
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.close, size: 18),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (_) => _searchRecipes(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Remix style header
                    Row(
                      children: [
                        Text(
                          '\u{1F39B}\u{FE0F} Remix Style',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 16,
                            color: isDark
                                ? const Color(0xFFF5EDE6)
                                : ThemeService.charcoal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\u2014 pick your twist',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: ThemeService.warmGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Remix FilterChips
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: List.generate(_remixOptions.length, (index) {
                        final option = _remixOptions[index];
                        final emoji = _remixEmojis[index];
                        final isSelected = _selectedRemix == option;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRemix = option;
                            });
                            if (_searchController.text.isNotEmpty) {
                              _searchRecipes();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              ThemeService.warmOrange,
                                              ThemeService.goldenYellow,
                                            ]
                                          : [
                                              ThemeService.fieryRed,
                                              ThemeService.goldenYellow,
                                            ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : isDark
                                      ? const Color(0xFF2A221C)
                                      : ThemeService.warmCream,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : isDark
                                        ? const Color(0xFF3D322A)
                                        : ThemeService.warmGrey
                                            .withValues(alpha: 0.2),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark
                                                ? ThemeService.warmOrange
                                                : ThemeService.fieryRed)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  option,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : isDark
                                            ? const Color(0xFFB0A79E)
                                            : ThemeService.charcoal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // Search button
                    GestureDetector(
                      onTap: _isSearching ? null : _searchRecipes,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: _isSearching
                                ? [
                                    ThemeService.warmGrey
                                        .withValues(alpha: 0.4),
                                    ThemeService.warmGrey
                                        .withValues(alpha: 0.3),
                                  ]
                                : isDark
                                    ? [
                                        ThemeService.warmOrange,
                                        ThemeService.goldenYellow,
                                      ]
                                    : [
                                        ThemeService.fieryRed,
                                        ThemeService.goldenYellow,
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _isSearching
                                  ? Colors.transparent
                                  : (isDark
                                          ? ThemeService.warmOrange
                                          : ThemeService.fieryRed)
                                      .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSearching
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          isDark
                                              ? ThemeService.charcoal
                                              : ThemeService.pureWhite,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Cooking up results...',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? ThemeService.charcoal
                                            : ThemeService.pureWhite,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('\u{1F52A}',
                                        style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Search & Sizzle',
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 18,
                                        color: ThemeService.pureWhite,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Results section
                    if (_searchResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '\u{1F525} Results',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 18,
                                color: isDark
                                    ? const Color(0xFFF5EDE6)
                                    : ThemeService.charcoal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeService.fieryRed
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${_searchResults.length} found',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.fieryRed,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchResults.clear();
                                  _searchController.clear();
                                });
                              },
                              child: Text(
                                'Clear all',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: ThemeService.warmGrey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Results list or empty state
                    if (_searchResults.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = _searchResults[index];
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () => context.push('/recipe/${recipe.id}'),
                            onSave: () => _saveRecipe(recipe),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A221C) : ThemeService.warmCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D322A)
              : ThemeService.warmGrey.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeService.goldenYellow.withValues(alpha: 0.15),
                  ThemeService.fieryRed.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('\u{1F373}', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nothing on the stove yet!',
            style: GoogleFonts.luckiestGuy(
              fontSize: 18,
              color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type something above and hit search \u2014\nyour next delicious adventure awaits! \u{1F680}',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: ThemeService.warmGrey,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

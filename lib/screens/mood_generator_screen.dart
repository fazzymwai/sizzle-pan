import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';
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

  final List<_MoodOption> _moods = [
    const _MoodOption('Tired', '😴'),
    const _MoodOption('Lazy', '🦥'),
    const _MoodOption('Excited', '🤩'),
    const _MoodOption('Romantic', '🥰'),
    const _MoodOption('Stressed', '😤'),
    const _MoodOption('Happy', '😊'),
    const _MoodOption('Hungry', '🤤'),
  ];

  final List<_OccasionOption> _occasions = [
    const _OccasionOption('Breakfast', '🌅'),
    const _OccasionOption('Lunch', '☀️'),
    const _OccasionOption('Dinner', '🌙'),
    const _OccasionOption('Snack', '🍿'),
    const _OccasionOption('Date Night', '💕'),
    const _OccasionOption('Family Meal', '👨‍👩‍👧‍👦'),
    const _OccasionOption('Quick Meal', '⚡'),
    const _OccasionOption('Comfort Food', '🧸'),
  ];

  Future<void> _generateRecipes() async {
    if (_selectedMood.isEmpty || _selectedOccasion.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final recipes =
        AIService.generateRecipesFromMood(_selectedMood, _selectedOccasion);

    setState(() {
      _generatedRecipes = recipes;
      _isGenerating = false;
    });
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    try {
      await context.read<RecipeProvider>().saveRecipe(recipe);
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
    final canGenerate =
        _selectedMood.isNotEmpty && _selectedOccasion.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? ThemeService.darkBg : ThemeService.warmCream,
      appBar: AppBar(
        title: Text(
          'How I Feel',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
          ),
        ),
        leading: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D322A) : ThemeService.pureWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chef intro
            Container(
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
                          ThemeService.softCoral,
                          ThemeService.warmCream,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? ThemeService.warmOrange.withValues(alpha: 0.15)
                      : ThemeService.fieryRed.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  const Text('🎭', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's your culinary mood?",
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
                          "Pick a vibe and let's find the perfect dish!",
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: ThemeService.warmGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Mood selection
            Text(
              'How are you feeling?',
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = isSelected ? '' : mood.name;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isDark
                                  ? [
                                      ThemeService.warmOrange,
                                      ThemeService.goldenYellow
                                    ]
                                  : [
                                      ThemeService.fieryRed,
                                      ThemeService.warmOrange
                                    ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? const Color(0xFF2A221C)
                              : ThemeService.pureWhite),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                ? const Color(0xFF3D322A)
                                : ThemeService.warmCream),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isDark
                                        ? ThemeService.warmOrange
                                        : ThemeService.fieryRed)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          mood.name,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFF5EDE6)
                                    : ThemeService.charcoal),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Occasion selection
            Text(
              'What\u2019s the occasion?',
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _occasions.map((occasion) {
                final isSelected = _selectedOccasion == occasion.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOccasion = isSelected ? '' : occasion.name;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isDark
                                  ? [
                                      ThemeService.goldenYellow,
                                      ThemeService.warmOrange
                                    ]
                                  : [
                                      ThemeService.goldenYellow,
                                      ThemeService.fieryRed
                                    ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? const Color(0xFF2A221C)
                              : ThemeService.pureWhite),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                ? const Color(0xFF3D322A)
                                : ThemeService.warmCream),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: ThemeService.goldenYellow
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(occasion.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          occasion.name,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? ThemeService.charcoal
                                : (isDark
                                    ? const Color(0xFFF5EDE6)
                                    : ThemeService.charcoal),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Generate button
            if (canGenerate)
              GestureDetector(
                onTap: _isGenerating ? null : _generateRecipes,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [ThemeService.warmOrange, ThemeService.goldenYellow]
                          : [ThemeService.fieryRed, ThemeService.warmOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? ThemeService.warmOrange
                                : ThemeService.fieryRed)
                            .withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isGenerating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🍳', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Text(
                                'Generate Recipes',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Results
            if (_generatedRecipes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Perfect picks for you',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 18,
                        color: isDark
                            ? const Color(0xFFF5EDE6)
                            : ThemeService.charcoal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_generatedRecipes.length} recipes',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: ThemeService.warmGrey,
                      ),
                    ),
                  ],
                ),
              ),

            if (_generatedRecipes.isEmpty && !canGenerate)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.warmCream,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Pick your mood and occasion!',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.warmGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Then let the chef work his magic ✨",
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: ThemeService.warmGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_generatedRecipes.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _generatedRecipes[index];
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
    );
  }
}

class _MoodOption {
  final String name;
  final String emoji;
  const _MoodOption(this.name, this.emoji);
}

class _OccasionOption {
  final String name;
  final String emoji;
  const _OccasionOption(this.name, this.emoji);
}

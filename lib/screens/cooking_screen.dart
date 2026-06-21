import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/models/cooking_session.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/ai_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class CookingScreen extends StatefulWidget {
  final String recipeId;
  const CookingScreen({super.key, required this.recipeId});

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  Recipe? _recipe;
  CookingSession? _session;
  int _currentStep = 0;
  bool _isLoading = true;
  final TextEditingController _questionController = TextEditingController();
  final _uuid = const Uuid();
  String? _aiResponse;
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();
    _loadCookingData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadCookingData() async {
    setState(() => _isLoading = true);
    try {
      final recipe = await DatabaseService.getRecipeById(widget.recipeId);
      if (recipe != null) {
        final session = await DatabaseService.getActiveSession(widget.recipeId);
        setState(() {
          _recipe = recipe;
          _session = session;
          _currentStep = session?.currentStep ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _recipe = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCooking() async {
    final session = CookingSession(
      id: _uuid.v4(),
      recipeId: widget.recipeId,
      currentStep: 0,
      startedAt: DateTime.now(),
    );
    await DatabaseService.createCookingSession(session);
    setState(() {
      _session = session;
      _currentStep = 0;
    });
  }

  Future<void> _nextStep() async {
    if (_recipe == null || _currentStep >= _recipe!.steps.length - 1) {
      if (_recipe != null && _currentStep >= _recipe!.steps.length - 1) {
        await _completeCooking();
      }
      return;
    }
    final newStep = _currentStep + 1;
    if (_session != null) {
      final updated = _session!.copyWith(currentStep: newStep);
      await DatabaseService.updateCookingSession(updated);
    }
    setState(() {
      _currentStep = newStep;
      _aiResponse = null;
    });
  }

  Future<void> _previousStep() async {
    if (_currentStep <= 0) return;
    final newStep = _currentStep - 1;
    if (_session != null) {
      final updated = _session!.copyWith(currentStep: newStep);
      await DatabaseService.updateCookingSession(updated);
    }
    setState(() {
      _currentStep = newStep;
      _aiResponse = null;
    });
  }

  Future<void> _completeCooking() async {
    if (_session != null) {
      await DatabaseService.completeCookingSession(_session!.id);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildCelebrationDialog(ctx),
    );
  }

  Future<void> _askAI() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _recipe == null) return;
    setState(() => _isAsking = true);
    final response = AIService.getCookingAdvice(question, _recipe!, _currentStep);
    setState(() {
      _aiResponse = response;
      _isAsking = false;
    });
    _questionController.clear();
  }

  void _exitWithConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? ThemeService.darkBg
            : ThemeService.warmCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Leave the Kitchen? \u{1F373}',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: ThemeService.fieryRed,
          ),
        ),
        content: Text(
          'Your progress will be saved. Come back anytime, chef! \u{1F468}\u200D\u{1F373}',
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: ThemeService.warmGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Keep Cooking',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: ThemeService.goldenYellow,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeService.fieryRed,
              foregroundColor: ThemeService.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ThemeService.fieryRed, ThemeService.deepRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: ThemeService.fieryRed.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Amazing Job!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 32,
                color: ThemeService.pureWhite,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You crushed it, chef! \u{1F525}\nYour masterpiece is ready!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: ThemeService.pureWhite.withValues(alpha: 0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeService.goldenYellow,
                  foregroundColor: ThemeService.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Kitchen \u{1F3C6}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading State ──────────────────────────────────────────────────
  Widget _buildLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(ThemeService.fieryRed),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Firing up the kitchen... \u{1F525}',
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: isDark ? ThemeService.warmGrey : ThemeService.charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Not Found State ────────────────────────────────────────────────
  Widget _buildNotFound() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\u{1F615}',
              style: TextStyle(
                fontSize: 72,
                color: isDark ? ThemeService.warmGrey : ThemeService.charcoal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recipe Not Found',
              style: GoogleFonts.luckiestGuy(
                fontSize: 28,
                color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Looks like this recipe got away! \u{1F3C3}\nLet\'s find another one to sizzle!',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: isDark ? ThemeService.warmGrey : ThemeService.charcoal,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: Text(
                'Back to Recipes',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.fieryRed,
                foregroundColor: ThemeService.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pre-Cooking State ──────────────────────────────────────────────
  Widget _buildPreCooking() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipe = _recipe!;
    final greeting = ThemeService.randomChefGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chef greeting banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [ThemeService.darkBg, ThemeService.charcoal]
                    : [ThemeService.softCoral, ThemeService.warmCream],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? ThemeService.warmOrange.withValues(alpha: 0.3)
                    : ThemeService.fieryRed.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Text('\u{1F468}\u200D\u{1F373}', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    greeting,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recipe title header
          Center(
            child: Text(
              recipe.title,
              style: GoogleFonts.luckiestGuy(
                fontSize: 32,
                color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Get ready to make something amazing! \u{1F525}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: isDark ? ThemeService.warmGrey : ThemeService.charcoal,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recipe info grid
          Row(
            children: [
              _buildInfoChip('\u23F1\uFE0F ${recipe.cookingTime} min', isDark),
              const SizedBox(width: 10),
              _buildInfoChip('\u{1F37D}\uFE0F ${recipe.servings} serving${recipe.servings > 1 ? 's' : ''}', isDark),
              const SizedBox(width: 10),
              _buildInfoChip('\u{1F4CA} ${recipe.difficulty}', isDark),
            ],
          ),
          const SizedBox(height: 24),

          // Ingredients section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2A221C), const Color(0xFF1A1410)]
                    : [ThemeService.pureWhite, ThemeService.warmCream],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3D322A)
                    : ThemeService.goldenYellow.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : ThemeService.goldenYellow)
                      .withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('\u{1F6D2}', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      'Ingredients',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 20,
                        color: isDark ? ThemeService.goldenYellow : ThemeService.charcoal,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...recipe.ingredients.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '\u{1F373} ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            ing,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFFE0D6CC)
                                  : ThemeService.charcoal,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chef tip section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ThemeService.goldenYellow.withValues(alpha: 0.1)
                  : ThemeService.goldenYellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeService.goldenYellow.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u{1F4A1}', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ThemeService.randomChefTip(),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: isDark
                          ? ThemeService.goldenYellow
                          : ThemeService.warmGrey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start Cooking button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _startCooking,
              icon: const Icon(Icons.abc, size: 26),
              label: Text(
                'Start Cooking! \u{1F525}',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.fieryRed,
                foregroundColor: ThemeService.pureWhite,
                elevation: 4,
                shadowColor: ThemeService.fieryRed.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A221C)
            : ThemeService.pureWhite,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D322A)
              : ThemeService.goldenYellow.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFE0D6CC) : ThemeService.charcoal,
        ),
      ),
    );
  }

  // ─── Active Cooking State ───────────────────────────────────────────
  Widget _buildActiveCooking() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipe = _recipe!;
    final totalSteps = recipe.steps.length;
    final progress = (_currentStep + 1) / totalSteps;

    return Column(
      children: [
        // Step progress header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: BoxDecoration(
            color: isDark ? ThemeService.darkBg : ThemeService.warmCream,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF3D322A)
                    : ThemeService.warmGrey.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Column(
            children: [
              // Step counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? ThemeService.warmOrange.withValues(alpha: 0.15)
                      : ThemeService.fieryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of $totalSteps',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF3D322A)
                      : ThemeService.warmGrey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable cooking content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Current step card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2A221C), ThemeService.darkBg]
                          : [ThemeService.pureWhite, ThemeService.warmCream],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3D322A)
                          : ThemeService.fieryRed.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : ThemeService.fieryRed)
                            .withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number badge
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [ThemeService.fieryRed, ThemeService.deepRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ThemeService.fieryRed.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${_currentStep + 1}',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 24,
                                color: ThemeService.pureWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Step instruction
                      Text(
                        recipe.steps[_currentStep],
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF5EDE6)
                              : ThemeService.charcoal,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Chef encouragement
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ThemeService.goldenYellow.withValues(alpha: 0.08)
                              : ThemeService.goldenYellow.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ThemeService.goldenYellow.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('\u{1F468}\u200D\u{1F373}', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getStepEncouragement(),
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: isDark
                                      ? ThemeService.goldenYellow
                                      : ThemeService.warmGrey,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AI Assistant section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [ThemeService.warmOrange.withValues(alpha: 0.08), const Color(0xFF2A221C)]
                          : [ThemeService.softCoral.withValues(alpha: 0.4), ThemeService.pureWhite],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? ThemeService.warmOrange.withValues(alpha: 0.2)
                          : ThemeService.fieryRed.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('\u{1F916}', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(
                            'Chef Assistant',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 18,
                              color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Got a question? Need a substitution? Ask your AI chef!',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: isDark ? ThemeService.warmGrey : ThemeService.charcoal,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // AI response
                      if (_aiResponse != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1410)
                                : ThemeService.warmCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3D322A)
                                  : ThemeService.goldenYellow.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('\u{1F4AC}', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _aiResponse!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFFE0D6CC)
                                        : ThemeService.charcoal,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Question input
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A221C)
                                    : ThemeService.pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3D322A)
                                      : ThemeService.warmGrey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: TextField(
                                controller: _questionController,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFFF5EDE6)
                                      : ThemeService.charcoal,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ask your AI chef...',
                                  hintStyle: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: isDark
                                        ? ThemeService.warmGrey.withValues(alpha: 0.5)
                                        : ThemeService.warmGrey.withValues(alpha: 0.6),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _askAI(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _isAsking ? null : _askAI,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [ThemeService.fieryRed, ThemeService.deepRed],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeService.fieryRed.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isAsking
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            ThemeService.pureWhite,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: ThemeService.pureWhite,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom navigation bar
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? ThemeService.darkBg : ThemeService.warmCream,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF3D322A)
                    : ThemeService.warmGrey.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              // Previous button
              Expanded(
                child: GestureDetector(
                  onTap: _currentStep > 0 ? _previousStep : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _currentStep > 0
                          ? (isDark
                              ? const Color(0xFF2A221C)
                              : ThemeService.pureWhite)
                          : (isDark
                              ? const Color(0xFF2A221C).withValues(alpha: 0.5)
                              : ThemeService.warmGrey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentStep > 0
                            ? (isDark
                                ? const Color(0xFF3D322A)
                                : ThemeService.warmGrey.withValues(alpha: 0.3))
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _currentStep > 0
                                ? (isDark
                                    ? const Color(0xFFE0D6CC)
                                    : ThemeService.charcoal)
                                : ThemeService.warmGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _currentStep > 0
                                  ? (isDark
                                      ? const Color(0xFFE0D6CC)
                                      : ThemeService.charcoal)
                                  : ThemeService.warmGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Next / Complete button
              Expanded(
                child: GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _currentStep >= recipe.steps.length - 1
                          ? const LinearGradient(
                              colors: [ThemeService.goldenYellow, ThemeService.warmOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [ThemeService.fieryRed, ThemeService.deepRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_currentStep >= recipe.steps.length - 1
                                  ? ThemeService.goldenYellow
                                  : ThemeService.fieryRed)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep >= recipe.steps.length - 1
                                ? 'Complete \u{1F389}'
                                : 'Next',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _currentStep >= recipe.steps.length - 1
                                  ? ThemeService.charcoal
                                  : ThemeService.pureWhite,
                            ),
                          ),
                          if (_currentStep < recipe.steps.length - 1) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: ThemeService.pureWhite,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStepEncouragement() {
    final encouragements = [
      'You\'re doing great, chef! Keep that sizzle going! \u{1F525}',
      'Smells amazing already! You\'ve got this! \u{1F468}\u200D\u{1F373}',
      'Perfect timing — just like a pro! \u23F1\uFE0F',
      'Look at you go! Restaurant quality coming right up! \u{1F373}',
      'This is the secret to amazing food — you\'re nailing it! \u{1F4AA}',
      'Taste as you go — that\'s the chef way! \u{1F445}',
      'Almost there, and it\'s looking spectacular! \u2728',
      'Trust the process, chef — you\'re cooking magic! \u{1FA84}',
    ];
    return encouragements[_currentStep % encouragements.length];
  }

  // ─── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActiveCooking = _recipe != null && _session != null;

    return Scaffold(
      backgroundColor: isDark ? ThemeService.darkBg : ThemeService.warmCream,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: isActiveCooking ? _exitWithConfirmation : () => context.go('/'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A221C)
                  : ThemeService.pureWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark
                  ? const Color(0xFFE0D6CC)
                  : ThemeService.charcoal,
              size: 22,
            ),
          ),
        ),
        title: Text(
          isActiveCooking ? 'Sizzle Pan \u{1F373}' : (_recipe?.title ?? 'Cooking'),
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoading()
          : _recipe == null
              ? _buildNotFound()
              : _session == null
                  ? _buildPreCooking()
                  : _buildActiveCooking(),
    );
  }
}

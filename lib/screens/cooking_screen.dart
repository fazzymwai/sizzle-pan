import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/models/chat_message.dart';
import 'package:sizzle_pan/models/cooking_session.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/anthropic_service.dart';
import 'package:sizzle_pan/services/theme_service.dart';
import 'package:uuid/uuid.dart';

class _NamedTimer {
  final String id;
  final String label;
  int durationSeconds;
  int elapsedSeconds = 0;
  bool isRunning = false;
  int stepIndex;

  _NamedTimer({
    required this.id,
    required this.label,
    required this.durationSeconds,
    required this.stepIndex,
  });

  int get remaining => durationSeconds - elapsedSeconds;
  double get progress =>
      durationSeconds > 0 ? elapsedSeconds / durationSeconds : 0.0;
  String get formatted {
    final r = remaining;
    return '${r ~/ 60}:${(r % 60).toString().padLeft(2, '0')}';
  }
}

class _PanicOption {
  final String emoji;
  final String label;
  final String hint;
  final String question;
  const _PanicOption(this.emoji, this.label, this.hint, this.question);
}

class CookingScreen extends StatefulWidget {
  final String recipeId;
  const CookingScreen({super.key, required this.recipeId});

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  final PageController _pageCtrl = PageController();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();
  final _uuid = const Uuid();

  Recipe? _recipe;
  int _currentStep = 0;
  bool _isLoading = true;
  bool _showChat = false;
  bool _isAsking = false;
  bool _isComplete = false;

  // Timers
  final List<_NamedTimer> _timers = [];
  Timer? _globalTimer;
  int _timerIdCounter = 0;

  // Chat
  List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    _globalTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    final recipe =
        await context.read<RecipeProvider>().getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
      if (recipe != null) {
        // Parse timer hints from steps
        for (int i = 0; i < recipe.steps.length; i++) {
          final seconds = _parseTimerFromStep(recipe.steps[i]);
          if (seconds > 0) {
            _timers.add(_NamedTimer(
              id: 'auto_${_timerIdCounter++}',
              label: 'Step ${i + 1}',
              durationSeconds: seconds,
              stepIndex: i,
            ));
          }
        }
        // Load existing session
        _loadExistingSession(recipe.id);
      }
    }
  }

  Future<void> _loadExistingSession(String recipeId) async {
    final session = await DatabaseService.getActiveSession(recipeId);
    if (session != null && mounted) {
      setState(() {
        _currentStep = session.currentStep;
        _chatMessages = session.chatHistory
            .map((m) => ChatMessage(
                  role: m['role']!,
                  content: m['content']!,
                  timestamp: DateTime.now(),
                ))
            .toList();
      });
      _pageCtrl.jumpToPage(_currentStep);
    }
  }

  int _parseTimerFromStep(String step) {
    final regex = RegExp(r'(\d+)\s*(min|minute|minutes|sec|second|seconds)',
        caseSensitive: false);
    final match = regex.firstMatch(step);
    if (match != null) {
      final num = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      if (unit.startsWith('min')) return num * 60;
      return num;
    }
    return 0;
  }

  void _addTimer(String label, int seconds, {int? stepIndex}) {
    setState(() {
      _timers.add(_NamedTimer(
        id: 't${_timerIdCounter++}',
        label: label,
        durationSeconds: seconds,
        stepIndex: stepIndex ?? _currentStep,
      ));
    });
  }

  void _removeTimer(String id) {
    setState(() {
      _timers.removeWhere((t) => t.id == id);
    });
    _stopGlobalTimerIfNeeded();
  }

  void _toggleTimer(String id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    setState(() {
      timer.isRunning = !timer.isRunning;
      if (timer.isRunning) {
        _startGlobalTimer();
      } else {
        _stopGlobalTimerIfNeeded();
      }
    });
  }

  void _resetTimer(String id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    setState(() {
      timer.elapsedSeconds = 0;
      timer.isRunning = false;
    });
    _stopGlobalTimerIfNeeded();
  }

  void _startGlobalTimer() {
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        bool anyRunning = false;
        for (final t in _timers) {
          if (t.isRunning) {
            t.elapsedSeconds++;
            if (t.durationSeconds > 0 &&
                t.elapsedSeconds >= t.durationSeconds) {
              t.isRunning = false;
              _onTimerComplete(t);
            }
            anyRunning = true;
          }
        }
        if (!anyRunning) _globalTimer?.cancel();
      });
    });
  }

  void _stopGlobalTimerIfNeeded() {
    if (_timers.every((t) => !t.isRunning)) _globalTimer?.cancel();
  }

  void _onTimerComplete(_NamedTimer timer) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A221C)
            : ThemeService.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏰', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Time\'s up!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 24,
                color: ThemeService.fieryRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${timer.label}" is done!',
              style: GoogleFonts.nunito(
                  fontSize: 14, color: ThemeService.warmGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_recipe == null) return;
    if (_currentStep < _recipe!.steps.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _completeCooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeCooking() async {
    final session = await DatabaseService.getActiveSession(widget.recipeId);
    if (session != null) {
      await DatabaseService.completeCookingSession(session.id);
    }
    if (!mounted) return;
    setState(() => _isComplete = true);
  }

  Future<void> _saveSession() async {
    if (_recipe == null) return;
    final existing = await DatabaseService.getActiveSession(widget.recipeId);
    final session = (existing ??
            CookingSession(
              id: _uuid.v4(),
              recipeId: widget.recipeId,
              currentStep: _currentStep,
              startedAt: DateTime.now(),
            ))
        .copyWith(
      currentStep: _currentStep,
      chatHistory: _chatMessages.map((m) => m.toJson()).toList(),
      stepTimers: _timers
          .map((t) => StepTimer(
                stepIndex: t.stepIndex,
                durationSeconds: t.durationSeconds,
                elapsedSeconds: t.elapsedSeconds,
              ))
          .toList(),
    );

    if (existing != null) {
      await DatabaseService.updateCookingSession(session);
    } else {
      await DatabaseService.createCookingSession(session);
    }
  }

  // ─── AI Chat ────────────────────────────────────────────────────────

  Future<void> _askAI() async {
    final question = _chatCtrl.text.trim();
    if (question.isEmpty || _recipe == null) return;

    setState(() {
      _isAsking = true;
      _chatMessages.add(ChatMessage(
          role: 'user', content: question, timestamp: DateTime.now()));
    });
    _chatCtrl.clear();

    try {
      final response = await AnthropicService.getCookingAdvice(
        question: question,
        recipeTitle: _recipe!.title,
        recipeSteps: _recipe!.steps,
        currentStepIndex: _currentStep,
        ingredients: _recipe!.ingredientNames,
        conversationHistory: _chatMessages.map((m) => m.toJson()).toList(),
      );

      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
              role: 'assistant', content: response, timestamp: DateTime.now()));
          _isAsking = false;
        });
        _saveSession();
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollCtrl.hasClients) {
            _chatScrollCtrl.animateTo(
              _chatScrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            role: 'assistant',
            content: 'Hmm, I had trouble answering that. Let me try again!',
            timestamp: DateTime.now(),
          ));
          _isAsking = false;
        });
      }
    }
  }

  // ─── Substitutions ──────────────────────────────────────────────────

  Future<void> _showSubstitutions(String ingredient) async {
    if (_recipe == null) return;
    try {
      final result =
          await AnthropicService.getSubstitutions(ingredient, _recipe!.title);
      final subs = (jsonDecode(result) as List)
          .map((e) => Substitution.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A221C)
              : ThemeService.pureWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, color: ThemeService.goldenYellow),
              const SizedBox(width: 8),
              Text(
                'Swap $ingredient',
                style: GoogleFonts.luckiestGuy(
                    fontSize: 20, color: ThemeService.fieryRed),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: subs
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              ThemeService.goldenYellow.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.swap,
                                style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(s.ratio,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: ThemeService.warmGrey)),
                            if (s.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(s.notes!,
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: ThemeService.warmGrey,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Thanks!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  // ─── Panic / Rescue Mode ────────────────────────────────────────────

  void _showPanicMode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeService.warmGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🚨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text('Panic Mode',
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 22, color: ThemeService.fieryRed)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Something go wrong? Tap to ask the AI for help.',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: ThemeService.warmGrey)),
            const SizedBox(height: 16),
            ..._panicOptions.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _sendPanicMessage(option.question);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Text(option.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(option.label,
                                    style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFFF5EDE6)
                                            : ThemeService.charcoal)),
                                Text(option.hint,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: ThemeService.warmGrey)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: ThemeService.warmGrey),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _sendPanicMessage(String question) {
    setState(() {
      _showChat = true;
      _chatCtrl.text = question;
    });
    Future.delayed(const Duration(milliseconds: 500), _askAI);
  }

  static const _panicOptions = [
    _PanicOption('🧂', 'Oversalted', 'Too salty \u2014 fix it!',
        'I oversalted my dish, what can I do to fix it right now?'),
    _PanicOption('💧', 'Too watery', 'Sauce too thin',
        'My sauce is too watery, how do I thicken it quickly?'),
    _PanicOption('🔥', 'Burning', 'Sticking to the pan',
        'My food is burning / sticking to the pan, what should I do?'),
    _PanicOption('🥛', 'Sauce broke', 'Emulsion separated',
        'My sauce broke / separated, how do I rescue it?'),
    _PanicOption('🌶️', 'Too spicy', 'Over-seasoned',
        'I made it too spicy, how can I tone it down?'),
    _PanicOption('❓', 'Something else', 'Describe the issue',
        'Help! Something went wrong with my cooking. Can you help?'),
  ];

  // ─── Technique Micro-Help ───────────────────────────────────────────

  void _showTechniqueHelp(String verb) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A221C)
            : ThemeService.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeService.goldenYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book,
                  color: ThemeService.goldenYellow, size: 20),
            ),
            const SizedBox(width: 10),
            Text(verb[0].toUpperCase() + verb.substring(1),
                style: GoogleFonts.luckiestGuy(
                    fontSize: 20, color: ThemeService.fieryRed)),
          ],
        ),
        content: FutureBuilder<String>(
          future: _getTechniqueExplanation(verb),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Text(
              snapshot.data ?? 'Could not load technique info.',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE0D6CC)
                      : ThemeService.charcoal,
                  height: 1.5),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<String> _getTechniqueExplanation(String verb) async {
    try {
      return await AnthropicService.getCookingAdvice(
        question: 'Explain what "$verb" means in cooking, in 2-3 sentences.',
        recipeTitle: _recipe?.title ?? '',
        recipeSteps: _recipe?.steps ?? [],
        currentStepIndex: _currentStep,
        ingredients: _recipe?.ingredientNames ?? [],
      );
    } catch (_) {
      return 'Could not load explanation. Try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(strokeWidth: 4)),
              const SizedBox(height: 24),
              Text('Firing up the kitchen... 🔥',
                  style: GoogleFonts.nunito(
                      fontSize: 18, color: ThemeService.warmGrey)),
            ],
          ),
        ),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😢', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Recipe not found',
                  style: GoogleFonts.nunito(
                      fontSize: 16, color: ThemeService.warmGrey)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    if (_isComplete) {
      return _buildCelebration(isDark);
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1410) : ThemeService.warmCream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ─── Top Bar ──────────────────────────────────────────
                _buildTopBar(isDark),

                // ─── Step Content (PageView) ──────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (page) {
                      setState(() => _currentStep = page);
                      _saveSession();
                    },
                    itemCount: _recipe!.steps.length +
                        1, // +1 for ingredients overview
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildOverview(isDark);
                      }
                      return _buildStepPage(isDark, index - 1);
                    },
                  ),
                ),

                // ─── Timer Overview Bar ───────────────────────────────
                _buildTimerBar(isDark),

                // ─── Bottom Controls ───────────────────────────────────
                _buildBottomControls(isDark),
              ],
            ),

            // ─── Chat Panel ───────────────────────────────────────────
            if (_showChat) _buildChatPanel(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final totalSteps = _recipe!.steps.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3D322A) : ThemeService.pureWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _recipe!.title,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF5EDE6)
                            : ThemeService.charcoal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_currentStep + 1} / $totalSteps',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.warmGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / totalSteps,
                    backgroundColor: isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.warmCream,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Panic button
          GestureDetector(
            onTap: _showPanicMode,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🚨', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 6),
          // Chat toggle
          GestureDetector(
            onTap: () => setState(() => _showChat = !_showChat),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _showChat
                    ? (isDark ? ThemeService.warmOrange : ThemeService.fieryRed)
                    : (isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.pureWhite),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: _showChat
                    ? Colors.white
                    : (isDark
                        ? ThemeService.warmOrange
                        : ThemeService.fieryRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recipe!.title,
            style: GoogleFonts.luckiestGuy(
              fontSize: 32,
              color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
            ),
          ),
          if (_recipe!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _recipe!.description,
              style: GoogleFonts.nunito(
                  fontSize: 15, color: ThemeService.warmGrey, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),

          // Quick info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip('⏱ ${_recipe!.cookingTime} min'),
              _infoChip('🍽 ${_recipe!.servings} servings'),
              _infoChip(_recipe!.difficulty == 'Easy'
                  ? '🟢 $_currentStep'
                  : _recipe!.difficulty == 'Medium'
                      ? '🟡 $_currentStep'
                      : '🔴 ${_recipe!.difficulty}'),
              if (_recipe!.dietaryInfo.isNotEmpty)
                ..._recipe!.dietaryInfo.map((d) => _infoChip('🥗 $d')),
            ],
          ),
          const SizedBox(height: 20),

          // Ingredients list
          Text(
            'Ingredients',
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          ..._recipe!.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ing.owned
                            ? Colors.green
                            : (isDark
                                ? ThemeService.warmOrange
                                : ThemeService.fieryRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ing.amount} ${ing.name}',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFFE0D6CC)
                            : ThemeService.charcoal,
                        decoration:
                            ing.owned ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.green,
                      ),
                    ),
                    if (!ing.owned) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showSubstitutions(ing.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ThemeService.goldenYellow
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Swap',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ThemeService.goldenYellow),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )),

          const SizedBox(height: 16),
          // Shopping list
          GestureDetector(
            onTap: () {
              context.read<RecipeProvider>().generateShoppingList(
                    _recipe!.ingredientNames,
                    _recipe!.ownedIngredients,
                  );
              context.push('/shopping');
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF3D322A)
                        : ThemeService.warmCream),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: ThemeService.goldenYellow),
                  const SizedBox(width: 10),
                  Text('Generate Shopping List',
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: () => _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [ThemeService.fieryRed, ThemeService.warmOrange]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    'Start Cooking! 🔪',
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeService.fieryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStepPage(bool isDark, int stepIndex) {
    final stepText = _recipe!.steps[stepIndex];
    final stepTimers = _timers.where((t) => t.stepIndex == stepIndex).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? ThemeService.warmOrange.withValues(alpha: 0.2)
                  : ThemeService.fieryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${stepIndex + 1} / ${_recipe!.steps.length}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? ThemeService.warmOrange : ThemeService.fieryRed,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Step text with tappable technique verbs
          RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: isDark ? const Color(0xFFF5EDE6) : ThemeService.charcoal,
              ),
              children: _buildStepTextSpans(stepText, isDark),
            ),
          ),

          const SizedBox(height: 24),

          // Add Timer button
          GestureDetector(
            onTap: () => _showAddTimerDialog(isDark, stepIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 18, color: ThemeService.warmGrey),
                  const SizedBox(width: 8),
                  Text('Add Timer',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.warmGrey)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Step-specific timers
          ...stepTimers.map((timer) => _buildTimerCard(timer, isDark)),

          const SizedBox(height: 20),

          // Substitutions shortcut
          if (_recipe!.missingIngredients.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ThemeService.goldenYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: ThemeService.goldenYellow.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz,
                          color: ThemeService.goldenYellow, size: 18),
                      const SizedBox(width: 8),
                      Text('Missing something?',
                          style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _recipe!.missingIngredients
                        .map((ing) => GestureDetector(
                              onTap: () => _showSubstitutions(ing),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: ThemeService.goldenYellow
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(ing,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeService.goldenYellow)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step Text with Technique Micro-Help ────────────────────────────

  List<InlineSpan> _buildStepTextSpans(String text, bool isDark) {
    final verbSet = <String>{
      'boil',
      'simmer',
      'sauté',
      'deglaze',
      'fold',
      'whisk',
      'knead',
      'roast',
      'sear',
      'blanch',
      'braise',
      'poach',
      'steam',
      'caramelize',
      'temper',
      'julienne',
      'marinate',
      'proof',
      'cream',
      'dredge',
      'glaze',
      'infuse',
      'render',
      'roux',
      'truss',
      'zest',
      'broil',
      'char',
      'chiffonade',
      'emulsify',
      'fillet',
      'parboil',
      'scald',
      'shock'
    };
    final words = text.split(' ');
    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^\w]'), '');
      final clean = word.toLowerCase();
      if (verbSet.contains(clean)) {
        spans.add(WidgetSpan(
          child: GestureDetector(
            onTap: () => _showTechniqueHelp(clean),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ThemeService.goldenYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: ThemeService.goldenYellow.withValues(alpha: 0.3)),
              ),
              child: Text(
                words[i],
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.goldenYellow,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      ThemeService.goldenYellow.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: words[i]));
      }
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }

  // ─── Timer Card ─────────────────────────────────────────────────────

  Widget _buildTimerCard(_NamedTimer timer, bool isDark) {
    final progress = timer.progress;
    final isExpired = timer.durationSeconds > 0 &&
        timer.elapsedSeconds >= timer.durationSeconds;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.green
              : timer.isRunning
                  ? (isDark ? ThemeService.warmOrange : ThemeService.fieryRed)
                  : (isDark ? const Color(0xFF3D322A) : ThemeService.warmCream),
          width: isExpired || timer.isRunning ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.green.withValues(alpha: 0.15)
                      : (timer.isRunning
                          ? (isDark
                                  ? ThemeService.warmOrange
                                  : ThemeService.fieryRed)
                              .withValues(alpha: 0.15)
                          : ThemeService.warmGrey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timer.label,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isExpired
                            ? Colors.green
                            : (timer.isRunning
                                ? (isDark
                                    ? ThemeService.warmOrange
                                    : ThemeService.fieryRed)
                                : ThemeService.warmGrey))),
              ),
              const Spacer(),
              if (timer.durationSeconds > 0)
                Text(
                  isExpired ? '✓ Done!' : timer.formatted,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isExpired
                        ? Colors.green
                        : (timer.isRunning
                            ? (isDark
                                ? ThemeService.warmOrange
                                : ThemeService.fieryRed)
                            : (isDark
                                ? const Color(0xFFE0D6CC)
                                : ThemeService.charcoal)),
                  ),
                )
              else
                Text(
                  '${timer.elapsedSeconds ~/ 60}:${(timer.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: timer.isRunning
                        ? (isDark
                            ? ThemeService.warmOrange
                            : ThemeService.fieryRed)
                        : ThemeService.warmGrey,
                  ),
                ),
            ],
          ),
          if (timer.durationSeconds > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor:
                    isDark ? const Color(0xFF3D322A) : ThemeService.warmCream,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpired
                      ? Colors.green
                      : (isDark
                          ? ThemeService.warmOrange
                          : ThemeService.fieryRed),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _resetTimer(timer.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeService.warmGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('↺ Reset',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: ThemeService.warmGrey,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleTimer(timer.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: timer.isRunning
                        ? const LinearGradient(colors: [
                            ThemeService.deepRed,
                            ThemeService.fieryRed
                          ])
                        : const LinearGradient(colors: [
                            ThemeService.fieryRed,
                            ThemeService.warmOrange
                          ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(timer.isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(timer.isRunning ? 'Pause' : 'Start',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeTimer(timer.id),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Add Timer Dialog ──────────────────────────────────────────────

  void _showAddTimerDialog(bool isDark, int stepIndex) {
    final nameCtrl = TextEditingController();
    int minutes = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.timer, color: ThemeService.fieryRed),
              const SizedBox(width: 8),
              Text('New Timer',
                  style: GoogleFonts.luckiestGuy(
                      fontSize: 20, color: ThemeService.fieryRed)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Timer name (e.g. "Pasta", "Sauce")',
                  hintStyle: GoogleFonts.nunito(fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setDialogState(() {
                      if (minutes > 1) minutes--;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.softCoral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.remove, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$minutes min',
                        style: GoogleFonts.nunito(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: () => setDialogState(() => minutes++),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.softCoral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Seconds: ${minutes * 60}',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: ThemeService.warmGrey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: ThemeService.warmGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _addTimer(
                  nameCtrl.text.trim().isEmpty
                      ? 'Timer ${_timerIdCounter + 1}'
                      : nameCtrl.text.trim(),
                  minutes * 60,
                  stepIndex: stepIndex,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.fieryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add Timer',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timer Overview Bar ─────────────────────────────────────────────

  Widget _buildTimerBar(bool isDark) {
    final runningTimers = _timers
        .where((t) =>
            t.isRunning || (t.durationSeconds > 0 && t.elapsedSeconds > 0))
        .toList();
    if (runningTimers.isEmpty) return const SizedBox.shrink();

    // Sort: next-to-fire first
    runningTimers.sort((a, b) => a.remaining.compareTo(b.remaining));
    final next = runningTimers.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A221C) : ThemeService.pureWhite,
        border: Border(
          top: BorderSide(
              color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream),
          bottom: BorderSide(
              color: isDark ? const Color(0xFF3D322A) : ThemeService.warmCream),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ThemeService.goldenYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.timer,
                size: 16, color: ThemeService.goldenYellow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Next: ${next.label}',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF5EDE6)
                                : ThemeService.charcoal)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? ThemeService.warmOrange
                                : ThemeService.fieryRed)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(next.formatted,
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? ThemeService.warmOrange
                                  : ThemeService.fieryRed)),
                    ),
                  ],
                ),
                if (runningTimers.length > 1)
                  Text('+${runningTimers.length - 1} more running',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: ThemeService.warmGrey)),
              ],
            ),
          ),
          if (runningTimers.any((t) => t.isRunning))
            GestureDetector(
              onTap: () {
                // Pause all
                for (final t in _timers) t.isRunning = false;
                _stopGlobalTimerIfNeeded();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('All',
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.red)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Back
          if (_currentStep > 0)
            GestureDetector(
              onTap: _previousStep,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF3D322A) : ThemeService.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
            ),
          const Spacer(),
          // Next / Complete
          GestureDetector(
            onTap: _currentStep < _recipe!.steps.length - 1
                ? _nextStep
                : _completeCooking,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [ThemeService.fieryRed, ThemeService.warmOrange]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentStep < _recipe!.steps.length - 1
                        ? 'Next Step'
                        : '✨ Finish Up!',
                    style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < _recipe!.steps.length - 1
                        ? Icons.arrow_forward
                        : Icons.celebration,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(bool isDark) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: GestureDetector(
        onTap: () {}, // Prevent pass-through
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1410) : ThemeService.warmCream,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A221C)
                        : ThemeService.pureWhite,
                    border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF3D322A)
                              : ThemeService.warmCream),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              ThemeService.goldenYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                            child: Text('🤖', style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Sous-Chef',
                                style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                            Text('Ask me anything about the recipe',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: ThemeService.warmGrey)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showChat = false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3D322A)
                                : ThemeService.warmCream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: _chatMessages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('💬',
                                    style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 16),
                                Text('Ask me anything!',
                                    style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  '"Can I swap butter for oil?"\n"How do I know it\'s done?"\n"I burnt the garlic, now what?"',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: ThemeService.warmGrey,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final msg = _chatMessages[index];
                            final isUser = msg.role == 'user';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser) ...[
                                    const Text('🤖',
                                        style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? (isDark
                                                ? ThemeService.warmOrange
                                                    .withValues(alpha: 0.3)
                                                : ThemeService.fieryRed
                                                    .withValues(alpha: 0.1))
                                            : (isDark
                                                ? const Color(0xFF2A221C)
                                                : ThemeService.pureWhite),
                                        borderRadius:
                                            BorderRadius.circular(16).copyWith(
                                          bottomRight: isUser
                                              ? const Radius.circular(4)
                                              : Radius.circular(16),
                                          bottomLeft: !isUser
                                              ? const Radius.circular(4)
                                              : Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        msg.content,
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: isDark
                                              ? const Color(0xFFE0D6CC)
                                              : ThemeService.charcoal,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isUser) ...[
                                    const SizedBox(width: 8),
                                    const Text('🧑‍🍳',
                                        style: TextStyle(fontSize: 20)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A221C)
                        : ThemeService.pureWhite,
                    border: Border(
                      top: BorderSide(
                          color: isDark
                              ? const Color(0xFF3D322A)
                              : ThemeService.warmCream),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          decoration: InputDecoration(
                            hintText: 'Ask your sous-chef...',
                            hintStyle: GoogleFonts.nunito(fontSize: 14),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onSubmitted: (_) => _askAI(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isAsking ? null : _askAI,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              ThemeService.fieryRed,
                              ThemeService.warmOrange
                            ]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _isAsking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration(bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [ThemeService.fieryRed, ThemeService.deepRed]),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              Text(
                'Amazing Job, Chef!',
                style: GoogleFonts.luckiestGuy(
                    fontSize: 36, color: Colors.white, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'You crushed it! 🔥\nYour masterpiece is ready!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: ThemeService.goldenYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Back to Kitchen 🏆',
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ThemeService.charcoal),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A221C)
            : ThemeService.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Leave the Kitchen? 🍳',
            style: GoogleFonts.luckiestGuy(
                fontSize: 22, color: ThemeService.fieryRed)),
        content: Text('Your progress will be saved. Come back anytime!',
            style:
                GoogleFonts.nunito(fontSize: 15, color: ThemeService.warmGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep Cooking',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: ThemeService.goldenYellow)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _saveSession();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeService.fieryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Exit',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

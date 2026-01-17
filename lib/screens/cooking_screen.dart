import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/models/recipe.dart';
import 'package:sizzle_pan/models/cooking_session.dart';
import 'package:sizzle_pan/services/database_service.dart';
import 'package:sizzle_pan/services/ai_service.dart';

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
  String? _aiResponse;

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
    setState(() {
      _isLoading = true;
    });

    try {
      final recipe = await DatabaseService.getRecipeById(widget.recipeId);
      if (recipe != null) {
        final session = await DatabaseService.getActiveSession(widget.recipeId);
        
        setState(() {
          _recipe = recipe;
          _session = session;
          _currentStep = session?.currentStep ?? 0;
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

  Future<void> _startCooking() async {
    if (_recipe == null) return;

    try {
      final session = CookingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipeId: _recipe!.id,
        currentStep: 0,
        startedAt: DateTime.now(),
      );

      await DatabaseService.createCookingSession(session);
      
      setState(() {
        _session = session;
        _currentStep = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start cooking session')),
        );
      }
    }
  }

  Future<void> _nextStep() async {
    if (_recipe == null || _session == null) return;

    final nextStep = _currentStep + 1;
    
    if (nextStep >= _recipe!.steps.length) {
      await _completeCooking();
      return;
    }

    try {
      final updatedSession = _session!.copyWith(
        currentStep: nextStep,
      );
      
      await DatabaseService.updateCookingSession(updatedSession);
      
      setState(() {
        _session = updatedSession;
        _currentStep = nextStep;
        _aiResponse = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update step')),
        );
      }
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep <= 0 || _session == null) return;

    try {
      final updatedSession = _session!.copyWith(
        currentStep: _currentStep - 1,
      );
      
      await DatabaseService.updateCookingSession(updatedSession);
      
      setState(() {
        _session = updatedSession;
        _currentStep--;
        _aiResponse = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update step')),
        );
      }
    }
  }

  Future<void> _completeCooking() async {
    if (_session == null) return;

    try {
      await DatabaseService.completeCookingSession(_session!.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Cooking Complete!'),
            content: const Text('Great job! Your dish is ready to enjoy.'),
            actions: [
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Finish'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete cooking')),
        );
      }
    }
  }

  Future<void> _askAI() async {
    if (_recipe == null || _questionController.text.trim().isEmpty) return;

    final question = _questionController.text.trim();
    
    setState(() {
      _aiResponse = 'Thinking...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final response = AIService.getCookingAdvice(question, _recipe!, _currentStep);
    
    setState(() {
      _aiResponse = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cooking Mode'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Recipe not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_recipe!.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to cook?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${_recipe!.title} • ${_recipe!.cookingTime} minutes',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startCooking,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Cooking'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentStep + 1} of ${_recipe!.steps.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Cooking Mode?'),
                  content: const Text('Your progress will be saved.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _recipe!.steps.length,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${_currentStep + 1}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recipe!.steps[_currentStep],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_aiResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Assistant',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiResponse!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'Ask your AI assistant...',
                          prefixIcon: const Icon(Icons.help_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _askAI,
                      child: const Text('Ask'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentStep > 0 ? _previousStep : null,
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        child: Text(
                          _currentStep < _recipe!.steps.length - 1
                              ? 'Next Step'
                              : 'Complete',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
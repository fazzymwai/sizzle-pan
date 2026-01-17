import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sizzle Pan',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI cooking companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    FeatureCard(
                      title: 'What I Have',
                      subtitle: 'Generate recipes from ingredients',
                      icon: Icons.kitchen,
                      color: const Color(0xFF4CAF50),
                      onTap: () => context.go('/ingredients'),
                    ),
                    FeatureCard(
                      title: 'How I Feel',
                      subtitle: 'Recipes based on mood',
                      icon: Icons.mood,
                      color: const Color(0xFF9C27B0),
                      onTap: () => context.go('/mood'),
                    ),
                    FeatureCard(
                      title: 'Search Recipes',
                      subtitle: 'Find and remix recipes',
                      icon: Icons.search,
                      color: const Color(0xFF2196F3),
                      onTap: () => context.go('/search'),
                    ),
                    FeatureCard(
                      title: 'My Recipes',
                      subtitle: 'Saved favorites',
                      icon: Icons.favorite,
                      color: const Color(0xFFFF6B35),
                      onTap: () => context.go('/saved'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
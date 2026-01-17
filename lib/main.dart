import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/screens/home_screen.dart';
import 'package:sizzle_pan/screens/ingredient_generator_screen.dart';
import 'package:sizzle_pan/screens/mood_generator_screen.dart';
import 'package:sizzle_pan/screens/search_screen.dart';
import 'package:sizzle_pan/screens/cooking_screen.dart';
import 'package:sizzle_pan/screens/recipe_detail_screen.dart';
import 'package:sizzle_pan/screens/saved_recipes_screen.dart';
import 'package:sizzle_pan/services/theme_service.dart';

void main() {
  runApp(const SizzlePanApp());
}

class SizzlePanApp extends StatelessWidget {
  const SizzlePanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'Sizzle Pan',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/ingredients',
      builder: (context, state) => const IngredientGeneratorScreen(),
    ),
    GoRoute(
      path: '/mood',
      builder: (context, state) => const MoodGeneratorScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedRecipesScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) {
        final recipeId = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: recipeId);
      },
    ),
    GoRoute(
      path: '/cooking/:id',
      builder: (context, state) {
        final recipeId = state.pathParameters['id']!;
        return CookingScreen(recipeId: recipeId);
      },
    ),
  ],
);

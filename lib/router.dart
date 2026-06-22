import 'package:go_router/go_router.dart';
import 'package:sizzle_pan/screens/splash_screen.dart';
import 'package:sizzle_pan/screens/main_shell.dart';
import 'package:sizzle_pan/screens/home_screen.dart';
import 'package:sizzle_pan/screens/ingredient_generator_screen.dart';
import 'package:sizzle_pan/screens/mood_generator_screen.dart';
import 'package:sizzle_pan/screens/search_screen.dart';
import 'package:sizzle_pan/screens/saved_recipes_screen.dart';
import 'package:sizzle_pan/screens/recipe_detail_screen.dart';
import 'package:sizzle_pan/screens/cooking_screen.dart';
import 'package:sizzle_pan/screens/shopping_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedRecipesScreen(),
        ),
      ],
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
    GoRoute(
      path: '/shopping',
      builder: (context, state) => const ShoppingListScreen(),
    ),
  ],
);

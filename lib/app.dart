import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizzle_pan/router.dart';
import 'package:sizzle_pan/providers/recipe_provider.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class SizzlePanApp extends StatelessWidget {
  const SizzlePanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Sizzle Pan',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

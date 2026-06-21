import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // ─── Sizzle Pan Color Palette ───────────────────────────────────────
  static const Color fieryRed = Color(0xFFD94A3D);
  static const Color deepRed = Color(0xFFB7322A);
  static const Color goldenYellow = Color(0xFFF5A623);
  static const Color warmOrange = Color(0xFFFF7A3D);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color warmGrey = Color(0xFF8C8176);
  static const Color softCoral = Color(0xFFFFE8E0);
  static const Color darkBg = Color(0xFF1A1410);

  // Chef personality phrases
  static const List<String> chefGreetings = [
    "Hey there, hungry chef! 🔥",
    "Ready to sizzle? 🍳",
    "Let's get cooking! 👨‍🍳",
    "What're we making today? 🥘",
    "Fire up that pan! 🔥",
    "Your kitchen, your rules! 🎯",
    "Time to get saucy! 🌶️",
    "Let's make magic happen! ✨",
  ];

  static const List<String> chefTips = [
    "Pro tip: Let your pan get hot before adding oil! 🔥",
    "Remember: Mise en place is the way! 🥇",
    "Taste as you go — that's the secret! 👨‍🍳",
    "Low and slow for flavor that glows! 🐌",
    "A hot pan = a sizzling start! 🍳",
    "Season from high up for even coverage! 🧂",
    "Let meat rest before slicing — trust me! 🥩",
    "Sharp knife = safe cooking! ⚔️",
  ];

  static String randomChefGreeting() =>
      chefGreetings[DateTime.now().millisecondsSinceEpoch % chefGreetings.length];

  static String randomChefTip() =>
      chefTips[DateTime.now().millisecondsSinceEpoch % chefTips.length];

  // ─── Light Theme ────────────────────────────────────────────────────
  ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: fieryRed,
      onPrimary: pureWhite,
      secondary: goldenYellow,
      onSecondary: charcoal,
      tertiary: warmOrange,
      onTertiary: pureWhite,
      error: const Color(0xFFE53935),
      onError: pureWhite,
      surface: pureWhite,
      onSurface: charcoal,
      surfaceContainerHighest: warmCream,
      onSurfaceVariant: warmGrey,
      outline: warmGrey.withValues(alpha: 0.4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmCream,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: charcoal,
        displayColor: charcoal,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: charcoal,
        titleTextStyle: GoogleFonts.luckiestGuy(
          fontSize: 20,
          color: fieryRed,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: pureWhite,
        shadowColor: fieryRed.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: warmCream, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fieryRed,
          foregroundColor: pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: goldenYellow,
          foregroundColor: charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: warmGrey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: warmGrey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: fieryRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.nunito(
          color: warmGrey.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: warmGrey,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: warmCream,
        selectedColor: fieryRed,
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.nunito(fontSize: 13, color: pureWhite),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: warmGrey.withValues(alpha: 0.15),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: fieryRed,
        unselectedItemColor: warmGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────
  ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: warmOrange,
      onPrimary: charcoal,
      secondary: goldenYellow,
      onSecondary: charcoal,
      tertiary: fieryRed,
      onTertiary: pureWhite,
      error: const Color(0xFFEF5350),
      onError: charcoal,
      surface: darkBg,
      onSurface: const Color(0xFFF5EDE6),
      surfaceContainerHighest: const Color(0xFF2A221C),
      onSurfaceVariant: const Color(0xFFB0A79E),
      outline: const Color(0xFFB0A79E).withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.nunitoTextTheme(TextTheme(
        displayLarge: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        displayMedium: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        displaySmall: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        headlineLarge: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        headlineMedium: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        headlineSmall: GoogleFonts.luckiestGuy(color: const Color(0xFFF5EDE6)),
        titleLarge: GoogleFonts.nunito(color: const Color(0xFFF5EDE6), fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.nunito(color: const Color(0xFFF5EDE6), fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.nunito(color: const Color(0xFFF5EDE6), fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.nunito(color: const Color(0xFFE0D6CC)),
        bodyMedium: GoogleFonts.nunito(color: const Color(0xFFE0D6CC)),
        bodySmall: GoogleFonts.nunito(color: const Color(0xFFB0A79E)),
        labelLarge: GoogleFonts.nunito(color: const Color(0xFFF5EDE6), fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.nunito(color: const Color(0xFFB0A79E)),
        labelSmall: GoogleFonts.nunito(color: const Color(0xFFB0A79E)),
      )).apply(
        bodyColor: const Color(0xFFE0D6CC),
        displayColor: const Color(0xFFF5EDE6),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFE0D6CC),
        titleTextStyle: GoogleFonts.luckiestGuy(
          fontSize: 20,
          color: warmOrange,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2A221C),
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF3D322A), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmOrange,
          foregroundColor: charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: goldenYellow,
          foregroundColor: charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A221C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFB0A79E).withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFB0A79E).withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: warmOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.nunito(
          color: const Color(0xFFB0A79E).withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIconColor: const Color(0xFFB0A79E),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3D322A),
        selectedColor: warmOrange,
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.nunito(fontSize: 13, color: charcoal),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D322A),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A221C),
        selectedItemColor: warmOrange,
        unselectedItemColor: Color(0xFFB0A79E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

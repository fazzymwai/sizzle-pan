import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [ThemeService.darkBg, const Color(0xFF2A221C)]
                  : [ThemeService.warmCream, ThemeService.pureWhite],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated logo
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                ThemeService.warmOrange,
                                ThemeService.goldenYellow
                              ]
                            : [ThemeService.fieryRed, ThemeService.warmOrange],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? ThemeService.warmOrange
                                  : ThemeService.fieryRed)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🍳', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _fadeAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'SIZZLE PAN',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 40,
                          color: isDark
                              ? ThemeService.warmOrange
                              : ThemeService.fieryRed,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your sassy AI kitchen sidekick',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: ThemeService.warmGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Loading indicator
                AnimatedBuilder(
                  animation: _fadeAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? ThemeService.goldenYellow
                                : ThemeService.fieryRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preparing the kitchen... 🔥',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: ThemeService.warmGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

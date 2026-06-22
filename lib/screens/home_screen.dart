import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizzle_pan/widgets/feature_card.dart';
import 'package:sizzle_pan/services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sizzleController;
  late Animation<double> _sizzleAnimation;

  @override
  void initState() {
    super.initState();
    _sizzleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _sizzleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _sizzleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sizzleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = ThemeService.randomChefGreeting();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _SizzlePatternPainter(isDark: isDark),
              ),
            ),
            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Header row
                  Row(
                    children: [
                      // Branding
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _sizzleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _sizzleAnimation.value,
                                    child: const Text('🍳',
                                        style: TextStyle(fontSize: 28)),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'SIZZLE PAN',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 28,
                                  color: isDark
                                      ? ThemeService.warmOrange
                                      : ThemeService.fieryRed,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Your sassy AI kitchen sidekick',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: ThemeService.warmGrey,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Theme toggle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3D322A)
                              : ThemeService.pureWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3D322A)
                                : ThemeService.warmCream,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            final themeService = context.read<ThemeService>();
                            themeService.toggleTheme();
                          },
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            size: 20,
                            color: isDark
                                ? ThemeService.goldenYellow
                                : ThemeService.warmGrey,
                          ),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Chef greeting card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                ThemeService.warmOrange.withValues(alpha: 0.15),
                                ThemeService.goldenYellow
                                    .withValues(alpha: 0.05),
                              ]
                            : [
                                ThemeService.fieryRed.withValues(alpha: 0.08),
                                ThemeService.goldenYellow
                                    .withValues(alpha: 0.04),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? ThemeService.warmOrange.withValues(alpha: 0.2)
                            : ThemeService.fieryRed.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Chef emoji
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? ThemeService.warmOrange.withValues(alpha: 0.2)
                                : ThemeService.fieryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child:
                                Text('👨‍🍳', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
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
                                "What's cooking today?",
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
                  const SizedBox(height: 24),
                  // Feature grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      FeatureCard(
                        title: 'What I Have',
                        subtitle: 'Recipes from your ingredients',
                        icon: Icons.kitchen_outlined,
                        color: const Color(0xFF4CAF50),
                        onTap: () => context.push('/ingredients'),
                      ),
                      FeatureCard(
                        title: 'How I Feel',
                        subtitle: 'Cook according to your mood',
                        icon: Icons.mood_outlined,
                        color: const Color(0xFF9C27B0),
                        onTap: () => context.push('/mood'),
                      ),
                      FeatureCard(
                        title: 'Shopping List',
                        subtitle: 'What you need to buy',
                        icon: Icons.shopping_cart_outlined,
                        color: const Color(0xFF4CAF50),
                        onTap: () => context.push('/shopping'),
                      ),
                      FeatureCard(
                        title: 'My Recipes',
                        subtitle: 'Your saved collection',
                        icon: Icons.favorite_outline,
                        color: ThemeService.fieryRed,
                        onTap: () => context.go('/saved'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chef tip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A221C)
                          : ThemeService.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3D322A)
                            : ThemeService.warmCream,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ThemeService.goldenYellow
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('💡', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ThemeService.randomChefTip(),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFB0A79E)
                                  : ThemeService.warmGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Background pattern painter
class _SizzlePatternPainter extends CustomPainter {
  final bool isDark;

  _SizzlePatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? ThemeService.warmOrange : ThemeService.fieryRed)
          .withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Draw subtle diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }

    // Draw small circles as subtle texture
    final dotPaint = Paint()
      ..color = (isDark ? ThemeService.goldenYellow : ThemeService.fieryRed)
          .withValues(alpha: 0.04);

    for (int i = 0; i < 20; i++) {
      final x = (i * 137.5 + 50) % size.width;
      final y = (i * 89.3 + 30) % size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

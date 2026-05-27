import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'dashboard_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _completeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final logoColor = isDark ? Colors.white : Colors.black87;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isCompact = width < 440 || height < 700;
          final isVeryCompact = height < 600;
          final horizontalPadding = Responsive.horizontalPadding(context);
          
          final titleFont = isVeryCompact ? 24.0 : (isCompact ? 28.0 : 34.0);
          final accentFont = isVeryCompact ? 20.0 : (isCompact ? 24.0 : 30.0);
          final bodyFont = isVeryCompact ? 13.0 : (isCompact ? 14.0 : 16.0);
          final animationHeight = isVeryCompact ? 140.0 : (isCompact ? 180.0 : 240.0);
          final topCircleSize = isVeryCompact ? 140.0 : (isCompact ? 200.0 : 280.0);
          final bottomCircleSize = isVeryCompact ? 120.0 : (isCompact ? 160.0 : 240.0);
          final buttonHeight = isVeryCompact ? 46.0 : (isCompact ? 52.0 : 60.0);

          return Stack(
            children: [
              Positioned(
                top: -topCircleSize * 0.5,
                right: -topCircleSize * 0.3,
                child: Container(
                  width: topCircleSize,
                  height: topCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -bottomCircleSize * 0.5,
                left: -bottomCircleSize * 0.4,
                child: Container(
                  width: bottomCircleSize,
                  height: bottomCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isVeryCompact ? 8 : (isCompact ? 12 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo compacto
                      Padding(
                        padding: EdgeInsets.only(
                          top: isVeryCompact ? 8 : (isCompact ? 12 : 16),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isVeryCompact ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentColor.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.psychology,
                                  color: AppTheme.accentColor,
                                  size: isVeryCompact ? 22 : 26,
                                ),
                              ),
                              SizedBox(width: isVeryCompact ? 8 : 12),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    logoColor,
                                    logoColor.withOpacity(0.8),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'PsicoLearn',
                                  style: TextStyle(
                                    color: logoColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: isVeryCompact ? 22 : (isCompact ? 26 : 28),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isVeryCompact ? 10 : (isCompact ? 14 : 18)),

                      // Título principal
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVeryCompact ? 12 : (isCompact ? 14 : 20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'CUMPLE EL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: titleFont,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              'PERFIL DESEADO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: accentFont,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isVeryCompact ? 10 : (isCompact ? 12 : 16)),

                      // Descripción
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVeryCompact ? 12 : (isCompact ? 16 : 28),
                        ),
                        child: Text(
                          'Evaluación psicométrica integral diseñada para potenciar tu desarrollo profesional y personal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: bodyFont,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),

                      SizedBox(height: isVeryCompact ? 14 : (isCompact ? 18 : 24)),

                      // Animación
                      SizedBox(
                        height: animationHeight,
                        child: Lottie.asset(
                          'assets/animations/meditating_brain.json',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) {
                            return const LevitatingIcon();
                          },
                        ),
                      ),

                      SizedBox(height: isVeryCompact ? 12 : (isCompact ? 16 : 20)),

                      // Botón de acción
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVeryCompact ? 12 : (isCompact ? 16 : 24),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isVeryCompact ? 14 : 20,
                                vertical: 0,
                              ),
                            ),
                            onPressed: () => _completeWelcome(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'COMENZAR AHORA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    fontSize: isVeryCompact ? 13 : (isCompact ? 14 : 15),
                                  ),
                                ),
                                SizedBox(width: isVeryCompact ? 8 : 10),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: isVeryCompact ? 18 : 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isVeryCompact ? 12 : (isCompact ? 16 : 28)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Fallback levitating triangle
class LevitatingIcon extends StatefulWidget {
  const LevitatingIcon({super.key});

  @override
  State<LevitatingIcon> createState() => _LevitatingIconState();
}

class _LevitatingIconState extends State<LevitatingIcon> {
  double _target = 10.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -10, end: _target),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      onEnd: () => setState(() => _target = _target == 10 ? -10 : 10),
      builder: (context, v, child) =>
          Transform.translate(offset: Offset(0, v), child: child),
      child: Icon(
        Icons.psychology,
        size: 120,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

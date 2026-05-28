import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/features/home/presentation/dashboard_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with TickerProviderStateMixin {
  final SecurityService _security = sl<SecurityService>();
  bool _isChecking = false;

  // Animaciones de fondo tipo Aurora
  late AnimationController _auroraController;
  late Animation<double> _auroraAnimation;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    _auroraAnimation = CurvedAnimation(
      parent: _auroraController,
      curve: Curves.easeInOutSine,
    );

    _checkInitialAuth();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialAuth() async {
    if (_security.currentUser != null) {
      final isActive = await _security.checkActivation();
      if (isActive && mounted) {
        _navigateToDashboard();
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const DashboardScreen(),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isChecking = true);
    HapticFeedback.mediumImpact();

    try {
      final user = await _security.signInWithGoogle();
      if (user == null) {
        setState(() => _isChecking = false);
        return;
      }

      final isActive = await _security.checkActivation();
      
      if (isActive && mounted) {
        HapticFeedback.heavyImpact();
        _navigateToDashboard();
      } else if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar('Acceso restringido. Tu cuenta está en revisión por el administrador.');
        setState(() => _isChecking = false);
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      _showErrorSnackBar('Error al conectar con Google. Reintenta.');
      setState(() => _isChecking = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _contactAdmin() async {
    final Uri url = Uri.parse('https://wa.me/51930267232?text=Hola,%20solicito%20activación%20para%20PsicoLearn');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('No se pudo abrir el enlace de soporte.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF131314),
      body: Stack(
        children: [
          // ── AURORA BACKGROUND BLOCKS ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auroraAnimation,
              builder: (context, _) {
                final val = _auroraAnimation.value;
                return Stack(
                  children: [
                    // Blob 1: Cyan/Azul (Superior Izquierda)
                    Positioned(
                      top: -150 + (val * 80),
                      left: -150 + (val * 120),
                      child: _AuroraBlob(
                        size: isDesktop ? 600 : 400,
                        color: const Color(0xFF00E5FF),
                        opacity: 0.15,
                      ),
                    ),
                    // Blob 2: Morado (Centro Derecha)
                    Positioned(
                      top: 100 - (val * 60),
                      right: -100 - (val * 80),
                      child: _AuroraBlob(
                        size: isDesktop ? 700 : 450,
                        color: const Color(0xFF9B72CB),
                        opacity: 0.18,
                      ),
                    ),
                    // Blob 3: Rosa/Azul (Inferior Izquierda)
                    Positioned(
                      bottom: -200 + (val * 100),
                      left: 50 - (val * 50),
                      child: _AuroraBlob(
                        size: isDesktop ? 550 : 350,
                        color: const Color(0xFFD96570),
                        opacity: 0.12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── MAIN CONTENT ──
          SafeArea(
            child: Column(
              children: [
                // Floating Navbar
                _buildNavbar(),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: _buildHeroSection(true)),
                                  const SizedBox(width: 60),
                                  Expanded(child: _buildRightSideContent(true)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildHeroSection(false),
                                  const SizedBox(height: 48),
                                  _buildRightSideContent(false),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F20).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF9B72CB), Color(0xFFD96570), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PsicoLearn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _contactAdmin,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC4C7C5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Soporte', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F20).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF4285F4), size: 16),
              const SizedBox(width: 8),
              Text(
                'SISTEMA DE PREPARACIÓN PNP',
                style: TextStyle(
                  color: Color(0xFFC4C7C5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Title H1
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF9B72CB), Color(0xFFD96570), Color(0xFF00E5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Entrenamiento Psicológico Inteligente',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 48 : 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Subtitle
        Text(
          'Desarrolla el perfil psicológico y capacidad cognitiva requeridos para tu ingreso a la PNP con retroalimentación en tiempo real y simulación de exámenes.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC4C7C5),
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 36),
        // CTA Button
        _buildGoogleSignInButton(),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isChecking ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF131314),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: _isChecking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF131314)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/google_logo.svg',
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'INICIAR CON GOOGLE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRightSideContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          const Text(
            'CARACTERÍSTICAS DEL SISTEMA',
            style: TextStyle(
              color: Color(0xFF9B72CB),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Grid Bento Box
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.3 : 2.0,
          ),
          children: const [
            _BentoCard(
              title: 'Misión Diaria',
              description: 'Resuelve 50 preguntas personalizadas cada día para mantener tu racha.',
              icon: Icons.bolt_rounded,
              gradientColors: [Color(0xFF00E5FF), Color(0xFF4285F4)],
            ),
            _BentoCard(
              title: 'Psicotécnico',
              description: 'Ejercicios interactivos de figuras y razonamiento espacial.',
              icon: Icons.extension_rounded,
              gradientColors: [Color(0xFF9B72CB), Color(0xFFD96570)],
            ),
            _BentoCard(
              title: 'Simulacros Reales',
              description: 'Exámenes completos contrarreloj con la estructura exacta PNP.',
              icon: Icons.timer_rounded,
              gradientColors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
            ),
            _BentoCard(
              title: 'La Escuelita',
              description: 'Retroalimentación y repaso enfocado únicamente en tus errores.',
              icon: Icons.school_rounded,
              gradientColors: [Color(0xFFD96570), Color(0xFF00E5FF)],
            ),
          ],
        ),
      ],
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _AuroraBlob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _BentoCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _BentoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F20).withOpacity(_isHovered ? 0.6 : 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? widget.gradientColors.first.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.gradientColors.first.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.gradientColors.first.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.gradientColors.first,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: Color(0xFFC4C7C5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

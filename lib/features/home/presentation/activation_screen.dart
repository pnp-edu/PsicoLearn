import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/features/home/presentation/dashboard_screen.dart';
import 'package:psicolearn/features/home/presentation/widgets/web_helper.dart'
    if (dart.library.html) 'package:psicolearn/features/home/presentation/widgets/web_helper_web.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with TickerProviderStateMixin {
  final SecurityService _security = sl<SecurityService>();
  bool _isChecking = false;

  // Animaciones de fondo tipo Aurora (Drift circular continuo)
  late AnimationController _auroraController;
  late Animation<double> _auroraAnimation;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WebHelper.registerViewFactory('login-html', 'psicolearn_gemini_redesign.html');
      WebHelper.setupMessageListener(
        onGoogleSignIn: _handleGoogleSignIn,
        onViewDemo: _showDemoDialog,
        onSupport: _contactAdmin,
      );
    }
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    
    _auroraAnimation = CurvedAnimation(
      parent: _auroraController,
      curve: Curves.linear,
    );

    _checkInitialAuth();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WebHelper.disposeMessageListener();
    }
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
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, fontFamily: 'Google Sans'))),
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
    final Uri url = Uri.parse('https://wa.me/51955285763?text=Hola,%20solicito%20activación%20para%20PsicoLearn');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('No se pudo abrir el enlace de soporte.');
    }
  }

  void _showDemoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: const Color(0xFF0C101B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Color(0xFF4285F4),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'PsicoLearn Demo',
                              style: TextStyle(
                                fontFamily: 'Google Sans Display',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFBDC1C6)),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Bienvenido a la preparación inteligente!',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE8EAED),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Estás viendo la demo estática del sistema. Para acceder al entrenamiento completo de la red de preparación táctica PNP, por favor inicia sesión:',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF9AA0A6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDemoFeatureItem('⚡', 'Misión Diaria', 'Ejercicios focalizados para mantener el hábito de estudio diario.'),
                    _buildDemoFeatureItem('🧩', 'Psicotécnico Avanzado', 'Razonamiento lógico-matemático y espacial con simulador.'),
                    _buildDemoFeatureItem('🎯', 'Simulacros Oficiales', 'Exámenes con tiempo cronometrado bajo el formato real de la PNP.'),
                    _buildDemoFeatureItem('🎓', 'La Escuelita Táctica', 'Repaso inteligente basado en tus errores y debilidades de estudio.'),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFBDC1C6),
                            textStyle: const TextStyle(fontFamily: 'Google Sans'),
                          ),
                          child: const Text('Cerrar'),
                        ),
                        const SizedBox(width: 12),
                        _GoogleSignInButton(
                          isLoading: _isChecking,
                          onTap: () {
                            Navigator.of(context).pop();
                            _handleGoogleSignIn();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8EAED),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF9AA0A6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        backgroundColor: Color(0xFF060A14),
        body: HtmlElementView(viewType: 'login-html'),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: Stack(
        children: [
          // ── AURORA NEURAL BACKGROUND ──
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _auroraAnimation,
                    builder: (context, _) {
                      final val = _auroraAnimation.value;
                      return Stack(
                        children: [
                          // Blob 1 (Blue)
                          Positioned(
                            top: -100,
                            left: -100,
                            child: _AuroraBlob(
                              width: 500,
                              height: 400,
                              color: const Color(0xFF4285F4),
                              opacity: 0.22,
                              animationValue: val,
                              phaseShift: 0.0,
                            ),
                          ),
                          // Blob 2 (Purple)
                          Positioned(
                            top: 50,
                            right: -50,
                            child: _AuroraBlob(
                              width: 400,
                              height: 500,
                              color: const Color(0xFF8A2BE2),
                              opacity: 0.18,
                              animationValue: val,
                              phaseShift: -2.0 * math.pi * 4.0 / 12.0, // delay -4s
                            ),
                          ),
                          // Blob 3 (Red)
                          Positioned(
                            bottom: 0,
                            left: screenWidth * 0.3,
                            child: _AuroraBlob(
                              width: 350,
                              height: 300,
                              color: const Color(0xFFEA4335),
                              opacity: 0.12,
                              animationValue: val,
                              phaseShift: -2.0 * math.pi * 8.0 / 12.0, // delay -8s
                            ),
                          ),
                          // Blob 4 (Green)
                          Positioned(
                            bottom: 50,
                            right: screenWidth * 0.2,
                            child: _AuroraBlob(
                              width: 300,
                              height: 350,
                              color: const Color(0xFF34A853),
                              opacity: 0.14,
                              animationValue: val,
                              phaseShift: -2.0 * math.pi * 2.0 / 12.0, // delay -2s
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── NEURAL GRID OVERLAY ──
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NeuralGridPainter(),
              ),
            ),
          ),

          // ── MAIN CONTENT ──
          SafeArea(
            child: Column(
              children: [
                // Custom Navbar
                _buildNavbar(),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 20,
                        vertical: isDesktop ? 40 : 24,
                      ),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 1.0),
        ),
      ),
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
                    colors: [Color(0xFF4285F4), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🧠',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PsicoLearn',
                style: TextStyle(
                  fontFamily: 'Google Sans Display',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8EAED),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          _HoverNavPill(
            text: 'Soporte',
            onTap: _contactAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _buildChip(),
        const SizedBox(height: 28),
        _buildTitle(isDesktop),
        const SizedBox(height: 20),
        _buildDescription(isDesktop),
        const SizedBox(height: 36),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _GoogleSignInButton(
              isLoading: _isChecking,
              onTap: _handleGoogleSignIn,
            ),
            _GhostButton(
              text: 'Ver demo',
              onTap: _showDemoDialog,
            ),
          ],
        ),
        _buildStatsBar(isDesktop),
      ],
    );
  }

  Widget _buildChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.35), width: 1.0),
        color: const Color(0xFF4285F4).withOpacity(0.08),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          SizedBox(width: 7),
          Text(
            'SISTEMA DE PREPARACIÓN PNP',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: Color(0xFF8AB4F8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDesktop) {
    final double fontSize = isDesktop ? 44.0 : 32.0;
    final fontStyle = TextStyle(
      fontFamily: 'Google Sans Display',
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: -1.0,
      height: 1.15,
    );

    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF8AB4F8), Color(0xFFC58AF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Offset.zero & bounds.size),
          child: Text(
            'Entrenamiento',
            style: fontStyle.copyWith(color: Colors.white),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFEA4335), Color(0xFFFBBC04), Color(0xFF34A853), Color(0xFF4285F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Offset.zero & bounds.size),
          child: Text(
            'Psicológico',
            style: fontStyle.copyWith(color: Colors.white),
          ),
        ),
        Text(
          'Inteligente',
          style: fontStyle.copyWith(color: const Color(0xFFE8EAED)),
        ),
      ],
    );
  }

  Widget _buildDescription(bool isDesktop) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: RichText(
        textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: Color(0xFF9AA0A6),
            height: 1.7,
          ),
          children: [
            TextSpan(
              text: 'Desarrolla el perfil psicológico y capacidad cognitiva requeridos para tu ingreso a la PNP con ',
            ),
            TextSpan(
              text: 'retroalimentación en tiempo real',
              style: TextStyle(
                color: Color(0xFFC4C7CC),
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: ' y simulación de exámenes.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDesktop) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.only(top: 28),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x12FFFFFF), width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
        children: [
          _buildStatItem('50+', 'PREGUNTAS DIARIAS'),
          _buildStatItem('98%', 'TASA DE APROBACIÓN'),
          _buildStatItem('12k', 'POSTULANTES ACTIVOS'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE8EAED), Color(0xFF9AA0A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Offset.zero & bounds.size),
          child: Text(
            number,
            style: const TextStyle(
              fontFamily: 'Google Sans Display',
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 11,
            color: Color(0xFF5F6368),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildRightSideContent(bool isDesktop) {
    const cards = [
      _BentoCardRedesign(
        title: 'Misión Diaria',
        description: 'Resuelve 50 preguntas personalizadas cada día para mantener tu racha.',
        icon: '⚡',
        glowColor: Color(0x264285F4),
        lineColor: Color(0xFF4285F4),
        iconBgColor: Color(0x264285F4),
        iconTextColor: Color(0xFF8AB4F8),
        iconBorderColor: Color(0x404285F4),
      ),
      _BentoCardRedesign(
        title: 'Psicotécnico',
        description: 'Ejercicios interactivos de figuras y razonamiento espacial.',
        icon: '🧩',
        glowColor: Color(0x268A2BE2),
        lineColor: Color(0xFF9B59B6),
        iconBgColor: Color(0x268A2BE2),
        iconTextColor: Color(0xFFC58AF9),
        iconBorderColor: Color(0x408A2BE2),
      ),
      _BentoCardRedesign(
        title: 'Simulacros Reales',
        description: 'Exámenes completos contrarreloj con la estructura exacta PNP.',
        icon: '🎯',
        glowColor: Color(0x2634A853),
        lineColor: Color(0xFF34A853),
        iconBgColor: Color(0x2634A853),
        iconTextColor: Color(0xFF81C995),
        iconBorderColor: Color(0x4034A853),
      ),
      _BentoCardRedesign(
        title: 'La Escuelita',
        description: 'Retroalimentación y repaso enfocado únicamente en tus errores.',
        icon: '🎓',
        glowColor: Color(0x1FEA4335),
        lineColor: Color(0xFFEA4335),
        iconBgColor: Color(0x1FEA4335),
        iconTextColor: Color(0xFFF28B82),
        iconBorderColor: Color(0x33EA4335),
      ),
    ];

    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        Container(
          alignment: isDesktop ? Alignment.centerRight : Alignment.center,
          margin: const EdgeInsets.only(bottom: 20),
          child: const Text(
            'CARACTERÍSTICAS DEL SISTEMA',
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
              color: Color(0xFF5F6368),
            ),
          ),
        ),
        isDesktop
            ? GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                children: cards,
              )
            : Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                  const SizedBox(height: 12),
                  cards[2],
                  const SizedBox(height: 12),
                  cards[3],
                ],
              ),
      ],
    );
  }
}

// ── CUSTOM COMPONENTS ──

class NeuralGridPainter extends CustomPainter {
  const NeuralGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(0.04)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeuralGridPainter oldDelegate) => false;
}

class _AuroraBlob extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double opacity;
  final double animationValue;
  final double phaseShift;

  const _AuroraBlob({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
    required this.animationValue,
    required this.phaseShift,
  });

  @override
  Widget build(BuildContext context) {
    final double theta = 2.0 * math.pi * animationValue + phaseShift;
    
    // Drifting physics
    final double dx = 20.0 * math.sin(theta) + 10.0 * math.cos(2 * theta);
    final double dy = -15.0 * math.cos(theta) + 5.0 * math.sin(2 * theta);
    
    // Scaling physics
    final double scale = 1.0 + 0.04 * math.sin(theta + math.pi / 4);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.elliptical(width / 2, height / 2),
            ),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.7,
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: 0.9 + 0.1 * _animation.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverNavPill extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _HoverNavPill({required this.text, required this.onTap});

  @override
  State<_HoverNavPill> createState() => _HoverNavPillState();
}

class _HoverNavPillState extends State<_HoverNavPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
            color: Colors.white.withOpacity(_isHovered ? 0.08 : 0.04),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: _isHovered ? const Color(0xFFE8EAED) : const Color(0xFF9AA0A6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.isLoading, required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF3367D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                ),
            boxShadow: _isHovered && !widget.isLoading
                ? [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          transform: Matrix4.translationValues(0.0, _isHovered && !widget.isLoading ? -1.0 : 0.0, 0.0),
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/google_logo.svg',
                      height: 18,
                      width: 18,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Iniciar con Google',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _GhostButton({required this.text, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.15),
              width: 1.0,
            ),
            color: Colors.white.withOpacity(_isHovered ? 0.04 : 0.0),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: _isHovered ? const Color(0xFFE8EAED) : const Color(0xFFBDC1C6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoCardRedesign extends StatefulWidget {
  final String title;
  final String description;
  final String icon;
  final Color glowColor;
  final Color lineColor;
  final Color iconBgColor;
  final Color iconTextColor;
  final Color iconBorderColor;

  const _BentoCardRedesign({
    required this.title,
    required this.description,
    required this.icon,
    required this.glowColor,
    required this.lineColor,
    required this.iconBgColor,
    required this.iconTextColor,
    required this.iconBorderColor,
  });

  @override
  State<_BentoCardRedesign> createState() => _BentoCardRedesignState();
}

class _BentoCardRedesignState extends State<_BentoCardRedesign> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.white.withOpacity(_isHovered ? 0.05 : 0.03),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.6, -0.6),
                        radius: 0.8,
                        colors: [
                          widget.glowColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.iconBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: widget.iconBorderColor, width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.icon,
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.iconTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE8EAED),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF9AA0A6),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isHovered ? 1.0 : 0.0,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            widget.lineColor,
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/features/home/presentation/dashboard_screen.dart';
import '../../../core/widgets/laboratory_background.dart';


class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with TickerProviderStateMixin {
  final SecurityService _security = sl<SecurityService>();
  bool _isChecking = false;
  
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    if (_security.currentUser != null) {
      // Si ya hay sesión de Firebase, intentamos verificar activación automáticamente
      final isActive = await _security.checkActivation();
      if (isActive && mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const DashboardScreen(),
            transitionsBuilder: (context, anim1, anim2, child) => 
                FadeTransition(opacity: anim1, child: child),
          ),
        );
      }
    }
  }

  void _initAnimations() {
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }


  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
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

      // Una vez logueado con Google, verificamos activación en Firestore
      final isActive = await _security.checkActivation();
      
      if (isActive && mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const DashboardScreen(),
            transitionsBuilder: (context, anim1, anim2, child) => 
                FadeTransition(opacity: anim1, child: child),
          ),
        );
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

  void _continueInFreeMode() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const DashboardScreen(),
        transitionsBuilder: (context, anim1, anim2, child) => 
            FadeTransition(opacity: anim1, child: child),
      ),
    );
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



  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      resizeToAvoidBottomInset: false, // Evita que la imagen se mueva al abrir el teclado
      body: SizedBox.expand(
        child: Stack(
          children: [
            // GRID DE LABORATORIO (NUEVO)
            const Positioned.fill(child: LaboratoryBackground()),
            
            // IMAGEN DE FONDO

            Positioned.fill(
              child: Image.asset(
                'assets/portada-pnp.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            // OVERLAY GRADIENTE
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      const Color(0xFF0A0E12).withOpacity(0.6),
                      const Color(0xFF0A0E12).withOpacity(0.9),
                      const Color(0xFF0A0E12),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TÍTULO EN LA PARTE SUPERIOR
                  _buildCompactHeader(isSmallScreen),
                  
                  // ESPACIO VACÍO EN EL MEDIO (Para ver el arco)
                  const Spacer(),
                  
                  // CARD DE BIENVENIDA SUBIDA UN POCO
                  Column(
                    children: [
                      _buildCompactActivationCard(isSmallScreen),
                      const SizedBox(height: 80), // Empuja la card hacia arriba
                      _buildCompactFooter(),
                      const SizedBox(height: 20), // Margen final
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCompactHeader(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 40 : 50,
          height: isSmallScreen ? 40 : 50,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.security_rounded,
            color: AppTheme.accentColor,
            size: isSmallScreen ? 18 : 24,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'PSICOLEARN',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 22 : 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          'Acceso Seguro al Sistema',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActivationCard(bool isSmallScreen) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BIENVENIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión con tu cuenta de Google\npara acceder al sistema táctico.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),
              _buildGoogleSignInButton(isSmallScreen),
              const SizedBox(height: 16),
              _buildFreeModeButton(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeModeButton(bool isSmallScreen) {
    return TextButton(
      onPressed: _isChecking ? null : _continueInFreeMode,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text(
        'CONTINUAR EN MODO GRATUITO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }


  Widget _buildEmailInput() {
    return const SizedBox.shrink(); // Ya no se usa
  }

  Widget _buildGoogleSignInButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 54,
      child: OutlinedButton(
        onPressed: _isChecking ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.accentColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.black.withOpacity(0.2),
        ),
        child: _isChecking
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/google_logo.svg',
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'INICIAR CON GOOGLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isSmallScreen) {
    // Ya no lo usamos directamente, pero lo dejamos por si quieres un botón de "Reintentar"
    return const SizedBox.shrink();
  }


  Widget _buildCompactFooter() {
    return Opacity(
      opacity: 0.3,
      child: Column(
        children: [
          const Text(
            'PSICOLEARN PNP • 2026',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/notification_service.dart';
import 'package:psicolearn/features/home/presentation/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/features/home/presentation/activation_screen.dart';
import 'package:psicolearn/core/widgets/laboratory_background.dart';

void main() {
  // 1. Asegurar enlace con el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Lanzar la app inmediatamente (evita pantalla negra del sistema)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PsicoLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Container(
          color: Colors.black87, // Fondo oscuro para pantallas grandes
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
      // Iniciamos con el SplashScreen táctico
      home: const TacticalSplashScreen(),
    );
  }
}

class TacticalSplashScreen extends StatefulWidget {
  const TacticalSplashScreen({super.key});

  @override
  State<TacticalSplashScreen> createState() => _TacticalSplashScreenState();
}

class _TacticalSplashScreenState extends State<TacticalSplashScreen> {
  double _progress = 0.0;
  String _status = 'INICIALIZANDO SISTEMAS...';

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    try {
      // Fase 1: Firebase
      setState(() { _status = 'CONECTANDO A LA RED TÁCTICA...'; _progress = 0.3; });
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('ℹ️ Sistema: Firebase operando en modo local.');
      }

      // Fase 2: Localizador de Servicios
      setState(() { _status = 'CONFIGURANDO NÚCLEO...'; _progress = 0.6; });
      await initServiceLocator().timeout(const Duration(seconds: 10));

      // Fase 3: Seguridad y Activación
      setState(() { _status = 'VERIFICANDO CREDENCIALES...'; _progress = 0.8; });
      final security = sl<SecurityService>();
      final isActivated = await security.checkActivation().timeout(
        const Duration(seconds: 7),
        onTimeout: () => true, // Fallback offline
      );

      // Fase 4: Notificaciones
      _initNotificationsQuietly();

      setState(() { _status = 'ACCESO CONCEDIDO'; _progress = 1.0; });
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navegación final
      if (!isActivated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActivationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error en arranque: $e');
      if (mounted) {
        // En caso de error crítico, intentamos ir al Dashboard (o login)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  Future<void> _initNotificationsQuietly() async {
    try {
      final notify = sl<NotificationService>();
      await notify.init();
    } catch (e) {
      debugPrint('⚠️ Notificaciones: Fallo en carga silenciosa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      body: LaboratoryBackground(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 30.0 : 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o Icono Táctico compacto
                Container(
                  width: isSmallScreen ? 60 : 80,
                  height: isSmallScreen ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_outlined, 
                    color: AppTheme.accentColor, 
                    size: isSmallScreen ? 30 : 40
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),
                // Barra de progreso personalizada
                SizedBox(
                  width: isSmallScreen ? 180 : 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      minHeight: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
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

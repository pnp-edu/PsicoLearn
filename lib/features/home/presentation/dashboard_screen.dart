import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psicolearn/core/utils/responsive.dart';
import '../../../core/services/app_date_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/di/service_locator.dart';
import '../../personality_test/presentation/test_screen.dart';
import '../../personality_test/domain/controllers/test_controller.dart';
import '../../spatial_test/presentation/spatial_test_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../../interview/presentation/interview_screen.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/daily_mission_card.dart';
import 'widgets/action_card_carousel.dart';
import '../../home/presentation/activation_screen.dart';
import '../../../core/services/security_service.dart';
import 'admin_panel_screen.dart';
import '../../../core/widgets/laboratory_background.dart';
import '../../exam/presentation/exam_simulation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_dashboard_layout.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _todayCompleted = false;
  String _diagnosis = '...';
  int _failedCount = 0;
  int _questionsAnswered = 0;
  int _totalQuestionsInDaily = 50;
  String _weakestDim = '';
  double _weakestScore = 100;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late PageController _pageController;
  Timer? _carouselTimer;
  bool _isUserInteracting = false;
  late VoidCallback _securityListener;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _pulseController.forward(from: 0.0);
        });
      }
    });

    _pulseController.forward();

    _pulseAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    final screenWidth = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width / 
                        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final viewportFraction = screenWidth < 360 ? 0.55 : 0.48;

    _pageController = PageController(viewportFraction: viewportFraction, initialPage: 1000);

    _loadProgress();
    _startAutoScroll();
    _initSecurityListener();
  }

  void _initSecurityListener() {
    _securityListener = () {
      if (sl<SecurityService>().isLocked.value && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ActivationScreen()),
          (route) => false,
        );
      }
    };
    sl<SecurityService>().isLocked.addListener(_securityListener);
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isUserInteracting && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    sl<SecurityService>().isLocked.removeListener(_securityListener);
    _carouselTimer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final storage = sl<StorageService>();
      final lastCompleted = storage.getString('last_completed_date') ?? '';
      final today = AppDateService.todayKey();
      final result = await TestController.getDiagnosisResult();
      final diagnosis = result.diagnosis;
      final failed = result.respuestasIncorrectas;

      setState(() {
        _todayCompleted = lastCompleted == today;
        _diagnosis = diagnosis;
        _failedCount = failed;
        _questionsAnswered = result.preguntasRespondidas;

        // Encontrar dimensión más débil
        if (result.scoresPorDimension.isNotEmpty) {
          final sorted = result.scoresPorDimension.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          _weakestDim = sorted.first.key;
          _weakestScore = sorted.first.value;
        }
      });
    } catch (e) {
      debugPrint('❌ Dashboard: Error al cargar progreso: $e');
    }
  }

  Future<void> _startDailyTest() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TestScreen(
          onCompleted: _onDailyTestCompleted,
          isDailyMission: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted) return;
    _loadProgress();
  }

  Future<void> _startPsychotechnicalTest() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SpatialTestScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted) return;
    _loadProgress();
  }


  Future<void> _startEscuelita() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TestScreen(isCorrectingErrors: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted) return;
    _loadProgress();
  }

  Future<void> _startSpatialEscuelita() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SpatialTestScreen(isReviewMode: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted) return;
    _loadProgress();
  }

  Future<void> _startMedicalExam() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const InterviewScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showUpgradePrompt(String message) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.accentColor, width: 1)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Text('ACCESO LIMITADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Aquí podrías llevar a una pantalla de pago o contacto
                _contactAdmin();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
              child: const Text('SER USUARIO PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactAdmin() async {
    final url = Uri.parse('https://wa.me/51955285763?text=Hola,%20quiero%20activar%20mi%20cuenta%20PRO%20de%20PsicoLearn');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _startExamSimulation() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ExamSimulationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted) return;
    _loadProgress();
  }

  Future<void> _onDailyTestCompleted() async {
    try {
      final storage = sl<StorageService>();
      final lastCompleted = storage.getString('last_completed_date') ?? '';
      final today = AppDateService.todayKey();
      if (lastCompleted != today) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        int streak = storage.getInt('streak_days') ?? 0;
        streak = lastCompleted == yesterdayKey ? streak + 1 : 1;
        final totalDays = (storage.getInt('total_days_completed') ?? 0) + 1;
        await storage.setString('last_completed_date', today);
        await storage.setInt('total_days_completed', totalDays);
        await storage.setInt('streak_days', streak);
      }
    } catch (e) {
      debugPrint('❌ Dashboard: Error al completar test diario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const isWideWeb = true; // Force web layout everywhere

    // On web wide layout, navigation is handled by the sidebar
    // The Scaffold still wraps everything but without a bottom nav bar.
    return Scaffold(
      extendBody: !isWideWeb,
      body: LaboratoryBackground(
        child: WebDashboardLayout(
          selectedIndex: _selectedIndex,
          onTabChanged: (i) {
            setState(() => _selectedIndex = i);
            if (i == 0) _loadProgress();
          },
          homeTab: _buildHomeTab(),
          onContactAdmin: _contactAdmin,
        ),
      ),
      bottomNavigationBar: isWideWeb ? null : _buildNavBar(),
      floatingActionButton: null,
    );
  }

  Widget _buildNavBar() {
    if (_selectedIndex > 1) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          0,
          Responsive.horizontalPadding(context),
          12,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF161B22).withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex > 1 ? 0 : _selectedIndex,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedItemColor: AppTheme.accentColor,
              unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
              onTap: (i) => setState(() => _selectedIndex = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded, size: 26),
                  label: 'INICIO',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  activeIcon: Icon(Icons.person_rounded, size: 26),
                  label: 'PERFIL',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final width = MediaQuery.of(context).size.width;
    const isWideWeb = true; // Force desktop home view on mobile too

    if (isWideWeb) {
      return _buildWebHomeTab();
    }

    // Original mobile layout
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DashboardHeader(
          diagnosis: _diagnosis,
          pulseAnimation: _pulseAnimation,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context)),
          child: DailyMissionCard(
            todayCompleted: _todayCompleted,
            questionsAnswered: _questionsAnswered,
            totalQuestions: _totalQuestionsInDaily,
            onTap: _startDailyTest,
          ),
        ),
        const SizedBox(height: 12),
        ActionCardCarousel(
          controller: _pageController,
          onInteractionChanged: (interacting) =>
              _isUserInteracting = interacting,
          items: [
            ActionCardItem(
              title: 'PONTE A PRUEBA',
              subtitle: 'Simulación de examen real',
              icon: Icons.timer_rounded,
              color: const Color(0xFF00E5FF),
              onTap: _startExamSimulation,
            ),
            ActionCardItem(
              title: 'PSICOTÉCNICO',
              subtitle: 'Razonamiento espacial',
              icon: Icons.extension_rounded,
              color: Colors.tealAccent,
              onTap: _startPsychotechnicalTest,
            ),
            ActionCardItem(
              title: 'LA ESCUELITA',
              subtitle: 'Refuerzo de Errores',
              icon: Icons.school_rounded,
              color: Colors.orangeAccent,
              onTap: _startEscuelita,
            ),
            ActionCardItem(
              title: 'EXAMEN MÉDICO',
              subtitle: 'Psicología (Entrevista)',
              icon: Icons.forum_rounded,
              color: Colors.blueAccent,
              onTap: _startMedicalExam,
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Wide-screen web home layout - Gemini Inspired
  // ──────────────────────────────────────────
  Widget _buildWebHomeTab() {
    final secService = sl<SecurityService>();
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Enhanced Gemini-style header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 2.0,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Floating welcome badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.accentColor.withOpacity(0.3),
                                        AppTheme.accentColor.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: AppTheme.accentColor.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.psychology_rounded,
                                        color: AppTheme.accentColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '¡Bienvenido de vuelta!',
                                        style: TextStyle(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),

                                // Animated diagnosis status
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, _) {
                                    final baseColor = _diagnosis == 'APTO'
                                        ? const Color(0xFF10B981)
                                        : (_diagnosis == 'PENDIENTE' || _diagnosis == '...'
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444));
                                    
                                    return ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          baseColor.withOpacity(0.6),
                                          baseColor,
                                          Colors.white,
                                          baseColor,
                                          baseColor.withOpacity(0.6),
                                        ],
                                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                        begin: Alignment(_pulseAnimation.value - 1, 0),
                                        end: Alignment(_pulseAnimation.value + 1, 0),
                                      ).createShader(bounds),
                                      child: Text(
                                        'ESTADO: $_diagnosis',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          height: 1.1,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  'Tu progreso actual en la evaluación psicométrica integral',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _WebDailyBadge(
                              todayCompleted: _todayCompleted,
                              questionsAnswered: _questionsAnswered,
                              totalQuestions: _totalQuestionsInDaily,
                              onTap: _startDailyTest,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Floating welcome badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.accentColor.withOpacity(0.3),
                                          AppTheme.accentColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.psychology_rounded,
                                          color: AppTheme.accentColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '¡Bienvenido de vuelta!',
                                          style: TextStyle(
                                            color: AppTheme.accentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),

                                  // Animated diagnosis status
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, _) {
                                      final baseColor = _diagnosis == 'APTO'
                                          ? const Color(0xFF10B981)
                                          : (_diagnosis == 'PENDIENTE' || _diagnosis == '...'
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFEF4444));
                                      
                                      return ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            baseColor.withOpacity(0.6),
                                            baseColor,
                                            Colors.white,
                                            baseColor,
                                            baseColor.withOpacity(0.6),
                                          ],
                                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                          begin: Alignment(_pulseAnimation.value - 1, 0),
                                          end: Alignment(_pulseAnimation.value + 1, 0),
                                        ).createShader(bounds),
                                        child: Text(
                                          'ESTADO: $_diagnosis',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            height: 1.1,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    'Tu progreso actual en la evaluación psicométrica integral',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      height: 1.4,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 32),
                            
                            // Enhanced daily mission card
                            Expanded(
                              flex: 2,
                              child: _WebDailyBadge(
                                todayCompleted: _todayCompleted,
                                questionsAnswered: _questionsAnswered,
                                totalQuestions: _totalQuestionsInDaily,
                                onTap: _startDailyTest,
                              ),
                            ),
                          ],
                        ),
            ),
            
            const SizedBox(height: 24),

            // ── Enhanced stats grid ──
            if (isMobile)
              Column(
                children: [
                  _buildStatCard(
                    'Preguntas Respondidas',
                    '$_questionsAnswered',
                    'En total',
                    Icons.task_alt_rounded,
                    const Color(0xFF06B6D4),
                  ),
                  const SizedBox(height: 20),
                  _buildStatCard(
                    'Errores Cometidos',
                    '$_failedCount',
                    'Para mejorar',
                    Icons.assignment_late_rounded,
                    const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 20),
                  _buildStatCard(
                    'Dimensión Débil',
                    _weakestDim.isEmpty ? 'N/A' : _weakestDim,
                    '${_weakestScore.toStringAsFixed(1)}% precisión',
                    Icons.track_changes_rounded,
                    const Color(0xFFEF4444),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Preguntas Respondidas',
                      '$_questionsAnswered',
                      'En total',
                      Icons.task_alt_rounded,
                      const Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      'Errores Cometidos',
                      '$_failedCount',
                      'Para mejorar',
                      Icons.assignment_late_rounded,
                      const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      'Dimensión Débil',
                      _weakestDim.isEmpty ? 'N/A' : _weakestDim,
                      '${_weakestScore.toStringAsFixed(1)}% precisión',
                      Icons.track_changes_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // ── Section title ──
            _WebSectionTitle('Módulos de Entrenamiento'),
            const SizedBox(height: 30),

            // ── Enhanced cards grid ──
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                crossAxisSpacing: isMobile ? 16 : 24,
                mainAxisSpacing: isMobile ? 16 : 24,
                childAspectRatio: isMobile ? 1.8 : 1.4,
              ),
              children: [
                _buildActionCard(
                  'MISIÓN DIARIA',
                  _todayCompleted
                      ? '¡Completada hoy!'
                      : '$_questionsAnswered / $_totalQuestionsInDaily preguntas',
                  _todayCompleted ? Icons.check_circle_rounded : Icons.bolt_rounded,
                  _todayCompleted 
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFF9100)]),
                  _todayCompleted ? null : _startDailyTest,
                  isCompleted: _todayCompleted,
                ),
                _buildActionCard(
                  'PSICOTÉCNICO',
                  'Razonamiento espacial y lógico',
                  Icons.extension_rounded,
                  const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  _startPsychotechnicalTest,
                ),
                _buildActionCard(
                  'PONTE A PRUEBA',
                  'Simulación de examen real',
                  Icons.timer_rounded,
                  const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  _startExamSimulation,
                ),
                _buildActionCard(
                  'LA ESCUELITA',
                  'Refuerzo de errores cometidos',
                  Icons.school_rounded,
                  const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                  _startEscuelita,
                ),
                _buildActionCard(
                  'ENTREVISTA MÉDICA',
                  'Evaluación psicológica personal',
                  Icons.forum_rounded,
                  const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
                  _startMedicalExam,
                ),
                if (secService.isAdmin)
                  _buildActionCard(
                    'ADMIN PANEL',
                    'Gestión de usuarios y sistema',
                    Icons.admin_panel_settings_rounded,
                    const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminPanelScreen())),
                  ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F20).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFC4C7C5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback? onTap, {
    bool isLocked = false,
    bool isCompleted = false,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          gradient: isLocked 
              ? LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800])
              : gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!isLocked && onTap != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCompleted ? 'COMPLETADO' : 'COMENZAR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _WebSectionTitle extends StatelessWidget {
  final String title;

  const _WebSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _WebDailyBadge extends StatelessWidget {
  final bool todayCompleted;
  final int questionsAnswered;
  final int totalQuestions;
  final VoidCallback? onTap;

  const _WebDailyBadge({
    super.key,
    required this.todayCompleted,
    required this.questionsAnswered,
    required this.totalQuestions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0 ? (questionsAnswered / totalQuestions).clamp(0.0, 1.0) : 0.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: todayCompleted
              ? const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: todayCompleted ? const Color(0xFF2DD4BF).withOpacity(0.5) : const Color(0xFFFFAB00).withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (todayCompleted ? const Color(0xFF0D9488) : const Color(0xFFFF6F00)).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    todayCompleted ? Icons.check_circle_rounded : Icons.bolt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  todayCompleted ? 'MISIÓN COMPLETADA' : 'MISIÓN DIARIA REQUERIDA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              todayCompleted 
                  ? '¡Buen trabajo! Vuelve mañana.'
                  : '$questionsAnswered de $totalQuestions preguntas completadas',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!todayCompleted) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WebActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final String? badge;

  const _WebActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

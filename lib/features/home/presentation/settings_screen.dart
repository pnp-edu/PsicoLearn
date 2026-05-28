import 'package:flutter/material.dart';
import 'package:psicolearn/features/interview/domain/services/interview_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/app_date_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/laboratory_background.dart';
import 'activation_screen.dart';



class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _realismModeEnabled = false;
  int _daysSinceInstall = 0;
  String _installDate = '';
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = sl<StorageService>();
    final installDate = await AppDateService.getInstallDate();
    final days = await AppDateService.getDaysSinceInstall();

    
    setState(() {
      _realismModeEnabled = storage.getBool('interview_realism_mode') ?? false;
      _daysSinceInstall = days;
      _installDate =
          '${installDate.day.toString().padLeft(2, '0')}/${installDate.month.toString().padLeft(2, '0')}/${installDate.year}';

      _loading = false;
    });
  }

  Future<void> _setRealismMode(bool value) async {
    final storage = sl<StorageService>();
    await storage.setBool('interview_realism_mode', value);
    setState(() => _realismModeEnabled = value);
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () {
            if (widget.onBack != null) widget.onBack!();
          },
        ),
        title: Text(
          'AJUSTES',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
      ),
      body: LaboratoryBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),

              children: [
                // ── Info card ──────────────────────────────────────────────
                _buildSectionHeader('INFORMACIÓN DE LA APP', subColor),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Fecha de instalación',
                        _installDate,
                        textColor,
                        subColor,
                      ),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                      _buildInfoRow(
                        Icons.local_fire_department_rounded,
                        'Días en entrenamiento',
                        '$_daysSinceInstall ${_daysSinceInstall == 1 ? "día" : "días"}',
                        textColor,
                        subColor,
                        valueColor: AppTheme.accentColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),



                const SizedBox(height: 28),

                const SizedBox(height: 28),

                // ── Reset Interview ─────────────────────────────────────────
                _buildSectionHeader('ZONA DE ENTRENAMIENTO', subColor),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Si has dominado todas las preguntas de entrevista, puedes reiniciarlas aquí para volver a practicar desde cero.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final interviewService = sl<InterviewService>();
                            await interviewService.resetMastery();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Simulador de entrevista reiniciado correctamente.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('REINICIAR TODA LA ENTREVISTA', 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── SESIÓN ─────────────────────────────────────────
                _buildSectionHeader('SESIÓN', subColor),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Cierra tu sesión actual en este dispositivo de forma segura.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF161B22),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    SizedBox(width: 10),
                                    Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: const Text(
                                  '¿Estás seguro de que deseas cerrar tu sesión actual?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                    child: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final securityService = sl<SecurityService>();
                              await securityService.signOut();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ActivationScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('CERRAR SESIÓN', 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subColor, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: subColor, fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

}

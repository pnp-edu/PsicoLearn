import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/question.dart';

class TestFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String correctText;
  final Question question;
  final VoidCallback onContinue;

  const TestFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.correctText,
    required this.question,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        isSmallScreen ? 14 : 18,
        20,
        isSmallScreen ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 35,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                    color: accentColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? 'PERFIL ALINEADO' : 'DESVIACIÓN DETECTADA',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: isSmallScreen ? 13 : 15,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        question.dimension.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: isSmallScreen ? 8 : 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            if (!isCorrect) ...[
              _buildInfoCard(
                isDark,
                title: 'RESPUESTA IDEAL',
                content: correctText,
                color: Colors.greenAccent,
                icon: Icons.check_circle_outline,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
            ],

            _buildInfoCard(
              isDark,
              title: 'FUNDAMENTO PSICOLÓGICO',
              content: question.hint,
              color: AppTheme.accentColor,
              icon: Icons.lightbulb_outline_rounded,
              isSmallScreen: isSmallScreen,
            ),

            if (!isCorrect && question.esEscalaMentira) ...[
              SizedBox(height: isSmallScreen ? 8 : 10),
              _buildInfoCard(
                isDark,
                title: 'ALERTA DE SINCERIDAD',
                content: 'Estás intentando proyectar una imagen artificialmente perfecta. Esto invalida tu perfil.',
                color: Colors.orangeAccent,
                icon: Icons.warning_amber_rounded,
                isSmallScreen: isSmallScreen,
              ),
            ],

            SizedBox(height: isSmallScreen ? 14 : 18),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 44 : 50,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'ENTENDIDO, CONTINUAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark, {
    required String title,
    required String content,
    required Color color,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            content,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/models/interview_question.dart';

class InterviewCard extends StatefulWidget {
  final InterviewQuestion question;
  final int index;

  const InterviewCard({
    super.key,
    required this.question,
    required this.index,
  });

  @override
  State<InterviewCard> createState() => _InterviewCardState();
}

class _InterviewCardState extends State<InterviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Colors.purpleAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isExpanded 
              ? accentColor.withOpacity(0.5) 
              : (isDark ? Colors.white10 : Colors.black12),
          width: 1.5,
        ),
        boxShadow: [
          if (_isExpanded)
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'PREGUNTA ${widget.index + 1}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.question.pregunta,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _buildExpandedContent(isDark, accentColor),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(bool isDark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _sectionHeader(Icons.psychology_rounded, 'ANÁLISIS DEL EVALUADOR', accentColor),
        const SizedBox(height: 8),
        Text(
          widget.question.puntosClave,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader(Icons.verified_user_rounded, 'RESPUESTA IDEAL', Colors.greenAccent),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
          ),
          child: Text(
            widget.question.respuestaIdeal,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.greenAccent,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

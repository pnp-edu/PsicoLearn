import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Estado de respuesta por opción
enum OptionState { idle, selectedCorrect, selectedWrong, revealedCorrect }

class OptionsSelector extends StatefulWidget {
  final Map<String, String> options;
  final String? initialValue;
  final String? correctAnswer;
  final bool isReviewMode;       // Modo corrección: muestra correcta directamente
  final bool isExamMode;         // Modo examen: sin feedback, permite re-selección
  final ValueChanged<String> onChanged;

  const OptionsSelector({
    super.key,
    required this.options,
    this.initialValue,
    this.correctAnswer,
    this.isReviewMode = false,
    this.isExamMode = false,
    required this.onChanged,
  });

  @override
  State<OptionsSelector> createState() => _OptionsSelectorState();
}

class _OptionsSelectorState extends State<OptionsSelector>
    with TickerProviderStateMixin {
  String? _selectedValue;
  bool _locked = false; 

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    if (_selectedValue != null && !widget.isExamMode) _locked = true;

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    // Animación de pulso para modo examen
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OptionsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedValue = widget.initialValue;
        _locked = _selectedValue != null && !widget.isExamMode;
      });
    }
  }

  OptionState _stateFor(String key) {
    final isCorrect = key == widget.correctAnswer;
    final isSelected = key == _selectedValue;

    if (widget.isReviewMode) {
      if (isCorrect) return OptionState.revealedCorrect;
      return OptionState.idle;
    }

    if (widget.isExamMode) {
      return isSelected ? OptionState.selectedCorrect : OptionState.idle;
    }

    if (_selectedValue == null) return OptionState.idle;

    final selectedCorrect = _selectedValue == widget.correctAnswer;

    if (isSelected && selectedCorrect) return OptionState.selectedCorrect;
    if (isSelected && !selectedCorrect) return OptionState.selectedWrong;
    if (!isSelected && isCorrect && !selectedCorrect) return OptionState.revealedCorrect;

    return OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    final scale = (screenWidth / 375.0).clamp(0.8, 1.0);

    // Usamos GridView para mejor control del espacio
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isLandscape ? 4 : 2, // 4 columnas en landscape, 2 en portrait
      mainAxisSpacing: isLandscape ? 8 : 14,
      crossAxisSpacing: 8,
      childAspectRatio: isLandscape ? 1.2 : (screenWidth < 360 ? 0.85 : 0.95),
      children: widget.options.entries.map((entry) {
        final state = _stateFor(entry.key);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked
              ? null
              : () {
                  final isCorrect = entry.key == widget.correctAnswer;
                  if (isCorrect) {
                    HapticFeedback.lightImpact();
                  } else {
                    HapticFeedback.mediumImpact();
                    _shakeCtrl.forward(from: 0);
                  }

                  setState(() {
                    _selectedValue = entry.key;
                    if (!widget.isExamMode) _locked = true;
                  });

                  widget.onChanged(entry.key);
                },
          child: _buildOption(entry, state, isDark, scale),
        );
      }).toList(),
    );
  }

  Widget _buildOption(MapEntry<String, String> entry, OptionState state, bool isDark, double scale) {
    final isWrong = state == OptionState.selectedWrong;

    Color circleColor;
    Color borderColor;
    Color textColor;
    List<BoxShadow> shadows = [];
    Widget? icon;

    switch (state) {
      case OptionState.selectedCorrect:
        final color = widget.isExamMode ? const Color(0xFF00E5FF) : Colors.greenAccent;
        circleColor = color.withOpacity(0.2);
        borderColor = color;
        textColor = color;
        if (widget.isExamMode) {
          return AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final glow = 14 + (6 * _pulseCtrl.value);
              return _buildBaseOption(entry, scale, circleColor, borderColor, textColor, 
                [BoxShadow(color: color.withOpacity(0.4), blurRadius: glow, spreadRadius: 2 * _pulseCtrl.value)],
                Icon(Icons.radio_button_checked, size: 22, color: color), isWrong);
            },
          );
        }
        shadows = [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)];
        icon = Icon(widget.isExamMode ? Icons.radio_button_checked : Icons.check_rounded, size: 22, color: color);
        break;
      case OptionState.selectedWrong:
        circleColor = Colors.redAccent.withOpacity(0.2);
        borderColor = Colors.redAccent;
        textColor = Colors.redAccent;
        shadows = [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)];
        icon = const Icon(Icons.close_rounded, size: 22, color: Colors.redAccent);
        break;
      case OptionState.revealedCorrect:
        circleColor = Colors.greenAccent.withOpacity(0.1);
        borderColor = Colors.greenAccent.withOpacity(0.7);
        textColor = Colors.greenAccent;
        shadows = [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)];
        icon = Icon(Icons.check_circle_outline_rounded, size: 22, color: Colors.greenAccent.withOpacity(0.8));
        break;
      case OptionState.idle:
        final unselected = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2);
        circleColor = Colors.transparent;
        borderColor = unselected;
        textColor = isDark ? Colors.white70 : Colors.black87;
        break;
    }

    return _buildBaseOption(entry, scale, circleColor, borderColor, textColor, shadows, icon, isWrong);
  }

  Widget _buildBaseOption(MapEntry<String, String> entry, double scale, Color circleColor, Color borderColor, Color textColor, List<BoxShadow> shadows, Widget? icon, bool isWrong) {
    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 48 * scale,
      height: 48 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: shadows,
      ),
      child: Center(child: icon),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        isWrong
            ? AnimatedBuilder(
                animation: _shakeAnim,
                builder: (ctx, child) {
                  final dx = 6 * (0.5 - (_shakeAnim.value % 0.25 / 0.25)).abs() * (1 - _shakeCtrl.value);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: bubble,
              )
            : bubble,
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: TextStyle(
              color: textColor,
              fontSize: 11 * scale,
              fontWeight: textColor != (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87) ? FontWeight.w800 : FontWeight.w600,
              height: 1.15,
            ),
            child: Text(
              entry.value,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: content,
    );
  }
}

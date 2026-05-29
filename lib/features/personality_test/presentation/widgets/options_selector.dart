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
    final isLandscape = screenWidth > 600;

    final scale = (screenWidth / 375.0).clamp(0.8, 1.0);

    final children = widget.options.entries.map((entry) {
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
        child: isLandscape
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildDesktopOption(entry, state, isDark, scale),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: _buildMobileOption(entry, state, isDark, scale),
              ),
      );
    }).toList();

    if (isLandscape) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    } else {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0,
        runSpacing: 24.0,
        children: children,
      );
    }
  }

  void _getOptionColors(OptionState state, bool isDark, outColors) {
    switch (state) {
      case OptionState.selectedCorrect:
        final color = widget.isExamMode ? const Color(0xFF00E5FF) : Colors.greenAccent;
        outColors['circle'] = color.withOpacity(0.2);
        outColors['border'] = color;
        outColors['text'] = color;
        outColors['icon'] = Icon(widget.isExamMode ? Icons.radio_button_checked : Icons.check_rounded, size: 22, color: color);
        outColors['shadows'] = [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)];
        break;
      case OptionState.selectedWrong:
        outColors['circle'] = Colors.redAccent.withOpacity(0.2);
        outColors['border'] = Colors.redAccent;
        outColors['text'] = Colors.redAccent;
        outColors['icon'] = const Icon(Icons.close_rounded, size: 22, color: Colors.redAccent);
        outColors['shadows'] = [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)];
        break;
      case OptionState.revealedCorrect:
        outColors['circle'] = Colors.greenAccent.withOpacity(0.1);
        outColors['border'] = Colors.greenAccent.withOpacity(0.7);
        outColors['text'] = Colors.greenAccent;
        outColors['icon'] = Icon(Icons.check_circle_outline_rounded, size: 22, color: Colors.greenAccent.withOpacity(0.8));
        outColors['shadows'] = [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)];
        break;
      case OptionState.idle:
        final unselected = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2);
        outColors['circle'] = Colors.transparent;
        outColors['border'] = unselected;
        outColors['text'] = isDark ? Colors.white70 : Colors.black87;
        outColors['icon'] = null;
        outColors['shadows'] = <BoxShadow>[];
        break;
    }
  }

  Widget _buildDesktopOption(MapEntry<String, String> entry, OptionState state, bool isDark, double scale) {
    final isWrong = state == OptionState.selectedWrong;
    final Map<String, dynamic> colors = {};
    _getOptionColors(state, isDark, colors);

    Color circleColor = colors['circle'];
    Color borderColor = colors['border'];
    Color textColor = colors['text'];
    Widget? icon = colors['icon'];
    List<BoxShadow> shadows = colors['shadows'];

    if (widget.isExamMode && state == OptionState.selectedCorrect) {
       return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
             final glow = 14 + (6 * _pulseCtrl.value);
             shadows = [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: glow, spreadRadius: 2 * _pulseCtrl.value)];
             return _buildDesktopCard(entry, scale, circleColor, borderColor, textColor, shadows, icon, isWrong, isDark);
          },
       );
    }
    return _buildDesktopCard(entry, scale, circleColor, borderColor, textColor, shadows, icon, isWrong, isDark);
  }

  Widget _buildDesktopCard(MapEntry<String, String> entry, double scale, Color circleColor, Color borderColor, Color textColor, List<BoxShadow> shadows, Widget? icon, bool isWrong, bool isDark) {
    final baseBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
    final cardBg = circleColor == Colors.transparent ? baseBg : circleColor.withOpacity(0.15);

    final bubble = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        border: Border.all(color: borderColor, width: 2.0),
      ),
      child: Center(child: icon != null ? Transform.scale(scale: 0.9, child: icon) : null),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          bubble,
          const SizedBox(width: 20),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 280),
              style: TextStyle(
                color: textColor,
                fontSize: 18 * scale,
                fontWeight: textColor != (isDark ? Colors.white70 : Colors.black87) ? FontWeight.w800 : FontWeight.w600,
                height: 1.2,
              ),
              child: Text(entry.value),
            ),
          ),
        ],
      ),
    );

    if (isWrong) {
      return AnimatedBuilder(
        animation: _shakeAnim,
        builder: (ctx, child) {
          final dx = 6 * (0.5 - (_shakeAnim.value % 0.25 / 0.25)).abs() * (1 - _shakeCtrl.value);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: card,
      );
    }
    return card;
  }

  Widget _buildMobileOption(MapEntry<String, String> entry, OptionState state, bool isDark, double scale) {
    final isWrong = state == OptionState.selectedWrong;
    final Map<String, dynamic> colors = {};
    _getOptionColors(state, isDark, colors);

    Color circleColor = colors['circle'];
    Color borderColor = colors['border'];
    Color textColor = colors['text'];
    Widget? icon = colors['icon'];
    List<BoxShadow> shadows = colors['shadows'];

    if (widget.isExamMode && state == OptionState.selectedCorrect) {
       return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
             final glow = 14 + (6 * _pulseCtrl.value);
             shadows = [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: glow, spreadRadius: 2 * _pulseCtrl.value)];
             return _buildMobileBaseOption(entry, scale, circleColor, borderColor, textColor, shadows, icon, isWrong);
          },
       );
    }
    return _buildMobileBaseOption(entry, scale, circleColor, borderColor, textColor, shadows, icon, isWrong);
  }

  Widget _buildMobileBaseOption(MapEntry<String, String> entry, double scale, Color circleColor, Color borderColor, Color textColor, List<BoxShadow> shadows, Widget? icon, bool isWrong) {
    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 48.0 * scale,
      height: 48.0 * scale,
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
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 280),
          style: TextStyle(
            color: textColor,
            fontSize: 13.0 * scale,
            fontWeight: textColor != (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87) ? FontWeight.w800 : FontWeight.w600,
            height: 1.25,
          ),
          child: Text(
            entry.value,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: content,
    );
  }
}

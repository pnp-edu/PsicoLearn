import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';

class SpatialOptionsGrid extends StatelessWidget {
  final Map<String, String> options;
  final String? selectedOption;
  final String correctOption;
  final bool answered;
  final Function(String) onSelect;

  const SpatialOptionsGrid({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.correctOption,
    required this.answered,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final optionsList = options.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'SELECCIONA UNA OPCIÓN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Row(
          children: [
            for (int i = 0; i < 3 && i < optionsList.length; i++) ...[
              Expanded(
                child: _buildOptionTile(
                  context: context,
                  key: optionsList[i].key,
                  assetPath: optionsList[i].value,
                  isDark: isDark,
                ),

              ),
              if (i < 2) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (optionsList.length > 3)
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (int i = 3; i < optionsList.length; i++) ...[
                Expanded(
                  flex: 2,
                  child: _buildOptionTile(
                    context: context,
                    key: optionsList[i].key,
                    assetPath: optionsList[i].value,
                    isDark: isDark,
                  ),
                ),
                if (i < optionsList.length - 1) const SizedBox(width: 10),
              ],
              const Expanded(child: SizedBox()),
            ],
          ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String key,
    required String assetPath,
    required bool isDark,
  }) {
    final isSelected = selectedOption == key;
    final isCorrect = key == correctOption;
    final showResult = answered;

    Color borderColor;
    Color bgColor;
    Color labelColor;

    if (!showResult) {
      borderColor = isSelected
          ? AppTheme.accentColor
          : (isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1));
      bgColor = isSelected
          ? AppTheme.accentColor.withOpacity(0.1)
          : (isDark ? const Color(0xFF161B22) : Colors.white);
      labelColor = isSelected ? AppTheme.accentColor : Colors.grey;
    } else {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
        bgColor = Colors.greenAccent.withOpacity(0.1);
        labelColor = Colors.greenAccent;
      } else if (isSelected) {
        borderColor = Colors.redAccent;
        bgColor = Colors.redAccent.withOpacity(0.1);
        labelColor = Colors.redAccent;
      } else {
        borderColor =
            isDark ? Colors.white.withOpacity(0.06) : Colors.black12;
        bgColor = isDark ? const Color(0xFF161B22) : Colors.white;
        labelColor = Colors.grey;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375.0).clamp(0.8, 1.0);
    final isSmall = screenWidth < 360;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onSelect(key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withOpacity(isSelected ? 0.9 : 0.15),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: borderColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor de la figura de opción
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 1.0, end: isSelected ? 1.1 : 1.0),
              builder: (context, val, child) {
                return Transform.scale(scale: val, child: child);
              },
              child: SvgPicture.asset(
                assetPath,
                height: isSmall ? 30 : 38,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => SizedBox(
                  height: isSmall ? 30 : 38,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 1.0)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Indicador de letra/resultado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showResult && isCorrect)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle_rounded,
                          color: Colors.greenAccent, size: 14 * scale),
                    )
                  else if (showResult && isSelected && !isCorrect)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.cancel_rounded,
                          color: Colors.redAccent, size: 14 * scale),
                    ),
                  Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14 * scale,
                      color: labelColor,
                      letterSpacing: 0.5,
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
}

import 'package:flutter/material.dart';
import 'package:psicolearn/core/constants/colors.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        shadowColor: AppColors.neonCyan,
        elevation: 12,
      ),
      child: Text(label),
    );
  }
}

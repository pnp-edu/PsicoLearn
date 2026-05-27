import 'package:flutter/material.dart';
import 'package:psicolearn/core/constants/colors.dart';
import 'package:psicolearn/core/constants/dimensions.dart';
import 'package:psicolearn/features/test/domain/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacing),
      padding: const EdgeInsets.all(AppDimensions.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha:0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.spacing),
          Wrap(
            spacing: AppDimensions.spacing,
            runSpacing: AppDimensions.spacing / 2,
            children: question.options.map((option) {
              return Chip(
                label: Text(option),
                backgroundColor: AppColors.neonCyan.withValues(alpha:0.15),
                labelStyle: const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:psicolearn/core/constants/colors.dart';

class LikertScale extends StatelessWidget {
  const LikertScale({
    super.key,
    required this.values,
    required this.onSelected,
  });

  final List<String> values;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(values.length, (index) {
        return GestureDetector(
          onTap: () => onSelected(index),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.6)),
            ),
            child: Text(
              values[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}

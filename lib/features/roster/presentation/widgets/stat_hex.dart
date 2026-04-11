import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatHex extends StatelessWidget {
  final String label;
  final int value;
  final int modifier;

  const StatHex({
    super.key,
    required this.label,
    required this.value,
    this.modifier = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(),
              width: modifier != 0 ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getValueColor(),
                ),
              ),
              if (modifier != 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getModifierColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      modifier > 0 ? '+$modifier' : '$modifier',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (modifier > 0) return AppColors.success;
    if (modifier < 0) return AppColors.error;
    return AppColors.surfaceLight;
  }

  Color _getValueColor() {
    if (modifier > 0) return AppColors.success;
    if (modifier < 0) return AppColors.error;
    return AppColors.textPrimary;
  }

  Color _getModifierColor() {
    if (modifier > 0) return AppColors.success;
    if (modifier < 0) return AppColors.error;
    return AppColors.textMuted;
  }
}

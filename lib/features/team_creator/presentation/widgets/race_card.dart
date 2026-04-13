import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';

class RaceCard extends StatelessWidget {
  final BaseTeam race;
  final bool isSelected;
  final VoidCallback onTap;

  const RaceCard({
    super.key,
    required this.race,
    required this.isSelected,
    required this.onTap,
  });

  Color get _tierColor {
    switch (race.tier) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.accent;
      case 3:
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        height: 230,
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Tier badge top-right
            if (race.tier != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _tierColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    'TIER ${race.tier}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _tierColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            // Main content: logo centered, name below
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Image.asset(
                        'teams/${race.id}/logo.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          PhosphorIcons.shield(PhosphorIconsStyle.fill),
                          color: AppColors.textMuted,
                          size: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      race.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        letterSpacing: 1.2,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 12),
                      Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

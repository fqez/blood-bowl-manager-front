import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/team.dart';

class SkillBadge extends StatelessWidget {
  final Skill skill;
  final bool? isAcquired;
  final String? displayName;
  final String? tooltip;

  const SkillBadge({
    super.key,
    required this.skill,
    this.isAcquired,
    this.displayName,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final acquired = isAcquired ?? !skill.isStarting;
    final categoryColor = _getCategoryColor();
    final badgeColor = acquired ? AppColors.accent : categoryColor;

    final label = displayName ?? skill.name;

    return Tooltip(
      message: tooltip ?? skill.description ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(acquired ? 0.18 : 0.15),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: badgeColor.withOpacity(acquired ? 0.7 : 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(acquired ? 0.35 : 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  acquired
                      ? PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)
                      : _getCategoryIcon(),
                  size: 12,
                  color: acquired ? AppColors.accentLight : categoryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (skill.isStarting) ...[
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.starFour(PhosphorIconsStyle.fill),
                size: 10,
                color: categoryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (skill.family.toLowerCase()) {
      case 'general':
        return AppColors.info;
      case 'agility':
        return AppColors.success;
      case 'strength':
        return AppColors.error;
      case 'passing':
        return AppColors.warning;
      case 'mutation':
        return const Color(0xFF9B59B6);
      case 'extraordinary':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getCategoryIcon() {
    switch (skill.family.toLowerCase()) {
      case 'general':
        return PhosphorIcons.user(PhosphorIconsStyle.fill);
      case 'agility':
        return PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill);
      case 'strength':
        return PhosphorIcons.barbell(PhosphorIconsStyle.fill);
      case 'passing':
        return PhosphorIcons.football(PhosphorIconsStyle.fill);
      case 'mutation':
        return PhosphorIcons.dna(PhosphorIconsStyle.fill);
      case 'extraordinary':
        return PhosphorIcons.star(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.question(PhosphorIconsStyle.fill);
    }
  }
}

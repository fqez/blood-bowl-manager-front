import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/team.dart';

class SkillBadge extends StatelessWidget {
  final Skill skill;

  const SkillBadge({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: skill.description ?? skill.name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getCategoryColor().withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getCategoryColor().withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skill icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(),
                  size: 12,
                  color: _getCategoryColor(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              skill.name,
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
                color: _getCategoryColor(),
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

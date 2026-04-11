import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';

class PositionCard extends StatelessWidget {
  final BasePosition position;
  final int hiredCount;
  final bool canHire;
  final bool affordable;
  final VoidCallback? onHire;

  const PositionCard({
    super.key,
    required this.position,
    required this.hiredCount,
    required this.canHire,
    required this.affordable,
    this.onHire,
  });

  @override
  Widget build(BuildContext context) {
    final atMax = hiredCount >= position.maxQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: atMax ? AppColors.success.withOpacity(0.5) : AppColors.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          // Position icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getPositionIcon(),
                color: AppColors.accent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Position info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      position.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$hiredCount/${position.maxQuantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: atMax ? AppColors.success : AppColors.textMuted,
                        fontWeight: atMax ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Stats
                Row(
                  children: [
                    _buildStatChip('M', position.stats.ma),
                    _buildStatChip('F', position.stats.st),
                    _buildStatChip('A', position.stats.ag),
                    _buildStatChip('P', position.stats.pa),
                    _buildStatChip('D', position.stats.av),
                  ],
                ),
              ],
            ),
          ),
          // Price and action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${position.cost ~/ 1000}k',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: affordable ? AppColors.accent : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              if (atMax)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Máximo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onHire,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 14),
                        const SizedBox(width: 4),
                        const Text('Fichar'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label$value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  IconData _getPositionIcon() {
    final name = position.name.toLowerCase();
    if (name.contains('lineman') || name.contains('lineador')) {
      return PhosphorIcons.user(PhosphorIconsStyle.fill);
    } else if (name.contains('blitzer')) {
      return PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill);
    } else if (name.contains('catcher') || name.contains('receptor')) {
      return PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill);
    } else if (name.contains('thrower') || name.contains('lanzador')) {
      return PhosphorIcons.football(PhosphorIconsStyle.fill);
    } else if (name.contains('ogre') || name.contains('troll') || name.contains('big guy')) {
      return PhosphorIcons.personArmsSpread(PhosphorIconsStyle.fill);
    }
    return PhosphorIcons.user(PhosphorIconsStyle.fill);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/team.dart';

class PlayerRow extends ConsumerWidget {
  final Character character;
  final VoidCallback? onTap;

  const PlayerRow({
    super.key,
    required this.character,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: character.status == PlayerStatus.dead ||
                  character.status == PlayerStatus.injured
              ? 2
              : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildJerseyNumber(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo()),
              _buildStats(),
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJerseyNumber() {
    final isDead = character.status == PlayerStatus.dead;
    final isInjured = character.status == PlayerStatus.injured;
    final isMNG = character.missNextGame;
    final borderColor = isDead
        ? AppColors.textMuted.withOpacity(0.4)
        : isInjured
            ? AppColors.warning.withOpacity(0.6)
            : isMNG
                ? AppColors.error.withOpacity(0.6)
                : AppColors.primary.withOpacity(0.4);
    final textColor = isDead
        ? AppColors.textMuted
        : isInjured
            ? AppColors.warning
            : AppColors.textPrimary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDead
                ? AppColors.surfaceLight.withOpacity(0.5)
                : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${character.number}',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ),
        if (isDead)
          _buildStatusBadge(PhosphorIcons.skull(PhosphorIconsStyle.fill),
              AppColors.textMuted),
        if (isInjured && !isDead)
          _buildStatusBadge(PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
              AppColors.warning),
        if (isMNG && !isDead && !isInjured)
          _buildStatusBadge(
              PhosphorIcons.prohibit(PhosphorIconsStyle.fill), AppColors.error),
      ],
    );
  }

  Widget _buildStatusBadge(IconData icon, Color color) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                character.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: character.status == PlayerStatus.dead
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  decoration: character.status == PlayerStatus.dead
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          character.position,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildLevelBadge(),
            const SizedBox(width: 8),
            if (character.skills.isNotEmpty) ...[
              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 12, color: AppColors.info),
              const SizedBox(width: 2),
              Text(
                '${character.skills.length} habs',
                style: TextStyle(fontSize: 11, color: AppColors.info),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getLevelColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Nv.${character.level}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getLevelColor(),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final stats = character.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem('M', stats.ma),
          _buildStatItem('F', stats.st),
          _buildStatItem('A', stats.ag),
          _buildStatItem('P', stats.pa),
          _buildStatItem('D', stats.av),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (character.status == PlayerStatus.dead)
      return AppColors.textMuted.withOpacity(0.5);
    if (character.status == PlayerStatus.injured) return AppColors.warning;
    if (character.missNextGame) return AppColors.error;
    return AppColors.surfaceLight;
  }

  Color _getLevelColor() {
    if (character.level >= 6) return AppColors.accent;
    if (character.level >= 4) return AppColors.info;
    if (character.level >= 2) return AppColors.success;
    return AppColors.textMuted;
  }
}

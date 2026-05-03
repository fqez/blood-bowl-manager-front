import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../roster/domain/models/team.dart';
import '../../domain/models/aftermatch.dart';

class TouchdownRecorder extends ConsumerWidget {
  final Team? homeTeam;
  final Team? awayTeam;
  final int homeGoal;
  final int awayGoal;
  final List<TouchdownRecord> touchdowns;
  final ValueChanged<TouchdownRecord> onTouchdownAdded;
  final ValueChanged<int> onTouchdownRemoved;

  const TouchdownRecorder({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoal,
    required this.awayGoal,
    required this.touchdowns,
    required this.onTouchdownAdded,
    required this.onTouchdownRemoved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Column(
      children: [
        // Recorded touchdowns
        if (touchdowns.isNotEmpty) ...[
          ...touchdowns.asMap().entries.map((entry) =>
              _buildTouchdownItem(context, lang, entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        // Add touchdown buttons
        Row(
          children: [
            Expanded(
              child: _buildAddButton(
                context,
                lang: lang,
                team: homeTeam,
                isHome: true,
                remaining:
                    homeGoal - touchdowns.where((t) => t.isHomeTeam).length,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAddButton(
                context,
                lang: lang,
                team: awayTeam,
                isHome: false,
                remaining:
                    awayGoal - touchdowns.where((t) => !t.isHomeTeam).length,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTouchdownItem(
      BuildContext context, String lang, int index, TouchdownRecord td) {
    final textTheme = context.textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: td.isHomeTeam ? AppColors.primary : AppColors.accent,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.target(PhosphorIconsStyle.fill),
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  td.playerName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${td.isHomeTeam ? tr(lang, 'aftermatch.home') : tr(lang, 'aftermatch.away')} • TD #${index + 1}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold)),
            onPressed: () => onTouchdownRemoved(index),
            color: AppColors.error,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context, {
    required String lang,
    required Team? team,
    required bool isHome,
    required int remaining,
  }) {
    final enabled = remaining > 0;
    final textTheme = context.textTheme;

    return OutlinedButton(
      onPressed: enabled
          ? () => _showPlayerSelector(context, lang, team, isHome)
          : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(
          color: enabled
              ? (isHome ? AppColors.primary : AppColors.accent)
              : AppColors.surfaceLight,
        ),
        foregroundColor: enabled
            ? (isHome ? AppColors.primary : AppColors.accent)
            : AppColors.textMuted,
      ),
      child: Column(
        children: [
          Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.bold), size: 24),
          const SizedBox(height: 8),
          Text(team?.name ??
              (isHome
                  ? tr(lang, 'aftermatch.home')
                  : tr(lang, 'aftermatch.away'))),
          Text(
            trf(lang, 'aftermatch.remaining', {'n': '$remaining'}),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerSelector(
      BuildContext context, String lang, Team? team, bool isHome) {
    if (team == null) return;

    final textTheme = context.textTheme;

    final players =
        team.characters.where((c) => c.status == PlayerStatus.healthy).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(lang, 'aftermatch.selectScorer'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        '#${player.number}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      player.position,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onTouchdownAdded(TouchdownRecord(
                        playerId: player.id,
                        playerName: player.name,
                        isHomeTeam: isHome,
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../domain/models/aftermatch.dart';

class TouchdownRecorder extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Recorded touchdowns
        if (touchdowns.isNotEmpty) ...[
          ...touchdowns.asMap().entries.map((entry) =>
            _buildTouchdownItem(entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        // Add touchdown buttons
        Row(
          children: [
            Expanded(
              child: _buildAddButton(
                context,
                team: homeTeam,
                isHome: true,
                remaining: homeGoal - touchdowns.where((t) => t.isHomeTeam).length,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAddButton(
                context,
                team: awayTeam,
                isHome: false,
                remaining: awayGoal - touchdowns.where((t) => !t.isHomeTeam).length,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTouchdownItem(int index, TouchdownRecord td) {
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${td.isHomeTeam ? "Local" : "Visitante"} • TD #${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
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
    required Team? team,
    required bool isHome,
    required int remaining,
  }) {
    final enabled = remaining > 0;

    return OutlinedButton(
      onPressed: enabled ? () => _showPlayerSelector(context, team, isHome) : null,
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
          Text(team?.name ?? (isHome ? 'Local' : 'Visitante')),
          Text(
            '$remaining restantes',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerSelector(BuildContext context, Team? team, bool isHome) {
    if (team == null) return;

    final players = team.characters.where((c) => c.status == PlayerStatus.healthy).toList();

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
              'Selecciona anotador',
              style: TextStyle(
                fontSize: 18,
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
                        style: TextStyle(
                          fontSize: 12,
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

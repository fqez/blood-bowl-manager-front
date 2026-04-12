import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';

class LeagueCard extends StatelessWidget {
  final League league;
  final VoidCallback? onTap;

  const LeagueCard({
    super.key,
    required this.league,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(league.status);
    final statusLabel = _getStatusLabel(league.status);

    // Find user's team in this league (simplified - first team for now)
    final userTeam = league.teams.isNotEmpty ? league.teams.first : null;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (userTeam != null)
                    Text(
                      'Pos. ${league.teams.indexOf(userTeam) + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                league.name,
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (userTeam != null) ...[
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.shield(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tu Equipo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userTeam.teamName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Jornada Actual',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jornada ${league.currentRound} / ${league.maxRounds}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const Spacer(),
                  if (league.status == LeagueStatus.active)
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('JUGAR'),
                    )
                  else
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('VER'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.active:
        return AppColors.success;
      case LeagueStatus.paused:
        return AppColors.warning;
      case LeagueStatus.finished:
      case LeagueStatus.completed:
      case LeagueStatus.cancelled:
        return AppColors.textMuted;
      case LeagueStatus.draft:
        return AppColors.warning;
    }
  }

  String _getStatusLabel(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.active:
        return 'ACTIVA';
      case LeagueStatus.paused:
        return 'PAUSADA';
      case LeagueStatus.finished:
        return 'FINALIZADA';
      case LeagueStatus.completed:
        return 'COMPLETADA';
      case LeagueStatus.cancelled:
        return 'CANCELADA';
      case LeagueStatus.draft:
        return 'INSCRIPCIÓN';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class StandingsTable extends StatelessWidget {
  final List<LeagueTeam> teams;
  final String leagueId;

  const StandingsTable({
    super.key,
    required this.teams,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    // Sort teams by points, then goal difference
    final sortedTeams = List<LeagueTeam>.from(teams)
      ..sort((a, b) {
        final pointsDiff = b.points.compareTo(a.points);
        if (pointsDiff != 0) return pointsDiff;
        return b.touchdownDifference.compareTo(a.touchdownDifference);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          _buildHeader(),
          ...sortedTeams.asMap().entries.map((entry) =>
            _buildTeamRow(context, entry.key + 1, entry.value)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'POS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'EQUIPO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildHeaderCell('PTS'),
          _buildHeaderCell('J'),
          _buildHeaderCell('G'),
          _buildHeaderCell('E'),
          _buildHeaderCell('P'),
          _buildHeaderCell('TD+/-'),
          _buildHeaderCell('CAS'),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, int position, LeagueTeam team) {
    final isUserTeam = position == 1; // Simplified - should check actual user team

    return InkWell(
      onTap: () => context.go('/league/$leagueId/team/${team.teamId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUserTeam ? AppColors.primary.withOpacity(0.1) : null,
          border: Border(
            top: BorderSide(color: AppColors.surfaceLight),
            left: isUserTeam
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getPositionColor(position),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Team icon placeholder
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          team.teamName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUserTeam ? FontWeight.bold : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${team.coachName} • TV ${team.teamValue ~/ 1000}k',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _buildDataCell('${team.points}', isBold: true, color: AppColors.accent),
            _buildDataCell('${team.gamesPlayed}'),
            _buildDataCell('${team.wins}', color: AppColors.success),
            _buildDataCell('${team.draws}'),
            _buildDataCell('${team.losses}', color: team.losses > 0 ? AppColors.error : null),
            _buildDataCell(
              '${team.touchdownDifference >= 0 ? '+' : ''}${team.touchdownDifference}',
              color: team.touchdownDifference > 0
                  ? AppColors.success
                  : team.touchdownDifference < 0
                      ? AppColors.error
                      : null,
            ),
            _buildDataCell('${team.casualtiesFor}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.textMuted;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.surfaceLight;
    }
  }
}

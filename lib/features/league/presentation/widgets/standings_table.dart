import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class StandingsTable extends StatelessWidget {
  final List<LeagueStanding> standings;
  final String leagueId;

  const StandingsTable({
    super.key,
    required this.standings,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    // Sort standings by points, then touchdown diff
    final sortedStandings = List<LeagueStanding>.from(standings)
      ..sort((a, b) {
        final pointsDiff = b.points.compareTo(a.points);
        if (pointsDiff != 0) return pointsDiff;
        return b.touchdownDiff.compareTo(a.touchdownDiff);
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
          ...sortedStandings.asMap().entries.map((entry) =>
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

  Widget _buildTeamRow(BuildContext context, int position, LeagueStanding standing) {
    final isUserTeam = position == 1; // Simplified - should check actual user team

    return InkWell(
      onTap: () => context.go('/league/$leagueId/team/${standing.teamId}'),
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
                          standing.teamName,
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
                ],
              ),
            ),
            _buildDataCell('${standing.points}', isBold: true, color: AppColors.accent),
            _buildDataCell('${standing.gamesPlayed}'),
            _buildDataCell('${standing.wins}', color: AppColors.success),
            _buildDataCell('${standing.draws}'),
            _buildDataCell('${standing.losses}', color: standing.losses > 0 ? AppColors.error : null),
            _buildDataCell(
              '${standing.touchdownDiff >= 0 ? '+' : ''}${standing.touchdownDiff}',
              color: standing.touchdownDiff > 0
                  ? AppColors.success
                  : standing.touchdownDiff < 0
                      ? AppColors.error
                      : null,
            ),
            _buildDataCell('${standing.casualtiesFor}'),
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

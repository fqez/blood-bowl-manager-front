import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

enum _StandingsSortColumn {
  position,
  team,
  points,
  played,
  wins,
  draws,
  losses,
  touchdownDiff,
  casualties,
}

class StandingsTable extends ConsumerStatefulWidget {
  final List<LeagueStanding> standings;
  final String leagueId;
  final ValueChanged<LeagueStanding>? onTeamTap;

  const StandingsTable({
    super.key,
    required this.standings,
    required this.leagueId,
    this.onTeamTap,
  });

  @override
  ConsumerState<StandingsTable> createState() => _StandingsTableState();
}

class _StandingsTableState extends ConsumerState<StandingsTable> {
  _StandingsSortColumn _sortColumn = _StandingsSortColumn.position;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final defaultRankedStandings = _defaultRankedStandings(widget.standings);
    final rankByTeamId = <String, int>{};
    for (var index = 0; index < defaultRankedStandings.length; index++) {
      rankByTeamId[defaultRankedStandings[index].teamId] = index + 1;
    }
    final sortedStandings = _sortedStandings(
      widget.standings,
      rankByTeamId,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          _buildHeader(lang),
          ...sortedStandings.asMap().entries.map(
                (entry) => _buildTeamRow(
                  rankByTeamId[entry.value.teamId] ?? entry.key + 1,
                  entry.value,
                ),
              ),
        ],
      ),
    );
  }

  List<LeagueStanding> _defaultRankedStandings(List<LeagueStanding> source) {
    return List<LeagueStanding>.from(source)
      ..sort((a, b) {
        final pointsDiff = b.points.compareTo(a.points);
        if (pointsDiff != 0) return pointsDiff;
        final tdDiff = b.touchdownDiff.compareTo(a.touchdownDiff);
        if (tdDiff != 0) return tdDiff;
        final casualtiesDiff = b.casualtiesFor.compareTo(a.casualtiesFor);
        if (casualtiesDiff != 0) return casualtiesDiff;
        return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      });
  }

  List<LeagueStanding> _sortedStandings(
    List<LeagueStanding> source,
    Map<String, int> rankByTeamId,
  ) {
    final sorted = List<LeagueStanding>.from(source);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case _StandingsSortColumn.position:
          result = (rankByTeamId[a.teamId] ?? 9999)
              .compareTo(rankByTeamId[b.teamId] ?? 9999);
        case _StandingsSortColumn.team:
          result = a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
        case _StandingsSortColumn.points:
          result = a.points.compareTo(b.points);
        case _StandingsSortColumn.played:
          result = a.gamesPlayed.compareTo(b.gamesPlayed);
        case _StandingsSortColumn.wins:
          result = a.wins.compareTo(b.wins);
        case _StandingsSortColumn.draws:
          result = a.draws.compareTo(b.draws);
        case _StandingsSortColumn.losses:
          result = a.losses.compareTo(b.losses);
        case _StandingsSortColumn.touchdownDiff:
          result = a.touchdownDiff.compareTo(b.touchdownDiff);
        case _StandingsSortColumn.casualties:
          result = a.casualtiesFor.compareTo(b.casualtiesFor);
      }
      if (result == 0) {
        result = a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  void _setSort(_StandingsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column == _StandingsSortColumn.position ||
            column == _StandingsSortColumn.team;
      }
    });
  }

  Widget _buildHeader(String lang) {
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
            child: _buildHeaderButton(
              tr(lang, 'standings.pos'),
              _StandingsSortColumn.position,
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildHeaderButton(
              tr(lang, 'standings.team'),
              _StandingsSortColumn.team,
              align: TextAlign.left,
            ),
          ),
          _buildHeaderCell(
              tr(lang, 'standings.pts'), _StandingsSortColumn.points),
          _buildHeaderCell(
              tr(lang, 'standings.played'), _StandingsSortColumn.played),
          _buildHeaderCell(
              tr(lang, 'standings.wins'), _StandingsSortColumn.wins),
          _buildHeaderCell(
              tr(lang, 'standings.draws'), _StandingsSortColumn.draws),
          _buildHeaderCell(
              tr(lang, 'standings.losses'), _StandingsSortColumn.losses),
          _buildHeaderCell(
              tr(lang, 'standings.tdDiff'), _StandingsSortColumn.touchdownDiff),
          _buildHeaderCell(
              tr(lang, 'standings.cas'), _StandingsSortColumn.casualties),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, _StandingsSortColumn column) {
    return SizedBox(
      width: 40,
      child: _buildHeaderButton(
        text,
        column,
      ),
    );
  }

  Widget _buildHeaderButton(
    String text,
    _StandingsSortColumn column, {
    TextAlign align = TextAlign.center,
  }) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => _setSort(column),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: align == TextAlign.left
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.accent : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
                textAlign: align,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(int position, LeagueStanding standing) {
    final isUserTeam =
        position == 1; // Simplified - should check actual user team

    return InkWell(
      onTap:
          widget.onTeamTap == null ? null : () => widget.onTeamTap!(standing),
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
                            fontWeight:
                                isUserTeam ? FontWeight.bold : FontWeight.w500,
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
            _buildDataCell('${standing.points}',
                isBold: true, color: AppColors.accent),
            _buildDataCell('${standing.gamesPlayed}'),
            _buildDataCell('${standing.wins}', color: AppColors.success),
            _buildDataCell('${standing.draws}'),
            _buildDataCell('${standing.losses}',
                color: standing.losses > 0 ? AppColors.error : null),
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

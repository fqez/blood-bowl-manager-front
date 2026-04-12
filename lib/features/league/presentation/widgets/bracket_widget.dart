import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class BracketWidget extends StatelessWidget {
  final List<Match> matches;

  const BracketWidget({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.graph(PhosphorIconsStyle.light),
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Bracket no generado todavía',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text('Inicia la liga para generar los enfrentamientos',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    // Group matches by round
    final matchesByRound = <int, List<Match>>{};
    for (final m in matches) {
      matchesByRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = matchesByRound.keys.toList()..sort();
    final roundNames = _buildRoundNames(rounds, matchesByRound);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int ri = 0; ri < rounds.length; ri++) ...[
            if (ri > 0) const SizedBox(width: 8),
            _buildRoundColumn(
              context,
              roundName: roundNames[rounds[ri]] ?? 'Ronda ${rounds[ri]}',
              roundMatches: matchesByRound[rounds[ri]]!,
              totalRounds: rounds.length,
              roundIndex: ri,
            ),
          ],
        ],
      ),
    );
  }

  Map<int, String> _buildRoundNames(
      List<int> rounds, Map<int, List<Match>> byRound) {
    final total = rounds.length;
    final result = <int, String>{};
    for (int i = 0; i < total; i++) {
      final round = rounds[i];
      final remaining = total - i;
      if (remaining == 1) {
        result[round] = 'Final';
      } else if (remaining == 2) {
        result[round] = 'Semifinales';
      } else if (remaining == 3) {
        result[round] = 'Cuartos';
      } else if (remaining == 4) {
        result[round] = 'Octavos';
      } else {
        result[round] = 'Ronda $round';
      }
    }
    return result;
  }

  Widget _buildRoundColumn(
    BuildContext context, {
    required String roundName,
    required List<Match> roundMatches,
    required int totalRounds,
    required int roundIndex,
  }) {
    // Each subsequent round has fewer matches — space them out more
    final spacingFactor = 1 << roundIndex; // 1, 2, 4, 8 ...
    const matchCardHeight = 88.0;
    const matchSpacing = 8.0;
    final verticalPad = (spacingFactor - 1) * (matchCardHeight + matchSpacing) / 2;

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round header
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              roundName.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Match cards with vertical padding to align with next round
          for (int i = 0; i < roundMatches.length; i++) ...[
            if (i > 0) SizedBox(height: matchSpacing * spacingFactor),
            Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPad > 0 ? verticalPad : 0),
              child: _buildMatchCard(context, roundMatches[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Match match) {
    final isPlayed = match.isPlayed;
    final homeName = match.home.teamName;
    final awayName = match.away.teamName;
    String? homeScore;
    String? awayScore;
    bool homeWon = false;
    bool awayWon = false;

    if (isPlayed) {
      homeScore = '${match.scoreHome}';
      awayScore = '${match.scoreAway}';
      homeWon = match.scoreHome > match.scoreAway;
      awayWon = match.scoreAway > match.scoreHome;
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlayed
              ? AppColors.success.withOpacity(0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _teamRow(homeName, homeScore, homeWon, isTop: true),
          Container(height: 1, color: AppColors.surfaceLight),
          _teamRow(awayName, awayScore, awayWon, isTop: false),
        ],
      ),
    );
  }

  Widget _teamRow(
    String teamName,
    String? score,
    bool isWinner, {
    required bool isTop,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isWinner ? AppColors.success.withOpacity(0.08) : Colors.transparent,
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(9))
            : const BorderRadius.vertical(bottom: Radius.circular(9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: 12, color: AppColors.success),
            ),
          Expanded(
            child: Text(
              teamName.isEmpty ? '???' : teamName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isWinner
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                score,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

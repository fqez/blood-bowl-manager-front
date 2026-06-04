class LeagueDashboardStats {
  const LeagueDashboardStats({
    required this.leagueId,
    required this.leagueName,
    required this.generatedAt,
    required this.currentRound,
    required this.totalMatches,
    required this.playedMatches,
    required this.inProgressMatches,
    required this.scheduledMatches,
    required this.completionRatio,
    required this.totalTouchdowns,
    required this.totalCasualties,
    required this.avgTouchdownsPerMatch,
    required this.avgCasualtiesPerMatch,
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    required this.homeWinRate,
    required this.awayWinRate,
    required this.drawRate,
    required this.avgHomeTurnSeconds,
    required this.avgAwayTurnSeconds,
    required this.avgHomeRerollsUsed,
    required this.avgAwayRerollsUsed,
    required this.touchdownsByRound,
    required this.casualtiesByRound,
    required this.rounds,
    required this.outcomeDistribution,
    required this.scoreBucketDistribution,
    required this.eventTypeCounts,
    required this.injuryTypeCounts,
    required this.topByPoints,
    required this.topAttack,
    required this.topViolence,
  });

  final String leagueId;
  final String leagueName;
  final DateTime generatedAt;
  final int? currentRound;
  final int totalMatches;
  final int playedMatches;
  final int inProgressMatches;
  final int scheduledMatches;
  final double completionRatio;
  final int totalTouchdowns;
  final int totalCasualties;
  final double avgTouchdownsPerMatch;
  final double avgCasualtiesPerMatch;
  final int homeWins;
  final int awayWins;
  final int draws;
  final double homeWinRate;
  final double awayWinRate;
  final double drawRate;
  final double avgHomeTurnSeconds;
  final double avgAwayTurnSeconds;
  final double avgHomeRerollsUsed;
  final double avgAwayRerollsUsed;
  final List<int> touchdownsByRound;
  final List<int> casualtiesByRound;
  final List<LeagueDashboardRoundStats> rounds;
  final Map<String, int> outcomeDistribution;
  final Map<String, int> scoreBucketDistribution;
  final Map<String, int> eventTypeCounts;
  final Map<String, int> injuryTypeCounts;
  final List<LeagueDashboardTeamRow> topByPoints;
  final List<LeagueDashboardTeamRow> topAttack;
  final List<LeagueDashboardTeamRow> topViolence;

  factory LeagueDashboardStats.fromJson(Map<String, dynamic> json) {
    List<int> toIntList(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((entry) => entry is num ? entry.toInt() : 0)
          .toList(growable: false);
    }

    Map<String, int> toIntMap(dynamic value) {
      if (value is! Map<String, dynamic>) return const {};
      return value.map(
        (key, entry) => MapEntry(key, entry is num ? entry.toInt() : 0),
      );
    }

    List<LeagueDashboardTeamRow> toTeamRows(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(LeagueDashboardTeamRow.fromJson)
          .toList(growable: false);
    }

    List<LeagueDashboardRoundStats> toRoundStats(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(LeagueDashboardRoundStats.fromJson)
          .toList(growable: false);
    }

    double toDouble(dynamic value) => value is num ? value.toDouble() : 0;

    return LeagueDashboardStats(
      leagueId: (json['league_id'] as String?) ?? '',
      leagueName: (json['league_name'] as String?) ?? '',
      generatedAt: DateTime.tryParse((json['generated_at'] as String?) ?? '') ??
          DateTime.now(),
      currentRound: (json['current_round'] as num?)?.toInt(),
      totalMatches: (json['total_matches'] as num?)?.toInt() ?? 0,
      playedMatches: (json['played_matches'] as num?)?.toInt() ?? 0,
      inProgressMatches: (json['in_progress_matches'] as num?)?.toInt() ?? 0,
      scheduledMatches: (json['scheduled_matches'] as num?)?.toInt() ?? 0,
      completionRatio: toDouble(json['completion_ratio']),
      totalTouchdowns: (json['total_touchdowns'] as num?)?.toInt() ?? 0,
      totalCasualties: (json['total_casualties'] as num?)?.toInt() ?? 0,
      avgTouchdownsPerMatch: toDouble(json['avg_touchdowns_per_match']),
      avgCasualtiesPerMatch: toDouble(json['avg_casualties_per_match']),
      homeWins: (json['home_wins'] as num?)?.toInt() ?? 0,
      awayWins: (json['away_wins'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      homeWinRate: toDouble(json['home_win_rate']),
      awayWinRate: toDouble(json['away_win_rate']),
      drawRate: toDouble(json['draw_rate']),
      avgHomeTurnSeconds: toDouble(json['avg_home_turn_seconds']),
      avgAwayTurnSeconds: toDouble(json['avg_away_turn_seconds']),
      avgHomeRerollsUsed: toDouble(json['avg_home_rerolls_used']),
      avgAwayRerollsUsed: toDouble(json['avg_away_rerolls_used']),
      touchdownsByRound: toIntList(json['touchdowns_by_round']),
      casualtiesByRound: toIntList(json['casualties_by_round']),
      rounds: toRoundStats(json['rounds']),
      outcomeDistribution: toIntMap(json['outcome_distribution']),
      scoreBucketDistribution: toIntMap(json['score_bucket_distribution']),
      eventTypeCounts: toIntMap(json['event_type_counts']),
      injuryTypeCounts: toIntMap(json['injury_type_counts']),
      topByPoints: toTeamRows(json['top_by_points']),
      topAttack: toTeamRows(json['top_attack']),
      topViolence: toTeamRows(json['top_violence']),
    );
  }
}

class LeagueDashboardRoundStats {
  const LeagueDashboardRoundStats({
    required this.round,
    required this.matchesTotal,
    required this.matchesPlayed,
    required this.touchdowns,
    required this.casualties,
  });

  final int round;
  final int matchesTotal;
  final int matchesPlayed;
  final int touchdowns;
  final int casualties;

  factory LeagueDashboardRoundStats.fromJson(Map<String, dynamic> json) {
    return LeagueDashboardRoundStats(
      round: (json['round'] as num?)?.toInt() ?? 0,
      matchesTotal: (json['matches_total'] as num?)?.toInt() ?? 0,
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      touchdowns: (json['touchdowns'] as num?)?.toInt() ?? 0,
      casualties: (json['casualties'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeagueDashboardTeamRow {
  const LeagueDashboardTeamRow({
    required this.teamId,
    required this.teamName,
    required this.points,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.touchdownsFor,
    required this.touchdownsAgainst,
    required this.touchdownDiff,
    required this.casualtiesFor,
    required this.casualtiesAgainst,
    required this.winRate,
  });

  final String teamId;
  final String teamName;
  final int points;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int touchdownsFor;
  final int touchdownsAgainst;
  final int touchdownDiff;
  final int casualtiesFor;
  final int casualtiesAgainst;
  final double winRate;

  factory LeagueDashboardTeamRow.fromJson(Map<String, dynamic> json) {
    return LeagueDashboardTeamRow(
      teamId: (json['team_id'] as String?) ?? '',
      teamName: (json['team_name'] as String?) ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      touchdownsFor: (json['touchdowns_for'] as num?)?.toInt() ?? 0,
      touchdownsAgainst: (json['touchdowns_against'] as num?)?.toInt() ?? 0,
      touchdownDiff: (json['touchdown_diff'] as num?)?.toInt() ?? 0,
      casualtiesFor: (json['casualties_for'] as num?)?.toInt() ?? 0,
      casualtiesAgainst: (json['casualties_against'] as num?)?.toInt() ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

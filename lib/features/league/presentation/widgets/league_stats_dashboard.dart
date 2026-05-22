import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class LeagueStatsDashboard extends StatelessWidget {
  const LeagueStatsDashboard({
    super.key,
    required this.league,
    required this.matches,
  });

  final League league;
  final List<Match> matches;

  @override
  Widget build(BuildContext context) {
    final stats = _LeagueStats.from(league, matches);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final isCompact = constraints.maxWidth < 620;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(stats, isCompact),
              const SizedBox(height: 18),
              _MetricRail(stats: stats),
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _Panel(
                        title: 'Ritmo por jornada',
                        icon:
                            PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                        child: _LineChart(
                          series: [
                            _LineSeries(
                              label: 'Touchdowns',
                              color: AppColors.primary,
                              values: stats.touchdownsByRound,
                            ),
                            _LineSeries(
                              label: 'Bajas',
                              color: AppColors.warning,
                              values: stats.casualtiesByRound,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: _Panel(
                        title: 'Resultado de partidos',
                        icon: PhosphorIcons.chartDonut(PhosphorIconsStyle.fill),
                        child: _OutcomeDonut(stats: stats),
                      ),
                    ),
                  ],
                )
              else ...[
                _Panel(
                  title: 'Ritmo por jornada',
                  icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                  child: _LineChart(
                    series: [
                      _LineSeries(
                        label: 'Touchdowns',
                        color: AppColors.primary,
                        values: stats.touchdownsByRound,
                      ),
                      _LineSeries(
                        label: 'Bajas',
                        color: AppColors.warning,
                        values: stats.casualtiesByRound,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _Panel(
                  title: 'Resultado de partidos',
                  icon: PhosphorIcons.chartDonut(PhosphorIconsStyle.fill),
                  child: _OutcomeDonut(stats: stats),
                ),
              ],
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _TeamPodium(stats: stats)),
                    const SizedBox(width: 18),
                    Expanded(child: _ScoreShapeChart(stats: stats)),
                  ],
                )
              else ...[
                _TeamPodium(stats: stats),
                const SizedBox(height: 18),
                _ScoreShapeChart(stats: stats),
              ],
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _Panel(
                        title: 'Mapa de actividad',
                        icon:
                            PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                        child: _RoundBubbleChart(stats: stats),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 2,
                      child: _Panel(
                        title: 'Estado del calendario',
                        icon: PhosphorIcons.calendarCheck(
                            PhosphorIconsStyle.fill),
                        child: _CalendarRadialStatus(stats: stats),
                      ),
                    ),
                  ],
                )
              else ...[
                _Panel(
                  title: 'Mapa de actividad',
                  icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                  child: _RoundBubbleChart(stats: stats),
                ),
                const SizedBox(height: 18),
                _Panel(
                  title: 'Estado del calendario',
                  icon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.fill),
                  child: _CalendarRadialStatus(stats: stats),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(_LeagueStats stats, bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.20),
            AppColors.card,
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DASHBOARD DE LIGA',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: isCompact ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Radiografia competitiva: marcadores, violencia, ritmo por jornada y rendimiento de equipos.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _CompletionGauge(stats: stats),
        ],
      ),
    );
  }
}

class _LeagueStats {
  const _LeagueStats({
    required this.league,
    required this.matches,
    required this.played,
    required this.scheduled,
    required this.inProgress,
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    required this.totalTouchdowns,
    required this.totalCasualties,
    required this.touchdownsByRound,
    required this.casualtiesByRound,
    required this.roundIntensity,
    required this.scoreBuckets,
  });

  final League league;
  final List<Match> matches;
  final List<Match> played;
  final int scheduled;
  final int inProgress;
  final int homeWins;
  final int awayWins;
  final int draws;
  final int totalTouchdowns;
  final int totalCasualties;
  final List<double> touchdownsByRound;
  final List<double> casualtiesByRound;
  final List<_RoundIntensity> roundIntensity;
  final Map<String, int> scoreBuckets;

  factory _LeagueStats.from(League league, List<Match> matches) {
    final played = matches.where((match) => match.isPlayed).toList();
    final scheduled = matches.where((match) => match.isPending).length;
    final inProgress = matches.where((match) => match.isInProgress).length;
    final homeWins = played.where((m) => m.scoreHome > m.scoreAway).length;
    final awayWins = played.where((m) => m.scoreAway > m.scoreHome).length;
    final draws = played.where((m) => m.scoreHome == m.scoreAway).length;
    final totalTouchdowns = played.fold<int>(
      0,
      (sum, match) => sum + match.scoreHome + match.scoreAway,
    );
    final totalCasualties = league.standings.fold<int>(
      0,
      (sum, standing) => sum + standing.casualtiesFor,
    );
    final maxRound = math.max(
      league.maxRounds,
      matches.isEmpty
          ? 0
          : matches.map((match) => match.round).reduce(math.max),
    );
    final touchdownsByRound = List<double>.filled(maxRound, 0);
    final casualtiesByRound = List<double>.filled(maxRound, 0);
    final casualtiesPerGame =
        played.isEmpty ? 0 : totalCasualties / played.length;
    final scoreBuckets = {'Cerrados': 0, 'Medios': 0, 'Festival': 0};

    for (final match in played) {
      final roundIndex = match.round - 1;
      if (roundIndex >= 0 && roundIndex < touchdownsByRound.length) {
        touchdownsByRound[roundIndex] += match.scoreHome + match.scoreAway;
        casualtiesByRound[roundIndex] += casualtiesPerGame;
      }

      final totalScore = match.scoreHome + match.scoreAway;
      if (totalScore <= 1) {
        scoreBuckets['Cerrados'] = scoreBuckets['Cerrados']! + 1;
      } else if (totalScore <= 3) {
        scoreBuckets['Medios'] = scoreBuckets['Medios']! + 1;
      } else {
        scoreBuckets['Festival'] = scoreBuckets['Festival']! + 1;
      }
    }

    final roundIntensity = List.generate(maxRound, (index) {
      final round = index + 1;
      final roundMatches =
          matches.where((match) => match.round == round).toList();
      final playedRound =
          roundMatches.where((match) => match.isPlayed).toList();
      final touchdowns = playedRound.fold<int>(
        0,
        (sum, match) => sum + match.scoreHome + match.scoreAway,
      );
      return _RoundIntensity(
        round: round,
        matches: roundMatches.length,
        played: playedRound.length,
        touchdowns: touchdowns,
      );
    });

    return _LeagueStats(
      league: league,
      matches: matches,
      played: played,
      scheduled: scheduled,
      inProgress: inProgress,
      homeWins: homeWins,
      awayWins: awayWins,
      draws: draws,
      totalTouchdowns: totalTouchdowns,
      totalCasualties: totalCasualties,
      touchdownsByRound: touchdownsByRound,
      casualtiesByRound: casualtiesByRound,
      roundIntensity: roundIntensity,
      scoreBuckets: scoreBuckets,
    );
  }

  int get totalMatches => matches.length;
  int get playedMatches => played.length;
  int get remainingMatches => scheduled + inProgress;
  double get completion => totalMatches == 0 ? 0 : playedMatches / totalMatches;
  double get averageTouchdowns =>
      playedMatches == 0 ? 0 : totalTouchdowns / playedMatches;
  double get averageCasualties =>
      playedMatches == 0 ? 0 : totalCasualties / playedMatches;
  double get homeWinRate =>
      playedMatches == 0 ? 0 : homeWins / playedMatches * 100;
  double get awayWinRate =>
      playedMatches == 0 ? 0 : awayWins / playedMatches * 100;
  double get drawRate => playedMatches == 0 ? 0 : draws / playedMatches * 100;

  List<LeagueStanding> get pointsLeaders => _sortedBy((s) => s.points);
  List<LeagueStanding> get attackLeaders => _sortedBy((s) => s.touchdownsFor);
  List<LeagueStanding> get defenseLeaders =>
      _sortedBy((s) => -s.touchdownsAgainst);
  List<LeagueStanding> get casualtyLeaders => _sortedBy((s) => s.casualtiesFor);

  int get maxPoints =>
      league.standings.fold<int>(0, (max, s) => math.max(max, s.points));
  int get maxTouchdownsFor =>
      league.standings.fold<int>(0, (max, s) => math.max(max, s.touchdownsFor));
  int get maxCasualtiesFor =>
      league.standings.fold<int>(0, (max, s) => math.max(max, s.casualtiesFor));
  int get maxTouchdownsAgainst => league.standings
      .fold<int>(0, (max, s) => math.max(max, s.touchdownsAgainst));

  List<LeagueStanding> _sortedBy(num Function(LeagueStanding) value) {
    final copy = List<LeagueStanding>.from(league.standings);
    copy.sort((a, b) => value(b).compareTo(value(a)));
    return copy;
  }
}

class _RoundIntensity {
  const _RoundIntensity({
    required this.round,
    required this.matches,
    required this.played,
    required this.touchdowns,
  });

  final int round;
  final int matches;
  final int played;
  final int touchdowns;
}

class _MetricRail extends StatelessWidget {
  const _MetricRail({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricPuckData(
        label: 'TD',
        value: '${stats.totalTouchdowns}',
        detail: '${stats.averageTouchdowns.toStringAsFixed(1)} / partido',
        icon: PhosphorIcons.target(PhosphorIconsStyle.fill),
        color: AppColors.primary,
      ),
      _MetricPuckData(
        label: 'CAS',
        value: '${stats.totalCasualties}',
        detail: '${stats.averageCasualties.toStringAsFixed(1)} / partido',
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        color: AppColors.warning,
      ),
      _MetricPuckData(
        label: 'Local',
        value: '${stats.homeWinRate.toStringAsFixed(0)}%',
        detail: '${stats.homeWins} victorias',
        icon: PhosphorIcons.houseLine(PhosphorIconsStyle.fill),
        color: AppColors.success,
      ),
      _MetricPuckData(
        label: 'Visitante',
        value: '${stats.awayWinRate.toStringAsFixed(0)}%',
        detail: '${stats.awayWins} victorias',
        icon: PhosphorIcons.airplaneTilt(PhosphorIconsStyle.fill),
        color: AppColors.skillPassing,
      ),
      _MetricPuckData(
        label: 'Empates',
        value: '${stats.drawRate.toStringAsFixed(0)}%',
        detail: '${stats.draws} partidos',
        icon: PhosphorIcons.handshake(PhosphorIconsStyle.fill),
        color: AppColors.accent,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: items.map((item) => _MetricPuck(data: item)).toList(),
      ),
    );
  }
}

class _MetricPuckData {
  const _MetricPuckData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _MetricPuck extends StatelessWidget {
  const _MetricPuck({required this.data});

  final _MetricPuckData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withValues(alpha: 0.13),
              border: Border.all(color: data.color.withValues(alpha: 0.45)),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  data.value,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPodium extends StatelessWidget {
  const _TeamPodium({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final top = stats.pointsLeaders.take(3).toList();
    final attack =
        stats.attackLeaders.isEmpty ? null : stats.attackLeaders.first;
    final casualties =
        stats.casualtyLeaders.isEmpty ? null : stats.casualtyLeaders.first;
    final defense =
        stats.defenseLeaders.isEmpty ? null : stats.defenseLeaders.first;

    return _Panel(
      title: 'Equipos destacados',
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      child: Column(
        children: [
          SizedBox(
            height: 218,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top.length > 1)
                  Expanded(
                    child: _PodiumStep(
                      standing: top[1],
                      place: 2,
                      height: 122,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (top.isNotEmpty)
                  Expanded(
                    child: _PodiumStep(
                      standing: top[0],
                      place: 1,
                      height: 154,
                      color: AppColors.accent,
                    ),
                  ),
                if (top.length > 2)
                  Expanded(
                    child: _PodiumStep(
                      standing: top[2],
                      place: 3,
                      height: 104,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (attack != null)
                _SpotlightChip(
                  label: 'Ataque',
                  team: attack.teamName,
                  value: '${attack.touchdownsFor} TD',
                  color: AppColors.primary,
                ),
              if (casualties != null)
                _SpotlightChip(
                  label: 'Bajas',
                  team: casualties.teamName,
                  value: '${casualties.casualtiesFor} CAS',
                  color: AppColors.warning,
                ),
              if (defense != null)
                _SpotlightChip(
                  label: 'Defensa',
                  team: defense.teamName,
                  value: '${defense.touchdownsAgainst} enc.',
                  color: AppColors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({
    required this.standing,
    required this.place,
    required this.height,
    required this.color,
  });

  final LeagueStanding standing;
  final int place;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                '$place',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.42)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  standing.teamName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${standing.points} pts',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  const _SpotlightChip({
    required this.label,
    required this.team,
    required this.value,
    required this.color,
  });

  final String label;
  final String team;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              color: color,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreShapeChart extends StatelessWidget {
  const _ScoreShapeChart({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Cerrados', stats.scoreBuckets['Cerrados'] ?? 0, AppColors.info),
      ('Medios', stats.scoreBuckets['Medios'] ?? 0, AppColors.accent),
      ('Festival', stats.scoreBuckets['Festival'] ?? 0, AppColors.primary),
    ];

    return _Panel(
      title: 'Forma de los marcadores',
      icon: PhosphorIcons.chartPieSlice(PhosphorIconsStyle.fill),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Center(
              child: SizedBox.square(
                dimension: 170,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values:
                        entries.map((entry) => entry.$2.toDouble()).toList(),
                    colors: entries.map((entry) => entry.$3).toList(),
                    gapRadians: 0.055,
                  ),
                  child: Center(
                    child: Text(
                      '${stats.playedMatches}',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: entries
                .map((entry) => _ScoreBubble(
                      label: entry.$1,
                      value: entry.$2,
                      color: entry.$3,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 98,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CompletionGauge extends StatelessWidget {
  const _CompletionGauge({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final percent = (stats.completion * 100).round();

    return SizedBox(
      width: 190,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [
                  stats.playedMatches.toDouble(),
                  stats.remainingMatches.toDouble()
                ],
                colors: const [AppColors.success, AppColors.surfaceLight],
                gapRadians: 0.035,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progreso',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.playedMatches}/${stats.totalMatches}',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    height: 1,
                  ),
                ),
                const Text(
                  'partidos',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeDonut extends StatelessWidget {
  const _OutcomeDonut({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final values = [
      stats.homeWins.toDouble(),
      stats.awayWins.toDouble(),
      stats.draws.toDouble(),
    ];
    final colors = [
      AppColors.success,
      AppColors.skillPassing,
      AppColors.accent
    ];
    final labels = [
      ('Local', stats.homeWins, AppColors.success),
      ('Visitante', stats.awayWins, AppColors.skillPassing),
      ('Empate', stats.draws, AppColors.accent),
    ];

    return Row(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: CustomPaint(
            painter: _DonutPainter(values: values, colors: colors),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${stats.playedMatches}',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'jugados',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: labels
                .map((item) => _LegendRow(
                      label: item.$1,
                      value: '${item.$2}',
                      color: item.$3,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarRadialStatus extends StatelessWidget {
  const _CalendarRadialStatus({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final total = math.max(stats.totalMatches, 1);
    final rings = [
      _RingData(
        label: 'Jugados',
        value: stats.playedMatches,
        percent: stats.playedMatches / total,
        color: AppColors.success,
      ),
      _RingData(
        label: 'En curso',
        value: stats.inProgress,
        percent: stats.inProgress / total,
        color: AppColors.warning,
      ),
      _RingData(
        label: 'Pendientes',
        value: stats.scheduled,
        percent: stats.scheduled / total,
        color: AppColors.info,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _MultiRingPainter(rings: rings),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(stats.completion * 100).round()}%',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'avance',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: rings
              .map((ring) => _LegendRow(
                    label: ring.label,
                    value: '${ring.value}',
                    color: ring.color,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RingData {
  const _RingData({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final int value;
  final double percent;
  final Color color;
}

class _RoundBubbleChart extends StatelessWidget {
  const _RoundBubbleChart({required this.stats});

  final _LeagueStats stats;

  @override
  Widget build(BuildContext context) {
    final maxTouchdowns = stats.roundIntensity.fold<int>(
      0,
      (max, round) => math.max(max, round.touchdowns),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.roundIntensity
          .map(
            (round) => _RoundBubble(
              round: round,
              maxTouchdowns: math.max(maxTouchdowns, 1),
            ),
          )
          .toList(),
    );
  }
}

class _RoundBubble extends StatelessWidget {
  const _RoundBubble({
    required this.round,
    required this.maxTouchdowns,
  });

  final _RoundIntensity round;
  final int maxTouchdowns;

  @override
  Widget build(BuildContext context) {
    final intensity = round.touchdowns / maxTouchdowns;
    final color = Color.lerp(AppColors.info, AppColors.primary, intensity) ??
        AppColors.primary;
    final diameter = 62.0 + intensity * 26.0;

    return SizedBox(
      width: 96,
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border:
                  Border.all(color: color.withValues(alpha: 0.65), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${round.touchdowns}',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'J${round.round}  ${round.played}/${round.matches}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineSeries {
  const _LineSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.series});

  final List<_LineSeries> series;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 240,
          child: CustomPaint(
            painter: _LineChartPainter(series: series),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: series
              .map((item) => _LegendRow(
                    label: item.label,
                    value: '',
                    color: item.color,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    this.gapRadians = 0.02,
  });

  final List<double> values;
  final List<Color> colors;
  final double gapRadians;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    final strokeWidth = math.min(size.width, size.height) * 0.15;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      paint.color = AppColors.surfaceLight;
      canvas.drawArc(rect.deflate(strokeWidth / 2), -math.pi / 2, math.pi * 2,
          false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / total) * math.pi * 2;
      if (sweep <= 0) continue;
      paint.color = colors[index % colors.length];
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start + gapRadians,
        math.max(0, sweep - gapRadians * 2),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _MultiRingPainter extends CustomPainter {
  const _MultiRingPainter({required this.rings});

  final List<_RingData> rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 18;
    const strokeWidth = 10.0;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceLight;

    for (var index = 0; index < rings.length; index++) {
      final ring = rings[index];
      final radius = baseRadius - index * 20;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(center, radius, backgroundPaint);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = ring.color;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ring.percent.clamp(0.0, 1.0),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiRingPainter oldDelegate) {
    return oldDelegate.rings != rings;
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.series});

  final List<_LineSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const right = 12.0;
    const top = 14.0;
    const bottom = 26.0;
    final chart =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final allValues = series.expand((item) => item.values).toList();
    final maxValue =
        math.max(1.0, allValues.isEmpty ? 1.0 : allValues.reduce(math.max));
    final maxPoints =
        series.fold<int>(0, (max, item) => math.max(max, item.values.length));

    final gridPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * (i / 4);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      labelPainter.text = TextSpan(
        text: (maxValue * i / 4).round().toString(),
        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(0, y - labelPainter.height / 2));
    }

    for (final item in series) {
      if (item.values.isEmpty) continue;
      final path = Path();
      final points = <Offset>[];
      for (var index = 0; index < item.values.length; index++) {
        final x = maxPoints <= 1
            ? chart.left
            : chart.left + chart.width * (index / (maxPoints - 1));
        final y = chart.bottom - chart.height * (item.values[index] / maxValue);
        final point = Offset(x, y);
        points.add(point);
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final paint = Paint()
        ..color = item.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);

      final dotPaint = Paint()..color = item.color;
      for (final point in points) {
        canvas.drawCircle(point, 4, dotPaint);
      }
    }

    for (var index = 0; index < maxPoints; index++) {
      final x = maxPoints <= 1
          ? chart.left
          : chart.left + chart.width * (index / (maxPoints - 1));
      labelPainter.text = TextSpan(
        text: 'J${index + 1}',
        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
      );
      labelPainter.layout();
      labelPainter.paint(
          canvas, Offset(x - labelPainter.width / 2, chart.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

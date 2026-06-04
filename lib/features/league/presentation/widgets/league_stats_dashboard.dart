import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league_dashboard_stats.dart';

class LeagueStatsDashboard extends StatelessWidget {
  const LeagueStatsDashboard({super.key, required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1180;
        final isCompact = constraints.maxWidth < 720;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHero(stats: stats),
              const SizedBox(height: 16),
              _KpiWrap(stats: stats),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _RoundTrendPanel(stats: stats)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _MatchOutcomePanel(stats: stats)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _TopTeamsPanel(stats: stats)),
                  ],
                )
              else ...[
                _RoundTrendPanel(stats: stats),
                const SizedBox(height: 16),
                _MatchOutcomePanel(stats: stats),
                const SizedBox(height: 16),
                _TopTeamsPanel(stats: stats),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _EventBarsPanel(stats: stats)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _InjuryBubblesPanel(stats: stats)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _PaceAndResourcesPanel(stats: stats)),
                  ],
                )
              else ...[
                _EventBarsPanel(stats: stats),
                const SizedBox(height: 16),
                _InjuryBubblesPanel(stats: stats),
                const SizedBox(height: 16),
                _PaceAndResourcesPanel(stats: stats),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final completion = (stats.completionRatio * 100).clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            AppColors.accent.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroIntro(stats: stats),
                const SizedBox(height: 16),
                _HeroProgress(stats: stats, completion: completion),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _HeroIntro(stats: stats)),
              const SizedBox(width: 20),
              Flexible(child: _HeroProgress(stats: stats, completion: completion)),
            ],
          );
        },
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard de liga',
          style: TextStyle(
            fontFamily: AppTypography.displayFontFamily,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stats.leagueName,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroChip(
              icon: PhosphorIcons.flagCheckered(PhosphorIconsStyle.fill),
              label: 'Jornada actual',
              value: stats.currentRound?.toString() ?? '-',
            ),
            _HeroChip(
              icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
              label: 'Touchdowns',
              value: '${stats.totalTouchdowns}',
            ),
            _HeroChip(
              icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
              label: 'Bajas',
              value: '${stats.totalCasualties}',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({required this.stats, required this.completion});

  final LeagueDashboardStats stats;
  final double completion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso de temporada',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: completion / 100,
                      strokeWidth: 9,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                    Center(
                      child: Text(
                        '${completion.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatLine(
                      label: 'Jugados',
                      value: '${stats.playedMatches}/${stats.totalMatches}',
                    ),
                    _StatLine(
                      label: 'En juego',
                      value: '${stats.inProgressMatches}',
                    ),
                    _StatLine(
                      label: 'Pendientes',
                      value: '${stats.scheduledMatches}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiWrap extends StatelessWidget {
  const _KpiWrap({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _KpiMetric(
        label: 'Partidos jugados',
        value: '${stats.playedMatches}',
        subtext: '${stats.scheduledMatches} pendientes',
        color: AppColors.info,
      ),
      _KpiMetric(
        label: 'TD por partido',
        value: stats.avgTouchdownsPerMatch.toStringAsFixed(2),
        subtext: '${stats.totalTouchdowns} en total',
        color: AppColors.primary,
      ),
      _KpiMetric(
        label: 'CAS por partido',
        value: stats.avgCasualtiesPerMatch.toStringAsFixed(2),
        subtext: '${stats.totalCasualties} en total',
        color: AppColors.warning,
      ),
      _KpiMetric(
        label: 'Victoria local',
        value: '${stats.homeWinRate.toStringAsFixed(1)}%',
        subtext: '${stats.homeWins} partidos',
        color: AppColors.success,
      ),
      _KpiMetric(
        label: 'Victoria visitante',
        value: '${stats.awayWinRate.toStringAsFixed(1)}%',
        subtext: '${stats.awayWins} partidos',
        color: AppColors.accent,
      ),
      _KpiMetric(
        label: 'Empates',
        value: '${stats.drawRate.toStringAsFixed(1)}%',
        subtext: '${stats.draws} partidos',
        color: AppColors.textSecondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 1320
            ? (width - 60) / 6
            : width >= 940
                ? (width - 24) / 3
                : width >= 560
                    ? (width - 12) / 2
                    : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _KpiMetric {
  const _KpiMetric({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
  });

  final String label;
  final String value;
  final String subtext;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.metric});

  final _KpiMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: TextStyle(
              color: metric.color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.subtext,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundTrendPanel extends StatelessWidget {
  const _RoundTrendPanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Ritmo por jornada',
      icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendChip(color: AppColors.primary, label: 'Touchdowns'),
              _LegendChip(color: AppColors.warning, label: 'Bajas'),
            ],
          ),
          const SizedBox(height: 14),
          if (stats.rounds.isEmpty)
            const SizedBox(
              height: 240,
              child: Center(child: _EmptyText('Sin jornadas registradas.')),
            )
          else ...[
            SizedBox(
              height: 210,
              child: CustomPaint(
                painter: _RoundTrendPainter(
                  touchdowns: stats.touchdownsByRound,
                  casualties: stats.casualtiesByRound,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 10),
            _RoundAxisLabels(rounds: stats.rounds),
          ],
        ],
      ),
    );
  }
}

class _RoundAxisLabels extends StatelessWidget {
  const _RoundAxisLabels({required this.rounds});

  final List<LeagueDashboardRoundStats> rounds;

  @override
  Widget build(BuildContext context) {
    final step = rounds.length > 10
        ? 3
        : rounds.length > 6
            ? 2
            : 1;

    return Row(
      children: [
        for (var index = 0; index < rounds.length; index++)
          Expanded(
            child: Text(
              index % step == 0 ? 'J${rounds[index].round}' : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchOutcomePanel extends StatelessWidget {
  const _MatchOutcomePanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final slices = [
      _ChartSlice(
        value: stats.outcomeDistribution['home_win'] ?? 0,
        color: AppColors.success,
        label: 'Local',
      ),
      _ChartSlice(
        value: stats.outcomeDistribution['draw'] ?? 0,
        color: AppColors.info,
        label: 'Empate',
      ),
      _ChartSlice(
        value: stats.outcomeDistribution['away_win'] ?? 0,
        color: AppColors.accent,
        label: 'Visitante',
      ),
    ];

    return _DashboardPanel(
      title: 'Resultado de partidos',
      icon: PhosphorIcons.chartDonut(PhosphorIconsStyle.fill),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(210),
                  painter: _DonutChartPainter(slices: slices),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.playedMatches}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'jugados',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final slice in slices)
            _LegendRow(
              color: slice.color,
              label: slice.label,
              value: '${slice.value}',
            ),
          const Divider(color: AppColors.surfaceLight, height: 22),
          _CategoryBarStrip(
            title: 'Forma de marcador',
            items: [
              _BarCategory(
                label: 'Cerrados',
                value: stats.scoreBucketDistribution['closed'] ?? 0,
                color: AppColors.info,
              ),
              _BarCategory(
                label: 'Medios',
                value: stats.scoreBucketDistribution['balanced'] ?? 0,
                color: AppColors.warning,
              ),
              _BarCategory(
                label: 'Festivales',
                value: stats.scoreBucketDistribution['shootout'] ?? 0,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopTeamsPanel extends StatelessWidget {
  const _TopTeamsPanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final maxPoints = stats.topByPoints.isEmpty ? 1 : stats.topByPoints.first.points;
    final attackLeader = stats.topAttack.isEmpty ? null : stats.topAttack.first;
    final violenceLeader = stats.topViolence.isEmpty ? null : stats.topViolence.first;

    return _DashboardPanel(
      title: 'Clasificacion rapida',
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top por puntos',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (stats.topByPoints.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(child: _EmptyText('Sin equipos clasificados.')),
            )
          else
            for (var i = 0; i < stats.topByPoints.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TeamBarRow(
                  rank: i + 1,
                  team: stats.topByPoints[i],
                  color: i == 0 ? AppColors.accent : AppColors.primary,
                  ratio: maxPoints == 0 ? 0 : stats.topByPoints[i].points / maxPoints,
                  trailing: '${stats.topByPoints[i].points} pts',
                ),
              ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 300;
              if (compact) {
                return Column(
                  children: [
                    _LeaderHighlight(
                      title: 'Mejor ataque',
                      icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
                      value: attackLeader == null
                          ? '-'
                          : '${attackLeader.teamName} · ${attackLeader.touchdownsFor} TD',
                    ),
                    const SizedBox(height: 10),
                    _LeaderHighlight(
                      title: 'Mas violento',
                      icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
                      value: violenceLeader == null
                          ? '-'
                          : '${violenceLeader.teamName} · ${violenceLeader.casualtiesFor} CAS',
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _LeaderHighlight(
                      title: 'Mejor ataque',
                      icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
                      value: attackLeader == null
                          ? '-'
                          : '${attackLeader.teamName} · ${attackLeader.touchdownsFor} TD',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LeaderHighlight(
                      title: 'Mas violento',
                      icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
                      value: violenceLeader == null
                          ? '-'
                          : '${violenceLeader.teamName} · ${violenceLeader.casualtiesFor} CAS',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventBarsPanel extends StatelessWidget {
  const _EventBarsPanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final topEvents = _topEntries(stats.eventTypeCounts, 6);

    return _DashboardPanel(
      title: 'Eventos mas registrados',
      icon: PhosphorIcons.chartBarHorizontal(PhosphorIconsStyle.fill),
      child: topEvents.isEmpty
          ? const SizedBox(
              height: 260,
              child: Center(child: _EmptyText('No hay eventos registrados.')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 210,
                  child: _VerticalBarChart(items: [
                    for (final entry in topEvents)
                      _BarCategory(
                        label: _compactLabel(entry.key),
                        value: entry.value,
                        color: AppColors.primary,
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final entry in topEvents)
                      _MiniPill(
                        label: _labelize(entry.key),
                        value: '${entry.value}',
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InjuryBubblesPanel extends StatelessWidget {
  const _InjuryBubblesPanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final topInjuries = _topEntries(stats.injuryTypeCounts, 6);
    final maxValue = topInjuries.isEmpty ? 1 : topInjuries.first.value;

    return _DashboardPanel(
      title: 'Mapa de lesiones',
      icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
      child: topInjuries.isEmpty
          ? const SizedBox(
              height: 260,
              child: Center(child: _EmptyText('No hay lesiones registradas.')),
            )
          : SizedBox(
              height: 260,
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final entry in topInjuries)
                      _BubbleStat(
                        label: _compactLabel(entry.key),
                        value: entry.value,
                        ratio: entry.value / maxValue,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PaceAndResourcesPanel extends StatelessWidget {
  const _PaceAndResourcesPanel({required this.stats});

  final LeagueDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Ritmo y recursos',
      icon: PhosphorIcons.timer(PhosphorIconsStyle.fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 260;
              if (compact) {
                return Column(
                  children: [
                    _MiniMetricCard(
                      title: 'Seg/turno local',
                      value: stats.avgHomeTurnSeconds.toStringAsFixed(1),
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 10),
                    _MiniMetricCard(
                      title: 'Seg/turno visita',
                      value: stats.avgAwayTurnSeconds.toStringAsFixed(1),
                      color: AppColors.accent,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Seg/turno local',
                      value: stats.avgHomeTurnSeconds.toStringAsFixed(1),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Seg/turno visita',
                      value: stats.avgAwayTurnSeconds.toStringAsFixed(1),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _DualProgressRow(
            label: 'Rerolls usados',
            leftValue: stats.avgHomeRerollsUsed,
            rightValue: stats.avgAwayRerollsUsed,
            leftColor: AppColors.info,
            rightColor: AppColors.accent,
          ),
          const SizedBox(height: 12),
          _DualProgressRow(
            label: 'Ritmo por turno',
            leftValue: stats.avgHomeTurnSeconds,
            rightValue: stats.avgAwayTurnSeconds,
            leftColor: AppColors.info,
            rightColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBarStrip extends StatelessWidget {
  const _CategoryBarStrip({required this.title, required this.items});

  final String title;
  final List<_BarCategory> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    flex: math.max(1, item.value),
                    child: Container(color: item.color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          _LegendRow(
            color: item.color,
            label: item.label,
            value: total == 0
                ? '0'
                : '${item.value} (${((item.value / total) * 100).toStringAsFixed(1)}%)',
          ),
      ],
    );
  }
}

class _TeamBarRow extends StatelessWidget {
  const _TeamBarRow({
    required this.rank,
    required this.team,
    required this.color,
    required this.ratio,
    required this.trailing,
  });

  final int rank;
  final LeagueDashboardTeamRow team;
  final Color color;
  final double ratio;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                team.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            backgroundColor: AppColors.surfaceLight,
            color: color,
            value: ratio.clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }
}

class _LeaderHighlight extends StatelessWidget {
  const _LeaderHighlight({
    required this.title,
    required this.icon,
    required this.value,
  });

  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BubbleStat extends StatelessWidget {
  const _BubbleStat({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final int value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final size = 56 + (ratio.clamp(0.15, 1.0) * 34);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.warning.withValues(alpha: 0.90),
                AppColors.error.withValues(alpha: 0.82),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualProgressRow extends StatelessWidget {
  const _DualProgressRow({
    required this.label,
    required this.leftValue,
    required this.rightValue,
    required this.leftColor,
    required this.rightColor,
  });

  final String label;
  final double leftValue;
  final double rightValue;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1.0, math.max(leftValue, rightValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _SingleProgress(
          value: leftValue,
          maxValue: maxValue,
          color: leftColor,
          trailing: leftValue.toStringAsFixed(1),
        ),
        const SizedBox(height: 8),
        _SingleProgress(
          value: rightValue,
          maxValue: maxValue,
          color: rightColor,
          trailing: rightValue.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class _SingleProgress extends StatelessWidget {
  const _SingleProgress({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.trailing,
  });

  final double value;
  final double maxValue;
  final Color color;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              color: color,
              value: (value / maxValue).clamp(0.0, 1.0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            trailing,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalBarChart extends StatelessWidget {
  const _VerticalBarChart({required this.items});

  final List<_BarCategory> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items.map((item) => item.value).reduce(math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${item.value}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxValue == 0 ? 0 : item.value / maxValue,
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BarCategory {
  const _BarCategory({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ChartSlice {
  const _ChartSlice({
    required this.value,
    required this.color,
    required this.label,
  });

  final int value;
  final Color color;
  final String label;
}

class _RoundTrendPainter extends CustomPainter {
  const _RoundTrendPainter({
    required this.touchdowns,
    required this.casualties,
  });

  final List<int> touchdowns;
  final List<int> casualties;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const top = 8.0;
    const bottomPad = 10.0;
    final right = size.width - 8.0;
    final bottom = size.height - bottomPad;
    final width = right - left;
    final height = bottom - top;

    final gridPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = top + (height / 3) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final count = math.max(touchdowns.length, casualties.length);
    if (count == 0) {
      return;
    }

    final maxValue = [1, ...touchdowns, ...casualties].reduce(math.max).toDouble();
    final step = count == 1 ? 0.0 : width / (count - 1);
    final barWidth = math.min(22.0, width / math.max(count * 1.9, 2));

    final barPaint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final value = i < casualties.length ? casualties[i].toDouble() : 0.0;
      final x = count == 1 ? left + (width / 2) : left + (step * i);
      final barHeight = (value / maxValue) * (height - 6);
      final rect = Rect.fromLTWH(
        x - (barWidth / 2),
        bottom - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        barPaint,
      );
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (var i = 0; i < count; i++) {
      final value = i < touchdowns.length ? touchdowns[i].toDouble() : 0.0;
      final x = count == 1 ? left + (width / 2) : left + (step * i);
      final y = bottom - ((value / maxValue) * (height - 10));
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = AppColors.primary;
    final innerPointPaint = Paint()..color = AppColors.textPrimary;
    for (var i = 0; i < count; i++) {
      final value = i < touchdowns.length ? touchdowns[i].toDouble() : 0.0;
      final x = count == 1 ? left + (width / 2) : left + (step * i);
      final y = bottom - ((value / maxValue) * (height - 10));
      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, innerPointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoundTrendPainter oldDelegate) {
    return oldDelegate.touchdowns != touchdowns ||
        oldDelegate.casualties != casualties;
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.slices});

  final List<_ChartSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, basePaint);

    if (total == 0) {
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) {
        continue;
      }
      final sweepAngle = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );
  }
}

List<MapEntry<String, int>> _topEntries(Map<String, int> map, int limit) {
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(limit).toList(growable: false);
}

String _compactLabel(String raw) {
  final label = _labelize(raw);
  if (label.length <= 10) {
    return label;
  }
  return label.split(' ').take(2).join('\n');
}

String _labelize(String raw) {
  return raw
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league.dart';
import '../widgets/standings_table.dart';
import '../widgets/match_card.dart';
import '../widgets/activity_feed.dart';

// Providers
final leagueProvider = FutureProvider.family<League, String>((ref, leagueId) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeague(leagueId);
});

final matchesProvider = FutureProvider.family<List<Match>, String>((ref, leagueId) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeagueMatches(leagueId);
});

class LeagueOverviewScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueOverviewScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueOverviewScreen> createState() => _LeagueOverviewScreenState();
}

class _LeagueOverviewScreenState extends ConsumerState<LeagueOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueProvider(widget.leagueId));
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(leagueAsync),
      body: leagueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (league) => Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStandingsTab(league, isWideScreen),
                  _buildCalendarTab(league),
                  _buildCurrentRoundTab(league, isWideScreen),
                  _buildStatsTab(league),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AsyncValue<League> leagueAsync) {
    return AppBar(
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular)),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Row(
        children: [
          Text(
            leagueAsync.valueOrNull?.name ?? 'Liga',
            style: TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          if (leagueAsync.valueOrNull != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Temporada ${leagueAsync.value!.currentSeason}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: leagueAsync.value!.currentRound,
              underline: const SizedBox(),
              dropdownColor: AppColors.surface,
              items: List.generate(
                leagueAsync.value!.maxRounds,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Jornada ${i + 1}'),
                ),
              ),
              onChanged: (value) {
                // TODO: Filter by round
              },
            ),
          ],
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _showTeamsDialog(),
          icon: Icon(PhosphorIcons.users(PhosphorIconsStyle.regular), size: 18),
          label: const Text('Ver Equipos'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.trophy(PhosphorIconsStyle.regular), size: 18),
                const SizedBox(width: 8),
                const Text('Clasificación'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 18),
                const SizedBox(width: 8),
                const Text('Calendario'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.football(PhosphorIconsStyle.regular), size: 18),
                const SizedBox(width: 8),
                const Text('Jornada Actual'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.regular), size: 18),
                const SizedBox(width: 8),
                const Text('Estadísticas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(League league, bool isWideScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWideScreen ? 24 : 16),
      child: isWideScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentRoundOverview(league),
                      const SizedBox(height: 24),
                      _buildStandingsSection(league),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildLeagueActions(league),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentRoundOverview(league),
                const SizedBox(height: 24),
                _buildStandingsSection(league),
                const SizedBox(height: 24),
                _buildLeagueActions(league),
              ],
            ),
    );
  }

  Widget _buildCurrentRoundOverview(League league) {
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.football(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'JORNADA ${league.currentRound}',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold), size: 16),
              label: const Text('VER TODAS'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error: $error'),
          data: (matches) {
            final currentRoundMatches = matches
                .where((m) => m.round == league.currentRound)
                .take(2)
                .toList();

            return Row(
              children: currentRoundMatches.map((match) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: currentRoundMatches.indexOf(match) == 0 ? 8 : 0,
                    left: currentRoundMatches.indexOf(match) == 1 ? 8 : 0,
                  ),
                  child: MatchCard(
                    match: match,
                    onTap: () {
                      if (match.isPending) {
                        context.go('/league/${widget.leagueId}/match/${match.id}/aftermatch');
                      }
                    },
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandingsSection(League league) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'CLASIFICACIÓN',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            ToggleButtons(
              isSelected: [true, false],
              onPressed: (index) {},
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 80, minHeight: 32),
              children: const [
                Text('General'),
                Text('Bajas (CAS)'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        StandingsTable(teams: league.teams, leagueId: widget.leagueId),
      ],
    );
  }

  Widget _buildLeagueActions(League league) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'ACCIONES DE LIGA',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: PhosphorIcons.users(PhosphorIconsStyle.regular),
          label: 'Ver Equipos y Plantillas',
          onTap: () => _showTeamsDialog(),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
          label: 'Reglamento de la Liga',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
          label: 'Contactar Comisario',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'ACTIVIDAD RECIENTE',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ActivityFeed(leagueId: widget.leagueId),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarTab(League league) {
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (matches) {
        // Group matches by round
        final matchesByRound = <int, List<Match>>{};
        for (final match in matches) {
          matchesByRound.putIfAbsent(match.round, () => []).add(match);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: league.maxRounds,
          itemBuilder: (context, index) {
            final round = index + 1;
            final roundMatches = matchesByRound[round] ?? [];

            return _buildRoundSection(round, roundMatches, league.currentRound);
          },
        );
      },
    );
  }

  Widget _buildRoundSection(int round, List<Match> matches, int currentRound) {
    final isCurrent = round == currentRound;
    final isPast = round < currentRound;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.surfaceLight,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  'Jornada $round',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTUAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'COMPLETADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sin partidos programados',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...matches.map((match) => _buildMatchRow(match)),
        ],
      ),
    );
  }

  Widget _buildMatchRow(Match match) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              match.homeTeamName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text(
              match.scoreDisplay,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: match.isPlayed ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match.awayTeamName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (match.isPending)
            TextButton(
              onPressed: () => context.go(
                '/league/${widget.leagueId}/match/${match.id}/aftermatch',
              ),
              child: const Text('Registrar'),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentRoundTab(League league, bool isWideScreen) {
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (matches) {
        final currentRoundMatches = matches
            .where((m) => m.round == league.currentRound)
            .toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jornada ${league.currentRound}',
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWideScreen ? 2 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2,
                ),
                itemCount: currentRoundMatches.length,
                itemBuilder: (context, index) {
                  return MatchCard(
                    match: currentRoundMatches[index],
                    expanded: true,
                    onTap: () {
                      final match = currentRoundMatches[index];
                      if (match.isPending) {
                        context.go('/league/${widget.leagueId}/match/${match.id}/aftermatch');
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(League league) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de la Liga',
            style: TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // TODO: Add statistics charts and tables
          Center(
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.chartBar(PhosphorIconsStyle.light),
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Próximamente',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTeamsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final leagueAsync = ref.watch(leagueProvider(widget.leagueId));

        return AlertDialog(
          title: const Text('Equipos de la Liga'),
          content: SizedBox(
            width: 400,
            child: leagueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error al cargar equipos'),
              data: (league) => ListView.builder(
                shrinkWrap: true,
                itemCount: league.teams.length,
                itemBuilder: (context, index) {
                  final team = league.teams[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        team.teamName.substring(0, 1),
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    title: Text(team.teamName),
                    subtitle: Text('${team.baseTeamName} • Coach: ${team.coachName}'),
                    trailing: Text('TV: ${team.teamValue ~/ 1000}k'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/league/${widget.leagueId}/team/${team.teamId}');
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

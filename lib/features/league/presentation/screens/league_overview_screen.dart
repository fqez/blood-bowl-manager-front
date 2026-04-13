import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league.dart';
import '../widgets/standings_table.dart';
import '../widgets/match_card.dart';
import '../widgets/activity_feed.dart';
import '../widgets/bracket_widget.dart';

// Providers
final leagueProvider =
    FutureProvider.family<League, String>((ref, leagueId) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeague(leagueId);
});

final matchesProvider =
    FutureProvider.family<List<Match>, String>((ref, leagueId) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeagueMatches(leagueId);
});

final leagueFormatProvider =
    FutureProvider.family<String, String>((ref, leagueId) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeagueFormat(leagueId);
});

class LeagueOverviewScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueOverviewScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueOverviewScreen> createState() =>
      _LeagueOverviewScreenState();
}

class _LeagueOverviewScreenState extends ConsumerState<LeagueOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final leagueAsync = ref.watch(leagueProvider(widget.leagueId));
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(leagueAsync),
      body: leagueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(trf(lang, 'common.error', {'e': '$error'}))),
        data: (league) => league.status == LeagueStatus.draft
            ? _buildDraftView(league, isWideScreen)
            : Column(
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
                        _buildBracketTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AsyncValue<League> leagueAsync) {
    final lang = ref.watch(localeProvider);
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
                'Temporada ${leagueAsync.value!.season}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: leagueAsync.value!.currentRound ?? 1,
              underline: const SizedBox(),
              dropdownColor: AppColors.surface,
              items: List.generate(
                leagueAsync.value!.maxRounds,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                      trf(lang, 'leagueOverview.round', {'n': '${i + 1}'})),
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
          label: Text(tr(lang, 'leagueOverview.viewTeams')),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTabBar() {
    final lang = ref.watch(localeProvider);
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
                Icon(PhosphorIcons.trophy(PhosphorIconsStyle.regular),
                    size: 18),
                const SizedBox(width: 8),
                Text(tr(lang, 'leagueOverview.standings')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                    size: 18),
                const SizedBox(width: 8),
                Text(tr(lang, 'leagueOverview.calendar')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.football(PhosphorIconsStyle.regular),
                    size: 18),
                const SizedBox(width: 8),
                Text(tr(lang, 'leagueOverview.currentRound')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
                    size: 18),
                const SizedBox(width: 8),
                Text(tr(lang, 'leagueOverview.stats')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.graph(PhosphorIconsStyle.regular), size: 18),
                const SizedBox(width: 8),
                Text(tr(lang, 'leagueOverview.bracket')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftView(League league, bool isWideScreen) {
    final lang = ref.watch(localeProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    final isOwner = currentUserId != null && league.ownerId == currentUserId;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWideScreen ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    color: AppColors.warning, size: 48),
                const SizedBox(height: 12),
                Text(
                  tr(lang, 'league.draftTitle'),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trf(lang, 'league.draftSubtitle', {
                    'current': '${league.teamsCount}',
                    'max': '${league.maxTeams}',
                  }),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Invite code section
          if (league.inviteCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      Icon(PhosphorIcons.key(PhosphorIconsStyle.fill),
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr(lang, 'league.inviteCode'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            league.inviteCode!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                            PhosphorIcons.copy(PhosphorIconsStyle.regular)),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: league.inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(tr(lang, 'createLeague.codeCopied'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(lang, 'league.shareInviteHint'),
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // League info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    Icon(PhosphorIcons.info(PhosphorIconsStyle.fill),
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr(lang, 'league.leagueInfo'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    tr(lang, 'league.format'),
                    league.format == 'round_robin'
                        ? tr(lang, 'createLeague.league')
                        : league.format),
                if (league.description != null &&
                    league.description!.isNotEmpty)
                  _buildInfoRow(tr(lang, 'createLeague.description'),
                      league.description!),
                _buildInfoRow(
                    tr(lang, 'league.commissioner'), league.ownerUsername),
                _buildInfoRow(
                    tr(lang, 'createLeague.maxTeams'), '${league.maxTeams}'),
                if (league.rules != null) ...[
                  _buildInfoRow(tr(lang, 'createLeague.budget'),
                      '${league.rules!.startingBudget ~/ 1000}k'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Registered teams
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      trf(lang, 'league.registeredTeams', {
                        'count': '${league.teamsCount}',
                      }),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (league.teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        tr(lang, 'league.noTeamsYet'),
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...league.teams.map((team) => Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: AppColors.surfaceLight)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceLight,
                              child: Text(
                                team.teamName.isNotEmpty
                                    ? team.teamName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    team.username,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (team.userId == currentUserId && !isOwner)
                              TextButton.icon(
                                onPressed: () =>
                                    _confirmLeaveLeague(league, team),
                                icon: Icon(
                                    PhosphorIcons.signOut(
                                        PhosphorIconsStyle.regular),
                                    size: 16,
                                    color: AppColors.error),
                                label: Text(
                                  tr(lang, 'league.leave'),
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start League button (owner only)
          if (isOwner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: league.teamsCount >= 2
                    ? () => _confirmStartLeague(league)
                    : null,
                icon:
                    Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: 20),
                label: Text(
                  tr(lang, 'league.startLeague'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.surfaceLight,
                ),
              ),
            ),
          if (isOwner && league.teamsCount < 2) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                tr(lang, 'league.needMoreTeams'),
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStartLeague(League league) {
    final lang = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(tr(lang, 'league.startLeague')),
        content: Text(
          trf(lang, 'league.startLeagueConfirm', {
            'count': '${league.teamsCount}',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(lang, 'common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(leagueRepositoryProvider);
                await repo.startLeague(widget.leagueId);
                ref.invalidate(leagueProvider(widget.leagueId));
                ref.invalidate(matchesProvider(widget.leagueId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(lang, 'league.leagueStarted'))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(trf(lang, 'common.error', {'e': '$e'}))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(tr(lang, 'league.startLeague')),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveLeague(League league, LeagueTeam team) {
    final lang = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(tr(lang, 'league.leaveLeague')),
        content: Text(tr(lang, 'league.leaveLeagueConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(lang, 'common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(leagueRepositoryProvider);
                await repo.leaveLeague(widget.leagueId, team.teamId);
                ref.invalidate(leagueProvider(widget.leagueId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(lang, 'league.leftLeague'))),
                  );
                  context.go('/dashboard');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(trf(lang, 'common.error', {'e': '$e'}))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(tr(lang, 'league.leave')),
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
    final lang = ref.watch(localeProvider);
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
              trf(lang, 'leagueOverview.round',
                  {'n': '${league.currentRound}'}),
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
              icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  size: 16),
              label: Text(tr(lang, 'leagueOverview.viewAll')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(trf(lang, 'common.error', {'e': '$error'})),
          data: (matches) {
            final currentRoundMatches = matches
                .where((m) => m.round == league.currentRound)
                .take(2)
                .toList();

            return Row(
              children: currentRoundMatches
                  .map((match) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                currentRoundMatches.indexOf(match) == 0 ? 8 : 0,
                            left:
                                currentRoundMatches.indexOf(match) == 1 ? 8 : 0,
                          ),
                          child: MatchCard(
                            match: match,
                            onTap: () {
                              if (match.isPending || match.isInProgress) {
                                context.go(
                                    '/league/${widget.leagueId}/match/${match.id}/live');
                              } else if (match.isPlayed) {
                                context.go(
                                    '/league/${widget.leagueId}/match/${match.id}/live');
                              }
                            },
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandingsSection(League league) {
    final lang = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              tr(lang, 'leagueOverview.standingsTitle'),
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
              children: [
                Text(tr(lang, 'leagueOverview.general')),
                Text(tr(lang, 'leagueOverview.casualties')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        StandingsTable(standings: league.standings, leagueId: widget.leagueId),
      ],
    );
  }

  Widget _buildLeagueActions(League league) {
    final lang = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill),
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              tr(lang, 'leagueOverview.actions'),
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
          label: tr(lang, 'leagueOverview.viewRosters'),
          onTap: () => _showTeamsDialog(),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
          label: tr(lang, 'leagueOverview.rules'),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
          label: tr(lang, 'leagueOverview.contactCommish'),
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              tr(lang, 'leagueOverview.recentActivity'),
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
    final lang = ref.watch(localeProvider);
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(trf(lang, 'common.error', {'e': '$error'}))),
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

            return _buildRoundSection(
                round, roundMatches, league.currentRound ?? 1);
          },
        );
      },
    );
  }

  Widget _buildRoundSection(int round, List<Match> matches, int currentRound) {
    final lang = ref.watch(localeProvider);
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
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  trf(lang, 'leagueOverview.round', {'n': '$round'}),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isCurrent ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tr(lang, 'leagueOverview.currentRound'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else if (isPast)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tr(lang, 'status.completed'),
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
    final lang = ref.watch(localeProvider);
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
              match.home.teamName,
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
                color: match.isPlayed
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match.away.teamName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (match.isPending || match.isInProgress)
            TextButton(
              onPressed: () => context.go(
                '/league/${widget.leagueId}/match/${match.id}/live',
              ),
              child: Text(match.isInProgress
                  ? tr(lang, 'match.continueMatch')
                  : tr(lang, 'match.startMatch')),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentRoundTab(League league, bool isWideScreen) {
    final lang = ref.watch(localeProvider);
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(trf(lang, 'common.error', {'e': '$error'}))),
      data: (matches) {
        final currentRoundMatches =
            matches.where((m) => m.round == league.currentRound).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trf(lang, 'leagueOverview.round',
                    {'n': '${league.currentRound}'}),
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
                      if (match.isPending || match.isInProgress) {
                        context.go(
                            '/league/${widget.leagueId}/match/${match.id}/live');
                      } else if (match.isPlayed) {
                        context.go(
                            '/league/${widget.leagueId}/match/${match.id}/live');
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
    final lang = ref.watch(localeProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(lang, 'leagueOverview.stats'),
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

  Widget _buildBracketTab() {
    final lang = ref.watch(localeProvider);
    final formatAsync = ref.watch(leagueFormatProvider(widget.leagueId));
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return formatAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          Center(child: Text(tr(lang, 'leagueOverview.errorFormat'))),
      data: (format) {
        if (format != 'knockout') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.graph(PhosphorIconsStyle.light),
                    size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'Solo disponible en ligas eliminatorias',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este formato es "${format == 'round_robin' ? tr(lang, 'format.league') : format}"',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text(trf(lang, 'common.error', {'e': '$err'}))),
          data: (matches) => BracketWidget(matches: matches),
        );
      },
    );
  }

  void _showTeamsDialog() {
    final lang = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (context) {
        final leagueAsync = ref.watch(leagueProvider(widget.leagueId));

        return AlertDialog(
          title: Text(tr(lang, 'leagueOverview.leagueTeams')),
          content: SizedBox(
            width: 400,
            child: leagueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(tr(lang, 'leagueOverview.errorTeams')),
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
                    subtitle: Text('Coach: ${team.username}'),
                    onTap: () {
                      Navigator.pop(context);
                      context
                          .go('/league/${widget.leagueId}/team/${team.teamId}');
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

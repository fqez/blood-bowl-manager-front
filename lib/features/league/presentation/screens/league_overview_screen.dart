import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../debug/data/debug_league_data.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league.dart';
import '../widgets/standings_table.dart';
import '../widgets/match_card.dart';
import '../widgets/bracket_widget.dart';
import '../widgets/league_stats_dashboard.dart';

// Providers
final leagueProvider =
    FutureProvider.family<League, String>((ref, leagueId) async {
  if (leagueId == debugLeagueId) return buildDebugLeague();

  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeague(leagueId);
});

final matchesProvider =
    FutureProvider.family<List<Match>, String>((ref, leagueId) async {
  if (leagueId == debugLeagueId) return buildDebugLeagueMatches();

  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeagueMatches(leagueId);
});

final leagueFormatProvider =
    FutureProvider.family<String, String>((ref, leagueId) async {
  if (leagueId == debugLeagueId) return 'round_robin';

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

  bool get _isDebugLeague => widget.leagueId == debugLeagueId;

  void _openMatch(Match match) {
    if (_isDebugLeague) return;
    context.go('/league/${widget.leagueId}/match/${match.id}/live');
  }

  Future<void> _showMatchSummaryDialog(Match match) async {
    final lang = ref.read(localeProvider);
    var summaryMatch = match;

    if (match.isPlayed && !_isDebugLeague) {
      try {
        summaryMatch = await ref
            .read(leagueRepositoryProvider)
            .getMatchDetail(widget.leagueId, match.id);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar el detalle del partido: $error'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 920,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMatchSummaryHeader(summaryMatch, lang),
                const SizedBox(height: 18),
                _buildReadOnlyMatchStats(summaryMatch, lang),
                const SizedBox(height: 18),
                _buildMatchTimeline(summaryMatch),
              ],
            ),
          ),
        ),
      ),
    );
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
    final isCompact = MediaQuery.of(context).size.width < 700;
    return AppBar(
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular)),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            leagueAsync.valueOrNull?.name ?? 'Liga',
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: isCompact ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
    final isCompact = MediaQuery.of(context).size.width < 700;
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        isScrollable: isCompact,
        tabAlignment: isCompact ? TabAlignment.start : TabAlignment.fill,
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
                    fontFamily: AppTypography.displayFontFamily,
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
    var scheduleMode = 'automatic';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(tr(lang, 'league.startLeague')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trf(lang, 'league.startLeagueConfirm', {
                  'count': '${league.teamsCount}',
                }),
              ),
              const SizedBox(height: 16),
              _scheduleModeTile(
                selected: scheduleMode == 'automatic',
                title: 'Calendario automatico',
                subtitle: 'Genera todos los cruces al empezar.',
                onTap: () => setDialogState(() => scheduleMode = 'automatic'),
              ),
              _scheduleModeTile(
                selected: scheduleMode == 'manual',
                title: 'Calendario manual',
                subtitle: 'Empieza sin partidos y editalos en Calendario.',
                onTap: () => setDialogState(() => scheduleMode = 'manual'),
              ),
            ],
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
                  await repo.startLeague(widget.leagueId,
                      scheduleMode: scheduleMode);
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
                          content:
                              Text(trf(lang, 'common.error', {'e': '$e'}))),
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
      ),
    );
  }

  Widget _scheduleModeTile({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentRoundOverview(league),
              const SizedBox(height: 24),
              _buildStandingsSection(league),
            ],
          ),
        ),
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
                fontFamily: AppTypography.displayFontFamily,
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
                            onTap:
                                _isDebugLeague ? null : () => _openMatch(match),
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
                fontFamily: AppTypography.displayFontFamily,
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
        StandingsTable(
          standings: league.standings,
          leagueId: widget.leagueId,
          onTeamTap: (standing) => _showTeamLeagueStats(league, standing),
        ),
      ],
    );
  }

  Future<void> _showTeamLeagueStats(
    League league,
    LeagueStanding standing,
  ) async {
    var matches = league.matches;
    try {
      matches = await ref.read(matchesProvider(widget.leagueId).future);
    } catch (_) {
      matches = league.matches;
    }
    if (!mounted) return;

    final teamMatches = matches
        .where((match) =>
            match.home.teamId == standing.teamId ||
            match.away.teamId == standing.teamId)
        .toList()
      ..sort((a, b) => a.round.compareTo(b.round));
    final playedMatches = teamMatches.where((match) => match.isPlayed).toList();
    final pendingMatches = teamMatches.where((match) => match.isPending).length;
    final inProgressMatches =
        teamMatches.where((match) => match.isInProgress).length;
    final touchdownsAverage = standing.gamesPlayed == 0
        ? 0.0
        : standing.touchdownsFor / standing.gamesPlayed;
    final casualtiesAverage = standing.gamesPlayed == 0
        ? 0.0
        : standing.casualtiesFor / standing.gamesPlayed;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTADISTICAS DE LIGA',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            standing.teamName,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        PhosphorIcons.x(PhosphorIconsStyle.bold),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _teamStatTile(
                        'Puntos', '${standing.points}', AppColors.accent),
                    _teamStatTile(
                        'Jugados', '${standing.gamesPlayed}', AppColors.info),
                    _teamStatTile(
                        'Victorias', '${standing.wins}', AppColors.success),
                    _teamStatTile('Empates', '${standing.draws}',
                        AppColors.textSecondary),
                    _teamStatTile(
                        'Derrotas', '${standing.losses}', AppColors.error),
                    _teamStatTile(
                      'TD',
                      '${standing.touchdownsFor}-${standing.touchdownsAgainst}',
                      AppColors.primary,
                    ),
                    _teamStatTile(
                        'Dif. TD',
                        '${standing.touchdownDiff >= 0 ? '+' : ''}${standing.touchdownDiff}',
                        AppColors.warning),
                    _teamStatTile(
                      'Bajas',
                      '${standing.casualtiesFor}-${standing.casualtiesAgainst}',
                      AppColors.error,
                    ),
                    _teamStatTile(
                        'TD / partido',
                        touchdownsAverage.toStringAsFixed(1),
                        AppColors.primaryLight),
                    _teamStatTile(
                        'Bajas / partido',
                        casualtiesAverage.toStringAsFixed(1),
                        AppColors.warning),
                    _teamStatTile(
                        'Pendientes', '$pendingMatches', AppColors.textMuted),
                    _teamStatTile(
                        'En curso', '$inProgressMatches', AppColors.info),
                  ],
                ),
                const SizedBox(height: 18),
                _teamMatchesPanel(standing, playedMatches, teamMatches),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamStatTile(String label, String value, Color color) {
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamMatchesPanel(
    LeagueStanding standing,
    List<Match> playedMatches,
    List<Match> teamMatches,
  ) {
    final rows = teamMatches.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PARTIDOS DE LIGA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              'Sin partidos asignados.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...rows.map((match) => _teamMatchStatRow(standing, match)),
          if (teamMatches.length > rows.length) ...[
            const SizedBox(height: 8),
            Text(
              '+${teamMatches.length - rows.length} partidos mas en calendario',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          if (playedMatches.isEmpty && rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aun no hay partidos completados para este equipo.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamMatchStatRow(LeagueStanding standing, Match match) {
    final isHome = match.home.teamId == standing.teamId;
    final opponent = isHome ? match.away.teamName : match.home.teamName;
    final teamScore = isHome ? match.scoreHome : match.scoreAway;
    final opponentScore = isHome ? match.scoreAway : match.scoreHome;
    final result = match.isPlayed
        ? teamScore > opponentScore
            ? 'Victoria'
            : teamScore < opponentScore
                ? 'Derrota'
                : 'Empate'
        : match.isInProgress
            ? 'En curso'
            : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              'J${match.round}',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              opponent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            match.isPlayed || match.isInProgress
                ? '$teamScore - $opponentScore'
                : '? - ?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(
              result,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(League league) {
    final lang = ref.watch(localeProvider);
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    final canEditCalendar = !_isDebugLeague &&
        currentUserId != null &&
        league.ownerId == currentUserId &&
        league.status == LeagueStatus.active;

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
        final maxRound = matchesByRound.isEmpty
            ? 0
            : matchesByRound.keys.reduce((a, b) => a > b ? a : b);
        final roundCount = math.max(league.maxRounds, maxRound);

        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill),
                      size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'Sin partidos programados',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (canEditCalendar)
                    ElevatedButton.icon(
                      onPressed: () => _showFixtureDialog(league),
                      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 18),
                      label: const Text('Añadir encuentro'),
                    ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (canEditCalendar)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFixtureDialog(league),
                    icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                        size: 18),
                    label: const Text('Añadir encuentro'),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: roundCount,
                itemBuilder: (context, index) {
                  final round = index + 1;
                  final roundMatches = matchesByRound[round] ?? [];

                  return _buildRoundSection(
                    round,
                    roundMatches,
                    league.currentRound ?? 1,
                    league,
                    canEditCalendar,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoundSection(int round, List<Match> matches, int currentRound,
      League league, bool canEditCalendar) {
    final lang = ref.watch(localeProvider);
    final isCurrent = round == currentRound;
    final isPast = round < currentRound;
    final isCompact = MediaQuery.of(context).size.width < 700;

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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  trf(lang, 'leagueOverview.round', {'n': '$round'}),
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
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
            ...matches.map((match) => _buildMatchRow(
                  match,
                  league: league,
                  canEditCalendar: canEditCalendar,
                )),
        ],
      ),
    );
  }

  Widget _buildMatchRow(Match match,
      {required League league, required bool canEditCalendar}) {
    final lang = ref.watch(localeProvider);
    final isCompact = MediaQuery.of(context).size.width < 700;
    final homeWon = match.isPlayed && match.scoreHome > match.scoreAway;
    final awayWon = match.isPlayed && match.scoreAway > match.scoreHome;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMatchSummaryDialog(match),
        hoverColor: AppColors.cardHover.withOpacity(0.35),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.surfaceLight),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackTeams = isCompact || constraints.maxWidth < 520;

              final score = Container(
                padding: EdgeInsets.symmetric(
                  horizontal: stackTeams ? 12 : 0,
                  vertical: stackTeams ? 6 : 0,
                ),
                alignment: Alignment.center,
                decoration: stackTeams
                    ? BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceLight),
                      )
                    : null,
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
              );

              final liveAction =
                  !_isDebugLeague && (match.isPending || match.isInProgress)
                      ? TextButton(
                          onPressed: () => _openMatch(match),
                          child: Text(match.isInProgress
                              ? tr(lang, 'match.continueMatch')
                              : tr(lang, 'match.startMatch')),
                        )
                      : null;
              final editActions = canEditCalendar && match.isPending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar encuentro',
                          onPressed: () =>
                              _showFixtureDialog(league, match: match),
                          icon: Icon(
                              PhosphorIcons.pencilSimple(
                                  PhosphorIconsStyle.regular),
                              size: 18,
                              color: AppColors.textSecondary),
                        ),
                        IconButton(
                          tooltip: 'Borrar encuentro',
                          onPressed: () => _confirmDeleteFixture(match),
                          icon: Icon(
                              PhosphorIcons.trash(PhosphorIconsStyle.regular),
                              size: 18,
                              color: AppColors.error),
                        ),
                      ],
                    )
                  : null;

              if (stackTeams) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCalendarTeamName(
                      match.home.teamName,
                      winner: homeWon,
                      alignment: Alignment.center,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(child: score),
                    const SizedBox(height: 8),
                    _buildCalendarTeamName(
                      match.away.teamName,
                      winner: awayWon,
                      alignment: Alignment.center,
                      textAlign: TextAlign.center,
                    ),
                    if (liveAction != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.center, child: liveAction),
                    ],
                    if (editActions != null) ...[
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.center, child: editActions),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildCalendarTeamName(
                      match.home.teamName,
                      winner: homeWon,
                      alignment: Alignment.centerRight,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(width: 80, child: score),
                  Expanded(
                    child: _buildCalendarTeamName(
                      match.away.teamName,
                      winner: awayWon,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  if (liveAction != null) liveAction,
                  if (editActions != null) editActions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showFixtureDialog(League league, {Match? match}) async {
    final isEditing = match != null;
    final formKey = GlobalKey<FormState>();
    final roundController = TextEditingController(
      text: '${match?.round ?? math.max(1, league.maxRounds + 1)}',
    );
    String? homeTeamId = match?.home.teamId;
    String? awayTeamId = match?.away.teamId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Editar encuentro' : 'Añadir encuentro'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: roundController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Jornada'),
                    validator: (value) {
                      final round = int.tryParse(value?.trim() ?? '');
                      if (round == null || round < 1) return 'Jornada invalida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: homeTeamId,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'Local'),
                    items: league.teams
                        .map((team) => DropdownMenuItem(
                              value: team.teamId,
                              child: Text(team.teamName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    validator: (value) => value == null ? 'Elige local' : null,
                    onChanged: (value) =>
                        setDialogState(() => homeTeamId = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: awayTeamId,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'Visitante'),
                    items: league.teams
                        .map((team) => DropdownMenuItem(
                              value: team.teamId,
                              child: Text(team.teamName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    validator: (value) {
                      if (value == null) return 'Elige visitante';
                      if (value == homeTeamId) return 'Debe ser otro equipo';
                      return null;
                    },
                    onChanged: (value) =>
                        setDialogState(() => awayTeamId = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    try {
      final repository = ref.read(leagueRepositoryProvider);
      final round = int.parse(roundController.text.trim());
      if (isEditing) {
        await repository.updateLeagueMatchFixture(
          widget.leagueId,
          match.id,
          round: round,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
        );
      } else {
        await repository.createLeagueMatch(
          widget.leagueId,
          round: round,
          homeTeamId: homeTeamId!,
          awayTeamId: awayTeamId!,
        );
      }
      ref.invalidate(leagueProvider(widget.leagueId));
      ref.invalidate(matchesProvider(widget.leagueId));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _confirmDeleteFixture(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Borrar encuentro'),
        content: Text(
          '${match.home.teamName} vs ${match.away.teamName}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(leagueRepositoryProvider)
          .deleteLeagueMatch(widget.leagueId, match.id);
      ref.invalidate(leagueProvider(widget.leagueId));
      ref.invalidate(matchesProvider(widget.leagueId));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildMatchSummaryHeader(Match match, String lang) {
    final statusLabel = match.isPlayed
        ? tr(lang, 'status.completed')
        : match.isInProgress
            ? tr(lang, 'match.inProgress')
            : 'Programado';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trf(lang, 'leagueOverview.round', {'n': '${match.round}'}),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${match.home.teamName} ${match.scoreDisplay} ${match.away.teamName}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryChip(statusLabel, AppColors.info),
                  if (match.weather != null)
                    _summaryChip(match.weather!, AppColors.warning),
                  if (match.gate != null)
                    _summaryChip('Entrada ${match.gate}', AppColors.accent),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            PhosphorIcons.x(PhosphorIconsStyle.bold),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildReadOnlyMatchStats(Match match, String lang) {
    final stats = _MatchSummaryStats.fromMatch(match);

    return _summaryPanel(
      title: tr(lang, 'aftermatch.matchResultTitle').toUpperCase(),
      child: Column(
        children: [
          _readOnlyStatRow(
            tr(lang, 'aftermatch.touchdowns'),
            stats.touchdownsHome,
            stats.touchdownsAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.casualties'),
            stats.casualtiesHome,
            stats.casualtiesAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.completions'),
            stats.completionsHome,
            stats.completionsAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.interceptions'),
            stats.interceptionsHome,
            stats.interceptionsAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.fouls'),
            stats.foulsHome,
            stats.foulsAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.kos'),
            stats.kosHome,
            stats.kosAway,
          ),
          _readOnlyStatRow(
            tr(lang, 'aftermatch.rerollsUsed'),
            stats.rerollsHome,
            stats.rerollsAway,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

  Widget _readOnlyStatRow(
    String label,
    int home,
    int away, {
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.surfaceLight))
            : null,
      ),
      child: Row(
        children: [
          _statValuePill(home),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _statValuePill(away),
        ],
      ),
    );
  }

  Widget _statValuePill(int value) {
    return Container(
      width: 48,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMatchTimeline(Match match) {
    final allPoints = _timelinePoints(match);
    final allTypes = _timelineLegendTypes(allPoints);
    var activeTypes = Set<String>.from(allTypes);
    _TimelinePoint? selectedPoint;

    return _summaryPanel(
      title: 'CRONOLOGIA DEL PARTIDO',
      child: allPoints.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Aun no hay eventos registrados para este partido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : StatefulBuilder(
              builder: (context, setTimelineState) {
                final points = allPoints
                    .where((point) => activeTypes.contains(point.filterType))
                    .toList();
                if (selectedPoint != null && !points.contains(selectedPoint)) {
                  selectedPoint = null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const chartHeight = 250.0;
                        final chartSize =
                            Size(constraints.maxWidth - 24, chartHeight - 24);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            final point = _hitTimelinePoint(
                              details.localPosition - const Offset(12, 12),
                              chartSize,
                              points,
                            );
                            if (point == null) return;
                            setTimelineState(() => selectedPoint = point);
                          },
                          child: Container(
                            height: chartHeight,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: CustomPaint(
                              painter: _MatchTimelinePainter(
                                points: points,
                                homeName: match.home.teamName,
                                awayName: match.away.teamName,
                                score: match.scoreDisplay,
                                selectedPoint: selectedPoint,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTypes
                          .map(
                            (type) => _timelineFilterPill(
                              type: type,
                              selected: activeTypes.contains(type),
                              onTap: () {
                                setTimelineState(() {
                                  if (activeTypes.contains(type)) {
                                    if (activeTypes.length > 1) {
                                      activeTypes.remove(type);
                                    }
                                  } else {
                                    activeTypes.add(type);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    if (selectedPoint != null) ...[
                      const SizedBox(height: 14),
                      _timelineDetailCard(selectedPoint!, match),
                    ],
                    const SizedBox(height: 14),
                    ...points.map((point) => _timelineEventRow(point, match)),
                  ],
                );
              },
            ),
    );
  }

  Widget _timelineFilterPill({
    required String type,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = _eventTypeColor(type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.13) : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected ? color.withOpacity(0.55) : AppColors.surfaceLight,
            ),
          ),
          child: Text(
            _eventTypeLabel(type),
            style: TextStyle(
              color: selected ? color : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timelineDetailCard(_TimelinePoint point, Match match) {
    final event = point.event;
    final teamName = _eventTeamName(match, event.team);
    final detail = _timelineEventDetails(event, match);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: point.color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${point.minute}'  ${point.label} - $teamName",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail.isEmpty ? 'Sin detalle adicional' : detail,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  _TimelinePoint? _hitTimelinePoint(
    Offset position,
    Size size,
    List<_TimelinePoint> points,
  ) {
    const left = 116.0;
    const right = 8.0;
    const top = 22.0;
    const bottom = 28.0;
    final chartWidth = math.max(size.width - left - right, 1.0);
    final centerY = size.height / 2;
    final maxBar = math.max((size.height - top - bottom) / 2 - 12, 18.0);
    final barsByMinute = <int, int>{};
    _TimelinePoint? bestPoint;
    var bestDistance = double.infinity;

    for (final point in points) {
      final used = barsByMinute.update(
        point.minute,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final x = left + chartWidth * point.minute / 90 + (used * 5) - 2;
      final height = maxBar * point.impact;
      final topY = point.isHome ? centerY - height : centerY;
      final rect = Rect.fromLTWH(x - 8, topY - 8, 21, height + 16);
      if (!rect.contains(position)) continue;
      final center = Offset(x + 2.5, topY + height / 2);
      final distance = (position - center).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestPoint = point;
      }
    }

    return bestPoint;
  }

  List<_TimelinePoint> _timelinePoints(Match match) {
    final ordered = [...match.events]..sort((a, b) {
        final minuteCompare = _eventMinute(a, match, 0).compareTo(
          _eventMinute(b, match, 0),
        );
        if (minuteCompare != 0) return minuteCompare;
        return a.id.compareTo(b.id);
      });

    return List.generate(ordered.length, (index) {
      final event = ordered[index];
      final type = event.type.toLowerCase();
      final filterType = _eventFilterType(type);
      return _TimelinePoint(
        event: event,
        minute: _eventMinute(event, match, index).clamp(0, 90),
        isHome: event.team.toLowerCase() == 'home',
        color: _eventTypeColor(type),
        label: _eventTypeLabel(filterType),
        impact: _eventImpact(type),
        filterType: filterType,
      );
    });
  }

  int _eventMinute(MatchEvent event, Match match, int index) {
    if (match.startedAt != null && event.timestamp != null) {
      return event.timestamp!
          .difference(match.startedAt!)
          .inMinutes
          .clamp(0, 90);
    }
    if (event.half > 0 && event.turn > 0) {
      final halfStart = (event.half.clamp(1, 2) - 1) * 45;
      final turnMinute = ((event.turn.clamp(1, 8) - 1) * (45 / 8)).round();
      return (halfStart + turnMinute + 3).clamp(0, 90);
    }
    final total = math.max(match.events.length, 1);
    return ((index + 1) * 90 / (total + 1)).round().clamp(0, 90);
  }

  Set<String> _timelineLegendTypes(List<_TimelinePoint> points) {
    return points.map((point) => point.filterType).toSet();
  }

  String _eventFilterType(String type) {
    switch (type.toLowerCase()) {
      case 'turnover':
      case 'turn_change':
      case 'turn':
        return 'turn_change';
      case 'pass':
        return 'completion';
      default:
        return type.toLowerCase();
    }
  }

  Widget _timelineEventRow(_TimelinePoint point, Match match) {
    final event = point.event;
    final teamName = _eventTeamName(match, event.team);
    final details = _timelineEventDetails(event, match);
    final moment = _eventMomentLabel(event, point.minute);
    final timestamp = _eventTimestampLabel(event.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${point.minute}'",
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moment,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(_eventTypeIcon(event.type), size: 18, color: point.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${point.label} - $teamName',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (details.isNotEmpty)
                    TextSpan(
                      text: '  $details',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (timestamp.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              timestamp,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _eventTeamName(Match match, String team) {
    switch (team.toLowerCase()) {
      case 'home':
        return match.home.teamName;
      case 'away':
        return match.away.teamName;
      default:
        return 'Sistema';
    }
  }

  String _eventMomentLabel(MatchEvent event, int minute) {
    if (event.half > 0 || event.turn > 0) {
      final half = event.half > 0 ? event.half : '-';
      final turn = event.turn > 0 ? event.turn : '-';
      return 'P$half T$turn';
    }
    return "Min $minute";
  }

  String _eventTimestampLabel(DateTime? timestamp) {
    if (timestamp == null) return '';
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _timelineEventDetails(MatchEvent event, Match match) {
    final parts = <String>[];
    if ((event.playerName ?? '').trim().isNotEmpty) {
      parts.add('Jugador: ${event.playerName!.trim()}');
    } else if ((event.playerId ?? '').trim().isNotEmpty) {
      parts.add('Jugador: ${event.playerId!.trim()}');
    }
    if ((event.victimName ?? '').trim().isNotEmpty) {
      parts.add('Víctima: ${event.victimName!.trim()}');
    } else if ((event.victimId ?? '').trim().isNotEmpty) {
      parts.add('Víctima: ${event.victimId!.trim()}');
    }
    if ((event.injury ?? '').trim().isNotEmpty) {
      parts.add('Lesión: ${_eventInjuryLabel(event.injury!)}');
    }
    final detail = _visibleStoredEventDetail(event.detail);
    if (detail.isNotEmpty) parts.add(detail);
    if ((event.createdByName ?? '').trim().isNotEmpty) {
      parts.add('Registrado por ${event.createdByName!.trim()}');
    }
    return parts.join(' · ');
  }

  String _visibleStoredEventDetail(String? detail) {
    if (detail == null) return '';
    return detail
        .split('\n')
        .where((line) => !line.startsWith('InducementSync:'))
        .join(' · ')
        .trim();
  }

  String _eventInjuryLabel(String injury) {
    switch (injury.toLowerCase()) {
      case 'sent_off':
        return 'Expulsado';
      case 'badly_hurt':
        return 'Sin secuelas';
      case 'miss_next_game':
      case 'missing_next_game':
        return 'Se pierde el próximo';
      case 'lasting_injury':
        return 'Lesión permanente';
      case 'dead':
      case 'rip':
        return 'Muerto';
      default:
        return injury.replaceAll('_', ' ');
    }
  }

  String _eventTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'touchdown':
        return 'Touchdown';
      case 'casualty':
        return 'Lesión/Baja';
      case 'badly_hurt':
        return 'Herido leve';
      case 'serious_injury':
        return 'Lesión grave';
      case 'rip':
        return 'Muerto';
      case 'completion':
      case 'pass':
        return 'Pase';
      case 'throw_teammate':
        return 'Lanzar compañero';
      case 'interception':
        return 'Intercepción';
      case 'foul':
        return 'Falta';
      case 'ko':
        return 'KO';
      case 'stun':
        return 'Aturdido';
      case 'score_change':
        return 'Marcador';
      case 'half_change':
        return 'Cambio de parte';
      case 'weather_change':
        return 'Clima';
      case 'kickoff_change':
        return 'Patada inicial';
      case 'reroll_change':
      case 'reroll_total_change':
        return 'Reroll';
      case 'inducement_purchase':
      case 'inducement_change':
        return 'Incentivo';
      case 'turnover':
      case 'turn_change':
      case 'turn':
        return 'Cambio de turno';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  Color _eventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'touchdown':
        return AppColors.accent;
      case 'casualty':
      case 'rip':
      case 'serious_injury':
        return AppColors.error;
      case 'badly_hurt':
      case 'completion':
      case 'pass':
        return AppColors.info;
      case 'throw_teammate':
        return AppColors.info;
      case 'interception':
        return AppColors.success;
      case 'foul':
        return AppColors.primaryLight;
      case 'ko':
      case 'stun':
        return AppColors.warning;
      case 'score_change':
        return AppColors.accent;
      case 'half_change':
      case 'turnover':
      case 'turn_change':
      case 'turn':
        return AppColors.skillAgility;
      case 'weather_change':
      case 'kickoff_change':
        return AppColors.warning;
      case 'reroll_change':
      case 'reroll_total_change':
        return const Color(0xFF9C27B0);
      case 'inducement_purchase':
      case 'inducement_change':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _eventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'touchdown':
        return PhosphorIcons.trophy(PhosphorIconsStyle.fill);
      case 'casualty':
      case 'rip':
      case 'serious_injury':
        return PhosphorIcons.skull(PhosphorIconsStyle.fill);
      case 'badly_hurt':
        return PhosphorIcons.firstAid(PhosphorIconsStyle.fill);
      case 'completion':
      case 'pass':
        return PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill);
      case 'throw_teammate':
        return PhosphorIcons.userSwitch(PhosphorIconsStyle.fill);
      case 'interception':
        return PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill);
      case 'foul':
        return PhosphorIcons.prohibit(PhosphorIconsStyle.fill);
      case 'ko':
      case 'stun':
        return PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill);
      case 'score_change':
        return PhosphorIcons.plusMinus(PhosphorIconsStyle.fill);
      case 'half_change':
        return PhosphorIcons.timer(PhosphorIconsStyle.fill);
      case 'turnover':
      case 'turn_change':
      case 'turn':
        return PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill);
      case 'weather_change':
        return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
      case 'kickoff_change':
        return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
      case 'reroll_change':
      case 'reroll_total_change':
        return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
      case 'inducement_purchase':
      case 'inducement_change':
        return PhosphorIcons.handCoins(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.circle(PhosphorIconsStyle.fill);
    }
  }

  double _eventImpact(String type) {
    switch (type.toLowerCase()) {
      case 'touchdown':
        return 1;
      case 'casualty':
      case 'rip':
      case 'serious_injury':
        return 0.86;
      case 'badly_hurt':
        return 0.76;
      case 'ko':
      case 'stun':
        return 0.72;
      case 'interception':
        return 0.68;
      case 'completion':
      case 'pass':
      case 'throw_teammate':
        return 0.56;
      case 'foul':
        return 0.5;
      case 'score_change':
      case 'half_change':
      case 'weather_change':
      case 'kickoff_change':
      case 'reroll_change':
      case 'reroll_total_change':
      case 'inducement_purchase':
      case 'inducement_change':
        return 0.44;
      case 'turnover':
      case 'turn_change':
      case 'turn':
        return 0.36;
      default:
        return 0.44;
    }
  }

  Widget _buildCalendarTeamName(
    String teamName, {
    required bool winner,
    required Alignment alignment,
    TextAlign textAlign = TextAlign.left,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (winner) ...[
          Icon(
            PhosphorIcons.crown(PhosphorIconsStyle.fill),
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: winner ? FontWeight.w800 : FontWeight.w500,
              color: winner ? AppColors.success : AppColors.textPrimary,
            ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Align(
      alignment: alignment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: winner
            ? const EdgeInsets.symmetric(horizontal: 9, vertical: 5)
            : EdgeInsets.zero,
        decoration: winner
            ? BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.success.withOpacity(0.35)),
              )
            : null,
        child: content,
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
                  fontFamily: AppTypography.displayFontFamily,
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
                    onTap: _isDebugLeague
                        ? null
                        : () => _openMatch(currentRoundMatches[index]),
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
    final matchesAsync = ref.watch(matchesProvider(widget.leagueId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(trf(lang, 'common.error', {'e': '$error'}))),
      data: (matches) => LeagueStatsDashboard(
        league: league,
        matches: matches,
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

class _MatchSummaryStats {
  const _MatchSummaryStats({
    required this.touchdownsHome,
    required this.touchdownsAway,
    required this.casualtiesHome,
    required this.casualtiesAway,
    required this.completionsHome,
    required this.completionsAway,
    required this.interceptionsHome,
    required this.interceptionsAway,
    required this.foulsHome,
    required this.foulsAway,
    required this.kosHome,
    required this.kosAway,
    required this.rerollsHome,
    required this.rerollsAway,
  });

  final int touchdownsHome;
  final int touchdownsAway;
  final int casualtiesHome;
  final int casualtiesAway;
  final int completionsHome;
  final int completionsAway;
  final int interceptionsHome;
  final int interceptionsAway;
  final int foulsHome;
  final int foulsAway;
  final int kosHome;
  final int kosAway;
  final int rerollsHome;
  final int rerollsAway;

  factory _MatchSummaryStats.fromMatch(Match match) {
    var touchdownsHome = 0;
    var touchdownsAway = 0;
    var casualtiesHome = 0;
    var casualtiesAway = 0;
    var completionsHome = 0;
    var completionsAway = 0;
    var interceptionsHome = 0;
    var interceptionsAway = 0;
    var foulsHome = 0;
    var foulsAway = 0;
    var kosHome = 0;
    var kosAway = 0;

    for (final event in match.events) {
      final isHome = event.team.toLowerCase() == 'home';
      switch (event.type.toLowerCase()) {
        case 'touchdown':
          isHome ? touchdownsHome++ : touchdownsAway++;
        case 'casualty':
          isHome ? casualtiesHome++ : casualtiesAway++;
        case 'completion':
        case 'pass':
          isHome ? completionsHome++ : completionsAway++;
        case 'interception':
          isHome ? interceptionsHome++ : interceptionsAway++;
        case 'foul':
          isHome ? foulsHome++ : foulsAway++;
        case 'ko':
          isHome ? kosHome++ : kosAway++;
      }
    }

    if (touchdownsHome == 0 &&
        touchdownsAway == 0 &&
        (match.isPlayed || match.isInProgress)) {
      touchdownsHome = match.scoreHome;
      touchdownsAway = match.scoreAway;
    }

    return _MatchSummaryStats(
      touchdownsHome: touchdownsHome,
      touchdownsAway: touchdownsAway,
      casualtiesHome: casualtiesHome,
      casualtiesAway: casualtiesAway,
      completionsHome: completionsHome,
      completionsAway: completionsAway,
      interceptionsHome: interceptionsHome,
      interceptionsAway: interceptionsAway,
      foulsHome: foulsHome,
      foulsAway: foulsAway,
      kosHome: kosHome,
      kosAway: kosAway,
      rerollsHome: match.rerollsUsedHome,
      rerollsAway: match.rerollsUsedAway,
    );
  }
}

class _TimelinePoint {
  const _TimelinePoint({
    required this.event,
    required this.minute,
    required this.isHome,
    required this.color,
    required this.label,
    required this.impact,
    required this.filterType,
  });

  final MatchEvent event;
  final int minute;
  final bool isHome;
  final Color color;
  final String label;
  final double impact;
  final String filterType;
}

class _MatchTimelinePainter extends CustomPainter {
  const _MatchTimelinePainter({
    required this.points,
    required this.homeName,
    required this.awayName,
    required this.score,
    this.selectedPoint,
  });

  final List<_TimelinePoint> points;
  final String homeName;
  final String awayName;
  final String score;
  final _TimelinePoint? selectedPoint;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 116.0;
    const right = 8.0;
    const top = 22.0;
    const bottom = 28.0;
    final chartWidth = math.max(size.width - left - right, 1.0);
    final centerY = size.height / 2;
    final maxBar = math.max((size.height - top - bottom) / 2 - 12, 18.0);
    final axisPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = AppColors.surfaceLight.withOpacity(0.45)
      ..strokeWidth = 1;

    for (var minute = 0; minute <= 90; minute += 15) {
      final x = left + chartWidth * minute / 90;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, size.height - bottom),
        gridPaint,
      );
      _paintText(
        canvas,
        '${minute}m',
        Offset(x - 12, size.height - 20),
        AppColors.textMuted,
        10,
        FontWeight.w700,
      );
    }

    canvas.drawLine(
      Offset(left, centerY),
      Offset(size.width - right, centerY),
      axisPaint,
    );
    _paintText(
      canvas,
      homeName,
      const Offset(0, 22),
      AppColors.textPrimary,
      11,
      FontWeight.w900,
      maxWidth: left - 10,
    );
    _paintText(
      canvas,
      score,
      Offset(0, centerY - 9),
      AppColors.accent,
      16,
      FontWeight.w900,
      maxWidth: left - 10,
    );
    _paintText(
      canvas,
      awayName,
      Offset(0, size.height - 48),
      AppColors.textPrimary,
      11,
      FontWeight.w900,
      maxWidth: left - 10,
    );

    final barsByMinute = <int, int>{};
    for (final point in points) {
      final used = barsByMinute.update(
        point.minute,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final x = left + chartWidth * point.minute / 90 + (used * 5) - 2;
      final height = maxBar * point.impact;
      final topY = point.isHome ? centerY - height : centerY;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, 5, height),
        const Radius.circular(2.5),
      );
      final paint = Paint()..color = point.color;
      if (point == selectedPoint) {
        final haloPaint = Paint()
          ..color = point.color.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 5, topY - 5, 15, height + 10),
            const Radius.circular(7),
          ),
          haloPaint,
        );
      }
      canvas.drawRRect(rect, paint);
      canvas.drawCircle(
        Offset(x + 2.5, point.isHome ? topY - 4 : topY + height + 4),
        point == selectedPoint ? 5 : 3,
        paint,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double size,
    FontWeight weight, {
    double maxWidth = double.infinity,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      maxLines: 2,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MatchTimelinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.homeName != homeName ||
        oldDelegate.awayName != awayName ||
        oldDelegate.score != score ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}

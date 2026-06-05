import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../league/domain/models/league.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/utils/player_advancement.dart';
import '../../domain/models/league_summary.dart';

final myLeaguesSummaryProvider =
    FutureProvider.autoDispose<List<LeagueSummaryModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final currentAuth = authState.valueOrNull;
  if (authState.isLoading || currentAuth?.isLoading == true) {
    return const <LeagueSummaryModel>[];
  }
  if (currentAuth?.isAuthenticated != true) {
    return const <LeagueSummaryModel>[];
  }

  return ref.watch(leagueRepositoryProvider).getMyLeaguesSummary();
});

final leagueNotificationsProvider =
    FutureProvider.autoDispose<List<_LeagueNotificationData>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final currentAuth = authState.valueOrNull;
  final userId = currentAuth?.user?.id;
  if (authState.isLoading || currentAuth?.isLoading == true) {
    return const <_LeagueNotificationData>[];
  }
  if (currentAuth?.isAuthenticated != true || userId == null) {
    return const <_LeagueNotificationData>[];
  }

  final leagues = await ref.watch(myLeaguesSummaryProvider.future);
  if (leagues.isEmpty) return const <_LeagueNotificationData>[];

  final leagueRepository = ref.watch(leagueRepositoryProvider);
  final teamRepository = ref.watch(teamRepositoryProvider);
  final notifications = <_LeagueNotificationData>[];

  for (final leagueSummary in leagues) {
    try {
      final league = await leagueRepository.getLeague(leagueSummary.id);
      final userTeams =
          league.teams.where((team) => team.userId == userId).toList();
      if (userTeams.isEmpty) continue;

      notifications.addAll(
        _buildUpcomingMatchNotifications(league, userTeams),
      );

      notifications.addAll(
        _buildPendingAftermatchNotifications(league, userTeams),
      );

      for (final team in userTeams) {
        try {
          final detail = await teamRepository.getUserTeamDetail(
            team.teamId,
            leagueId: league.id,
          );
          final rosterSize =
              detail.players.where((player) => !player.isDead).length;
          if (rosterSize < 11) {
            notifications.add(
              _LeagueNotificationData(
                type: NotificationType.shortRoster,
                title: 'Plantilla por debajo de 11',
                description:
                    'Liga: ${league.name}\nEquipo: ${detail.name} • Solo tienes $rosterSize jugadores en plantilla.',
                meta: detail.name,
                actionLabel: 'Ver roster',
                actionRoute: '/league/${league.id}/team/${detail.id}',
                priority: 2,
              ),
            );
          }

          final availablePlayers = detail.players
              .where(
                (player) =>
                    !player.isDead &&
                    hasAvailableAdvancement(
                        level: player.level, spp: player.spp),
              )
              .toList();
          if (availablePlayers.isEmpty) continue;

          final playerSummary = availablePlayers.length == 1
              ? '${availablePlayers.first.name} puede mejorar.'
              : '${availablePlayers.length} jugadores pueden mejorar.';
          notifications.add(
            _LeagueNotificationData(
              type: NotificationType.levelUp,
              title: availablePlayers.length == 1
                  ? 'Mejora disponible'
                  : '${availablePlayers.length} mejoras disponibles',
              description:
                  'Liga: ${league.name}\nEquipo: ${detail.name} • $playerSummary',
              meta: detail.name,
              actionLabel: 'Ir a mejoras',
              actionRoute: '/league/${league.id}/team/${detail.id}',
              priority: 2,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      continue;
    }
  }

  notifications.sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;
    return a.description.compareTo(b.description);
  });

  return notifications;
});

Match? _nextUpcomingMatchForTeam(League league, String teamId) {
  final upcomingMatches = league.matches
      .where(
        (match) =>
            (match.home.teamId == teamId || match.away.teamId == teamId) &&
            (match.isPending || match.isInProgress),
      )
      .toList();
  upcomingMatches.sort((a, b) {
    final statusRankA = a.isInProgress ? 0 : 1;
    final statusRankB = b.isInProgress ? 0 : 1;
    if (statusRankA != statusRankB) {
      return statusRankA.compareTo(statusRankB);
    }
    final roundCompare = a.round.compareTo(b.round);
    if (roundCompare != 0) return roundCompare;
    final aDate = a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  });
  if (upcomingMatches.isEmpty) return null;
  return upcomingMatches.first;
}

List<_LeagueNotificationData> _buildUpcomingMatchNotifications(
  League league,
  List<LeagueTeam> userTeams,
) {
  final notifications = <_LeagueNotificationData>[];

  for (final team in userTeams) {
    final nextMatch = _nextUpcomingMatchForTeam(league, team.teamId);
    if (nextMatch == null) continue;

    final isHomeTeam = nextMatch.home.teamId == team.teamId;
    final opponentName =
        isHomeTeam ? nextMatch.away.teamName : nextMatch.home.teamName;

    notifications.add(
      _LeagueNotificationData(
        type: NotificationType.nextMatch,
        title: nextMatch.isInProgress ? 'Partido en curso' : 'Próximo partido',
        description: 'Liga: ${league.name}\n${team.teamName} vs $opponentName.',
        meta: 'J${nextMatch.round}',
        actionLabel: nextMatch.isInProgress ? 'Ir al partido' : 'Ver partido',
        actionRoute: '/league/${league.id}/match/${nextMatch.id}/live',
        priority: nextMatch.isInProgress ? 0 : 1,
      ),
    );
  }

  return notifications;
}

List<_LeagueNotificationData> _buildPendingAftermatchNotifications(
  League league,
  List<LeagueTeam> userTeams,
) {
  final notifications = <_LeagueNotificationData>[];

  for (final team in userTeams) {
    for (final match in league.matches) {
      final isHomeTeam = match.home.teamId == team.teamId;
      final isAwayTeam = match.away.teamId == team.teamId;
      if (!match.isPlayed || (!isHomeTeam && !isAwayTeam)) continue;

      final submittedAt = isHomeTeam
          ? match.aftermatchHomeSubmittedAt
          : match.aftermatchAwaySubmittedAt;
      if (submittedAt != null) continue;

      final opponentName =
          isHomeTeam ? match.away.teamName : match.home.teamName;
      notifications.add(
        _LeagueNotificationData(
          type: NotificationType.aftermatch,
          title: 'Informe postpartido pendiente',
          description:
              'Liga: ${league.name}\n${team.teamName} vs $opponentName.',
          meta: 'J${match.round}',
          actionLabel: 'Ir al informe',
          actionRoute: '/league/${league.id}/match/${match.id}/aftermatch',
          priority: 0,
        ),
      );
    }
  }

  return notifications;
}

class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final leaguesAsync = ref.watch(myLeaguesSummaryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1000;
    final isCompact = screenWidth < 700;
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context, isWide, isCompact, lang),
          Expanded(
            child: leaguesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildError(err, lang),
              data: (leagues) =>
                  _buildDashboard(context, leagues, isWide, isCompact, lang),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(
      BuildContext context, bool isWide, bool isCompact, String lang) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(lang, 'dashboard.title'),
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFontFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr(lang, 'dashboard.subtitle'),
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              PhosphorIcons.user(PhosphorIconsStyle.fill),
                              size: 16,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/create-team'),
                          icon: Icon(
                              PhosphorIcons.plus(PhosphorIconsStyle.bold),
                              size: 14),
                          label: Text(tr(lang, 'leagues.team'),
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side:
                                const BorderSide(color: AppColors.surfaceLight),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/leagues/create'),
                          icon: Icon(
                              PhosphorIcons.trophy(PhosphorIconsStyle.bold),
                              size: 14),
                          label: Text(tr(lang, 'leagues.league'),
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.go('/leagues/join'),
                          icon: Icon(
                              PhosphorIcons.signIn(PhosphorIconsStyle.bold),
                              size: 14),
                          label: Text(tr(lang, 'leagues.join'),
                              style: const TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          tr(lang, 'dashboard.title'),
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          tr(lang, 'dashboard.subtitle'),
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/create-team'),
                      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 14),
                      label: Text(
                          isWide
                              ? tr(lang, 'leagues.createTeam')
                              : tr(lang, 'leagues.team'),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.surfaceLight),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/leagues/create'),
                      icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.bold),
                          size: 14),
                      label: Text(
                          isWide
                              ? tr(lang, 'leagues.createLeague')
                              : tr(lang, 'leagues.league'),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => context.go('/leagues/join'),
                      icon: Icon(PhosphorIcons.signIn(PhosphorIconsStyle.bold),
                          size: 14),
                      label: Text(
                          isWide
                              ? tr(lang, 'leagues.joinLeague')
                              : tr(lang, 'leagues.join'),
                          style: const TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill),
                          size: 16, color: AppColors.textMuted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD BODY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDashboard(BuildContext context, List<LeagueSummaryModel> leagues,
      bool isWide, bool isCompact, String lang) {
    if (leagues.isEmpty) {
      return _buildEmpty(context, lang);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myLeaguesSummaryProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            _buildStatsSection(leagues, isCompact, lang),
            const SizedBox(height: 24),
            // Main content
            if (isWide)
              _buildWideLayout(context, leagues, lang)
            else
              _buildNarrowLayout(context, leagues, lang),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsSection(
      List<LeagueSummaryModel> leagues, bool isCompact, String lang) {
    final activeCount = leagues.where((league) => league.isActive).length;
    final draftCount = leagues.where((league) => league.isDraft).length;
    final ownedCount = leagues.where((league) => league.isCommissioner).length;
    final totalTeams = leagues.fold<int>(
      0,
      (sum, league) => sum + league.teamCount,
    );
    final totalSlots = leagues.fold<int>(
      0,
      (sum, league) => sum + league.maxTeams,
    );

    final cards = [
      _StatCard(
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
        label: tr(lang, 'leagues.totalLeagues'),
        value: '${leagues.length}',
        subtext: trf(lang, 'leagues.activeCount', {'n': '$activeCount'}),
        subtextColor: AppColors.success,
      ),
      _StatCard(
        icon: PhosphorIcons.flagCheckered(PhosphorIconsStyle.fill),
        label: tr(lang, 'leagues.openDrafts'),
        value: '$draftCount',
        subtext: tr(lang, 'leagues.pendingKickoff'),
        subtextColor: draftCount > 0 ? AppColors.accent : null,
      ),
      _StatCard(
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        label: tr(lang, 'leagues.registeredTeamsShort'),
        value: '$totalTeams',
        subtext: trf(lang, 'leagues.availableSlots', {'n': '$totalSlots'}),
      ),
      _StatCard(
        icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
        label: tr(lang, 'leagues.commissionerLeagues'),
        value: '$ownedCount',
        subtext: tr(lang, 'leagues.managedByYou'),
        iconColor: AppColors.accent,
      ),
    ];

    if (!isCompact) {
      return Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index != cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUTS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWideLayout(
      BuildContext context, List<LeagueSummaryModel> leagues, String lang) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Active Leagues (larger)
        Expanded(
          flex: 3,
          child: _buildLeaguesSection(context, leagues, lang),
        ),
        const SizedBox(width: 20),
        // Right: Notifications
        Expanded(
          flex: 2,
          child: _buildNotificationsSection(lang),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context, List<LeagueSummaryModel> leagues, String lang) {
    return Column(
      children: [
        _buildLeaguesSection(context, leagues, lang),
        const SizedBox(height: 20),
        _buildNotificationsSection(lang),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEAGUES SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLeaguesSection(
      BuildContext context, List<LeagueSummaryModel> leagues, String lang) {
    final isCompact = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  tr(lang, 'dashboard.activeLeagues'),
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _viewToggleButton(
                    icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                    selected: _isGridView,
                    onTap: () => setState(() => _isGridView = true),
                  ),
                  _viewToggleButton(
                    icon: PhosphorIcons.list(PhosphorIconsStyle.fill),
                    selected: !_isGridView,
                    onTap: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Leagues grid/list
        if (_isGridView && !isCompact)
          _buildLeaguesGrid(context, leagues, lang)
        else
          _buildLeaguesList(context, leagues, lang),
      ],
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon,
            size: 16,
            color: selected ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  Widget _buildLeaguesGrid(
      BuildContext context, List<LeagueSummaryModel> leagues, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = (constraints.maxWidth / 320).floor().clamp(1, 3);
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: leagues
              .map((l) => SizedBox(
                    width: cardWidth,
                    child: _DashboardLeagueCard(
                      league: l,
                      lang: lang,
                      onManage: l.isCommissioner
                          ? () => _showManageDialog(context, l)
                          : null,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildLeaguesList(
      BuildContext context, List<LeagueSummaryModel> leagues, String lang) {
    return Column(
      children: leagues
          .map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DashboardLeagueCard(
                  league: l,
                  lang: lang,
                  isListView: true,
                  onManage: l.isCommissioner
                      ? () => _showManageDialog(context, l)
                      : null,
                ),
              ))
          .toList(),
    );
  }

  Future<void> _showManageDialog(
      BuildContext context, LeagueSummaryModel league) async {
    final lang = ref.read(localeProvider);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => _ManageLeagueDialog(league: league, lang: lang),
    );

    if (action == null || !mounted) return;

    if (action == 'backoffice') {
      this.context.push('/league/${league.id}/backoffice');
      return;
    }

    try {
      if (action == 'archive') {
        await ref.read(leagueRepositoryProvider).archiveLeague(league.id);
        ref.invalidate(myLeaguesSummaryProvider);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content:
                  Text(trf(lang, 'leagues.archived', {'name': league.name})),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (action == 'delete') {
        await ref.read(leagueRepositoryProvider).deleteLeague(league.id);
        ref.invalidate(myLeaguesSummaryProvider);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content:
                  Text(trf(lang, 'leagues.deleted', {'name': league.name})),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(trf(lang, 'common.error', {'e': e.toString()})),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNotificationsSection(String lang) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final notificationsAsync = ref.watch(leagueNotificationsProvider);
    final notificationCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.length,
      orElse: () => 0,
    );
    final counterLabel =
        notificationCount == 1 ? '1 aviso' : '$notificationCount avisos';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  size: 18, color: AppColors.accent),
              Text(
                tr(lang, 'dashboard.notifications'),
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  counterLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          notificationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const _NotificationItem(
              type: NotificationType.info,
              title: 'Avisos no disponibles',
              description: 'No se pudieron cargar los avisos ahora mismo.',
              meta: '',
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return const _NotificationItem(
                  type: NotificationType.info,
                  title: 'Sin avisos pendientes',
                  description:
                      'No tienes informes postpartido ni mejoras pendientes en tus ligas.',
                  meta: '',
                );
              }

              return Column(
                children: [
                  for (var index = 0;
                      index < notifications.length;
                      index++) ...[
                    _NotificationItem(
                      type: notifications[index].type,
                      title: notifications[index].title,
                      description: notifications[index].description,
                      meta: notifications[index].meta,
                      actionLabel: notifications[index].actionLabel,
                      onAction: notifications[index].actionRoute == null
                          ? null
                          : () => context.go(notifications[index].actionRoute!),
                    ),
                    if (index != notifications.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMPTY & ERROR STATES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEmpty(BuildContext context, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight, width: 2),
              ),
              child: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.light),
                  size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              tr(lang, 'dashboard.noLeagues'),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(lang, 'dashboard.noLeaguesBody'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/leagues/join'),
                  icon: Icon(PhosphorIcons.key(PhosphorIconsStyle.bold),
                      size: 16),
                  label: Text(tr(lang, 'dashboard.joinWithCode')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/leagues/create'),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 16),
                  label: Text(tr(lang, 'dashboard.createLeague')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object err, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el dashboard',
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$err',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.invalidate(myLeaguesSummaryProvider),
            icon: Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold)),
            label: Text(tr(lang, 'common.retry')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtext;
  final Color? subtextColor;
  final Color? iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtext,
    this.subtextColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.accent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: iconColor ?? AppColors.accent),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (subtextColor == AppColors.success)
                      Icon(PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                          size: 10, color: subtextColor),
                    if (subtextColor == AppColors.error)
                      Icon(PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                          size: 10, color: subtextColor),
                    if (subtextColor != null) const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        subtext,
                        style: TextStyle(
                          fontSize: 10,
                          color: subtextColor ?? AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD LEAGUE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardLeagueCard extends StatelessWidget {
  final LeagueSummaryModel league;
  final String lang;
  final bool isListView;
  final VoidCallback? onManage;

  const _DashboardLeagueCard({
    required this.league,
    required this.lang,
    this.isListView = false,
    this.onManage,
  });

  // Map format to a display string
  String get _formatLabel {
    switch (league.format) {
      case 'round_robin':
        return tr(lang, 'format.league');
      case 'knockout':
        return tr(lang, 'format.cup');
      case 'swiss':
        return tr(lang, 'format.swiss');
      default:
        return league.format.toUpperCase();
    }
  }

  // A distinct accent color per format for the banner accent strip
  Color get _formatColor {
    switch (league.format) {
      case 'round_robin':
        return const Color.fromARGB(255, 97, 131, 66);
      case 'knockout':
        return AppColors.accent;
      case 'swiss':
        return AppColors.info;
      default:
        return AppColors.surfaceLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/league/${league.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── BANNER ──────────────────────────────────────────────────
            _buildBanner(context),
            // ── BODY ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner row
                  Row(
                    children: [
                      Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
                          size: 15, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          league.ownerUsername,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Team info row
                  _buildInfoRow(
                    icon: PhosphorIcons.shield(PhosphorIconsStyle.fill),
                    label: tr(lang, 'leagues.yourTeam'),
                    value: league.userTeamName ?? 'Sin equipo',
                    valueColor: league.userTeamName != null
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  // Teams count
                  _buildInfoRow(
                    icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    label: tr(lang, 'leagues.teams'),
                    value: '${league.teamCount} / ${league.maxTeams}',
                    valueColor: AppColors.textSecondary,
                  ),
                  if (league.isActive) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
                      label: tr(lang, 'leagues.round'),
                      value:
                          '${tr(lang, 'leagues.round')} ${league.currentRound ?? 1}',
                      valueColor: AppColors.accent,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCta(context),
                      ),
                      if (league.isCommissioner) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: onManage,
                          icon: Icon(
                              PhosphorIcons.sliders(PhosphorIconsStyle.bold),
                              size: 13),
                          label: Text(tr(lang, 'leagues.manage'),
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side:
                                const BorderSide(color: AppColors.surfaceLight),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _formatColor.withOpacity(0.25),
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Diagonal accent strip
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 4,
              height: 95,
              color: _formatColor,
            ),
          ),
          // Background logo
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/bb_logo.png',
                  height: 75,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // League name + format badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _formatColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _formatLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _formatColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (league.isCommissioner) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                tr(lang, 'leagues.commissioner'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        league.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status badge + invite code
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusBadge(status: league.status, lang: lang),
                    if (league.inviteCode != null && league.isDraft) ...[
                      const SizedBox(height: 6),
                      _InviteCodeChip(code: league.inviteCode!, lang: lang),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCta(BuildContext context) {
    if (league.isActive) {
      return FilledButton.icon(
        onPressed: () => context.go('/league/${league.id}'),
        icon: Icon(PhosphorIcons.football(PhosphorIconsStyle.bold), size: 13),
        label: Text(tr(lang, 'leagues.viewLeague'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      );
    } else if (league.isDraft) {
      return OutlinedButton.icon(
        onPressed: () => context.go('/league/${league.id}'),
        icon: Icon(PhosphorIcons.eye(PhosphorIconsStyle.bold), size: 13),
        label: Text(tr(lang, 'leagues.viewLeague'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.surfaceLight),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => context.go('/league/${league.id}'),
        icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.bold), size: 13),
        label: Text(tr(lang, 'leagues.viewResults'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.surfaceLight),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INVITE CODE CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _InviteCodeChip extends StatelessWidget {
  final String code;
  final String lang;
  const _InviteCodeChip({required this.code, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(lang, 'leagues.codeCopied')),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.key(PhosphorIconsStyle.fill),
                size: 10, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              code.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            Icon(PhosphorIcons.copy(PhosphorIconsStyle.regular),
                size: 10, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  final String lang;
  const _StatusBadge({required this.status, required this.lang});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppColors.success;
        label = tr(lang, 'status.active');
        break;
      case 'draft':
        color = AppColors.warning;
        label = tr(lang, 'status.draft');
        break;
      case 'paused':
        color = AppColors.warning;
        label = tr(lang, 'status.paused');
        break;
      case 'completed':
        color = AppColors.textMuted;
        label = tr(lang, 'status.completed');
        break;
      default:
        color = AppColors.textMuted;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION ITEM
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// MANAGE LEAGUE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _ManageLeagueDialog extends StatelessWidget {
  final LeagueSummaryModel league;
  final String lang;
  const _ManageLeagueDialog({required this.league, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(PhosphorIcons.sliders(PhosphorIconsStyle.bold),
                      size: 20, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GESTIONAR LIGA',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                        size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                league.name,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              _ManageOption(
                icon: PhosphorIcons.buildings(PhosphorIconsStyle.fill),
                color: AppColors.info,
                title: 'Backoffice de liga',
                description:
                    'Abre un panel unico para retocar datos de la liga y editar manualmente tesoreria, rerolls, factor de hinchas y otros parametros de los equipos inscritos.',
                enabled: true,
                onTap: () => Navigator.of(context).pop('backoffice'),
              ),
              const SizedBox(height: 12),
              // Archive option
              _ManageOption(
                icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                color: AppColors.warning,
                title: tr(lang, 'leagues.archive'),
                description:
                    'Marca la liga como completada. Se conservan todos los resultados y estadísticas. Esta acción no se puede deshacer.',
                enabled: !league.isDraft,
                disabledReason: league.isDraft
                    ? 'Solo puedes archivar ligas activas o en curso'
                    : null,
                onTap: () => Navigator.of(context).pop('archive'),
              ),
              const SizedBox(height: 12),
              // Delete option
              _ManageOption(
                icon: PhosphorIcons.trash(PhosphorIconsStyle.fill),
                color: AppColors.error,
                title: tr(lang, 'leagues.delete'),
                description:
                    'Borra la liga permanentemente junto con todos sus datos. Solo disponible para ligas en fase de inscripción.',
                enabled: league.isDraft,
                disabledReason: league.isActive
                    ? 'No puedes eliminar una liga activa. Archívala primero.'
                    : !league.isDraft
                        ? 'Solo se pueden eliminar ligas en fase de inscripción.'
                        : null,
                onTap: () => _confirmDelete(context),
              ),
              const SizedBox(height: 20),
              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr(lang, 'leagues.cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Confirmar eliminación',
          style: TextStyle(
            fontFamily: AppTypography.displayFontFamily,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${league.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr(lang, 'leagues.cancel'),
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop('delete');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(tr(lang, 'leagues.deletePermanently')),
          ),
        ],
      ),
    );
  }
}

class _ManageOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback onTap;

  const _ManageOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.enabled,
    this.disabledReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppColors.textMuted;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: effectiveColor.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 18, color: effectiveColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled ? description : (disabledReason ?? description),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 14, color: effectiveColor),
            ],
          ),
        ),
      ),
    );
  }
}

enum NotificationType { levelUp, aftermatch, nextMatch, shortRoster, info }

class _LeagueNotificationData {
  final NotificationType type;
  final String title;
  final String description;
  final String meta;
  final String? actionLabel;
  final String? actionRoute;
  final int priority;

  const _LeagueNotificationData({
    required this.type,
    required this.title,
    required this.description,
    required this.meta,
    this.actionLabel,
    this.actionRoute,
    required this.priority,
  });
}

class _NotificationItem extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String description;
  final String meta;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NotificationItem({
    required this.type,
    required this.title,
    required this.description,
    required this.meta,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bgColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _bgColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _bgColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(
                PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                size: 14,
              ),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: _bgColor,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (type) {
      case NotificationType.levelUp:
        return AppColors.warning;
      case NotificationType.aftermatch:
        return AppColors.info;
      case NotificationType.nextMatch:
        return AppColors.error;
      case NotificationType.shortRoster:
        return AppColors.mng;
      case NotificationType.info:
        return AppColors.info;
    }
  }

  String get _typeLabel {
    switch (type) {
      case NotificationType.levelUp:
        return 'MEJORA';
      case NotificationType.aftermatch:
        return 'POSTPARTIDO';
      case NotificationType.nextMatch:
        return 'PARTIDO';
      case NotificationType.shortRoster:
        return 'PLANTILLA';
      case NotificationType.info:
        return 'INFO';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league_summary.dart';

final myLeaguesSummaryProvider =
    FutureProvider<List<LeagueSummaryModel>>((ref) async {
  return ref.watch(leagueRepositoryProvider).getMyLeaguesSummary();
});

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
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context, isWide, lang),
          Expanded(
            child: leaguesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildError(err, lang),
              data: (leagues) =>
                  _buildDashboard(context, leagues, isWide, lang),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, bool isWide, String lang) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Title section
              Row(
                children: [
                  Text(
                    tr(lang, 'dashboard.title'),
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    tr(lang, 'dashboard.subtitle'),
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              // Action buttons
              OutlinedButton.icon(
                onPressed: () => context.go('/teams/create'),
                icon:
                    Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 14),
                label: Text(
                    isWide
                        ? tr(lang, 'leagues.createTeam')
                        : tr(lang, 'leagues.team'),
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceLight),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar placeholder
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
      bool isWide, String lang) {
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
            _buildStatsRow(leagues, lang),
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

  Widget _buildStatsRow(List<LeagueSummaryModel> leagues, String lang) {
    // Calculate stats from leagues
    final activeLeagues = leagues.where((l) => l.isActive).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
            label: tr(lang, 'dashboard.matchesPlayed'),
            value: '0',
            subtext: trf(lang, 'dashboard.matchesThisSeason', {'n': '0'}),
            subtextColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
            label: tr(lang, 'dashboard.winRate'),
            value: '0%',
            subtext: trf(lang, 'dashboard.totalWinsCount', {'n': '0'}),
            subtextColor: AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
            label: tr(lang, 'dashboard.totalSpp'),
            value: '0',
            subtext: tr(lang, 'dashboard.allActiveTeams'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
            label: tr(lang, 'dashboard.casualties'),
            value: '0',
            subtext: tr(lang, 'dashboard.bloodForNuffle'),
            iconColor: AppColors.error,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              tr(lang, 'dashboard.activeLeagues'),
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            // View toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Row(
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
        if (_isGridView)
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
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: leagues
          .map((l) => SizedBox(
                width: 420,
                child: _DashboardLeagueCard(
                  league: l,
                  lang: lang,
                  onManage:
                      l.isOwner ? () => _showManageDialog(context, l) : null,
                ),
              ))
          .toList(),
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
                  onManage:
                      l.isOwner ? () => _showManageDialog(context, l) : null,
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

    try {
      if (action == 'archive') {
        await ref.read(leagueRepositoryProvider).archiveLeague(league.id);
        ref.invalidate(myLeaguesSummaryProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
          ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
          Row(
            children: [
              Icon(PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                tr(lang, 'dashboard.notifications'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '0 Nuevos',
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
          // Placeholder notifications
          _NotificationItem(
            type: NotificationType.info,
            title: tr(lang, 'dashboard.welcome'),
            description: tr(lang, 'dashboard.welcomeBody'),
            timeAgo: 'Ahora',
          ),
          const SizedBox(height: 12),
          _NotificationItem(
            type: NotificationType.tip,
            title: tr(lang, 'dashboard.tip'),
            description: tr(lang, 'dashboard.tipBody'),
            timeAgo: '',
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
                fontFamily: AppTextStyles.displayFont,
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
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/leagues/join'),
                icon:
                    Icon(PhosphorIcons.key(PhosphorIconsStyle.bold), size: 16),
                label: Text(tr(lang, 'dashboard.joinWithCode')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceLight),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => context.go('/leagues/create'),
                icon:
                    Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
                label: Text(tr(lang, 'dashboard.createLeague')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ]),
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
              fontFamily: AppTextStyles.displayFont,
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
                    fontFamily: AppTextStyles.displayFont,
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
                      if (league.isOwner) ...[
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
                  'images/bb_logo.png',
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
                          if (league.isOwner) ...[
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
                          fontFamily: AppTextStyles.displayFont,
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
                        fontFamily: AppTextStyles.displayFont,
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
            fontFamily: AppTextStyles.displayFont,
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

enum NotificationType { levelUp, matchResult, invitation, info, tip }

class _NotificationItem extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String description;
  final String timeAgo;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _NotificationItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.onAction,
    this.actionLabel,
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
              if (timeAgo.isNotEmpty)
                Text(
                  timeAgo,
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
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: _bgColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:
                      Text(actionLabel!, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (type) {
      case NotificationType.levelUp:
        return AppColors.primary;
      case NotificationType.matchResult:
        return AppColors.info;
      case NotificationType.invitation:
        return AppColors.accent;
      case NotificationType.info:
        return AppColors.info;
      case NotificationType.tip:
        return AppColors.accent;
    }
  }

  String get _typeLabel {
    switch (type) {
      case NotificationType.levelUp:
        return 'SUBIDA DE NIVEL';
      case NotificationType.matchResult:
        return 'RESULTADO';
      case NotificationType.invitation:
        return 'INVITACIÓN A LIGA';
      case NotificationType.info:
        return 'INFO';
      case NotificationType.tip:
        return 'CONSEJO';
    }
  }
}

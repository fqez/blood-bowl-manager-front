import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/user_team.dart';

final myUserTeamsProvider =
    FutureProvider.autoDispose<List<UserTeamSummary>>((ref) async {
  return ref.watch(teamRepositoryProvider).getUserTeams();
});

class MyTeamsScreen extends ConsumerStatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  ConsumerState<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends ConsumerState<MyTeamsScreen> {
  final _searchController = TextEditingController();
  final _sharedTeamCodeController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRace;
  bool _isOpeningSharedTeam = false;
  String? _deletingTeamId;

  @override
  void dispose() {
    _searchController.dispose();
    _sharedTeamCodeController.dispose();
    super.dispose();
  }

  Future<void> _openSharedTeam(String lang) async {
    final teamCode = _sharedTeamCodeController.text.trim();
    if (teamCode.isEmpty || _isOpeningSharedTeam) return;

    setState(() => _isOpeningSharedTeam = true);
    try {
      await ref.read(teamRepositoryProvider).getUserTeamByShareCode(teamCode);
      if (!mounted) return;
      context.go('/teams/shared/$teamCode');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'myTeams.sharedTeamNotFound')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningSharedTeam = false);
    }
  }

  Future<void> _confirmDeleteTeam(UserTeamSummary team, String lang) async {
    if (_deletingTeamId != null) return;

    if (team.leagueMemberships.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'team.deleteBlockedByLeague')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          tr(lang, 'team.deleteTeam'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          trf(lang, 'team.deleteConfirm', {'name': team.name}),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), size: 16),
            label: Text(tr(lang, 'common.delete')),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingTeamId = team.id);
    try {
      await ref.read(teamRepositoryProvider).deleteUserTeam(team.id);
      ref.invalidate(myUserTeamsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'team.deleteDone')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _deletingTeamId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final teamsAsync = ref.watch(myUserTeamsProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, lang),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myUserTeamsProvider),
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildError(context, ref, err, lang),
          data: (teams) => teams.isEmpty
              ? _buildEmptyState(context, lang)
              : _buildTeamOverview(context, teams, isWide, lang),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String lang) {
    final isCompact = MediaQuery.of(context).size.width < 520;

    return AppBar(
      title: Row(
        children: [
          Expanded(
            child: Text(
              tr(lang, 'nav.myTeams').toUpperCase(),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            Text(
              tr(lang, 'team.rosterManagement'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/create-team'),
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
          label: Text(isCompact ? 'Crear' : tr(lang, 'leagues.createTeam')),
        ),
        SizedBox(width: isCompact ? 8 : 16),
      ],
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, Object error, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(tr(lang, 'team.errorLoadingTeams'),
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$error',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(myUserTeamsProvider),
            child: Text(tr(lang, 'common.retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.shield(PhosphorIconsStyle.light),
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr(lang, 'myTeams.emptyTitle'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'myTeams.emptySubtitle'),
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/create-team'),
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
            label: Text(tr(lang, 'leagues.createTeam')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildSharedTeamLookup(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOverview(BuildContext context, List<UserTeamSummary> teams,
      bool isWide, String lang) {
    final races = teams.map((team) => team.raceLabel).toSet().toList()..sort();
    final query = _searchQuery.trim().toLowerCase();
    final filteredTeams = teams.where((team) {
      final matchesRace =
          _selectedRace == null || team.raceLabel == _selectedRace;
      final matchesSearch = query.isEmpty ||
          team.name.toLowerCase().contains(query) ||
          team.raceLabel.toLowerCase().contains(query);
      return matchesRace && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isWide ? 24 : 16,
        isWide ? 24 : 16,
        isWide ? 24 : 16,
        isWide ? 24 : 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewHeader(context, teams, isWide, lang),
          const SizedBox(height: 24),
          _buildControlPanel(lang, races),
          const SizedBox(height: 24),
          if (filteredTeams.isEmpty)
            _buildNoFilteredTeams(lang)
          else
            _buildTeamsWrap(context, filteredTeams, lang),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context, List<UserTeamSummary> teams,
      bool isWide, String lang) {
    final totalTV = teams.fold<int>(0, (sum, team) => sum + team.teamValue);
    final totalPlayers =
        teams.fold<int>(0, (sum, team) => sum + team.playerCount);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _buildOverviewCopy(lang)),
                const SizedBox(width: 20),
                _buildSummaryRow(teams.length, totalPlayers, totalTV, lang),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCopy(lang),
                const SizedBox(height: 16),
                _buildSummaryRow(teams.length, totalPlayers, totalTV, lang),
              ],
            ),
    );
  }

  Widget _buildOverviewCopy(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.shieldChevron(PhosphorIconsStyle.fill),
                color: AppColors.accent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(lang, 'nav.myTeams').toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          tr(lang, 'team.manageRoster'),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildControlPanel(String lang, List<String> races) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          _buildFilters(lang, races),
          const SizedBox(height: 14),
          _buildSharedTeamLookup(lang, embedded: true),
        ],
      ),
    );
  }

  Widget _buildTeamsWrap(
      BuildContext context, List<UserTeamSummary> teams, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
                ? 2
                : 1;
        final spacing = columns == 1 ? 12.0 : 16.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: teams
              .map((team) => SizedBox(
                    width: cardWidth,
                    child: _TeamCard(
                      team: team,
                      lang: lang,
                      isDeleting: _deletingTeamId == team.id,
                      onTap: () => context.go('/teams/${team.id}'),
                      onDelete: () => _confirmDeleteTeam(team, lang),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildFilters(String lang, List<String> races) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final searchField = TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: tr(lang, 'myTeams.searchHint'),
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: Icon(PhosphorIcons.x(), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
          ),
        );

        final raceFilter = DropdownButtonFormField<String>(
          value: _selectedRace,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: tr(lang, 'myTeams.raceFilter'),
            prefixIcon: Icon(PhosphorIcons.shield(), size: 18),
          ),
          dropdownColor: AppColors.surface,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(tr(lang, 'myTeams.allRaces')),
            ),
            ...races.map(
              (race) => DropdownMenuItem<String>(
                value: race,
                child: Text(race, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _selectedRace = value),
        );

        if (isCompact) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 12),
              raceFilter,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: raceFilter),
          ],
        );
      },
    );
  }

  Widget _buildNoFilteredTeams(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(PhosphorIcons.magnifyingGlass(),
              size: 32, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            tr(lang, 'myTeams.noFilteredTeams'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(lang, 'myTeams.adjustFilters'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSharedTeamLookup(String lang, {bool embedded = false}) {
    return Container(
      padding: EdgeInsets.all(embedded ? 0 : 16),
      decoration: BoxDecoration(
        color: embedded ? Colors.transparent : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: embedded ? null : Border.all(color: AppColors.surfaceLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final input = TextField(
            controller: _sharedTeamCodeController,
            onSubmitted: (_) => _openSharedTeam(lang),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: tr(lang, 'myTeams.sharedTeamCode'),
              hintText: tr(lang, 'myTeams.sharedTeamCodeHint'),
              prefixIcon: Icon(PhosphorIcons.identificationCard(), size: 18),
            ),
          );
          final button = ElevatedButton.icon(
            onPressed:
                _isOpeningSharedTeam ? null : () => _openSharedTeam(lang),
            icon: _isOpeningSharedTeam
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(PhosphorIcons.eye(PhosphorIconsStyle.bold), size: 18),
            label: Text(tr(lang, 'myTeams.viewSharedTeam')),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(lang, 'myTeams.viewOtherTeams'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                input,
                const SizedBox(height: 12),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  tr(lang, 'myTeams.viewOtherTeams'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: input),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
      int teamCount, int totalPlayers, int totalTV, String lang) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStat('${teamCount}', tr(lang, 'myTeams.teams')),
        _buildStat('$totalPlayers', tr(lang, 'myTeams.totalPlayers')),
        _buildStat('${totalTV ~/ 1000}k', tr(lang, 'myTeams.totalTV')),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent)),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ──────────────────────── Team Card ──────────────────────────

class _TeamCard extends StatelessWidget {
  final UserTeamSummary team;
  final String lang;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.lang,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 170),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team.raceLabel,
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildDeleteButton(),
                      const SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildLeagueMemberships(),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildChip(PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                      '${team.playerCount}', tr(lang, 'myTeams.players')),
                  _buildChip(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      '${team.teamValue ~/ 1000}k', 'TV'),
                  _buildChip(
                      PhosphorIcons.coins(PhosphorIconsStyle.fill),
                      '${team.treasury ~/ 1000}k',
                      tr(lang, 'myTeams.treasury')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final canDelete = team.leagueMemberships.isEmpty && !isDeleting;
    return Tooltip(
      message: team.leagueMemberships.isEmpty
          ? tr(lang, 'team.deleteTeam')
          : tr(lang, 'team.deleteBlockedByLeague'),
      child: IconButton(
        onPressed: canDelete ? onDelete : null,
        icon: isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), size: 17),
        color: AppColors.error,
        disabledColor: AppColors.textMuted,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          minimumSize: const Size(30, 30),
          fixedSize: const Size(30, 30),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildLeagueMemberships() {
    if (team.leagueMemberships.isEmpty) {
      return Row(
        children: [
          Icon(PhosphorIcons.flag(PhosphorIconsStyle.regular),
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tr(lang, 'team.noLeagueMemberships'),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: team.leagueMemberships
          .map((league) => _buildLeagueChip(league))
          .toList(),
    );
  }

  Widget _buildLeagueChip(TeamLeagueMembership league) {
    final isActive = league.status == 'active';
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.18)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withOpacity(0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? PhosphorIcons.flagBanner(PhosphorIconsStyle.fill)
                : PhosphorIcons.flag(PhosphorIconsStyle.regular),
            size: 13,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${league.name} · ${league.statusLabel}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/teams/${team.baseRosterId}/logo.webp',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                color: AppColors.textMuted, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String value, String label) {
    return Container(
      width: 106,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

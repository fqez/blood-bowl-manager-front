import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/user_team.dart';

final myUserTeamsProvider = FutureProvider<List<UserTeamSummary>>((ref) async {
  return ref.watch(teamRepositoryProvider).getUserTeams();
});

class MyTeamsScreen extends ConsumerWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              : _buildTeamGrid(context, teams, isWide),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String lang) {
    return AppBar(
      title: Row(
        children: [
          Text(
            tr(lang, 'nav.myTeams').toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/create-team'),
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
          label: Text(tr(lang, 'leagues.createTeam')),
        ),
        const SizedBox(width: 16),
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
            'Sin equipos todavía',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer equipo de Blood Bowl para empezar',
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
        ],
      ),
    );
  }

  Widget _buildTeamGrid(
      BuildContext context, List<UserTeamSummary> teams, bool isWide) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          _buildSummaryRow(teams),
          const SizedBox(height: 24),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 1.6 : 2.4,
            ),
            itemCount: teams.length,
            itemBuilder: (context, i) => _TeamCard(
              team: teams[i],
              onTap: () => context.go('/teams/${teams[i].id}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<UserTeamSummary> teams) {
    final totalTV = teams.fold<int>(0, (sum, t) => sum + t.teamValue);

    return Row(
      children: [
        _buildStat('${teams.length}', 'Equipos'),
        const SizedBox(width: 16),
        _buildStat('${teams.fold<int>(0, (s, t) => s + t.playerCount)}',
            'Jugadores en total'),
        const SizedBox(width: 16),
        _buildStat('${totalTV ~/ 1000}k', 'TV total'),
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
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: logo + name
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          team.raceLabel,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: _buildLogo(),
              ),
              const Spacer(),
              // Stats row
              Row(
                children: [
                  _buildChip(PhosphorIcons.soccerBall(PhosphorIconsStyle.fill),
                      '${team.playerCount}', 'Jugadores'),
                  const SizedBox(width: 8),
                  _buildChip(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      '${team.teamValue ~/ 1000}k', 'TV'),
                  const SizedBox(width: 8),
                  _buildChip(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                      '${team.treasury ~/ 1000}k', 'Tesoro'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 150,
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/teams/${team.baseRosterId}/logo.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                color: AppColors.textMuted, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 10, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent)),
              ],
            ),
            Text(label,
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

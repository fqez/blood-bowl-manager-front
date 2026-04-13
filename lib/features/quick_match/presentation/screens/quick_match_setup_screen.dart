import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../league/domain/models/league.dart';
import '../../../shared/data/repositories.dart';

final _userTeamsProvider = FutureProvider<List<UserTeamSummary>>((ref) async {
  final repo = ref.read(teamRepositoryProvider);
  return repo.getUserTeams();
});

class QuickMatchSetupScreen extends ConsumerStatefulWidget {
  const QuickMatchSetupScreen({super.key});

  @override
  ConsumerState<QuickMatchSetupScreen> createState() =>
      _QuickMatchSetupScreenState();
}

class _QuickMatchSetupScreenState extends ConsumerState<QuickMatchSetupScreen> {
  String? _homeTeamId;
  String? _awayTeamId;
  bool _creating = false;

  Future<void> _create() async {
    if (_homeTeamId == null || _awayTeamId == null) return;
    setState(() => _creating = true);
    try {
      final repo = ref.read(quickMatchRepositoryProvider);
      final match = await repo.createQuickMatch(
        homeTeamId: _homeTeamId!,
        awayTeamId: _awayTeamId!,
      );
      if (!mounted) return;
      context.go('/quick-match/${match.id}/live');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final teamsAsync = ref.watch(_userTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(lang),
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error))),
              data: (teams) => _buildBody(teams, lang),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(PhosphorIcons.sword(PhosphorIconsStyle.fill),
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              tr(lang, 'quickMatch.title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<UserTeamSummary> teams, String lang) {
    final wide = MediaQuery.of(context).size.width >= 900;

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warning(PhosphorIconsStyle.regular),
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(tr(lang, 'quickMatch.noTeams'),
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/create-team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(tr(lang, 'nav.createTeam')),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: wide ? 64 : 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Team selectors ──
          if (wide)
            Row(
              children: [
                Expanded(
                    child: _buildTeamSelector(teams, _homeTeamId, true, lang)),
                const SizedBox(width: 24),
                Icon(PhosphorIcons.sword(PhosphorIconsStyle.bold),
                    color: AppColors.primary, size: 40),
                const SizedBox(width: 24),
                Expanded(
                    child: _buildTeamSelector(teams, _awayTeamId, false, lang)),
              ],
            )
          else ...[
            _buildTeamSelector(teams, _homeTeamId, true, lang),
            const SizedBox(height: 16),
            Center(
              child: Icon(PhosphorIcons.sword(PhosphorIconsStyle.bold),
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            _buildTeamSelector(teams, _awayTeamId, false, lang),
          ],
          const SizedBox(height: 40),

          // ── Start button ──
          Center(
            child: SizedBox(
              width: 280,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_homeTeamId != null && _awayTeamId != null && !_creating)
                        ? _create
                        : null,
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Icon(PhosphorIcons.play(PhosphorIconsStyle.fill),
                        size: 20),
                label: Text(
                  tr(lang, 'quickMatch.start'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          // ── Quick match history ──
          const SizedBox(height: 48),
          _buildHistory(lang),
        ],
      ),
    );
  }

  Widget _buildTeamSelector(
    List<UserTeamSummary> teams,
    String? selectedId,
    bool isHome,
    String lang,
  ) {
    final label = isHome
        ? tr(lang, 'quickMatch.homeTeam')
        : tr(lang, 'quickMatch.awayTeam');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selectedId != null ? AppColors.primary : AppColors.surfaceLight,
          width: selectedId != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              )),
          const SizedBox(height: 12),
          ...teams.map((t) {
            final isSelected = t.id == selectedId;
            final isDisabled = (isHome && t.id == _awayTeamId) ||
                (!isHome && t.id == _homeTeamId);

            return Opacity(
              opacity: isDisabled ? 0.35 : 1,
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => setState(() {
                          if (isHome) {
                            _homeTeamId = isSelected ? null : t.id;
                          } else {
                            _awayTeamId = isSelected ? null : t.id;
                          }
                        }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(30)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (t.icon != null && t.icon!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Image.network(t.icon!,
                              width: 28,
                              height: 28,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 28)),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            Text(t.raceLabel,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('TV ${(t.teamValue / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistory(String lang) {
    final historyAsync = ref.watch(_quickMatchHistoryProvider);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(lang, 'quickMatch.history'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...matches.map((m) => _buildHistoryCard(m, lang)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(Match m, String lang) {
    final statusColor = m.isPlayed
        ? AppColors.success
        : m.isInProgress
            ? AppColors.warning
            : AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (m.isInProgress) {
          context.go('/quick-match/${m.id}/live');
        } else if (m.isPlayed) {
          context.go('/quick-match/${m.id}/aftermatch');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(m.home.teamName,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                m.scoreDisplay,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: Text(m.away.teamName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                m.isPlayed
                    ? tr(lang, 'quickMatch.finished')
                    : m.isInProgress
                        ? tr(lang, 'quickMatch.inProgress')
                        : tr(lang, 'quickMatch.pending'),
                style: TextStyle(color: statusColor, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _quickMatchHistoryProvider = FutureProvider<List<Match>>((ref) async {
  final repo = ref.read(quickMatchRepositoryProvider);
  return repo.listQuickMatches();
});

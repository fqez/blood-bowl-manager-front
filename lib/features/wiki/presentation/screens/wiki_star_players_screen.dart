import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/star_player_popup.dart';
import '../../../shared/utils/team_special_rules.dart';
import '../../../roster/domain/models/team.dart';
import '../widgets/wiki_page_chrome.dart';

// ignore_for_file: deprecated_member_use

/// Provider that fetches full detail for every star player in a single request.
final _allStarPlayerDetailsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAllStarPlayerDetails();
});

final _wikiStarTeamsProvider = FutureProvider<List<BaseTeam>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getBaseTeams();
});

class WikiStarPlayersScreen extends ConsumerStatefulWidget {
  const WikiStarPlayersScreen({super.key});

  @override
  ConsumerState<WikiStarPlayersScreen> createState() =>
      _WikiStarPlayersScreenState();
}

class _WikiStarPlayersScreenState extends ConsumerState<WikiStarPlayersScreen> {
  String _search = '';
  String? _teamFilter;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final detailsAsync = ref.watch(_allStarPlayerDetailsProvider);
    final teamsAsync = ref.watch(_wikiStarTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context, lang),
          Expanded(
            child: detailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                    trf(lang, 'wikiStars.errorLoading', {'err': '$err'}),
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (allPlayers) => teamsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    trf(lang, 'wikiStars.errorLoading', {'err': '$err'}),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (teams) => WikiContentScale(
                  child: _buildBody(allPlayers, teams, lang),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, String lang) {
    return WikiPageTopBar(title: tr(lang, 'wikiStars.title'));
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    List<Map<String, dynamic>> allPlayers,
    List<BaseTeam> teams,
    String lang,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final isTeamFiltered = _teamFilter != null;
    final sortedTeams = List<BaseTeam>.from(teams)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Filter
    var filtered = allPlayers;
    if (_teamFilter != null) {
      filtered = filtered
          .where(
            (sp) => starPlayerAvailableForRosterAnyFavoured(
              sp,
              rosterId: _teamFilter!,
            ),
          )
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((sp) =>
              (sp['name'] as String? ?? '').toLowerCase().contains(q) ||
              ((sp['skills'] as List?) ?? [])
                  .any((s) => s.toString().toLowerCase().contains(q)))
          .toList();
    }

    // Sort alphabetically
    filtered.sort((a, b) =>
        (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final sp in filtered) {
      final letter =
          (sp['name'] as String? ?? '?').substring(0, 1).toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(sp);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    _letterKeys.clear();
    for (final letter in sortedLetters) {
      _letterKeys[letter] = GlobalKey();
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 24,
            isCompact ? 8 : 16,
            isCompact ? 14 : 24,
            0,
          ),
          child: Column(
            children: [
              if (isCompact)
                Column(
                  children: [
                    _buildSearchField(lang, compact: true),
                    const SizedBox(height: 8),
                    _buildTeamFilter(sortedTeams, lang, compact: true),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _buildSearchField(lang)),
                    const SizedBox(width: 12),
                    _buildTeamFilter(sortedTeams, lang),
                  ],
                ),
              if (_teamFilter != null && rosterCanChooseFavoured(_teamFilter)) ...[
                const SizedBox(height: 10),
                _buildFavouredTeamHint(lang),
              ],
              if (!isTeamFiltered) ...[
                SizedBox(height: isCompact ? 6 : 10),
                _buildAlphabetIndex(sortedLetters),
              ],
            ],
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        // ── Results count ─────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
          child: Row(
            children: [
              Text(
                '${filtered.length} ${tr(lang, 'wikiStars.title').toLowerCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Player list ───────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    lang == 'es'
                        ? 'No se encontraron jugadores estrella'
                        : 'No star players found',
                    style:
                        const TextStyle(color: AppColors.textMuted, fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 24,
                    0,
                    isCompact ? 16 : 24,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTeamFiltered)
                        _buildStarPlayerGrid(filtered, lang)
                      else
                        ...sortedLetters.map((letter) {
                          return Column(
                            key: _letterKeys[letter],
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildLetterHeader(letter),
                              const SizedBox(height: 8),
                              _buildStarPlayerGrid(grouped[letter]!, lang),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStarPlayerGrid(List<Map<String, dynamic>> players, String lang) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 5
            : constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 640
                    ? 3
                    : constraints.maxWidth > 420
                        ? 2
                        : 1;
        final spacing = constraints.maxWidth > 640 ? 12.0 : 10.0;
        final cardWidth =
            (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: players.map((sp) {
            return SizedBox(
              width: cardWidth,
              child: _buildStarPlayerCard(sp, lang),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Alphabet quick-access ─────────────────────────────────────────────────

  Widget _buildSearchField(String lang, {bool compact = false}) {
    return SizedBox(
      height: compact ? 48 : null,
      child: TextField(
        onChanged: (value) => setState(() => _search = value),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: compact ? 16 : 19,
        ),
        decoration: InputDecoration(
          hintText: tr(lang, 'wikiStars.search'),
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: compact ? 16 : 19,
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
            color: AppColors.textMuted,
            size: compact ? 20 : 22,
          ),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceLight),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 12 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFavouredTeamHint(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIcons.info(PhosphorIconsStyle.fill),
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr(lang, 'wikiStars.favouredTeamHint'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilter(
    List<BaseTeam> teams,
    String lang, {
    bool compact = false,
  }) {
    return Container(
      height: compact ? 48 : null,
      width: compact ? double.infinity : 280,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _teamFilter,
          hint: Text(
            tr(lang, 'wikiStars.teamFilter'),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: compact ? 16 : 19,
            ),
          ),
          dropdownColor: AppColors.card,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 16 : 19,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(lang == 'es' ? 'Todos' : 'All'),
            ),
            ...teams.map(
              (team) => DropdownMenuItem<String?>(
                value: team.id,
                child: SizedBox(
                  width: compact ? 240 : 200,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          'assets/teams/${team.id}/logo.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            PhosphorIcons.shield(PhosphorIconsStyle.fill),
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _teamFilter = value),
        ),
      ),
    );
  }

  Widget _buildAlphabetIndex(List<String> letters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: letters.map((l) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                final key = _letterKeys[l];
                if (key?.currentContext != null) {
                  Scrollable.ensureVisible(
                    key!.currentContext!,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLetterHeader(String letter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            const Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: AppTypography.displayFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 2.4,
        ),
      ),
    );
  }

  // ── Star player card ──────────────────────────────────────────────────────

  Widget _buildStarPlayerCard(Map<String, dynamic> sp, String lang) {
    final id = sp['id'] as String? ?? '';
    final name = sp['name'] as String? ?? '';
    final cost = sp['cost'] as int? ?? 0;
    final stats = sp['stats'] as Map<String, dynamic>? ?? {};
    final skills = (sp['skills'] as List?)?.cast<String>() ?? [];
    final previewSkills = skills.take(6).toList();

    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 520;
    final imageSize = isCompact ? 176.0 : 238.0;
    final imageOverlap = isCompact ? 88.0 : 118.0;
    final bodyTopPadding = isCompact ? 100.0 : 130.0;

    return GestureDetector(
      onTap: () => showStarPlayerPopup(
        context,
        ref,
        starPlayerId: id,
        lang: lang,
        initialStarPlayer: sp,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: imageOverlap),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: isCompact ? 318 : 348,
              ),
              padding: EdgeInsets.fromLTRB(
                isCompact ? 14 : 16,
                bodyTopPadding,
                isCompact ? 14 : 16,
                isCompact ? 14 : 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: isCompact ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                      height: 1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 10 : 12),
                  _buildStatsRow(stats),
                  SizedBox(height: isCompact ? 8 : 10),
                  SizedBox(
                    height: isCompact ? 84 : 72,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 5,
                        runSpacing: 5,
                        children: previewSkills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                height: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.coins(PhosphorIconsStyle.fill),
                        size: isCompact ? 14 : 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${cost ~/ 1000}K',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -imageOverlap,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Image.asset(
                    'assets/images/star_players/$id.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.star(PhosphorIconsStyle.fill),
                          size: 40,
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final entries = ['MA', 'ST', 'AG', 'PA', 'AV'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.map((key) {
        final val = stats[key]?.toString() ?? '-';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 34,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              Text(
                key,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent.withOpacity(0.7),
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

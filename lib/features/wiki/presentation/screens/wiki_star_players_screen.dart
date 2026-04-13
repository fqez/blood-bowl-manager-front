import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';

// ignore_for_file: deprecated_member_use

/// Provider that fetches full detail for every star player in a single request.
final _allStarPlayerDetailsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAllStarPlayerDetails();
});

class WikiStarPlayersScreen extends ConsumerStatefulWidget {
  const WikiStarPlayersScreen({super.key});

  @override
  ConsumerState<WikiStarPlayersScreen> createState() =>
      _WikiStarPlayersScreenState();
}

class _WikiStarPlayersScreenState extends ConsumerState<WikiStarPlayersScreen> {
  String _search = '';
  String? _typeFilter;
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
              data: (allPlayers) => _buildBody(allPlayers, lang),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(PhosphorIcons.book(PhosphorIconsStyle.fill),
                color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Text(
              'WIKI',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const Text('  >  ',
                style: TextStyle(fontSize: 11, color: Colors.white38)),
            Text(
              tr(lang, 'wikiStars.title'),
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(List<Map<String, dynamic>> allPlayers, String lang) {
    // Collect unique types
    final allTypes = <String>{};
    for (final sp in allPlayers) {
      final types = sp['player_types'] as List? ?? [];
      for (final t in types) {
        allTypes.add(t.toString());
      }
    }
    final sortedTypes = allTypes.toList()..sort();

    // Filter
    var filtered = allPlayers;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((sp) =>
              (sp['name'] as String? ?? '').toLowerCase().contains(q) ||
              ((sp['skills'] as List?) ?? [])
                  .any((s) => s.toString().toLowerCase().contains(q)))
          .toList();
    }
    if (_typeFilter != null) {
      filtered = filtered
          .where(
              (sp) => (sp['player_types'] as List? ?? []).contains(_typeFilter))
          .toList();
    }

    // Sort alphabetically
    filtered.sort((a, b) =>
        (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

    // Group by first letter
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final sp in filtered) {
      final letter =
          (sp['name'] as String? ?? '?').substring(0, 1).toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(sp);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    // Prepare letter keys
    _letterKeys.clear();
    for (final l in sortedLetters) {
      _letterKeys[l] = GlobalKey();
    }

    return Column(
      children: [
        // ── Search & filter bar ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              _buildHeader(lang),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: tr(lang, 'wikiStars.search'),
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(
                            PhosphorIcons.magnifyingGlass(
                                PhosphorIconsStyle.regular),
                            color: AppColors.textMuted,
                            size: 18),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.surfaceLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.surfaceLight),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Type filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _typeFilter,
                        hint: const Text('Tipo',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...sortedTypes.map((t) =>
                              DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (v) => setState(() => _typeFilter = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Alphabet index
              _buildAlphabetIndex(sortedLetters),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Results count ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '${filtered.length} ${tr(lang, 'wikiStars.title').toLowerCase()}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                    'No se encontraron jugadores estrella',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedLetters.map((letter) {
                      return Column(
                        key: _letterKeys[letter],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildLetterHeader(letter),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final crossCount = constraints.maxWidth > 900
                                  ? 3
                                  : constraints.maxWidth > 550
                                      ? 2
                                      : 1;
                              final cardW = (constraints.maxWidth -
                                      (crossCount - 1) * 12) /
                                  crossCount;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: grouped[letter]!.map((sp) {
                                  return SizedBox(
                                    width: cardW,
                                    child: _buildStarPlayerCard(sp, lang),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.accent.withOpacity(0.25),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                tr(lang, 'wikiStars.title'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'wikiStars.subtitle'),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Alphabet quick-access ─────────────────────────────────────────────────

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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: AppTextStyles.displayFont,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 2,
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
    final types = (sp['player_types'] as List?)?.cast<String>() ?? [];
    final ability = sp['special_ability'] as Map<String, dynamic>?;
    final playsFor = (sp['plays_for'] as List?)?.cast<String>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 190),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card body ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 200, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                // Name
                Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Cost + types
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                        size: 15, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${(cost ~/ 1000)}K',
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    if (types.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ...types.map((t) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          )),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Stats – centered, large
                _buildStatsRow(stats),
                const SizedBox(height: 10),
                // Skills – clickable, compact
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: skills.map((s) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => showSkillPopup(context, ref, skillName: s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.15)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                AppColors.textSecondary.withOpacity(0.3),
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Special ability
                if (ability != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                PhosphorIcons.lightning(
                                    PhosphorIconsStyle.fill),
                                size: 13,
                                color: AppColors.accent),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                (ability['name'] as String? ?? '')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.displayFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ability['description'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
                // Plays for
                if (playsFor.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        '${tr(lang, 'wikiStars.playsFor')} ',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          playsFor
                              .map((t) => t.replaceAll('_', ' '))
                              .map((t) => t[0].toUpperCase() + t.substring(1))
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Floating image on top ──
          Positioned(
            top: -190,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 380,
                height: 380,
                child: Image.asset(
                  'assets/images/star_players/$id.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
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
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final entries = ['MA', 'ST', 'AG', 'PA', 'AV'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.map((key) {
        final val = stats[key]?.toString() ?? '-';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 5),
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent.withOpacity(0.7),
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 16,
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

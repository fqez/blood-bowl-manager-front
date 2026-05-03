import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';
import '../widgets/wiki_page_chrome.dart';

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
    return WikiPageTopBar(title: tr(lang, 'wikiStars.title'));
  }

  Widget _buildHeader(String lang) {
    return WikiPageHeroHeader(
      icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiStars.title'),
      subtitle: tr(lang, 'wikiStars.subtitle'),
      accentColor: const Color(0xFFCE93D8),
      gradientColor: const Color(0xFF4A148C),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              _buildHeader(lang),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _search = value),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                      ),
                      decoration: InputDecoration(
                        hintText: tr(lang, 'wikiStars.search'),
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 19,
                        ),
                        prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass(
                              PhosphorIconsStyle.regular),
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.surfaceLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.surfaceLight),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _typeFilter,
                        hint: const Text(
                          'Tipo',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 19,
                          ),
                        ),
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...sortedTypes.map(
                            (type) => DropdownMenuItem<String?>(
                              value: type,
                              child: Text(type),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                    'No se encontraron jugadores estrella',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 18),
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
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
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
            padding: const EdgeInsets.fromLTRB(18, 208, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                // Name
                Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                // Cost + types
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                        size: 20, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${(cost ~/ 1000)}K',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    if (types.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ...types.map((t) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                  fontSize: 14,
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
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: skills.map((s) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => showSkillPopup(context, ref, skillName: s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.15)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 14,
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
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
                                size: 18,
                                color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (ability['name'] as String? ?? '')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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

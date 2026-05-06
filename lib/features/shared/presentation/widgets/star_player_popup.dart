import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories.dart';
import 'skill_popup.dart';

final starPlayerDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, starPlayerId) {
  return ref.watch(teamRepositoryProvider).getStarPlayer(starPlayerId);
});

void showStarPlayerPopup(
  BuildContext context,
  WidgetRef ref, {
  required String starPlayerId,
  required String lang,
  Map<String, dynamic>? initialStarPlayer,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final detailsAsync = ref.watch(starPlayerDetailProvider(starPlayerId));
        final fallback = initialStarPlayer;
        final detail = detailsAsync.valueOrNull ?? fallback;
        final isLoading = detailsAsync.isLoading && detail == null;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 820),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 0),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(lang, 'wikiStars.title'),
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                              size: 18),
                          color: AppColors.textMuted,
                          tooltip: tr(lang, 'common.close'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : detailsAsync.hasError && detail == null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    trf(lang, 'wikiStars.errorLoading', {
                                      'err': '${detailsAsync.error}',
                                    }),
                                    style:
                                        const TextStyle(color: AppColors.error),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 190, 18, 18),
                                child: StarPlayerDetailCard(
                                  starPlayer: detail!,
                                  lang: lang,
                                  imageSize: 340,
                                  imageOverlap: 170,
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class StarPlayerDetailCard extends ConsumerWidget {
  const StarPlayerDetailCard({
    super.key,
    required this.starPlayer,
    required this.lang,
    this.imageSize,
    this.imageOverlap,
  });

  final Map<String, dynamic> starPlayer;
  final String lang;
  final double? imageSize;
  final double? imageOverlap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = starPlayer['id'] as String? ?? '';
    final name = starPlayer['name'] as String? ?? '';
    final cost = starPlayer['cost'] as int? ?? 0;
    final stats = starPlayer['stats'] as Map<String, dynamic>? ?? {};
    final skills = (starPlayer['skills'] as List?)?.cast<String>() ?? [];
    final types = (starPlayer['player_types'] as List?)?.cast<String>() ?? [];
    final ability = starPlayer['special_ability'] as Map<String, dynamic>?;
    final playsFor = (starPlayer['plays_for'] as List?)?.cast<String>() ?? [];

    final isCompact = MediaQuery.of(context).size.width < 520;
    final resolvedImageSize = imageSize ?? (isCompact ? 220.0 : 380.0);
    final resolvedImageOverlap = imageOverlap ?? (isCompact ? 110.0 : 190.0);
    final bodyTopPadding = resolvedImageOverlap + 18;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, bodyTopPadding, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: isCompact ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                          size: 20, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        '${cost ~/ 1000}K',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  ...types.map(
                    (type) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StarPlayerStatsRow(stats: stats),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: skills.map((skill) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () =>
                          showSkillPopup(context, ref, skillName: skill),
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
                          skill,
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
              ],
              if (ability != null) ...[
                const SizedBox(height: 10),
                _StarPlayerAbilityBox(ability: ability),
              ],
              if (playsFor.isNotEmpty) ...[
                const SizedBox(height: 8),
                _StarPlayerPlaysFor(lang: lang, playsFor: playsFor),
              ],
            ],
          ),
        ),
        Positioned(
          top: -resolvedImageOverlap,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: resolvedImageSize,
              height: resolvedImageSize,
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
    );
  }
}

class _StarPlayerStatsRow extends StatelessWidget {
  const _StarPlayerStatsRow({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final entries = ['MA', 'ST', 'AG', 'PA', 'AV'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.map((key) {
        final value = stats[key]?.toString() ?? '-';
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
                value,
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

class _StarPlayerAbilityBox extends StatelessWidget {
  const _StarPlayerAbilityBox({required this.ability});

  final Map<String, dynamic> ability;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (ability['name'] as String? ?? '').toUpperCase(),
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
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPlayerPlaysFor extends StatelessWidget {
  const _StarPlayerPlaysFor({required this.lang, required this.playsFor});

  final String lang;
  final List<String> playsFor;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            playsFor
                .map((team) => team.replaceAll('_', ' '))
                .map((team) => team.isEmpty
                    ? team
                    : team[0].toUpperCase() + team.substring(1))
                .join(', '),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

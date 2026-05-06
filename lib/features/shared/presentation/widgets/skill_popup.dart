import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories.dart';

// ignore_for_file: deprecated_member_use

/// Shows a popup dialog with the skill's icon, name, family and description.
///
/// [skillName] is used to look up the perk in [allPerksProvider].
/// The lookup is case-insensitive and tries both the English and Spanish name.
/// [family] and [description] are optional fallbacks.
void showSkillPopup(
  BuildContext context,
  WidgetRef ref, {
  required String skillName,
  String? family,
  String? description,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final lang = ref.watch(localeProvider);
        final perksAsync = ref.watch(allPerksProvider);
        final allPerks = perksAsync.valueOrNull ?? [];
        final isLoading = perksAsync.isLoading && allPerks.isEmpty;

        final match = findPerkDefinition(allPerks, skillName);

        final perkId = match?['_id'] as String? ?? '';
        final displayName = localizedPerkName(allPerks, skillName, lang);
        final alternateName =
            alternateLocalizedPerkName(allPerks, skillName, lang);
        final descMap = match?['description'] as Map? ?? {};
        final displayDescription = localizedPerkValue(
          descMap,
          lang,
          fallback: description ?? '',
        );
        final perkFamily = match?['family'] as String? ?? family ?? '';
        final familyLabel = localizedPerkFamily(perkFamily, lang);
        final color = _familyColor(perkFamily);

        final screenWidth = MediaQuery.of(ctx).size.width;
        final popupWidth = screenWidth < 500 ? screenWidth * 0.92 : 480.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: popupWidth,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient header area
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.18),
                              color.withOpacity(0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Icon
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: color.withOpacity(0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: perkId.isNotEmpty
                                    ? Image.asset(
                                        'assets/images/perks/upscaled/perk-${perkId.replaceAll('_', '-')}.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          _familyIcon(perkFamily),
                                          size: 36,
                                          color: color.withOpacity(0.5),
                                        ),
                                      )
                                    : Icon(
                                        _familyIcon(perkFamily),
                                        size: 36,
                                        color: color.withOpacity(0.5),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Family badge
                            if (perkFamily.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: color.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_familyIcon(perkFamily),
                                        size: 13, color: color),
                                    const SizedBox(width: 6),
                                    Text(
                                      familyLabel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            // Name
                            Text(
                              displayName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (alternateName.isNotEmpty &&
                                alternateName.toLowerCase() !=
                                    displayName.toLowerCase())
                              Text(
                                alternateName,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                      // Description body
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (displayDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: Text(
                              displayDescription,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      // Close
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: color,
                              backgroundColor: color.withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: color.withOpacity(0.2)),
                              ),
                            ),
                            child: Text(tr(lang, 'common.close').toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Map<String, dynamic>? findPerkDefinition(
  List<Map<String, dynamic>> allPerks,
  String value,
) {
  final lowerValue = value.toLowerCase().trim();
  for (final perk in allPerks) {
    final nameMap = perk['name'] as Map? ?? {};
    final id = (perk['_id'] as String? ?? '').toLowerCase().trim();
    final en = (nameMap['en'] as String? ?? '').toLowerCase().trim();
    final es = (nameMap['es'] as String? ?? '').toLowerCase().trim();
    if (id == lowerValue || en == lowerValue || es == lowerValue) {
      return perk;
    }
  }
  return null;
}

String localizedPerkName(
  List<Map<String, dynamic>> allPerks,
  String skillName,
  String lang,
) {
  final match = findPerkDefinition(allPerks, skillName);
  final nameMap = match?['name'] as Map? ?? {};
  return localizedPerkValue(nameMap, lang, fallback: skillName);
}

String alternateLocalizedPerkName(
  List<Map<String, dynamic>> allPerks,
  String skillName,
  String lang,
) {
  final match = findPerkDefinition(allPerks, skillName);
  final nameMap = match?['name'] as Map? ?? {};
  return _alternateLocalizedValue(nameMap, lang);
}

String localizedPerkValue(Map source, String lang, {required String fallback}) {
  final value = source[lang] as String?;
  if (value != null && value.trim().isNotEmpty) return value;

  final english = source['en'] as String?;
  if (english != null && english.trim().isNotEmpty) return english;

  final spanish = source['es'] as String?;
  if (spanish != null && spanish.trim().isNotEmpty) return spanish;

  return fallback;
}

String _alternateLocalizedValue(Map source, String lang) {
  final alternateLang = lang == 'es' ? 'en' : 'es';
  return source[alternateLang] as String? ?? '';
}

String localizedPerkFamily(String family, String lang) {
  final labels = {
    'general': {'es': 'General', 'en': 'General'},
    'agility': {'es': 'Agilidad', 'en': 'Agility'},
    'strength': {'es': 'Fuerza', 'en': 'Strength'},
    'passing': {'es': 'Pase', 'en': 'Passing'},
    'mutation': {'es': 'Mutación', 'en': 'Mutation'},
    'extraordinary': {'es': 'Rasgo', 'en': 'Trait'},
    'trait': {'es': 'Rasgo', 'en': 'Trait'},
    'devious': {'es': 'Juego sucio', 'en': 'Devious'},
  };
  final normalized = family.toLowerCase();
  return labels[normalized]?[lang] ?? family;
}

Color _familyColor(String family) {
  switch (family.toLowerCase()) {
    case 'general':
      return AppColors.skillGeneral;
    case 'agility':
      return AppColors.skillAgility;
    case 'strength':
      return AppColors.skillStrength;
    case 'passing':
      return AppColors.skillPassing;
    case 'mutation':
      return AppColors.skillMutation;
    case 'extraordinary':
    case 'trait':
      return AppColors.skillExtraordinary;
    case 'devious':
      return const Color(0xFFFF6F00);
    default:
      return AppColors.textMuted;
  }
}

IconData _familyIcon(String family) {
  switch (family.toLowerCase()) {
    case 'general':
      return PhosphorIcons.user(PhosphorIconsStyle.fill);
    case 'agility':
      return PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill);
    case 'strength':
      return PhosphorIcons.barbell(PhosphorIconsStyle.fill);
    case 'passing':
      return PhosphorIcons.football(PhosphorIconsStyle.fill);
    case 'mutation':
      return PhosphorIcons.dna(PhosphorIconsStyle.fill);
    case 'extraordinary':
    case 'trait':
      return PhosphorIcons.star(PhosphorIconsStyle.fill);
    case 'devious':
      return PhosphorIcons.knife(PhosphorIconsStyle.fill);
    default:
      return PhosphorIcons.question(PhosphorIconsStyle.fill);
  }
}

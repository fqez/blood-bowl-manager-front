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
  final lang = ref.read(localeProvider);
  final perksAsync = ref.read(allPerksProvider);
  final allPerks = perksAsync.valueOrNull ?? [];

  // Try to find matching perk by name (en or es, case-insensitive)
  final lowerName = skillName.toLowerCase().trim();
  Map<String, dynamic>? match;
  for (final p in allPerks) {
    final nameMap = p['name'] as Map? ?? {};
    final en = (nameMap['en'] as String? ?? '').toLowerCase().trim();
    final es = (nameMap['es'] as String? ?? '').toLowerCase().trim();
    if (en == lowerName || es == lowerName) {
      match = p;
      break;
    }
  }

  final perkId = match?['_id'] as String? ?? '';
  final nameMap = match?['name'] as Map? ?? {};
  final nameEs = nameMap['es'] as String? ?? skillName;
  final nameEn = nameMap['en'] as String? ?? '';
  final descMap = match?['description'] as Map? ?? {};
  final descEs =
      descMap['es'] as String? ?? descMap['en'] as String? ?? description ?? '';
  final perkFamily = match?['family'] as String? ?? family ?? '';
  final color = _familyColor(perkFamily);

  showDialog(
    context: context,
    builder: (ctx) {
      final screenWidth = MediaQuery.of(ctx).size.width;
      final popupWidth = screenWidth < 500 ? screenWidth * 0.92 : 480.0;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                                    perkFamily.toUpperCase(),
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
                          // Name (Spanish)
                          Text(
                            nameEs.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          // Name (English)
                          if (nameEn.isNotEmpty &&
                              nameEn.toLowerCase() != nameEs.toLowerCase())
                            Text(
                              nameEn,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    // Description body
                    if (descEs.isNotEmpty)
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
                            descEs,
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
                              style: TextStyle(
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
  );
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

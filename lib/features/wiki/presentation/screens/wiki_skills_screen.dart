import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';

// ignore_for_file: deprecated_member_use

class WikiSkillsScreen extends ConsumerStatefulWidget {
  const WikiSkillsScreen({super.key});

  @override
  ConsumerState<WikiSkillsScreen> createState() => _WikiSkillsScreenState();
}

class _WikiSkillsScreenState extends ConsumerState<WikiSkillsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final perksAsync = ref.watch(allPerksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context, lang),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(lang),
                  const SizedBox(height: 28),
                  _buildAdvancementTable(lang),
                  const SizedBox(height: 32),
                  _buildSkillsSection(perksAsync, lang),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              tr(lang, 'wikiSkills.title'),
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

  Widget _buildHeader(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                tr(lang, 'wikiSkills.title'),
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
            tr(lang, 'wikiSkills.subtitle'),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // -- Advancement Table (dice roll → skill category) -------------------------

  Widget _buildAdvancementTable(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiSkills.advancement'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Cuando un jugador sube de nivel, tira 2D6 para determinar qué categoría de habilidad puede elegir.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final headers = [
      '1er D6',
      '2do D6',
      'AGILITY',
      'GENERAL',
      'MUTATION',
      'PASSING',
      'STRENGTH',
    ];
    final headerColors = [
      AppColors.textMuted,
      AppColors.textMuted,
      AppColors.skillAgility,
      AppColors.skillGeneral,
      AppColors.skillMutation,
      AppColors.skillPassing,
      AppColors.skillStrength,
    ];

    // Advancement table data: [1stD6, 2ndD6, Agility, General, Mutation, Passing, Strength, Extraordinary]
    final rows = [
      ['1-3', '1', 'Catch', 'Dauntless', 'Big Hand', 'Accurate', 'Arm Bar'],
      [
        '1-3',
        '2',
        'Diving Catch',
        'Dirty Player',
        'Disturbing Presence',
        'Cannoneer',
        'Brawler'
      ],
      [
        '1-3',
        '3',
        'Diving Tackle',
        'Fend',
        'Foul Appearance',
        'Cloud Burster',
        'Break Tackle'
      ],
      ['1-3', '4', 'Dodge', 'Frenzy', 'Horns', 'Dump-Off', 'Grab'],
      [
        '1-3',
        '5',
        'Defensive',
        'Kick',
        'Iron Hard Skin',
        'Fumblerooskie',
        'Guard'
      ],
      [
        '1-3',
        '6',
        'Jump Up',
        'Pro',
        'Tentacles',
        'Hail Mary Pass',
        'Juggernaut'
      ],
      ['4-6', '1', 'Leap', 'Shadowing', 'Two Heads', 'Leader', 'Mighty Blow'],
      [
        '4-6',
        '2',
        'Safe Pair of Hands',
        'Strip Ball',
        'Very Long Legs',
        'Nerves of Steel',
        'Multiple Block'
      ],
      [
        '4-6',
        '3',
        'Sidestep',
        'Sure Hands',
        'Monstrous Mouth',
        'On the Ball',
        'Pile Driver'
      ],
      [
        '4-6',
        '4',
        'Sneaky Git',
        'Tackle',
        'Prehensile Tail',
        'Pass',
        'Stand Firm'
      ],
      [
        '4-6',
        '5',
        'Sprint',
        'Wrestle',
        'Extra Arms',
        'Running Pass',
        'Strong Arm'
      ],
      ['4-6', '6', 'Sure Feet', 'Block', 'Claws', 'Safe Pass', 'Thick Skull'],
    ];

    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.surface),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return AppColors.card;
      }),
      border: TableBorder.all(color: AppColors.surfaceLight, width: 1),
      columnSpacing: 16,
      headingRowHeight: 44,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 36,
      columns: List.generate(headers.length, (i) {
        return DataColumn(
          label: Text(
            headers[i],
            style: TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: headerColors[i],
              letterSpacing: 0.5,
            ),
          ),
        );
      }),
      rows: List.generate(rows.length, (rowIdx) {
        final row = rows[rowIdx];
        final isTopHalf = rowIdx < 6;
        return DataRow(
          color: WidgetStateProperty.all(
            isTopHalf ? AppColors.card : AppColors.surface.withOpacity(0.7),
          ),
          cells: List.generate(row.length, (colIdx) {
            Color textColor;
            FontWeight weight = FontWeight.normal;
            if (colIdx < 2) {
              textColor = AppColors.accent;
              weight = FontWeight.bold;
            } else {
              textColor = headerColors[colIdx].withOpacity(0.85);
            }
            final isSkillCell = colIdx >= 2;
            final families = [
              '',
              '',
              'Agility',
              'General',
              'Mutation',
              'Passing',
              'Strength',
            ];
            return DataCell(
              isSkillCell
                  ? GestureDetector(
                      onTap: () => showSkillPopup(context, ref,
                          skillName: row[colIdx], family: families[colIdx]),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              row[colIdx],
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: weight,
                                decoration: TextDecoration.underline,
                                decorationColor: textColor.withOpacity(0.4),
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      row[colIdx],
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: weight,
                      ),
                    ),
            );
          }),
        );
      }),
    );
  }

  // -- Skills Catalog ---------------------------------------------------------

  Widget _buildSkillsSection(
      AsyncValue<List<Map<String, dynamic>>> perksAsync, String lang) {
    return perksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Text(trf(lang, 'wikiSkills.errorLoading', {'err': '$err'}),
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (perks) {
        // Group by family
        final families = <String, List<Map<String, dynamic>>>{};
        for (final perk in perks) {
          final family = perk['family'] as String? ?? 'General';
          families.putIfAbsent(family, () => []).add(perk);
        }

        // Sort families in a specific order
        final familyOrder = [
          'general',
          'agility',
          'strength',
          'passing',
          'mutation',
          'trait',
          'devious',
        ];
        final sortedFamilies =
            familyOrder.where((f) => families.containsKey(f)).toList();
        // Add any remaining families not in our list
        for (final f in families.keys) {
          if (!sortedFamilies.contains(f)) sortedFamilies.add(f);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedFamilies.map((family) {
            final familyPerks = families[family]!;
            return _buildFamilySection(family, familyPerks);
          }).toList(),
        );
      },
    );
  }

  Widget _buildFamilySection(String family, List<Map<String, dynamic>> perks) {
    final color = _familyColor(family);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Icon(_familyIcon(family), color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  family.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${perks.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Skills grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: perks.map((perk) {
                  final cardWidth =
                      (constraints.maxWidth - (crossAxisCount - 1) * 12) /
                          crossAxisCount;
                  return SizedBox(
                    width: cardWidth,
                    child: _buildSkillCard(perk, family),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> perk, String family) {
    final perkId = perk['_id'] as String? ?? '';
    final nameMap = perk['name'] as Map? ?? {};
    final nameEs = nameMap['es'] as String? ?? '';
    final nameEn = nameMap['en'] as String? ?? '';
    final descMap = perk['description'] as Map? ?? {};
    final descEs = descMap['es'] as String? ?? descMap['en'] as String? ?? '';
    final color = _familyColor(family);

    return GestureDetector(
      onTap: () => showSkillPopup(context, ref,
          skillName: nameEn.isNotEmpty ? nameEn : nameEs, family: family),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Perk image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/images/perks/upscaled/perk-${perkId.replaceAll('_', '-')}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      _familyIcon(family),
                      size: 24,
                      color: color.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameEs.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (nameEn.isNotEmpty)
                      Text(nameEn,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      descEs,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers

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
}

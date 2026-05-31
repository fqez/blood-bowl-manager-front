import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/perk_assets.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

class WikiSkillsScreen extends ConsumerStatefulWidget {
  const WikiSkillsScreen({super.key});

  @override
  ConsumerState<WikiSkillsScreen> createState() => _WikiSkillsScreenState();
}

class _WikiSkillsScreenState extends ConsumerState<WikiSkillsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final perksAsync = ref.watch(allPerksProvider);

    return WikiPageLayout(
      title: tr(lang, 'wikiSkills.title'),
      heroIcon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiSkills.subtitle'),
      accentColor: AppColors.accent,
      gradientColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancementTable(lang, perksAsync),
          const SizedBox(height: 32),
          _buildSkillsSection(perksAsync, lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -- Advancement Table (dice roll → skill category) -------------------------

  Widget _buildAdvancementTable(
      String lang, AsyncValue<List<Map<String, dynamic>>> perksAsync) {
    final perks = perksAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final traitPerks = _traitPerksFrom(perks);

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
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: AppTypography.wikiSectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lang == 'es'
                ? 'Cuando un jugador sube de nivel, tira 2D6 para determinar que categoria de habilidad puede elegir.'
                : 'When a player levels up, roll 2D6 to determine which skill category they may choose from.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    _buildCompactAdvancementList(lang, perks),
                    if (traitPerks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTraitsTable(
                        lang,
                        traitPerks,
                        availableWidth: constraints.maxWidth,
                      ),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: _buildTable(lang, perks),
                      ),
                    ),
                  ),
                  if (traitPerks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildTraitsTable(
                      lang,
                      traitPerks,
                      availableWidth: constraints.maxWidth,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> _advancementHeaders(String lang) => [
        '1er D6',
        '2do D6',
        lang == 'es' ? 'AGILIDAD' : 'AGILITY',
        lang == 'es' ? 'TRIQUIÑUELA' : 'DEVIOUS',
        'GENERAL',
        lang == 'es' ? 'MUTACION' : 'MUTATION',
        lang == 'es' ? 'PASE' : 'PASSING',
        lang == 'es' ? 'FUERZA' : 'STRENGTH',
      ];

  List<Color> get _advancementHeaderColors => [
        AppColors.textMuted,
        AppColors.textMuted,
        AppColors.skillAgility,
        const Color(0xFFFF6F00),
        AppColors.skillGeneral,
        AppColors.skillMutation,
        AppColors.skillPassing,
        AppColors.skillStrength,
      ];

  List<List<String>> get _advancementRows => [
        [
          '1-3',
          '1',
          'Catch',
          'Dirty Player',
          'Block',
          'Big Hand',
          'Accurate',
          'Arm Bar'
        ],
        [
          '1-3',
          '2',
          'Diving Catch',
          'Eye Gouge',
          'Dauntless',
          'Claws',
          'Cannoneer',
          'Brawler'
        ],
        [
          '1-3',
          '3',
          'Diving Tackle',
          'Fumblerooski',
          'Fend',
          'Disturbing Presence',
          'Cloud Burster',
          'Break Tackle'
        ],
        [
          '1-3',
          '4',
          'Dodge',
          'Lethal Flight',
          'Frenzy',
          'Extra Arms',
          'Dump-Off',
          'Bullseye'
        ],
        [
          '1-3',
          '5',
          'Defensive',
          'Lone Fouler',
          'Kick',
          'Foul Appearance',
          'Give and Go',
          'Grab'
        ],
        [
          '1-3',
          '6',
          'Hit and Run',
          'Pile Driver',
          'Pro',
          'Horns',
          'Hail Mary Pass',
          'Guard'
        ],
        [
          '4-6',
          '1',
          'Jump Up',
          'Put the Boot In',
          'Steady Footing',
          'Iron Hard Skin',
          'Leader',
          'Juggernaut'
        ],
        [
          '4-6',
          '2',
          'Leap',
          'Quick Foul',
          'Strip Ball',
          'Monstrous Mouth',
          'Nerves of Steel',
          'Mighty Blow'
        ],
        [
          '4-6',
          '3',
          'Safe Pair of Hands',
          'Saboteur',
          'Sure Hands',
          'Prehensile Tail',
          'On the Ball',
          'Multiple Block'
        ],
        [
          '4-6',
          '4',
          'Sidestep',
          'Shadowing',
          'Tackle',
          'Tentacles',
          'Pass',
          'Stand Firm'
        ],
        [
          '4-6',
          '5',
          'Sprint',
          'Sneaky Git',
          'Taunt',
          'Two Heads',
          'Punt',
          'Strong Arm'
        ],
        [
          '4-6',
          '6',
          'Sure Feet',
          'Violent Innovator',
          'Wrestle',
          'Very Long Legs',
          'Safe Pass',
          'Thick Skull'
        ],
      ];

  String _localizedSkillName(
      String englishName, List<Map<String, dynamic>> perks, String lang) {
    if (lang == 'en') return englishName;

    final normalized = englishName.toLowerCase().trim();
    for (final perk in perks) {
      final nameMap = perk['name'] as Map? ?? {};
      final english = (nameMap['en'] as String? ?? '').toLowerCase().trim();
      if (english == normalized) {
        return nameMap[lang] as String? ?? englishName;
      }
    }

    return _spanishAdvancementSkillFallbacks[englishName] ?? englishName;
  }

  static const Map<String, String> _spanishAdvancementSkillFallbacks = {
    'Catch': 'Atrapar',
    'Dauntless': 'Agallas',
    'Big Hand': 'Mano Grande',
    'Accurate': 'Precisión',
    'Arm Bar': 'Llave de Brazo',
    'Diving Catch': 'Recepción Heroica',
    'Dirty Player': 'Jugar Sucio',
    'Disturbing Presence': 'Presencia Perturbadora',
    'Cannoneer': 'Bombardero',
    'Brawler': 'Luchador',
    'Diving Tackle': 'Placaje Heroico',
    'Fend': 'Zafarse',
    'Foul Appearance': 'Apariencia Asquerosa',
    'Cloud Burster': 'Parte Nubes',
    'Break Tackle': 'Abrirse Paso',
    'Dodge': 'Esquivar',
    'Frenzy': 'Furia',
    'Horns': 'Cuernos',
    'Dump-Off': 'Liberar Rápido',
    'Grab': 'Apartar',
    'Defensive': 'Rompe defensas',
    'Kick': 'Patada',
    'Iron Hard Skin': 'Piel Ferrea',
    'Fumblerooskie': 'Fumblerooskie',
    'Guard': 'Defensa',
    'Jump Up': 'En Pie de un Salto',
    'Pro': 'Profesional',
    'Tentacles': 'Tentáculos',
    'Hail Mary Pass': 'Pase a lo Loco',
    'Juggernaut': 'Imparable',
    'Leap': 'Saltar',
    'Shadowing': 'Perseguir',
    'Two Heads': 'Dos Cabezas',
    'Leader': 'Líder',
    'Mighty Blow': 'Golpe Mortífero',
    'Safe Pair of Hands': 'Proteger el Cuero',
    'Strip Ball': 'Robar Balón',
    'Very Long Legs': 'Piernas Muy Largas',
    'Nerves of Steel': 'Nervios de Acero',
    'Multiple Block': 'Placaje Múltiple',
    'Sidestep': 'Paso Lateral',
    'Sure Hands': 'Manos Seguras',
    'Monstrous Mouth': 'Boca Monstruosa',
    'On the Ball': 'Atento al Balón',
    'Pile Driver': 'Crujir',
    'Sneaky Git': 'Furtivo',
    'Tackle': 'Placaje Defensivo',
    'Prehensile Tail': 'Cola Prensil',
    'Pass': 'Pasar',
    'Stand Firm': 'Mantenerse Firme',
    'Sprint': 'Esprintar',
    'Wrestle': 'Forcejeo',
    'Extra Arms': 'Brazos Adicionales',
    'Running Pass': 'Pase en carrera',
    'Strong Arm': 'Brazo Fuerte',
    'Sure Feet': 'Pies Firmes',
    'Block': 'Placar',
    'Claws': 'Garras',
    'Safe Pass': 'Pase Seguro',
    'Thick Skull': 'Cabeza Dura',
  };

  Widget _buildCompactAdvancementList(
      String lang, List<Map<String, dynamic>> perks) {
    final headers = _advancementHeaders(lang);
    final headerColors = _advancementHeaderColors;
    final rows = _advancementRows;
    final families = [
      '',
      '',
      'agility',
      'devious',
      'general',
      'mutation',
      'passing',
      'strength',
    ];

    return Column(
      children: List.generate(rows.length, (rowIdx) {
        final row = rows[rowIdx];
        final isTopHalf = rowIdx < 6;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: rowIdx == rows.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTopHalf
                ? AppColors.surface.withOpacity(0.35)
                : AppColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDiceBadge(headers[0], row[0]),
                  _buildDiceBadge(headers[1], row[1]),
                ],
              ),
              const SizedBox(height: 10),
              ...List.generate(families.length - 2, (skillIdx) {
                final colIdx = skillIdx + 2;
                final color = headerColors[colIdx];
                final skillName = row[colIdx];

                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: skillName == '-'
                      ? null
                      : () => showSkillPopup(context, ref,
                          skillName: skillName, family: families[colIdx]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(
                            headers[colIdx],
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localizedSkillName(skillName, perks, lang),
                            style: TextStyle(
                              fontSize: 15,
                              color: color.withOpacity(0.9),
                              decoration: skillName == '-'
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                              decorationColor: color.withOpacity(0.4),
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDiceBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTable(String lang, List<Map<String, dynamic>> perks) {
    final headers = _advancementHeaders(lang);
    final headerColors = _advancementHeaderColors;
    final rows = _advancementRows;

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
              fontFamily: AppTypography.displayFontFamily,
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
              textColor = headerColors[colIdx];
            }
            final isSkillCell = colIdx >= 2;
            final families = [
              '',
              '',
              'agility',
              'devious',
              'general',
              'mutation',
              'passing',
              'strength',
            ];
            final skillName = row[colIdx];
            return DataCell(
              isSkillCell
                  ? GestureDetector(
                      onTap: skillName == '-'
                          ? null
                          : () => showSkillPopup(context, ref,
                              skillName: skillName, family: families[colIdx]),
                      child: MouseRegion(
                        cursor: skillName == '-'
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _localizedSkillName(skillName, perks, lang),
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: weight,
                                decoration: skillName == '-'
                                    ? TextDecoration.none
                                    : TextDecoration.underline,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  List<Map<String, dynamic>> _traitPerksFrom(List<Map<String, dynamic>> perks) {
    final traitPerks = perks.where(_isTraitPerk).toList();
    traitPerks.sort((a, b) {
      final nameA = _localizedPerkName(a, 'en').toLowerCase();
      final nameB = _localizedPerkName(b, 'en').toLowerCase();
      return nameA.compareTo(nameB);
    });
    return traitPerks;
  }

  String _localizedPerkName(Map<String, dynamic> perk, String lang) {
    final nameMap = perk['name'] as Map? ?? {};
    final localized = nameMap[lang] as String? ?? '';
    if (localized.isNotEmpty) return localized;
    return (nameMap['en'] as String?) ?? (nameMap['es'] as String?) ?? '';
  }

  Widget _buildTraitsTable(
    String lang,
    List<Map<String, dynamic>> traitPerks, {
    required double availableWidth,
  }) {
    final color = AppColors.skillExtraordinary;

    final columnCount = availableWidth >= 980
        ? 4
        : availableWidth >= 700
            ? 3
            : 2;

    final rows = <TableRow>[];
    for (var index = 0; index < traitPerks.length; index += columnCount) {
      final slice = traitPerks.skip(index).take(columnCount).toList();
      rows.add(
        TableRow(
          children: List.generate(columnCount, (cellIndex) {
            if (cellIndex >= slice.length) {
              return const SizedBox(height: 44);
            }

            final perk = slice[cellIndex];
            final englishName = _localizedPerkName(perk, 'en');
            final localizedName = _localizedPerkName(perk, lang);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showSkillPopup(
                  context,
                  ref,
                  skillName:
                      englishName.isNotEmpty ? englishName : localizedName,
                  family: 'trait',
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    localizedName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                  color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                tr(lang, 'player.traits'),
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: AppTypography.wikiSectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(
              color: AppColors.surfaceLight,
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      ),
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
        final query = _searchQuery.trim().toLowerCase();
        final filteredPerks = query.isEmpty
            ? perks
            : perks.where((perk) => _matchesSearch(perk, query)).toList();

        final skillFamilies = <String, List<Map<String, dynamic>>>{};
        final traitPerks = <Map<String, dynamic>>[];
        for (final perk in filteredPerks) {
          if (_isTraitPerk(perk)) {
            traitPerks.add(perk);
            continue;
          }
          final family = perk['family'] as String? ?? 'General';
          skillFamilies.putIfAbsent(family, () => []).add(perk);
        }

        final familyOrder = [
          'general',
          'agility',
          'devious',
          'strength',
          'passing',
          'mutation',
        ];
        final sortedFamilies =
            familyOrder.where((f) => skillFamilies.containsKey(f)).toList();
        for (final f in skillFamilies.keys) {
          if (!sortedFamilies.contains(f)) sortedFamilies.add(f);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkillSearch(lang, perks.length, filteredPerks.length),
            const SizedBox(height: 16),
            if (filteredPerks.isEmpty)
              _buildNoSkillResults(lang)
            else ...[
              if (sortedFamilies.isNotEmpty) _buildCatalogHeading('SKILLS'),
              ...sortedFamilies.map((family) {
                final familyPerks = skillFamilies[family]!;
                return _buildFamilySection(family, familyPerks, lang);
              }),
              if (traitPerks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.surfaceLight,
                ),
                const SizedBox(height: 24),
                _buildCatalogHeading(tr(lang, 'player.traits')),
              ],
              if (traitPerks.isNotEmpty)
                _buildFamilySection('trait', traitPerks, lang),
            ],
          ],
        );
      },
    );
  }

  bool _isTraitPerk(Map<String, dynamic> perk) {
    final kind = (perk['kind'] as String? ?? '').toLowerCase().trim();
    final family = (perk['family'] as String? ?? '').toLowerCase().trim();
    return kind == 'trait' || family == 'trait' || family == 'extraordinary';
  }

  Widget _buildCatalogHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.displayFontFamily,
          fontSize: AppTypography.wikiSectionTitleFontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  bool _matchesSearch(Map<String, dynamic> perk, String query) {
    final nameMap = perk['name'] as Map? ?? {};
    final descMap = perk['description'] as Map? ?? {};
    final searchable = [
      perkIdFromJson(perk),
      perk['family'],
      perk['kind'],
      perk['elite'] == true ? 'elite' : null,
      nameMap['es'],
      nameMap['en'],
      descMap['es'],
      descMap['en'],
    ]
        .whereType<Object>()
        .map((value) => value.toString().toLowerCase())
        .join(' ');

    return searchable.contains(query);
  }

  Widget _buildSkillSearch(String lang, int totalCount, int visibleCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final countLabel = trf(lang, 'wikiSkills.searchCount', {
            'visible': '$visibleCount',
            'total': '$totalCount',
          });

          final searchField = TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: tr(lang, 'wikiSkills.searchHint'),
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(PhosphorIcons.x(), size: 18),
                      tooltip: tr(lang, 'wikiSkills.clearSearch'),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
            ),
          );

          final counter = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.listMagnifyingGlass(),
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                countLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 10),
                counter,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 16),
              counter,
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoSkillResults(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(PhosphorIcons.magnifyingGlass(),
              size: 32, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            tr(lang, 'wikiSkills.noResults'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(lang, 'wikiSkills.adjustSearch'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(
      String family, List<Map<String, dynamic>> perks, String lang) {
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
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: AppTypography.wikiSectionTitleFontSize,
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
                    height: constraints.maxWidth > 600 ? 132 : 148,
                    child: _buildSkillCard(perk, family, lang),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(
      Map<String, dynamic> perk, String family, String lang) {
    final perkId = perkIdFromJson(perk);
    final nameMap = perk['name'] as Map? ?? {};
    final nameEs = nameMap['es'] as String? ?? '';
    final nameEn = nameMap['en'] as String? ?? '';
    final descMap = perk['description'] as Map? ?? {};
    final descEs = descMap['es'] as String? ?? '';
    final descEn = descMap['en'] as String? ?? '';
    final primaryName = lang == 'es'
        ? (nameEs.isNotEmpty ? nameEs : nameEn)
        : (nameEn.isNotEmpty ? nameEn : nameEs);
    final secondaryName = lang == 'es'
        ? (nameEn.isNotEmpty ? nameEn : nameEs)
        : (nameEs.isNotEmpty ? nameEs : nameEn);
    final description = lang == 'es'
        ? (descEs.isNotEmpty ? descEs : descEn)
        : (descEn.isNotEmpty ? descEn : descEs);
    final color = _familyColor(family);
    final isElite = perk['elite'] == true;

    return GestureDetector(
      onTap: () => showSkillPopup(context, ref,
          skillName: nameEn.isNotEmpty ? nameEn : nameEs, family: family),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: double.infinity,
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
                    perkAssetPath(perkId),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            primaryName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: AppTypography.wikiSectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (isElite) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: color.withOpacity(0.35)),
                            ),
                            child: Text(
                              'ELITE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (secondaryName.isNotEmpty &&
                        secondaryName != primaryName)
                      Text(secondaryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
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

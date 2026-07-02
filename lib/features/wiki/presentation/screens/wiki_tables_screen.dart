import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/team_repository.dart';
import '../widgets/wiki_dice_board.dart';
import '../widgets/wiki_page_layout.dart';

final _wikiTablesCatalogProvider =
    FutureProvider<_WikiTablesCatalog>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return _WikiTablesCatalog(
    weather: await repo.getWeatherRules(),
    kickoffEvents: await repo.getKickoffEventRules(),
    injuries: await repo.getInjuryRules(),
    expensiveMistakes: await repo.getExpensiveMistakesRules(),
    sppRewards: await repo.getSppRewardsRules(),
    advancements: await repo.getAdvancementRules(),
    inducements: await repo.getInducementRules(),
  );
});

class WikiTablesScreen extends ConsumerStatefulWidget {
  const WikiTablesScreen({super.key});

  @override
  ConsumerState<WikiTablesScreen> createState() => _WikiTablesScreenState();
}

class _WikiTablesScreenState extends ConsumerState<WikiTablesScreen> {
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final tablesAsync = ref.watch(_wikiTablesCatalogProvider);

    return WikiPageLayout(
      title: tr(lang, 'wikiTables.title'),
      heroIcon: PhosphorIcons.table(PhosphorIconsStyle.bold),
      subtitle: tr(lang, 'wikiTables.subtitle'),
      accentColor: const Color(0xFFE0B95C),
      gradientColor: const Color(0xFF8C5A1A),
      child: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(lang, error),
        data: (catalog) {
          final sections = _buildSections(lang, catalog);
          for (final section in sections) {
            _sectionKeys.putIfAbsent(section.id, GlobalKey.new);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(lang),
              const SizedBox(height: 20),
              _buildIndexCard(lang, sections),
              const SizedBox(height: 24),
              ...sections.map(
                (section) => Padding(
                  key: _sectionKeys[section.id],
                  padding: const EdgeInsets.only(bottom: 20),
                  child: WikiDiceBoard(
                    headerIcon: section.headerIcon,
                    title: section.title,
                    subtitle: section.subtitle,
                    diceAssetPath: section.diceAssetPath,
                    entries: section.entries,
                    compactRowHeight: section.compactRowHeight,
                    desktopRowHeight: section.desktopRowHeight,
                    showRollCircle: section.showRollCircle,
                    rollTextScale: section.rollTextScale,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String lang, Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(
        trf(lang, 'wikiTables.errorLoading', {'err': '$error'}),
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildIntroCard(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(
        tr(lang, 'wikiTables.catalogNotice'),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildIndexCard(String lang, List<_TableSection> sections) {
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
              Icon(
                PhosphorIcons.listNumbers(PhosphorIconsStyle.bold),
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiTables.indexTitle'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sections
                .map(
                  (section) => InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _scrollToSection(section.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            section.entries.first.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: section.entries.first.color
                              .withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: section.entries.first.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(String sectionId) {
    final context = _sectionKeys[sectionId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.03,
    );
  }

  List<_TableSection> _buildSections(String lang, _WikiTablesCatalog catalog) {
    return [
      _buildRangeSection(
        id: 'weather',
        title: _text(lang, 'Tabla de clima', 'Weather Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 2D6', 'Backend catalogue · 2D6'),
        headerIcon: PhosphorIcons.cloudSun(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/2D6.png',
        entries: catalog.weather.table
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rollLabel,
                title: entry.value.localizedLabel(lang),
                description:
                    _firstSentence(entry.value.localizedDescription(lang)),
                color: _palette(entry.key),
                icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'kickoff',
        title: _text(lang, 'Tabla de evento de saque', 'Kick-off Event Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 2D6', 'Backend catalogue · 2D6'),
        headerIcon: PhosphorIcons.football(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/2D6.png',
        entries: catalog.kickoffEvents.table
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rollLabel,
                title: entry.value.localizedLabel(lang),
                description:
                    _firstSentence(entry.value.localizedDescription(lang)),
                color: _palette(entry.key),
                icon: PhosphorIcons.football(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'injury',
        title: _text(lang, 'Tabla de lesiones', 'Injury Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 2D6', 'Backend catalogue · 2D6'),
        headerIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/2D6.png',
        entries: catalog.injuries.injuryTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rangeLabel,
                title: entry.value.localizedLabel(lang),
                description:
                    _firstSentence(entry.value.localizedDescription(lang)),
                color: _palette(entry.key),
                icon: PhosphorIcons.heartBreak(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'stunty-injury',
        title: _text(lang, 'Tabla de lesiones stunty', 'Stunty Injury Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 2D6', 'Backend catalogue · 2D6'),
        headerIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/2D6.png',
        entries: catalog.injuries.stuntyInjuryTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rangeLabel,
                title: entry.value.localizedLabel(lang),
                description:
                    _firstSentence(entry.value.localizedDescription(lang)),
                color: _palette(entry.key + 1),
                icon: PhosphorIcons.heartBreak(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'casualty',
        title: _text(lang, 'Tabla de bajas', 'Casualty Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 1D16', 'Backend catalogue · 1D16'),
        headerIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D16.png',
        entries: catalog.injuries.casualtyTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rangeLabel,
                title: entry.value.localizedLabel(lang),
                description: _casualtySummary(lang, entry.value),
                color: _palette(entry.key + 2),
                icon: PhosphorIcons.heartBreak(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'lasting-injury',
        title:
            _text(lang, 'Tabla de lesión persistente', 'Lasting Injury Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 1D6', 'Backend catalogue · 1D6'),
        headerIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.injuries.lastingInjuryTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.rangeLabel,
                title: entry.value.localizedLabel(lang),
                description: _lastingSummary(lang, entry.value),
                color: _palette(entry.key + 3),
                icon: PhosphorIcons.heartBreak(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'spp-rewards',
        title: _text(lang, 'Recompensas de SPP', 'SPP Rewards'),
        subtitle: _text(lang, 'Catálogo backend · Logros y MVP',
            'Backend catalogue · Achievements and MVP'),
        headerIcon: PhosphorIcons.trophy(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: _buildSppEntries(lang, catalog.sppRewards),
        showRollCircle: false,
        compactRowHeight: 128,
        desktopRowHeight: 114,
      ),
      _buildRangeSection(
        id: 'advancement-costs',
        title:
            _text(lang, 'Tabla de coste de avances', 'Advancement Cost Table'),
        subtitle: _text(lang, 'Catálogo backend · 1 a 6 avances',
            'Backend catalogue · 1 to 6 advancements'),
        headerIcon: PhosphorIcons.star(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.advancements.costTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: '${entry.value.advancementNumber}',
                title: _localized(entry.value.levelName, lang),
                description: _advancementCostSummary(lang, entry.value),
                color: _palette(entry.key),
                icon: PhosphorIcons.star(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
        compactRowHeight: 136,
        desktopRowHeight: 120,
      ),
      _buildRangeSection(
        id: 'characteristics',
        title: _text(lang, 'Tabla de mejora de característica',
            'Characteristic Improvement Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 1D8', 'Backend catalogue · 1D8'),
        headerIcon: PhosphorIcons.star(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D8.png',
        entries: catalog.advancements.characteristicTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: _rangeLabel(entry.value.minRoll, entry.value.maxRoll),
                title: entry.value.choices.join(' / '),
                description:
                    _firstSentence(_localized(entry.value.description, lang)),
                color: _palette(entry.key + 1),
                icon: PhosphorIcons.star(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'value-increases',
        title: _text(lang, 'Tabla de aumento de valor', 'Value Increase Table'),
        subtitle: _text(lang, 'Catálogo backend · Impacto en TV',
            'Backend catalogue · Team value impact'),
        headerIcon: PhosphorIcons.star(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.advancements.valueIncreases
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: '${entry.key + 1}',
                title: _advancementTypeLabel(lang, entry.value.advancementType),
                description: _text(
                  lang,
                  '+${_formatGold(entry.value.value)} de valor de equipo',
                  '+${_formatGold(entry.value.value)} team value',
                ),
                color: _palette(entry.key + 2),
                icon: PhosphorIcons.star(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
        showRollCircle: false,
      ),
      _buildRangeSection(
        id: 'skill-categories',
        title: _text(lang, 'Tabla de categorías de habilidades',
            'Skill Categories Table'),
        subtitle: _text(lang, 'Catálogo backend · Claves oficiales',
            'Backend catalogue · Official shorthands'),
        headerIcon: PhosphorIcons.book(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.advancements.skillCategories
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: entry.value.symbol,
                title: _localized(entry.value.name, lang),
                description: _text(
                  lang,
                  'Familia ${_formatId(entry.value.family)}',
                  '${_formatId(entry.value.family)} family',
                ),
                color: _palette(entry.key + 3),
                icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'random-primary-skills',
        title: _text(
            lang, 'Tabla de primaria aleatoria', 'Random Primary Skill Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 2D6', 'Backend catalogue · 2D6'),
        headerIcon: PhosphorIcons.book(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/2D6.png',
        entries: catalog.advancements.randomPrimarySkillTable
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: '${entry.value.firstD6Label}/${entry.value.secondD6}',
                title: _text(lang, 'Resultados posibles', 'Possible results'),
                description: entry.value.perkIds.map(_formatId).join(' · '),
                color: _palette(entry.key + 4),
                icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
        compactRowHeight: 142,
        desktopRowHeight: 124,
      ),
      _buildRangeSection(
        id: 'inducements',
        title: _text(lang, 'Catálogo de incentivos', 'Inducement Catalogue'),
        subtitle: _text(lang, 'Catálogo backend · Compra previa al partido',
            'Backend catalogue · Pre-match purchases'),
        headerIcon: PhosphorIcons.shield(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.inducements.inducements
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: _inducementRoll(entry.value),
                title: entry.value.localizedName(lang),
                description: _inducementSummary(lang, entry.value),
                color: _palette(entry.key),
                icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
        showRollCircle: false,
        compactRowHeight: 140,
        desktopRowHeight: 124,
      ),
      _buildRangeSection(
        id: 'prayers-to-nuffle',
        title: _text(
            lang, 'Tabla de plegarias a Nuffle', 'Prayers to Nuffle Table'),
        subtitle:
            _text(lang, 'Catálogo backend · 1D16', 'Backend catalogue · 1D16'),
        headerIcon: PhosphorIcons.shield(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D16.png',
        entries: catalog.inducements.prayersToNuffle
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: '${entry.value.roll}',
                title: entry.value.localizedName(lang),
                description:
                    _firstSentence(entry.value.localizedDescription(lang)),
                color: _palette(entry.key + 1),
                icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
      ),
      _buildRangeSection(
        id: 'expensive-mistakes',
        title:
            _text(lang, 'Tabla de errores caros', 'Expensive Mistakes Table'),
        subtitle: _text(lang, 'Catálogo backend · Bandas de tesorería + D6',
            'Backend catalogue · Treasury bands + D6'),
        headerIcon: PhosphorIcons.coins(PhosphorIconsStyle.bold),
        diceAssetPath: 'assets/images/dice/1D6.png',
        entries: catalog.expensiveMistakes.bands
            .asMap()
            .entries
            .map(
              (entry) => _diceEntry(
                roll: _treasuryBandLabel(entry.value),
                title: _text(lang, 'Resultados por tirada', 'Roll results'),
                description: _expensiveMistakeSummary(
                  lang,
                  band: entry.value,
                  effects: catalog.expensiveMistakes.effects,
                ),
                color: _palette(entry.key + 2),
                icon: PhosphorIcons.coins(PhosphorIconsStyle.regular),
              ),
            )
            .toList(),
        showRollCircle: false,
        compactRowHeight: 150,
        desktopRowHeight: 130,
      ),
    ];
  }
}

_TableSection _buildRangeSection({
  required String id,
  required String title,
  required String subtitle,
  required IconData headerIcon,
  required String diceAssetPath,
  required List<WikiDiceBoardEntry> entries,
  bool showRollCircle = true,
  double compactRowHeight = 124,
  double desktopRowHeight = 110,
  double rollTextScale = 0.34,
}) {
  return _TableSection(
    id: id,
    title: title,
    subtitle: subtitle,
    headerIcon: headerIcon,
    diceAssetPath: diceAssetPath,
    entries: entries,
    showRollCircle: showRollCircle,
    compactRowHeight: compactRowHeight,
    desktopRowHeight: desktopRowHeight,
    rollTextScale: rollTextScale,
  );
}

WikiDiceBoardEntry _diceEntry({
  required String roll,
  required String title,
  required String description,
  required Color color,
  required IconData icon,
}) {
  return WikiDiceBoardEntry(
    roll: roll,
    title: title,
    color: color,
    icon: icon,
    description: description,
  );
}

List<WikiDiceBoardEntry> _buildSppEntries(String lang, SppRewardsRules rules) {
  final entries = <WikiDiceBoardEntry>[];
  for (var i = 0; i < rules.eventRewards.length; i++) {
    final reward = rules.eventRewards[i];
    entries.add(
      _diceEntry(
        roll: '+${reward.spp}',
        title: _eventTypeLabel(lang, reward.eventType),
        description: reward.localizedDescription(lang),
        color: _palette(i),
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
      ),
    );
  }
  entries.add(
    _diceEntry(
      roll: '+${rules.mvpSpp}',
      title: _text(lang, 'MVP', 'MVP'),
      description: _text(
        lang,
        'Jugador más valioso del partido.',
        'Most valuable player of the match.',
      ),
      color: _palette(entries.length),
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
    ),
  );
  entries.add(
    _diceEntry(
      roll:
          '+${rules.throwTeammate.thrownPlayerLandedSpp}/+${rules.throwTeammate.superbThrowerSpp}',
      title: _text(lang, 'Lanzamiento de compañero', 'Throw Team-Mate'),
      description: rules.throwTeammate.localizedDescription(lang),
      color: _palette(entries.length),
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
    ),
  );
  return entries;
}

String _casualtySummary(String lang, CasualtyTableEntry entry) {
  final base = _firstSentence(entry.localizedDescription(lang));
  if (!entry.requiresLastingInjuryRoll) return base;
  return _text(
    lang,
    '$base Requiere una tirada adicional de lesión persistente.',
    '$base Requires an additional lasting injury roll.',
  );
}

String _lastingSummary(String lang, LastingInjuryTableEntry entry) {
  final reduction = entry.reductionLabel.trim();
  if (reduction.isEmpty) {
    return _firstSentence(entry.localizedDescription(lang));
  }
  return '$reduction · ${_firstSentence(entry.localizedDescription(lang))}';
}

String _advancementCostSummary(String lang, AdvancementCostRow row) {
  return _text(
    lang,
    'Primaria aleatoria ${row.randomPrimarySkill} SPP · Primaria elegida ${row.choosePrimarySkill} · Secundaria ${row.chooseSecondarySkill} · Característica ${row.characteristicImprovement}',
    'Random primary ${row.randomPrimarySkill} SPP · Chosen primary ${row.choosePrimarySkill} · Secondary ${row.chooseSecondarySkill} · Characteristic ${row.characteristicImprovement}',
  );
}

String _inducementSummary(String lang, InducementRule rule) {
  final summary = <String>[];
  summary.add(_firstSentence(rule.localizedDescription(lang)));
  summary.add(
    _text(
      lang,
      'Máx. ${rule.maxPerTeam} por equipo',
      'Max ${rule.maxPerTeam} per team',
    ),
  );
  summary.add(_text(lang, 'Duración ${_formatId(rule.duration)}',
      'Duration ${_formatId(rule.duration)}'));
  if (rule.requiredSpecialRules.isNotEmpty) {
    summary.add(
      _text(
        lang,
        'Requiere ${rule.requiredSpecialRules.map(_formatId).join(', ')}',
        'Requires ${rule.requiredSpecialRules.map(_formatId).join(', ')}',
      ),
    );
  }
  return summary.join(' · ');
}

String _inducementRoll(InducementRule rule) {
  if (rule.cost != null) {
    return _formatGold(rule.cost!);
  }
  if (rule.costOptions.isNotEmpty) {
    final values = rule.costOptions.map((option) => option.cost).toList()
      ..sort();
    return '${_formatGold(values.first)}-${_formatGold(values.last)}';
  }
  return _formatId(rule.category);
}

String _expensiveMistakeSummary(
  String lang, {
  required ExpensiveMistakeBand band,
  required Map<String, ExpensiveMistakeEffect> effects,
}) {
  final labels = <String>[];
  for (var index = 0; index < band.results.length; index++) {
    final code = band.results[index];
    final effect = effects[code];
    final label = effect?.localizedLabel(lang) ?? _formatId(code);
    labels.add('${index + 1}: $label');
  }
  return labels.join(' · ');
}

String _treasuryBandLabel(ExpensiveMistakeBand band) {
  final min = _formatGold(band.minTreasury);
  final max = band.maxTreasury == null ? '+' : _formatGold(band.maxTreasury!);
  return max == '+' ? '$min+' : '$min-$max';
}

String _eventTypeLabel(String lang, String eventType) {
  switch (eventType) {
    case 'touchdown':
      return _text(lang, 'Touchdown', 'Touchdown');
    case 'completion':
      return _text(lang, 'Pase completado', 'Completion');
    case 'perfect_completion':
      return _text(lang, 'Pase perfecto', 'Perfect completion');
    case 'interception':
      return _text(lang, 'Intercepción', 'Interception');
    case 'casualty':
      return _text(lang, 'Baja causada', 'Casualty caused');
    case 'deflection':
      return _text(lang, 'Desvío', 'Deflection');
    default:
      return _formatId(eventType);
  }
}

String _advancementTypeLabel(String lang, String value) {
  switch (value) {
    case 'random_primary_skill':
      return _text(lang, 'Primaria aleatoria', 'Random primary skill');
    case 'choose_primary_skill':
      return _text(lang, 'Primaria elegida', 'Chosen primary skill');
    case 'choose_secondary_skill':
      return _text(lang, 'Secundaria elegida', 'Chosen secondary skill');
    case 'characteristic_improvement':
      return _text(
          lang, 'Mejora de característica', 'Characteristic improvement');
    default:
      return _formatId(value);
  }
}

String _rangeLabel(int minRoll, int maxRoll) {
  return minRoll == maxRoll ? '$minRoll' : '$minRoll-$maxRoll';
}

String _formatGold(int value) {
  if (value % 1000 == 0) {
    return '${value ~/ 1000}k';
  }
  return '$value';
}

String _firstSentence(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  final periodIndex = trimmed.indexOf('. ');
  if (periodIndex == -1) return trimmed;
  return trimmed.substring(0, periodIndex + 1);
}

String _formatId(String value) {
  if (value.trim().isEmpty) return value;
  return value
      .split(RegExp(r'[_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _text(String lang, String es, String en) {
  return lang == 'en' ? en : es;
}

String _localized(Map<String, String> values, String lang,
    [String fallback = '']) {
  return values[lang] ?? values['en'] ?? fallback;
}

Color _palette(int index) {
  const palette = <Color>[
    AppColors.accent,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF4DB6AC),
    Color(0xFFFF8A65),
  ];
  return palette[index % palette.length];
}

class _WikiTablesCatalog {
  final DiceRangeRules weather;
  final DiceRangeRules kickoffEvents;
  final InjuryRules injuries;
  final ExpensiveMistakesRules expensiveMistakes;
  final SppRewardsRules sppRewards;
  final AdvancementRules advancements;
  final InducementRules inducements;

  const _WikiTablesCatalog({
    required this.weather,
    required this.kickoffEvents,
    required this.injuries,
    required this.expensiveMistakes,
    required this.sppRewards,
    required this.advancements,
    required this.inducements,
  });
}

class _TableSection {
  final String id;
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final String diceAssetPath;
  final List<WikiDiceBoardEntry> entries;
  final bool showRollCircle;
  final double compactRowHeight;
  final double desktopRowHeight;
  final double rollTextScale;

  const _TableSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.diceAssetPath,
    required this.entries,
    required this.showRollCircle,
    required this.compactRowHeight,
    required this.desktopRowHeight,
    required this.rollTextScale,
  });
}

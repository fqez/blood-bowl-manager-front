import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_dice_board.dart';
import '../widgets/wiki_page_layout.dart';
import '../widgets/wiki_timeline_section.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl injury-related terms.
Map<String, String> _glossary(String lang) {
  final es = lang == 'es';

  return <String, String>{
    'Armour Value': es
        ? 'Valor de Armadura del jugador. Debes superar este valor con 2D6 para romper la armadura.'
        : 'The player\'s Armour Value. You must beat it on 2D6 to break armour.',
    'AV': es ? 'Valor de Armadura del jugador.' : 'The player\'s Armour Value.',
    'Stunned': es
        ? 'Aturdido: el jugador queda boca abajo y pierde su siguiente activacion.'
        : 'Stunned: the player is face down and loses their next activation.',
    'KO': es
        ? 'Inconsciente: el jugador va al banquillo de KO y puede volver mas tarde.'
        : 'Knocked-out: the player goes to the KO box and may return later.',
    'Casualty': es
        ? 'Lesion grave: el jugador sale del campo y se tira en la tabla correspondiente.'
        : 'Serious injury result: the player leaves the pitch and a Casualty roll is made.',
    'Badly Hurt': es
        ? 'Magullado: sin efecto permanente, pero fuera el resto del partido.'
        : 'Badly Hurt: no lasting effect, but the player misses the rest of the game.',
    'Serious Injury': es
        ? 'Herida grave: el jugador sufre una secuela y pierde el siguiente partido.'
        : 'Serious Injury: the player suffers a lasting effect and misses the next game.',
    'Dead': es
        ? 'Muerto: el jugador es eliminado permanentemente del roster.'
        : 'Dead: the player is removed from the roster permanently.',
    'Niggling Injury': es
        ? 'Lesion persistente: suma +1 a futuras tiradas de Casualty.'
        : 'Niggling Injury: adds +1 to future Casualty rolls.',
    'Apothecary': es
        ? 'Apotecario: puede usarse una vez por partido para mejorar un KO o Casualty.'
        : 'Apothecary: may be used once per game to improve a KO or Casualty result.',
    'Regeneration': es
        ? 'Regeneracion: permite ignorar una Casualty con una tirada de 4+.'
        : 'Regeneration: may ignore a Casualty on a 4+ roll.',
    'Mighty Blow': es
        ? 'Golpe Poderoso: anade +1 a Armadura o Lesion, pero no a ambas.'
        : 'Mighty Blow: adds +1 to Armour or Injury, but not both.',
    'Claw': es
        ? 'Garra: al tirar Armadura tras un bloqueo, trata la AV rival como 8+.'
        : 'Claw: when making an Armour roll after a block, treat the opponent as AV 8+.',
    'Foul': es
        ? 'Falta: patear a un jugador caido, con riesgo de expulsion.'
        : 'Foul: kicking a prone player with a risk of being sent off.',
    'Piling On': es
        ? 'Ensanamiento: permite repetir Armadura o Lesion al bloquear.'
        : 'Piling On: allows an Armour or Injury reroll after a block.',
  };
}

class WikiInjuriesScreen extends ConsumerWidget {
  const WikiInjuriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return WikiPageLayout(
      title: tr(lang, 'wikiInjuries.title'),
      heroIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiInjuries.subtitle'),
      accentColor: const Color(0xFFEF5350),
      gradientColor: const Color(0xFFB71C1C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArmourRollSection(lang),
          const SizedBox(height: 32),
          _buildInjuryTable(lang),
          const SizedBox(height: 32),
          _buildStuntyInjuryTable(lang),
          const SizedBox(height: 32),
          _buildCasualtyTable(lang),
          const SizedBox(height: 32),
          _buildAttributeReductionSection(lang),
          const SizedBox(height: 32),
          _buildModifiersSection(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Armour Roll ─────────────────────────────────────────────────────────────

  Widget _buildArmourRollSection(String lang) {
    final es = lang == 'es';
    final steps = [
      WikiTimelineEntry(
        marker: '1',
        title: es ? 'TIRADA DE ARMADURA' : 'ARMOUR ROLL',
        subtitle: es ? 'Armour Roll' : 'TIRADA DE ARMADURA',
        icon: PhosphorIcons.shieldChevron(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description: es
            ? 'Cuando un jugador es derribado, el rival tira 2D6. Si supera el Armour Value, la armadura se rompe.'
            : 'When a player is Knocked Down, the opponent rolls 2D6. If the result beats the Armour Value, the armour is broken.',
      ),
      WikiTimelineEntry(
        marker: '2',
        title: es ? 'TIRADA DE LESION' : 'INJURY ROLL',
        subtitle: es ? 'Injury Roll' : 'TIRADA DE LESION',
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Si la armadura se rompe, se tira en la tabla de Lesiones para ver si el jugador queda Aturdido, KO o sufre Casualty.'
            : 'If armour breaks, roll on the Injury table to see whether the player is Stunned, KO, or suffers a Casualty.',
      ),
      WikiTimelineEntry(
        marker: '3',
        title: es ? 'TABLA DE BAJAS' : 'CASUALTY TABLE',
        subtitle: es ? 'Casualty Table' : 'TABLA DE BAJAS',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFB71C1C),
        description: es
            ? 'Si sale Casualty, tira 1D16 para saber si el jugador queda Magullado, pierde el siguiente partido, sufre secuelas o muere.'
            : 'If the result is a Casualty, roll 1D16 to find out whether the player is Badly Hurt, misses the next game, suffers lasting damage, or dies.',
      ),
    ];

    return WikiTimelineSection(
      headerIcon: PhosphorIcons.listNumbers(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiInjuries.procedure'),
      subtitle: es
          ? 'Secuencia completa cuando un jugador es derribado.'
          : 'Full sequence when a player is knocked down.',
      entries: steps,
      railColor: Colors.white.withOpacity(0.58),
      railWidth: 52,
      circleSize: 24,
      lineWidth: 3,
      itemSpacing: 6,
      circleLineGap: 6,
      descriptionBuilder: (context, entry, fontSize) => _buildRichDescription(
        entry.description,
        lang: lang,
        fontSize: fontSize,
      ),
    );
  }

  // ── Injury Table ────────────────────────────────────────────────────────────

  Widget _buildInjuryTable(String lang) {
    return FutureBuilder<List<WikiDiceBoardEntry>>(
      future: _loadInjuryEntries(lang),
      builder: (context, snapshot) {
        final injuries = snapshot.data ?? _fallbackInjuryEntries(lang);

        return WikiDiceBoard(
          headerIcon: PhosphorIcons.hash(PhosphorIconsStyle.fill),
          title: tr(lang, 'wikiInjuries.injuryTable'),
          subtitle: lang == 'es'
              ? 'Se tiran 2D6 cuando la armadura del jugador se rompe.'
              : 'Roll 2D6 when a player\'s armour has been broken.',
          diceAssetPath: 'assets/images/dice/2D6.png',
          entries: injuries,
          descriptionBuilder: (context, entry, fontSize) =>
              _buildRichDescription(entry.description,
                  lang: lang, fontSize: fontSize),
        );
      },
    );
  }

  Widget _buildStuntyInjuryTable(String lang) {
    return FutureBuilder<List<WikiDiceBoardEntry>>(
      future: _loadStuntyInjuryEntries(lang),
      builder: (context, snapshot) {
        final injuries = snapshot.data ?? _fallbackStuntyInjuryEntries(lang);

        return WikiDiceBoard(
          headerIcon: PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill),
          title: lang == 'es'
              ? 'TABLA DE HERIDAS PARA ESCURRIDIZOS'
              : 'STUNTY INJURY TABLE',
          subtitle: lang == 'es'
              ? 'Se usa en lugar de la tabla normal para jugadores con Escurridizo.'
              : 'Used instead of the standard injury table for players with Stunty.',
          diceAssetPath: 'assets/images/dice/2D6.png',
          entries: injuries,
          descriptionBuilder: (context, entry, fontSize) =>
              _buildRichDescription(entry.description,
                  lang: lang, fontSize: fontSize),
        );
      },
    );
  }

  Future<List<WikiDiceBoardEntry>> _loadInjuryEntries(String lang) async {
    return _loadInjuryEntriesByTitle(
      lang,
      tableTitle: 'INJURY TABLE / TABLA DE LESIONES',
      fallback: _fallbackInjuryEntries(lang),
    );
  }

  Future<List<WikiDiceBoardEntry>> _loadStuntyInjuryEntries(String lang) async {
    return _loadInjuryEntriesByTitle(
      lang,
      tableTitle: 'STUNTY INJURY TABLE / TABLA DE LESIONES PARA ESCURRIDIZOS',
      fallback: _fallbackStuntyInjuryEntries(lang),
    );
  }

  Future<List<WikiDiceBoardEntry>> _loadInjuryEntriesByTitle(
    String lang, {
    required String tableTitle,
    required List<WikiDiceBoardEntry> fallback,
  }) async {
    final raw = await rootBundle.loadString('assets/rules/rules.json');
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return fallback;
    }

    for (final page in decoded) {
      if (page is! Map<String, dynamic>) {
        continue;
      }

      final sections = page['sections'];
      if (sections is! List) {
        continue;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) {
          continue;
        }

        final title = (section['title'] ?? '').toString();
        if (title != tableTitle) {
          continue;
        }

        final table = section['table'];
        if (table is! List) {
          return fallback;
        }

        return table
            .whereType<Map<String, dynamic>>()
            .map((item) => _injuryEntryFromCatalog(item, lang))
            .toList(growable: false);
      }
    }

    return fallback;
  }

  WikiDiceBoardEntry _injuryEntryFromCatalog(
    Map<String, dynamic> item,
    String lang,
  ) {
    final result = (item['Result'] ?? '').toString();
    final parts = result.split(' / ');
    final resultEn = parts.isNotEmpty ? parts.first.trim() : result;
    final resultEs = parts.length > 1 ? parts.last.trim() : result;
    final visuals = _injuryVisuals(resultEn);

    return WikiDiceBoardEntry(
      roll: (item['2D6'] ?? '').toString().replaceAll('-', '–'),
      title: lang == 'es' ? resultEs : resultEn,
      subtitle: lang == 'es' ? resultEn : resultEs,
      icon: visuals.icon,
      color: visuals.color,
      description:
          (lang == 'es' ? item['Description_es'] : item['Description_en'])
              .toString(),
    );
  }

  List<WikiDiceBoardEntry> _fallbackInjuryEntries(String lang) {
    final es = lang == 'es';

    return [
      WikiDiceBoardEntry(
        roll: '2–7',
        title: es ? 'ATURDIDO' : 'STUNNED',
        subtitle: es ? 'STUNNED' : 'ATURDIDO',
        icon: PhosphorIcons.smileyXEyes(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El jugador queda Aturdido inmediatamente.'
            : 'The player is immediately Stunned.',
      ),
      WikiDiceBoardEntry(
        roll: '8–9',
        title: es ? 'INCONSCIENTE' : 'KNOCKED-OUT',
        subtitle: es ? 'KNOCKED-OUT' : 'INCONSCIENTE',
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'El jugador queda Inconsciente inmediatamente. Retíralo del campo y colócalo en la zona de Inconscientes de su banquillo.'
            : 'The player is immediately Knocked-out. Remove them from the pitch and place them in the Knocked-out box of their dugout.',
      ),
      WikiDiceBoardEntry(
        roll: '10–12',
        title: es ? 'LESIONADO' : 'CASUALTY',
        subtitle: es ? 'CASUALTY' : 'LESIONADO',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: es
            ? 'El jugador sufre una lesión. Retíralo del campo y colócalo en la zona de Lesionados de su banquillo. A continuación el Entrenador del equipo rival hace una tirada de Lesiones contra él.'
            : 'The player suffers a Casualty. Remove them from the pitch and place them in the Casualty box of their dugout. The Coach of the opposing team then makes a Casualty Roll against them.',
      ),
    ];
  }

  List<WikiDiceBoardEntry> _fallbackStuntyInjuryEntries(String lang) {
    final es = lang == 'es';

    return [
      WikiDiceBoardEntry(
        roll: '2–6',
        title: es ? 'ATURDIDO' : 'STUNNED',
        subtitle: es ? 'STUNNED' : 'ATURDIDO',
        icon: PhosphorIcons.smileyXEyes(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El jugador queda Aturdido inmediatamente.'
            : 'The player is immediately Stunned.',
      ),
      WikiDiceBoardEntry(
        roll: '7–8',
        title: es ? 'INCONSCIENTE' : 'KNOCKED-OUT',
        subtitle: es ? 'KNOCKED-OUT' : 'INCONSCIENTE',
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'El jugador queda Inconsciente inmediatamente. Retíralo del campo y colócalo en la zona de Inconscientes de su banquillo.'
            : 'The player is immediately Knocked-out. Remove them from the pitch and place them in the Knocked-out box of their dugout.',
      ),
      WikiDiceBoardEntry(
        roll: '9',
        title: es ? 'MAGULLADO' : 'BADLY HURT',
        subtitle: es ? 'BADLY HURT' : 'MAGULLADO',
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        color: const Color(0xFF8BC34A),
        description: es
            ? 'El jugador sufre una lesión. Retíralo del campo y colócalo en la zona de Lesionados de su banquillo. En una liga, no hagas una tirada de Lesiones por él; en su lugar, el jugador sufre automáticamente el resultado de Magullado de la tabla de Lesiones.'
            : 'The player suffers a Casualty. Remove them from the pitch and place them in the Casualty box of their dugout. In League Play, no Casualty Roll is made for them, instead they automatically suffer the Badly Hurt result on the Casualty Table.',
      ),
      WikiDiceBoardEntry(
        roll: '10–12',
        title: es ? 'LESIONADO' : 'CASUALTY',
        subtitle: es ? 'CASUALTY' : 'LESIONADO',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: es
            ? 'El jugador sufre una lesión. Retíralo del campo y colócalo en la zona de Lesionados de su banquillo. A continuación el Entrenador del equipo rival hace una tirada de Lesiones contra él.'
            : 'The player suffers a Casualty. Remove them from the pitch and place them in the Casualty box of their dugout. The Coach of the opposing team then makes a Casualty Roll against them.',
      ),
    ];
  }

  ({IconData icon, Color color}) _injuryVisuals(String resultEn) {
    switch (resultEn) {
      case 'STUNNED':
        return (
          icon: PhosphorIcons.smileyXEyes(PhosphorIconsStyle.fill),
          color: const Color(0xFF66BB6A),
        );
      case 'KNOCKED-OUT':
        return (
          icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
          color: const Color(0xFFFFA726),
        );
      case 'BADLY HURT':
        return (
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          color: const Color(0xFF8BC34A),
        );
      case 'CASUALTY':
      default:
        return (
          icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
          color: const Color(0xFFE53935),
        );
    }
  }

  // ── Casualty Table ──────────────────────────────────────────────────────────

  Widget _buildCasualtyTable(String lang) {
    return FutureBuilder<List<WikiDiceBoardEntry>>(
      future: _loadCasualtyEntries(lang),
      builder: (context, snapshot) {
        final casualties = snapshot.data ?? _fallbackCasualtyEntries(lang);

        return WikiDiceBoard(
          headerIcon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
          title: tr(lang, 'wikiInjuries.casualtyTable'),
          subtitle: lang == 'es'
              ? 'Se tira 1D16 cuando un jugador sufre una Casualty.'
              : 'Roll 1D16 when a player suffers a Casualty.',
          diceAssetPath: 'assets/images/dice/1D16.png',
          entries: casualties,
          descriptionBuilder: (context, entry, fontSize) =>
              _buildRichDescription(entry.description,
                  lang: lang, fontSize: fontSize),
        );
      },
    );
  }

  Future<List<WikiDiceBoardEntry>> _loadCasualtyEntries(String lang) async {
    final raw = await rootBundle.loadString('assets/rules/rules.json');
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return _fallbackCasualtyEntries(lang);
    }

    for (final page in decoded) {
      if (page is! Map<String, dynamic>) {
        continue;
      }

      final sections = page['sections'];
      if (sections is! List) {
        continue;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) {
          continue;
        }

        final title = (section['title'] ?? '').toString();
        if (title != 'CASUALTY TABLE / TABLA DE LESIONES GRAVES') {
          continue;
        }

        final table = section['table'];
        if (table is! List) {
          return _fallbackCasualtyEntries(lang);
        }

        return table
            .whereType<Map<String, dynamic>>()
            .map((item) => _casualtyEntryFromCatalog(item, lang))
            .toList(growable: false);
      }
    }

    return _fallbackCasualtyEntries(lang);
  }

  WikiDiceBoardEntry _casualtyEntryFromCatalog(
    Map<String, dynamic> item,
    String lang,
  ) {
    final result = (item['Result'] ?? '').toString();
    final parts = result.split(' / ');
    final resultEn = parts.isNotEmpty ? parts.first.trim() : result;
    final resultEs = parts.length > 1 ? parts.last.trim() : result;
    final visuals = _casualtyVisuals(resultEn);

    return WikiDiceBoardEntry(
      roll: (item['D16'] ?? '').toString().replaceAll('-', '–'),
      title: lang == 'es' ? resultEs : resultEn,
      subtitle: lang == 'es' ? resultEn : resultEs,
      icon: visuals.icon,
      color: visuals.color,
      description:
          (lang == 'es' ? item['Description_es'] : item['Description_en'])
              .toString(),
    );
  }

  List<WikiDiceBoardEntry> _fallbackCasualtyEntries(String lang) {
    final es = lang == 'es';

    return [
      WikiDiceBoardEntry(
        roll: '1–8',
        title: es ? 'MAGULLADO' : 'BADLY HURT',
        subtitle: es ? 'BADLY HURT' : 'MAGULLADO',
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El jugador no sufre efectos a largo plazo.'
            : 'The player suffers no long term effects.',
      ),
      WikiDiceBoardEntry(
        roll: '9–10',
        title: es ? 'APALEADO' : 'SERIOUSLY HURT',
        subtitle: es ? 'SERIOUSLY HURT' : 'APALEADO',
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'El jugador se pierde el próximo partido.'
            : 'The player must miss their next game.',
      ),
      WikiDiceBoardEntry(
        roll: '11–12',
        title: es ? 'HERIDA GRAVE' : 'SERIOUS INJURY',
        subtitle: es ? 'SERIOUS INJURY' : 'HERIDA GRAVE',
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'El jugador sufre una Lesión mal curada y se pierde el próximo partido.'
            : 'The player suffers a Niggling Injury and must miss their next game.',
      ),
      WikiDiceBoardEntry(
        roll: '13–14',
        title: es ? 'HERIDA PERMANENTE' : 'LASTING INJURY',
        subtitle: es ? 'LASTING INJURY' : 'HERIDA PERMANENTE',
        icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
        color: const Color.fromARGB(255, 165, 239, 80),
        description: es
            ? 'El jugador sufre una reducción de atributo y se pierde el próximo partido.'
            : 'The player suffers a Characteristic reduction and must miss their next game.',
      ),
      WikiDiceBoardEntry(
        roll: '15–16',
        title: es ? 'MUERTO' : 'DEAD',
        subtitle: es ? 'DEAD' : 'MUERTO',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFB71C1C),
        description: es ? '¡El jugador ha muerto!' : 'The player is dead!',
      ),
    ];
  }

  ({IconData icon, Color color}) _casualtyVisuals(String resultEn) {
    switch (resultEn) {
      case 'BADLY HURT':
        return (
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          color: const Color(0xFF66BB6A),
        );
      case 'SERIOUSLY HURT':
        return (
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFFFFA726),
        );
      case 'SERIOUS INJURY':
        return (
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFFEF5350),
        );
      case 'LASTING INJURY':
        return (
          icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
          color: const Color.fromARGB(255, 165, 239, 80),
        );
      case 'DEAD':
      default:
        return (
          icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
          color: const Color(0xFFB71C1C),
        );
    }
  }

  // ── Attribute Reduction ───────────────────────────────────────────────────

  Widget _buildAttributeReductionSection(String lang) {
    return FutureBuilder<_AttributeReductionSectionData>(
      future: _loadAttributeReductionData(lang),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _fallbackAttributeReductionData(lang);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WikiDiceBoard(
              headerIcon: PhosphorIcons.chartLineDown(PhosphorIconsStyle.fill),
              title: lang == 'es'
                  ? 'REDUCCION DE ATRIBUTO'
                  : 'CHARACTERISTIC REDUCTION',
              subtitle: data.intro,
              diceAssetPath: 'assets/images/dice/1D6.png',
              entries: data.entries,
              descriptionBuilder: (context, entry, fontSize) =>
                  _buildAttributeReductionDescription(
                lang,
                entry.description,
                fontSize,
                entry.color,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                data.note,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_AttributeReductionSectionData> _loadAttributeReductionData(
    String lang,
  ) async {
    final raw = await rootBundle.loadString('assets/rules/rules.json');
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return _fallbackAttributeReductionData(lang);
    }

    String? intro;
    String? note;
    List<WikiDiceBoardEntry>? entries;

    for (final page in decoded) {
      if (page is! Map<String, dynamic>) {
        continue;
      }

      final sections = page['sections'];
      if (sections is! List) {
        continue;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) {
          continue;
        }

        final title = (section['title'] ?? '').toString();

        if (title == 'CHARACTERISTIC REDUCTION / REDUCCIÓN DE CARACTERÍSTICA') {
          intro = (lang == 'es' ? section['es'] : section['en']).toString();
          note = (lang == 'es' ? section['note_es'] : section['note_en'])
              .toString();
        }

        if (title == 'LASTING INJURY TABLE / TABLA DE LESIONES PERMANENTES') {
          final table = section['table'];
          if (table is List) {
            entries = table
                .whereType<Map<String, dynamic>>()
                .map((item) => _attributeReductionEntryFromCatalog(item, lang))
                .toList(growable: false);
          }
        }
      }
    }

    if (intro == null || note == null || entries == null) {
      return _fallbackAttributeReductionData(lang);
    }

    return _AttributeReductionSectionData(
      intro: intro,
      note: note,
      entries: entries,
    );
  }

  WikiDiceBoardEntry _attributeReductionEntryFromCatalog(
    Map<String, dynamic> item,
    String lang,
  ) {
    final injury = (item['Injury'] ?? '').toString();
    final parts = injury.split(' / ');
    final injuryEn = parts.isNotEmpty ? parts.first.trim() : injury;
    final injuryEs = parts.length > 1 ? parts.last.trim() : injury;
    final reduction = (lang == 'es'
            ? item['Reduction_es'] ?? item['Reduction']
            : item['Reduction_en'] ?? item['Reduction'])
        .toString();
    final visuals = _attributeReductionVisuals(injuryEn);

    return WikiDiceBoardEntry(
      roll: (item['D6'] ?? '').toString().replaceAll('-', '–'),
      title: lang == 'es' ? injuryEs : injuryEn,
      subtitle: lang == 'es' ? injuryEn : injuryEs,
      icon: visuals.icon,
      color: visuals.color,
      description: reduction,
    );
  }

  _AttributeReductionSectionData _fallbackAttributeReductionData(String lang) {
    final es = lang == 'es';

    return _AttributeReductionSectionData(
      intro: es
          ? 'Uno de los atributos del jugador empeora en 1. Para determinar qué atributo empeora, tira 1D6 y consulta la siguiente tabla de Heridas permanentes:'
          : 'One of the player\'s Characteristics worsens by 1. To determine which Characteristic worsens, roll a D6 and consult the following Lasting Injury table:',
      note: es
          ? 'En el caso de Movimiento o Fuerza, el atributo simplemente se reduce en 1.'
          : 'In the case of Movement or Strength, the Characteristic is simply reduced by 1.',
      entries: [
        WikiDiceBoardEntry(
          roll: '1–2',
          title: es ? 'CABEZA FRACTURADA' : 'HEAD INJURY',
          subtitle: es ? 'HEAD INJURY' : 'CABEZA FRACTURADA',
          icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
          color: const Color(0xFFEF5350),
          description: es ? '-1 AR' : '-1 AV',
        ),
        WikiDiceBoardEntry(
          roll: '3',
          title: es ? 'RODILLA APLASTADA' : 'SMASHED KNEE',
          subtitle: es ? 'SMASHED KNEE' : 'RODILLA APLASTADA',
          icon: PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill),
          color: const Color(0xFFFFA726),
          description: '-1 MV',
        ),
        WikiDiceBoardEntry(
          roll: '4',
          title: es ? 'BRAZO ROTO' : 'BROKEN ARM',
          subtitle: es ? 'BROKEN ARM' : 'BRAZO ROTO',
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFF42A5F5),
          description: es ? '-1 PS' : '-1 PA',
        ),
        WikiDiceBoardEntry(
          roll: '5',
          title: es ? 'CADERA DISLOCADA' : 'DISLOCATED HIP',
          subtitle: es ? 'DISLOCATED HIP' : 'CADERA DISLOCADA',
          icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
          color: const Color(0xFFAB47BC),
          description: '-1 AG',
        ),
        WikiDiceBoardEntry(
          roll: '6',
          title: es ? 'ROTURA DE HOMBRO' : 'BROKEN SHOULDER',
          subtitle: es ? 'BROKEN SHOULDER' : 'ROTURA DE HOMBRO',
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFF8D6E63),
          description: es ? '-1 FU' : '-1 ST',
        ),
      ],
    );
  }

  ({IconData icon, Color color}) _attributeReductionVisuals(String injuryEn) {
    switch (injuryEn) {
      case 'HEAD INJURY':
        return (
          icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
          color: const Color(0xFFEF5350),
        );
      case 'SMASHED KNEE':
        return (
          icon: PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill),
          color: const Color(0xFFFFA726),
        );
      case 'BROKEN ARM':
        return (
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFF42A5F5),
        );
      case 'DISLOCATED HIP':
        return (
          icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
          color: const Color(0xFFAB47BC),
        );
      case 'BROKEN SHOULDER':
      default:
        return (
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          color: const Color(0xFF8D6E63),
        );
    }
  }

  // ── Modifiers ───────────────────────────────────────────────────────────────

  Widget _buildModifiersSection(String lang) {
    final es = lang == 'es';
    final modifiers = [
      _ModifierEntry(
        name: es ? 'MIGHTY BLOW (+1)' : 'GOLPE PODEROSO',
        nameEs: es ? 'GOLPE PODEROSO' : 'MIGHTY BLOW (+1)',
        icon: PhosphorIcons.handFist(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Anade +1 a Armadura o Lesion. El entrenador elige cual, pero no ambas.'
            : 'Adds +1 to either the Armour roll or the Injury roll. The coach chooses which one, not both.',
      ),
      _ModifierEntry(
        name: es ? 'CLAW' : 'GARRA',
        nameEs: es ? 'GARRA' : 'CLAW',
        icon: PhosphorIcons.pawPrint(PhosphorIconsStyle.fill),
        color: const Color(0xFFAB47BC),
        description: es
            ? 'Al tirar Armadura tras un bloqueo, trata el Armour Value rival como 8+.'
            : 'When making an Armour roll after a block, treat the opponent\'s Armour Value as 8+.',
      ),
      _ModifierEntry(
        name: es ? 'DIRTY PLAYER (+1)' : 'JUEGO SUCIO',
        nameEs: es ? 'JUEGO SUCIO' : 'DIRTY PLAYER (+1)',
        icon: PhosphorIcons.sneakerMove(PhosphorIconsStyle.fill),
        color: const Color(0xFF8D6E63),
        description: es
            ? 'Anade +1 a Armadura o Lesion al hacer un Foul. Solo funciona en faltas.'
            : 'Adds +1 to Armour or Injury during a Foul. It only works on Fouls.',
      ),
      _ModifierEntry(
        name: es ? 'STUNTY' : 'PEQUENAJO',
        nameEs: es ? 'PEQUENAJO' : 'STUNTY',
        icon: PhosphorIcons.personSimple(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Los jugadores con Stunty usan su tabla especial y suelen sufrir peores resultados con mas facilidad.'
            : 'Players with Stunty use their own injury table and usually suffer worse results more easily.',
      ),
      _ModifierEntry(
        name: es ? 'THICK SKULL' : 'CRANEO DURO',
        nameEs: es ? 'CRANEO DURO' : 'THICK SKULL',
        icon: PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description: es
            ? 'Hace menos probable que el jugador salga KO, reduciendo parte del impacto de la tirada.'
            : 'Makes the player less likely to be knocked out, softening part of the injury roll.',
      ),
      _ModifierEntry(
        name: es ? 'APOTHECARY' : 'APOTECARIO',
        nameEs: es ? 'APOTECARIO' : 'APOTHECARY',
        icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'Se usa una vez por partido para intentar mejorar una Casualty o recuperar un KO.'
            : 'Used once per game to try to improve a Casualty result or recover a KO player.',
      ),
    ];

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
              Icon(PhosphorIcons.faders(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiInjuries.modifiers'),
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
            es
                ? 'Habilidades y efectos que modifican las tiradas de Armadura y Lesion.'
                : 'Skills and effects that modify Armour and Injury rolls.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...modifiers.map((m) => _buildModifierRow(m, lang)),
        ],
      ),
    );
  }

  Widget _buildModifierRow(_ModifierEntry m, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: m.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: m.color.withOpacity(0.35)),
            ),
            child: Center(
              child: Icon(m.icon, color: m.color, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.nameEs,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: m.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _buildRichDescription(m.description, lang: lang, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rich description with glossary ──────────────────────────────────────────

Widget _buildRichDescription(
  String text, {
  required String lang,
  double fontSize = 12,
  Color color = AppColors.textSecondary,
}) {
  final style = TextStyle(fontSize: fontSize, color: color, height: 1.5);
  final boldStyle = TextStyle(
    fontSize: fontSize,
    color: AppColors.accent,
    fontWeight: FontWeight.w600,
    height: 1.5,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.accent.withOpacity(0.3),
    decorationStyle: TextDecorationStyle.dotted,
  );

  final glossary = _glossary(lang);
  final sortedKeys = glossary.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final pattern = sortedKeys.map((k) => RegExp.escape(k)).join('|');
  final regex = RegExp('($pattern)', caseSensitive: false);

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(
          TextSpan(text: text.substring(lastEnd, match.start), style: style));
    }
    final matched = match.group(0)!;
    final tooltip = glossary[matched] ??
        glossary.entries
            .firstWhere((e) => e.key.toLowerCase() == matched.toLowerCase())
            .value;
    spans.add(WidgetSpan(
      child: Tooltip(
        message: tooltip,
        child: Text(matched, style: boldStyle),
      ),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: style));
  }

  return Text.rich(TextSpan(children: spans));
}

Widget _buildAttributeReductionDescription(
  String lang,
  String reduction,
  double fontSize,
  Color color,
) {
  final label =
      lang == 'es' ? 'Reducción de atributo: ' : 'Attribute reduction: ';

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        TextSpan(
          text: reduction,
          style: TextStyle(
            fontSize: fontSize + 1,
            color: color,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

// ── Data classes ────────────────────────────────────────────────────────────

class _AttributeReductionSectionData {
  final String intro;
  final String note;
  final List<WikiDiceBoardEntry> entries;

  const _AttributeReductionSectionData({
    required this.intro,
    required this.note,
    required this.entries,
  });
}

class _ModifierEntry {
  final String name;
  final String nameEs;
  final IconData icon;
  final Color color;
  final String description;

  const _ModifierEntry({
    required this.name,
    required this.nameEs,
    required this.icon,
    required this.color,
    required this.description,
  });
}

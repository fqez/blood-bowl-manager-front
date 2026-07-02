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

/// Glossary of Blood Bowl blocking terms.
Map<String, String> _glossary(String lang) {
  final es = lang == 'es';

  return <String, String>{
    'Blitz': es
        ? 'Accion especial: un jugador puede moverse y realizar un placaje en la misma activacion. Solo una por turno.'
        : 'Special action: a player can move and perform a Block in the same activation. Only one per turn.',
    'Block': es
        ? 'Habilidad: permite ignorar el resultado "Both Down" al placar sin caer.'
        : 'Skill: lets a player ignore the "Both Down" result when blocking without being knocked over.',
    'Dodge': es
        ? 'Habilidad: permite ignorar el resultado "Defender Stumbles" al ser placado.'
        : 'Skill: lets a player ignore the "Defender Stumbles" result when they are blocked.',
    'Guard': es
        ? 'Habilidad: permite dar asistencias de placaje incluso estando en la zona de defensa de un oponente.'
        : 'Skill: lets a player provide Block assists even while marked by an opponent.',
    'Tackle': es
        ? 'Habilidad: anula la habilidad Dodge del rival al bloquearlo.'
        : 'Skill: cancels the opponent\'s Dodge skill when blocking them.',
    'Frenzy': es
        ? 'Habilidad: obliga a hacer un segundo placaje si el primero termina en Push Back.'
        : 'Skill: forces a second Block if the first one results in a Push Back.',
    'Horns': es
        ? 'Habilidad: anade +1 ST al jugador al realizar un Blitz.'
        : 'Skill: adds +1 ST when the player performs a Blitz.',
    'Wrestle': es
        ? 'Habilidad: al obtener Both Down, puedes elegir que ambos jugadores caigan sin tirada de armadura.'
        : 'Skill: on Both Down, you may choose for both players to go down without making an Armour roll.',
    'Juggernaut': es
        ? 'Habilidad: al hacer Blitz, Both Down cuenta como Push Back en lugar de derribar a ambos.'
        : 'Skill: when making a Blitz, Both Down becomes Push Back instead of knocking both players down.',
    'Stand Firm': es
        ? 'Habilidad: el jugador puede elegir no ser empujado por un Push Back.'
        : 'Skill: the player may choose not to be moved by a Push Back.',
    'Strength': es
        ? 'Fuerza (ST) del jugador. Determina cuantos dados de placaje se tiran.'
        : 'The player\'s Strength (ST). It determines how many Block dice are rolled.',
    'Re-roll': es
        ? 'Permite repetir una tirada fallida. Cada equipo tiene un numero limitado por drive.'
        : 'Allows a failed roll to be repeated. Each team has a limited number per drive.',
    'Prone': es
        ? 'Estado del jugador: tumbado en el suelo; debe gastar movimiento para levantarse.'
        : 'Player state: lying on the ground and must spend movement to stand up.',
    'Stunned': es
        ? 'Estado del jugador: tumbado boca abajo; pierde su siguiente activacion.'
        : 'Player state: face down and loses their next activation.',
    'Tackle Zone': es
        ? 'Zona de control alrededor de un jugador en pie. Cada casilla adyacente forma su zona de defensa.'
        : 'Area of control around a standing player. Each adjacent square is part of that player\'s Tackle Zone.',
  };
}

class WikiBlockingScreen extends ConsumerWidget {
  const WikiBlockingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return WikiPageLayout(
      title: tr(lang, 'wikiBlocking.title'),
      heroIcon: PhosphorIcons.handFist(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiBlocking.subtitle'),
      accentColor: const Color(0xFFFF6D00),
      gradientColor: const Color(0xFFE65100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBlockDiceSection(lang),
          const SizedBox(height: 32),
          _buildBlockProcedure(lang),
          const SizedBox(height: 32),
          _buildDiceCountSection(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Block Dice ──────────────────────────────────────────────────────────────

  Widget _buildBlockDiceSection(String lang) {
    final es = lang == 'es';
    final diceFaces = [
      WikiDiceBoardEntry(
        roll: '×1',
        title: es ? 'ATACANTE DERRIBADO' : 'ATTACKER DOWN',
        subtitle: es ? 'ATTACKER DOWN' : 'ATACANTE DERRIBADO',
        iconAssetPath: 'assets/images/dice/skull.png',
        color: const Color(0xFFE53935),
        description: es
            ? 'El jugador que realiza el placaje es derribado. Se hace tirada de Armadura contra el. Este es el peor resultado posible para el atacante.'
            : 'The player making the Block is Knocked Down. Make an Armour roll against them. This is the worst possible result for the attacker.',
      ),
      WikiDiceBoardEntry(
        roll: '×1',
        title: es ? 'AMBOS CAIDOS' : 'BOTH DOWN',
        subtitle: es ? 'BOTH DOWN' : 'AMBOS CAIDOS',
        iconAssetPath: 'assets/images/dice/both_down.png',
        color: const Color(0xFFFF7043),
        description: es
            ? 'Ambos jugadores caen al suelo. Se tira Armadura contra los dos. La habilidad Block permite ignorar este resultado sin caer. Wrestle permite que ambos caigan sin tirada de armadura.'
            : 'Both players go down. Make an Armour roll against both. Block lets a player ignore this result without falling, and Wrestle lets both players go down without an Armour roll.',
      ),
      WikiDiceBoardEntry(
        roll: '×2',
        title: es ? 'EMPUJON' : 'PUSH BACK',
        subtitle: es ? 'PUSH BACK' : 'EMPUJON',
        iconAssetPath: 'assets/images/dice/push.png',
        color: const Color(0xFF42A5F5),
        description: es
            ? 'El defensor es empujado una casilla hacia atras en una direccion elegida por el atacante. No es derribado. Si sale del campo, la multitud lo golpea.'
            : 'The defender is pushed back one square in a direction chosen by the attacker. They are not knocked down. If pushed off the pitch, the crowd hits them.',
      ),
      WikiDiceBoardEntry(
        roll: '×1',
        title: es ? 'DEFENSOR TROPIEZA' : 'DEFENDER STUMBLES',
        subtitle: es ? 'DEFENDER STUMBLES' : 'DEFENSOR TROPIEZA',
        iconAssetPath: 'assets/images/dice/def_down.png',
        color: const Color(0xFFFFA726),
        description: es
            ? 'El defensor es empujado y derribado. Si tiene la habilidad Dodge, puede convertirlo en un simple Push Back. Tackle anula Dodge.'
            : 'The defender is pushed back and Knocked Down. If they have Dodge, they may turn this into a simple Push Back instead. Tackle cancels Dodge.',
      ),
      WikiDiceBoardEntry(
        roll: '×1',
        title: es ? 'DERRIBADO' : 'POW!',
        subtitle: es ? 'POW!' : 'DERRIBADO',
        iconAssetPath: 'assets/images/dice/pow.png',
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El defensor es empujado y derribado. Este es el mejor resultado para el atacante. Dodge no puede anularlo.'
            : 'The defender is pushed back and Knocked Down. This is the best result for the attacker. Dodge cannot cancel it.',
      ),
    ];

    return WikiDiceBoard(
      headerIcon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiBlocking.blockDice'),
      subtitle: es
          ? 'El dado de Placaje tiene 6 caras con 5 resultados distintos (Push Back aparece 2 veces).'
          : 'The Block die has 6 faces with 5 different results (Push Back appears twice).',
      diceAssetPath: 'assets/images/dice/3POW.png',
      entries: diceFaces,
      compactRowHeight: 124,
      desktopRowHeight: 116,
      showRollCircle: false,
      inlineRollBadgeWhenHidden: false,
      compactRowIconScale: 0.82,
      desktopRowIconScale: 0.86,
    );
  }

  // ── Block Procedure ─────────────────────────────────────────────────────────

  Widget _buildBlockProcedure(String lang) {
    final es = lang == 'es';
    final steps = [
      WikiTimelineEntry(
        marker: '1',
        title: es ? 'DECLARAR PLACAJE' : 'DECLARE BLOCK',
        icon: PhosphorIcons.target(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Elige a un jugador oponente adyacente como objetivo. El atacante no puede moverse antes de placar salvo que sea un Blitz.'
            : 'Choose an adjacent opposing player as the target. The attacker cannot move before blocking unless this is part of a Blitz.',
      ),
      WikiTimelineEntry(
        marker: '2',
        title: es ? 'CALCULAR DADOS' : 'CALCULATE DICE',
        icon: PhosphorIcons.scales(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'Compara la Strength del atacante con la del defensor, incluyendo asistencias. Eso determina cuantos dados se tiran y quien elige el resultado.'
            : 'Compare the attacker\'s Strength to the defender\'s, including assists. That decides how many dice are rolled and who chooses the result.',
      ),
      WikiTimelineEntry(
        marker: '3',
        title: es ? 'TIRAR DADOS DE PLACAJE' : 'ROLL BLOCK DICE',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'Tira el numero de dados correspondiente. El jugador que elige decide cual de los resultados aplicar.'
            : 'Roll the required number of Block dice. The player who has choice decides which result is applied.',
      ),
      WikiTimelineEntry(
        marker: '4',
        title: es ? 'APLICAR RESULTADO' : 'APPLY RESULT',
        icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Resuelve el resultado elegido: Push Back, derribo o ambos. Si hay empujon, elige la direccion. Si hay derribo, tira Armadura.'
            : 'Resolve the chosen result: Push Back, a knockdown, or both. If there is a push, choose the direction. If someone goes down, make the Armour roll.',
      ),
      WikiTimelineEntry(
        marker: '5',
        title: es ? 'SEGUIR' : 'FOLLOW UP',
        icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description: es
            ? 'El atacante puede avanzar de forma opcional a la casilla que dejo libre el defensor empujado. Con Frenzy esto es obligatorio.'
            : 'The attacker may optionally move into the square vacated by the pushed defender. With Frenzy, this follow-up is mandatory.',
      ),
    ];

    return WikiTimelineSection(
      headerIcon: PhosphorIcons.listNumbers(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiBlocking.procedure'),
      subtitle: es
          ? 'Pasos para resolver un placaje en Blood Bowl.'
          : 'Steps to resolve a Block in Blood Bowl.',
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

  // ── Dice Count Table ────────────────────────────────────────────────────────

  Widget _buildDiceCountSection(String lang) {
    return FutureBuilder<List<WikiDiceBoardEntry>>(
      future: _loadDiceCountEntries(lang),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? _fallbackDiceCountEntries(lang);

        return WikiDiceBoard(
          headerIcon: PhosphorIcons.scales(PhosphorIconsStyle.fill),
          title: '${tr(lang, 'wikiBlocking.diceCount')} '
              '(${_diceCountLegend(lang)})',
          subtitle: lang == 'es'
              ? 'La cantidad de dados depende de la comparacion de Fuerza entre atacante y defensor, incluyendo asistencias.'
              : 'The number of dice depends on the Strength comparison between attacker and defender, including assists.',
          diceAssetPath: 'assets/images/dice/3POW.png',
          entries: entries,
          compactRowHeight: 124,
          desktopRowHeight: 116,
          compactRowIconScale: 0.82,
          desktopRowIconScale: 0.86,
          rollTextScale: 0.18,
          descriptionBuilder: (context, entry, fontSize) =>
              _buildRichDescription(
            entry.description,
            lang: lang,
            fontSize: fontSize,
          ),
        );
      },
    );
  }

  String _diceCountLegend(String lang) {
    return lang == 'es'
        ? 'FA = Fuerza Atacante, FD = Fuerza Defensora'
        : 'FA = Attacker Strength, FD = Defender Strength';
  }

  Future<List<WikiDiceBoardEntry>> _loadDiceCountEntries(String lang) async {
    final raw = await rootBundle.loadString('assets/rules/rules.json');
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return _fallbackDiceCountEntries(lang);
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
        if (!title.startsWith('PERFORMING A BLOCK ACTION')) {
          continue;
        }

        final catalog = section['dice_count_catalog'];
        if (catalog is! List) {
          return _fallbackDiceCountEntries(lang);
        }

        return catalog
            .whereType<Map<String, dynamic>>()
            .map((item) => WikiDiceBoardEntry(
                  roll: _localizedCatalogValue(item, lang, 'roll'),
                  title: _localizedCatalogValue(item, lang, 'title'),
                  subtitle: _localizedCatalogValue(item, lang, 'subtitle'),
                  iconAssetPath: item['iconAssetPath'] as String?,
                  color: _catalogColor(item['color'] as String?),
                  description:
                      _localizedCatalogValue(item, lang, 'description'),
                ))
            .toList(growable: false);
      }
    }

    return _fallbackDiceCountEntries(lang);
  }

  List<WikiDiceBoardEntry> _fallbackDiceCountEntries(String lang) {
    final es = lang == 'es';

    return [
      WikiDiceBoardEntry(
        roll: 'FA >> FD',
        title: es ? '3 DADOS' : '3 DICE',
        subtitle: es ? 'ATACANTE ELIGE' : 'ATTACKER CHOOSES',
        iconAssetPath: 'assets/images/dice/+3POW.png',
        color: const Color(0xFF2E7D32),
        description: es
            ? 'Se lanzan 3 dados de placaje y el atacante elige el resultado. Requisito: la Fuerza del Atacante debe ser más del doble que la del Defensor tras aplicar asistencias y modificadores.'
            : 'Roll 3 Block dice and the attacker chooses the result. Requirement: the Attacker Strength must be more than double the Defender Strength after assists and modifiers are applied.',
      ),
      WikiDiceBoardEntry(
        roll: 'FA > FD',
        title: es ? '2 DADOS' : '2 DICE',
        subtitle: es ? 'ATACANTE ELIGE' : 'ATTACKER CHOOSES',
        iconAssetPath: 'assets/images/dice/+2POW.png',
        color: const Color(0xFF66BB6A),
        description: es
            ? 'Se lanzan 2 dados de placaje y el atacante elige el resultado. Requisito: la Fuerza del Atacante debe ser mayor que la del Defensor, pero no más del doble, tras aplicar asistencias y modificadores.'
            : 'Roll 2 Block dice and the attacker chooses the result. Requirement: the Attacker Strength must be higher than the Defender Strength, but not more than double, after assists and modifiers are applied.',
      ),
      WikiDiceBoardEntry(
        roll: 'FA = FD',
        title: es ? '1 DADO' : '1 DIE',
        subtitle: es ? 'SIN ELECCION' : 'NO CHOICE',
        iconAssetPath: 'assets/images/dice/+1POW.png',
        color: const Color(0xFFFFA726),
        description: es
            ? 'Se lanza 1 dado de placaje. Requisito: la Fuerza del Atacante y la del Defensor deben ser iguales tras aplicar asistencias y modificadores.'
            : 'Roll 1 Block die. Requirement: the Attacker Strength and Defender Strength must be equal after assists and modifiers are applied.',
      ),
      WikiDiceBoardEntry(
        roll: 'FA < FD',
        title: es ? '2 DADOS' : '2 DICE',
        subtitle: es ? 'DEFENSOR ELIGE' : 'DEFENDER CHOOSES',
        iconAssetPath: 'assets/images/dice/-2POW.png',
        color: const Color(0xFFEF5350),
        description: es
            ? 'Se lanzan 2 dados de placaje y el defensor elige el resultado. Requisito: la Fuerza del Defensor debe ser mayor que la del Atacante, pero no más del doble, tras aplicar asistencias y modificadores.'
            : 'Roll 2 Block dice and the defender chooses the result. Requirement: the Defender Strength must be higher than the Attacker Strength, but not more than double, after assists and modifiers are applied.',
      ),
      WikiDiceBoardEntry(
        roll: 'FA << FD',
        title: es ? '3 DADOS' : '3 DICE',
        subtitle: es ? 'DEFENSOR ELIGE' : 'DEFENDER CHOOSES',
        iconAssetPath: 'assets/images/dice/-3POW.png',
        color: const Color(0xFFB71C1C),
        description: es
            ? 'Se lanzan 3 dados de placaje y el defensor elige el resultado. Requisito: la Fuerza del Defensor debe ser más del doble que la del Atacante tras aplicar asistencias y modificadores.'
            : 'Roll 3 Block dice and the defender chooses the result. Requirement: the Defender Strength must be more than double the Attacker Strength after assists and modifiers are applied.',
      ),
    ];
  }

  String _localizedCatalogValue(
    Map<String, dynamic> item,
    String lang,
    String baseKey,
  ) {
    final preferredKey = lang == 'es' ? '${baseKey}Es' : '${baseKey}En';
    final fallbackKey = lang == 'es' ? '${baseKey}En' : '${baseKey}Es';

    return (item[preferredKey] ?? item[fallbackKey] ?? '').toString();
  }

  Color _catalogColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return AppColors.accent;
    }

    final normalized = hexColor.replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16);

    if (value == null) {
      return AppColors.accent;
    }

    return Color(value);
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

// ── Data classes ────────────────────────────────────────────────────────────

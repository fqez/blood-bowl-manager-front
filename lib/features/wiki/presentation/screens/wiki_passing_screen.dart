import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl passing terms.
Map<String, String> _glossary(String lang) {
  final es = lang == 'es';

  return <String, String>{
    'AG': es
        ? 'Agilidad del jugador. Marca la dificultad base de esquivas, recepciones e intercepciones.'
        : 'The player\'s Agility. It sets the base difficulty for catches and interceptions.',
    'PA': es
        ? 'Capacidad de Pase del jugador. Marca lo facil o dificil que es lanzar pases.'
        : 'The player\'s Passing Ability. It determines how easy or hard it is to throw a pass.',
    'Tackle Zone': es
        ? 'Zona de control alrededor de un jugador en pie. Cada casilla adyacente forma su zona de defensa.'
        : 'Area of control around a standing player. Each adjacent square is part of that player\'s Tackle Zone.',
    'Re-roll': es
        ? 'Permite repetir una tirada fallida. Cada equipo tiene un numero limitado por drive.'
        : 'Allows a failed roll to be repeated. Each team has a limited number per drive.',
    'Fumble': es
        ? 'Fallo catastrofico del pase. El balon cae junto al lanzador.'
        : 'A catastrophic passing failure. The ball is dropped near the thrower.',
    'Accurate Pass': es
        ? 'Pase preciso: el balon llega exactamente a la casilla objetivo.'
        : 'An accurate pass: the ball lands exactly in the target square.',
    'Inaccurate Pass': es
        ? 'Pase impreciso: el balon se desvia antes de poder ser atrapado.'
        : 'An inaccurate pass: the ball deviates before anyone can catch it.',
    'Interception': es
        ? 'Un jugador rival en la trayectoria puede intentar cortar el pase.'
        : 'An opposing player in the flight path may try to cut off the pass.',
    'Completion': es
        ? 'Pase completado: un companero atrapa el balon y el lanzador gana 1 SPP.'
        : 'Completed pass: a team-mate catches the ball and the thrower gains 1 SPP.',
    'Hand-off': es
        ? 'Entrega en mano a un companero adyacente sin tirada de pase.'
        : 'A hand-off to an adjacent team-mate without a passing roll.',
    'Catch': es
        ? 'Habilidad: permite repetir una tirada fallida para atrapar el balon.'
        : 'Skill: allows a failed catch roll to be rerolled.',
    'Pass': es
        ? 'Habilidad: permite repetir una tirada fallida de pase.'
        : 'Skill: allows a failed passing roll to be rerolled.',
    'Nerves of Steel': es
        ? 'Habilidad: ignora modificadores por zonas enemigas al pasar o atrapar.'
        : 'Skill: ignores enemy marking modifiers when passing or catching.',
    'Safe Pass': es
        ? 'Habilidad: ayuda a evitar perder el balon tras un pase fallido.'
        : 'Skill: helps prevent the thrower from losing the ball after a failed pass.',
    'Diving Catch': es
        ? 'Habilidad: mejora la recepcion de pases precisos y amplia el alcance para atraparlos.'
        : 'Skill: improves catching accurate passes and extends catching reach.',
    'Dump-Off': es
        ? 'Habilidad: permite un pase rapido cuando un rival declara un bloqueo.'
        : 'Skill: allows a Quick Pass when an opponent declares a block.',
    'SPP': es
        ? 'Puntos de experiencia que los jugadores ganan por acciones destacadas.'
        : 'Experience points players earn for standout actions.',
  };
}

class WikiPassingScreen extends ConsumerWidget {
  const WikiPassingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return WikiPageLayout(
      title: tr(lang, 'wikiPassing.title'),
      heroIcon: PhosphorIcons.football(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiPassing.subtitle'),
      accentColor: const Color(0xFF42A5F5),
      gradientColor: const Color(0xFF1565C0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPassRangesSection(lang),
          const SizedBox(height: 32),
          _buildPassProcedure(lang),
          const SizedBox(height: 32),
          _buildModifiersSection(lang),
          const SizedBox(height: 32),
          _buildCatchAndIntercept(lang),
          const SizedBox(height: 32),
          _buildSpecialPlays(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Pass Ranges ─────────────────────────────────────────────────────────────

  Widget _buildPassRangesSection(String lang) {
    final es = lang == 'es';
    final ranges = [
      _PassRange(
        name: es ? 'PASE RAPIDO' : 'QUICK PASS',
        nameEn: 'Quick Pass',
        range: '1–3',
        modifier: '+1',
        color: const Color(0xFF66BB6A),
        icon: PhosphorIcons.arrowBendRightUp(PhosphorIconsStyle.fill),
        description: es
            ? 'El rango mas corto. Cubre hasta 3 casillas y da un +1 a la tirada de pase.'
            : 'The shortest range. It covers up to 3 squares and gives a +1 modifier to the pass roll.',
      ),
      _PassRange(
        name: es ? 'PASE CORTO' : 'SHORT PASS',
        nameEn: 'Short Pass',
        range: '4–6',
        modifier: '0',
        color: const Color(0xFF42A5F5),
        icon: PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
        description: es
            ? 'Rango medio-corto. Cubre de 4 a 6 casillas y no tiene modificador extra.'
            : 'Medium-short range. It covers 4 to 6 squares with no extra modifier.',
      ),
      _PassRange(
        name: es ? 'PASE LARGO' : 'LONG PASS',
        nameEn: 'Long Pass',
        range: '7–10',
        modifier: '−1',
        color: const Color(0xFFFFA726),
        icon: PhosphorIcons.arrowBendDoubleUpRight(PhosphorIconsStyle.fill),
        description: es
            ? 'Rango largo. Cubre de 7 a 10 casillas y aplica un -1 a la tirada de pase.'
            : 'Long range. It covers 7 to 10 squares and applies a -1 modifier to the pass roll.',
      ),
      _PassRange(
        name: es ? 'BOMBA LARGA' : 'LONG BOMB',
        nameEn: 'Long Bomb',
        range: '11–13',
        modifier: '−2',
        color: const Color(0xFFEF5350),
        icon: PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
        description: es
            ? 'El rango maximo. Cubre de 11 a 13 casillas y aplica un -2. Solo los mejores lanzadores lo intentan.'
            : 'The maximum range. It covers 11 to 13 squares and applies a -2 modifier. Only the best throwers attempt it.',
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
              Icon(PhosphorIcons.target(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiPassing.ranges'),
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
                ? 'La distancia entre lanzador y receptor determina el rango y el modificador.'
                : 'The distance between thrower and target determines the range and modifier.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...ranges.map((r) => _buildPassRangeRow(r, lang)),
        ],
      ),
    );
  }

  Widget _buildPassRangeRow(_PassRange r, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [r.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: r.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: r.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: r.color.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  r.range,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: r.color,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: r.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.modifier,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: r.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(r.icon, color: r.color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      r.name,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: r.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r.nameEn,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildRichDescription(r.description, lang: lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pass Procedure ──────────────────────────────────────────────────────────

  Widget _buildPassProcedure(String lang) {
    final es = lang == 'es';
    final steps = [
      _PassStep(
        number: '1',
        title: es ? 'DECLARAR PASE' : 'DECLARE PASS',
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Elige al lanzador y declara una casilla objetivo. Puede moverse antes, pero no lanzar bien si esta demasiado presionado.'
            : 'Choose the thrower and declare a target square. The player may move first, but pressure still makes the pass harder.',
      ),
      _PassStep(
        number: '2',
        title: es ? 'MEDIR DISTANCIA' : 'MEASURE RANGE',
        icon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'Cuenta la distancia entre lanzador y objetivo para saber si es Quick Pass, Short Pass, Long Pass o Long Bomb.'
            : 'Measure the distance between thrower and target to determine the pass category.',
      ),
      _PassStep(
        number: '3',
        title: es ? 'TIRADA DE PASE' : 'PASS ROLL',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'Tira 1D6 aplicando PA y modificadores. Un 1 natural siempre es Fumble.'
            : 'Roll 1D6 and apply PA plus modifiers. A natural 1 is always a Fumble.',
      ),
      _PassStep(
        number: '4',
        title: es ? 'INTERCEPCIONES' : 'INTERCEPTIONS',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Un rival de pie en la trayectoria del pase puede intentar interceptarlo antes de que llegue al objetivo.'
            : 'A standing opponent in the flight path may try to intercept the ball before it reaches the target.',
      ),
      _PassStep(
        number: '5',
        title: es ? 'RECEPCION' : 'CATCH',
        icon: PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description: es
            ? 'El jugador objetivo intenta atrapar el balon. Si lo consigue en un pase completado, el lanzador gana 1 SPP.'
            : 'The target player attempts to catch the ball. If the completion succeeds, the thrower gains 1 SPP.',
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
              Icon(PhosphorIcons.listNumbers(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiPassing.procedure'),
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
                ? 'Pasos para resolver un pase en Blood Bowl.'
                : 'Steps to resolve a pass in Blood Bowl.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) => _buildPassStepCard(s, steps.length, lang)),
        ],
      ),
    );
  }

  Widget _buildPassStepCard(_PassStep step, int totalSteps, String lang) {
    final stepNum = int.parse(step.number);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [step.color, step.color.withOpacity(0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: step.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    step.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (stepNum < totalSteps)
                Container(
                  width: 2,
                  height: 24,
                  color: step.color.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    step.color.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: step.color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: step.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: step.color,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildRichDescription(step.description, lang: lang),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modifiers Table ─────────────────────────────────────────────────────────

  Widget _buildModifiersSection(String lang) {
    final es = lang == 'es';
    final modifiers = [
      _PassModifier(
        name: es ? 'Rango del pase' : 'Pass range',
        effect: es
            ? 'Rapido +1 / Corto 0 / Largo −1 / Bomba −2'
            : 'Quick +1 / Short 0 / Long −1 / Bomb −2',
        color: const Color(0xFF42A5F5),
      ),
      _PassModifier(
        name: es
            ? 'Zonas enemigas sobre el lanzador'
            : 'Enemy Tackle Zones on thrower',
        effect:
            es ? '−1 por cada zona enemiga' : '−1 for each enemy Tackle Zone',
        color: const Color(0xFFEF5350),
      ),
      _PassModifier(
        name: es ? 'Clima: Lluvia Torrencial' : 'Weather: Pouring Rain',
        effect: es ? '−1 al pase' : '−1 to passing',
        color: const Color(0xFF78909C),
      ),
      _PassModifier(
        name: es ? 'Clima: Ventisca' : 'Weather: Blizzard',
        effect: es
            ? 'Solo pases rapidos y cortos'
            : 'Only Quick and Short Passes allowed',
        color: const Color(0xFF90CAF9),
      ),
      _PassModifier(
        name: es ? 'Resultado natural de 1' : 'Natural 1',
        effect: es ? 'Siempre es Fumble' : 'Always a Fumble',
        color: const Color(0xFFB71C1C),
      ),
      _PassModifier(
        name: es ? 'Resultado natural de 6' : 'Natural 6',
        effect: es ? 'Siempre es Accurate Pass' : 'Always an Accurate Pass',
        color: const Color(0xFF2E7D32),
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
                tr(lang, 'wikiPassing.modifiers'),
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
                ? 'Modificadores que afectan a la tirada de pase.'
                : 'Modifiers that affect the pass roll.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...modifiers.map((m) => _buildModifierRow(m)),
        ],
      ),
    );
  }

  Widget _buildModifierRow(_PassModifier m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: m.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    m.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    m.effect,
                    style: TextStyle(
                      fontSize: 12,
                      color: m.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Catch & Interception ────────────────────────────────────────────────────

  Widget _buildCatchAndIntercept(String lang) {
    final es = lang == 'es';
    final entries = [
      _CatchEntry(
        name: es ? 'ATRAPAR PASE PRECISO' : 'CATCH ACCURATE PASS',
        nameEn: 'Catch Accurate Pass',
        icon: PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El receptor tira para atrapar con bonificador por Accurate Pass y penalizadores por marcas enemigas.'
            : 'The receiver rolls to catch with a bonus for an Accurate Pass and penalties for enemy markers.',
      ),
      _CatchEntry(
        name: es ? 'ATRAPAR PASE IMPRECISO' : 'CATCH INACCURATE PASS',
        nameEn: 'Catch Inaccurate Pass',
        icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'Si el pase es impreciso, el balon se desvia antes de que alguien pueda intentar atraparlo.'
            : 'If the pass is inaccurate, the ball deviates before anyone may try to catch it.',
      ),
      _CatchEntry(
        name: es ? 'INTERCEPCION' : 'INTERCEPTION',
        nameEn: 'Interception',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Un rival de pie en la trayectoria puede intentar una intercepcion con penalizador.'
            : 'A standing opponent in the flight path may attempt an interception with a penalty.',
      ),
      _CatchEntry(
        name: es ? 'FUMBLE' : 'FUMBLE',
        nameEn: 'Fumble',
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        color: const Color(0xFFB71C1C),
        description: es
            ? 'Con un 1 natural, el pase falla automaticamente y el balon cae junto al lanzador.'
            : 'On a natural 1, the pass automatically fails and the ball drops near the thrower.',
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
              Icon(PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiPassing.catchIntercept'),
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
                ? 'Resolucion de recepciones, intercepciones y balones sueltos.'
                : 'Resolution of catches, interceptions, and loose balls.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => _buildCatchRow(e, lang)),
        ],
      ),
    );
  }

  Widget _buildCatchRow(_CatchEntry e, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [e.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: e.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: e.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: e.color.withOpacity(0.4)),
            ),
            child: Center(
              child: Icon(e.icon, color: e.color, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      e.name,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: e.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  e.nameEn,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                _buildRichDescription(e.description, lang: lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Special Plays ───────────────────────────────────────────────────────────

  Widget _buildSpecialPlays(String lang) {
    final es = lang == 'es';
    final plays = [
      _SpecialPlay(
        name: 'HAND-OFF',
        nameEs: es ? 'ENTREGA EN MANO' : 'HAND-OFF',
        icon: PhosphorIcons.handshake(PhosphorIconsStyle.fill),
        color: const Color(0xFF26A69A),
        description: es
            ? 'Pasa el balon a un jugador adyacente sin tirada de pase. Solo hay que atrapar.'
            : 'Pass the ball to an adjacent player without a passing roll. Only the catch matters.',
      ),
      _SpecialPlay(
        name: 'DUMP-OFF',
        nameEs: es ? 'PASE DESESPERADO' : 'DUMP-OFF',
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'Si un rival declara un bloqueo, el portador con Dump-Off puede intentar un Quick Pass antes de resolverlo.'
            : 'If an opponent declares a block, a ball carrier with Dump-Off may attempt a Quick Pass before it is resolved.',
      ),
      _SpecialPlay(
        name: 'HAIL MARY PASS',
        nameEs: es ? 'PASE AVE MARIA' : 'HAIL MARY PASS',
        icon: PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description: es
            ? 'Permite lanzar a cualquier casilla sin importar distancia. Siempre es impreciso y no puede interceptarse.'
            : 'Lets the player throw to any square regardless of distance. It is always inaccurate and cannot be intercepted.',
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
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiPassing.specialPlays'),
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
                ? 'Jugadas especiales relacionadas con el pase.'
                : 'Special plays related to passing.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...plays.map((p) => _buildSpecialPlayRow(p, lang)),
        ],
      ),
    );
  }

  Widget _buildSpecialPlayRow(_SpecialPlay p, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.color.withOpacity(0.35)),
            ),
            child: Center(
              child: Icon(p.icon, color: p.color, size: 18),
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
                      p.nameEs,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: p.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _buildRichDescription(p.description, lang: lang, fontSize: 11),
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

// ── Data classes ────────────────────────────────────────────────────────────

class _PassRange {
  final String name;
  final String nameEn;
  final String range;
  final String modifier;
  final Color color;
  final IconData icon;
  final String description;

  const _PassRange({
    required this.name,
    required this.nameEn,
    required this.range,
    required this.modifier,
    required this.color,
    required this.icon,
    required this.description,
  });
}

class _PassStep {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const _PassStep({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _PassModifier {
  final String name;
  final String effect;
  final Color color;

  const _PassModifier({
    required this.name,
    required this.effect,
    required this.color,
  });
}

class _CatchEntry {
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String description;

  const _CatchEntry({
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _SpecialPlay {
  final String name;
  final String nameEs;
  final IconData icon;
  final Color color;
  final String description;

  const _SpecialPlay({
    required this.name,
    required this.nameEs,
    required this.icon,
    required this.color,
    required this.description,
  });
}

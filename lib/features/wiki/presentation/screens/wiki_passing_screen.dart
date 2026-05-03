import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl passing terms.
const _glossary = <String, String>{
  'AG':
      'Agilidad (Agility) del jugador. Determina la dificultad base de pases, recepciones e intercepciones.',
  'PA':
      'Precisión de Pase (Passing Ability). Determina el modificador base para lanzar pases.',
  'Tackle Zone':
      'Zona de control alrededor de un jugador de pie. Cada casilla adyacente es su Tackle Zone.',
  'Re-roll':
      'Permite repetir una tirada de dados fallida. Cada equipo tiene un número limitado por drive.',
  'Fumble':
      'El pase falla catastróficamente. El balón se dispersa desde la casilla del lanzador.',
  'Accurate Pass':
      'Pase preciso: el balón aterriza exactamente en la casilla objetivo.',
  'Inaccurate Pass':
      'Pase impreciso: el balón se desvía D8 desde la casilla objetivo antes de poder ser atrapado.',
  'Interception':
      'Un jugador rival en la trayectoria del pase puede intentar interceptar el balón.',
  'Completion':
      'Pase completado: el receptor atrapa el balón con éxito. El lanzador recibe 1 SPP.',
  'Hand-off':
      'Entrega en mano: pasar el balón a un jugador adyacente sin tirada de pase. Solo requiere atrapar.',
  'Catch': 'Habilidad: permite repetir una tirada fallida de atrapar el balón.',
  'Pass': 'Habilidad: permite repetir una tirada fallida de pase.',
  'Nerves of Steel':
      'Habilidad: ignora los modificadores por Tackle Zones enemigas al pasar o atrapar.',
  'Safe Pass':
      'Habilidad: si el pase falla, el lanzador no suelta el balón (Fumble se convierte en balón suelto).',
  'Diving Catch':
      'Habilidad: +1 al atrapar un pase preciso. Permite intentar atrapar en casillas adyacentes.',
  'Dump-Off':
      'Habilidad: permite hacer un pase rápido (Quick Pass) cuando un oponente declara un bloqueo.',
  'SPP':
      'Star Player Points – puntos de experiencia que ganan los jugadores por acciones destacadas.',
};

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
    final ranges = [
      _PassRange(
        name: 'PASE RÁPIDO',
        nameEn: 'Quick Pass',
        range: '1–3',
        modifier: '+1',
        color: const Color(0xFF66BB6A),
        icon: PhosphorIcons.arrowBendRightUp(PhosphorIconsStyle.fill),
        description: 'El rango más corto. Cubre hasta 3 casillas de distancia. '
            'Se obtiene un bonificador de +1 a la tirada de pase.',
      ),
      _PassRange(
        name: 'PASE CORTO',
        nameEn: 'Short Pass',
        range: '4–6',
        modifier: '0',
        color: const Color(0xFF42A5F5),
        icon: PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
        description: 'Rango medio-corto. Cubre de 4 a 6 casillas. '
            'Sin modificador adicional por distancia.',
      ),
      _PassRange(
        name: 'PASE LARGO',
        nameEn: 'Long Pass',
        range: '7–10',
        modifier: '−1',
        color: const Color(0xFFFFA726),
        icon: PhosphorIcons.arrowBendDoubleUpRight(PhosphorIconsStyle.fill),
        description: 'Rango largo. Cubre de 7 a 10 casillas. '
            'Se aplica un penalizador de -1 a la tirada de pase.',
      ),
      _PassRange(
        name: 'BOMBA LARGA',
        nameEn: 'Long Bomb',
        range: '11–13',
        modifier: '−2',
        color: const Color(0xFFEF5350),
        icon: PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
        description: 'El rango máximo. Cubre de 11 a 13 casillas. '
            'Se aplica un penalizador de -2. Solo los mejores lanzadores lo intentan.',
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
            'La distancia entre lanzador y receptor determina el rango y el modificador.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...ranges.map((r) => _buildPassRangeRow(r)),
        ],
      ),
    );
  }

  Widget _buildPassRangeRow(_PassRange r) {
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
                _buildRichDescription(r.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pass Procedure ──────────────────────────────────────────────────────────

  Widget _buildPassProcedure(String lang) {
    final steps = [
      _PassStep(
        number: '1',
        title: 'DECLARAR PASE',
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'Elige el jugador con balón como lanzador y una casilla objetivo. '
            'Se puede pasar tras moverse (gasta toda la acción). No se puede pasar '
            'si está en una Tackle Zone sin la mejora adecuada.',
      ),
      _PassStep(
        number: '2',
        title: 'MEDIR DISTANCIA',
        icon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Cuenta las casillas entre lanzador y objetivo para determinar '
            'el rango del pase: Quick Pass, Short Pass, Long Pass o Long Bomb.',
      ),
      _PassStep(
        number: '3',
        title: 'TIRADA DE PASE',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'Tira 1D6 y suma/resta los modificadores (PA del lanzador, rango, '
            'Tackle Zones enemigas, clima). Con 2+ es preciso, con resultado '
            'natural de 1 siempre es Fumble.',
      ),
      _PassStep(
        number: '4',
        title: 'INTERCEPCIONES',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Cualquier jugador rival en la trayectoria del pase puede intentar '
            'una Interception (necesita AG 2+ con modificadores). Si tiene éxito, '
            'roba el balón y recibe 2 SPP.',
      ),
      _PassStep(
        number: '5',
        title: 'RECEPCIÓN',
        icon: PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description:
            'El jugador en la casilla objetivo tira AG para atrapar. Si el pase '
            'fue preciso obtiene +1. Si fue impreciso, el balón se desvía antes. '
            'Si atrapa, el lanzador recibe 1 SPP por Completion.',
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
            'Pasos para resolver un pase en Blood Bowl.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) => _buildPassStepCard(s, steps.length)),
        ],
      ),
    );
  }

  Widget _buildPassStepCard(_PassStep step, int totalSteps) {
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
                  _buildRichDescription(step.description),
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
    final modifiers = [
      _PassModifier(
        name: 'Rango del pase',
        effect: 'Quick +1 / Short 0 / Long −1 / Bomb −2',
        color: const Color(0xFF42A5F5),
      ),
      _PassModifier(
        name: 'Tackle Zones enemigas sobre el lanzador',
        effect: '−1 por cada Tackle Zone enemiga',
        color: const Color(0xFFEF5350),
      ),
      _PassModifier(
        name: 'Clima: Lluvia Torrencial',
        effect: '−1 al pase',
        color: const Color(0xFF78909C),
      ),
      _PassModifier(
        name: 'Clima: Ventisca',
        effect: 'Solo Quick Pass y Short Pass permitidos',
        color: const Color(0xFF90CAF9),
      ),
      _PassModifier(
        name: 'Resultado natural de 1',
        effect: 'Siempre es Fumble (fallo automático)',
        color: const Color(0xFFB71C1C),
      ),
      _PassModifier(
        name: 'Resultado natural de 6',
        effect: 'Siempre es Accurate Pass (éxito automático)',
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
            'Modificadores que afectan a la tirada de pase (1D6 + PA del lanzador + modificadores).',
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
    final entries = [
      _CatchEntry(
        name: 'ATRAPAR PASE PRECISO',
        nameEn: 'Catch Accurate Pass',
        icon: PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'Tira 1D6 + AG del receptor. Obtiene +1 por pase preciso (Accurate Pass). '
            'Se aplica -1 por cada Tackle Zone enemiga. Éxito con 2+.',
      ),
      _CatchEntry(
        name: 'ATRAPAR PASE IMPRECISO',
        nameEn: 'Catch Inaccurate Pass',
        icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Si el pase fue impreciso, el balón se desvía (scatter D8, D6 casillas). '
            'Si aterriza en un jugador, este puede intentar atraparlo sin el +1 de precisión.',
      ),
      _CatchEntry(
        name: 'INTERCEPCIÓN',
        nameEn: 'Interception',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Un jugador rival de pie en la trayectoria del pase puede intentar '
            'interceptar tirando AG con -2 de penalizador. Si tiene éxito, '
            'atrapa el balón y recibe 2 SPP.',
      ),
      _CatchEntry(
        name: 'FUMBLE',
        nameEn: 'Fumble',
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        color: const Color(0xFFB71C1C),
        description: 'Si el lanzador saca un 1 natural, es Fumble automático. '
            'El balón se cae y se dispersa (scatter) desde la casilla del lanzador. '
            'Se pierde el turno si no se tiene Safe Pass.',
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
            'Resolución de recepciones, intercepciones y balones sueltos.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => _buildCatchRow(e)),
        ],
      ),
    );
  }

  Widget _buildCatchRow(_CatchEntry e) {
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
                _buildRichDescription(e.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Special Plays ───────────────────────────────────────────────────────────

  Widget _buildSpecialPlays(String lang) {
    final plays = [
      _SpecialPlay(
        name: 'HAND-OFF',
        nameEs: 'ENTREGA EN MANO',
        icon: PhosphorIcons.handshake(PhosphorIconsStyle.fill),
        color: const Color(0xFF26A69A),
        description:
            'Pasa el balón a un jugador adyacente sin hacer tirada de pase. '
            'El receptor solo necesita hacer una tirada de AG para atrapar. '
            'No puede ser interceptado. Cuenta como Completion si tiene éxito.',
      ),
      _SpecialPlay(
        name: 'DUMP-OFF',
        nameEs: 'PASE DESESPERADO',
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Si un jugador con el balón tiene la habilidad Dump-Off y un oponente '
            'declara un bloqueo contra él, puede intentar un pase rápido (Quick Pass) '
            'antes de que se resuelva el bloqueo.',
      ),
      _SpecialPlay(
        name: 'HAIL MARY PASS',
        nameEs: 'PASE AVE MARÍA',
        icon: PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description:
            'Habilidad especial: permite lanzar el balón a cualquier casilla del campo, '
            'sin importar la distancia. El pase siempre se trata como impreciso '
            'y no puede ser interceptado.',
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
            'Jugadas especiales relacionadas con el pase.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...plays.map((p) => _buildSpecialPlayRow(p)),
        ],
      ),
    );
  }

  Widget _buildSpecialPlayRow(_SpecialPlay p) {
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
                _buildRichDescription(p.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rich description with glossary ──────────────────────────────────────────

Widget _buildRichDescription(String text,
    {double fontSize = 12, Color color = AppColors.textSecondary}) {
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

  final sortedKeys = _glossary.keys.toList()
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
    final tooltip = _glossary[matched] ??
        _glossary.entries
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl injury-related terms.
const _glossary = <String, String>{
  'Armour Value':
      'Valor de Armadura (AV) del jugador. Se necesita superar este valor con 2D6 para romper la armadura.',
  'AV': 'Armour Value – Valor de Armadura del jugador.',
  'Stunned':
      'Aturdido: el jugador queda boca abajo y pierde su siguiente activación.',
  'KO':
      'Fuera de combate: el jugador va al banquillo de KO. Tira 4+ al inicio de cada drive para recuperarse.',
  'Casualty':
      'Baja: el jugador sufre una herida grave. Se tira en la tabla de Bajas para determinar el efecto.',
  'Badly Hurt':
      'Herido leve: sin efecto permanente, pero el jugador queda fuera del resto del partido.',
  'Serious Injury':
      'Lesión grave: el jugador pierde permanentemente un punto de característica o gana Niggling Injury.',
  'Dead': 'Muerto: el jugador es eliminado permanentemente del roster.',
  'Niggling Injury':
      'Lesión persistente: cada vez que sufra una baja, se añade +1 al resultado de Casualty.',
  'Apothecary':
      'Boticario: puede usarse una vez por partido para repetir un resultado de Casualty o recuperar un KO.',
  'Regeneration':
      'Regeneración: habilidad que permite ignorar una Casualty con un resultado de 4+ en 1D6.',
  'Mighty Blow':
      'Golpe Poderoso: añade +1 al resultado de Armadura o Lesión (elige uno).',
  'Claw':
      'Garra: al romper armadura, el rival siempre se considera AV 8+ (ignora AV altos).',
  'Foul':
      'Falta: acción de pisotear a un jugador caído. Se añade +1 AV por asistente, pero hay riesgo de expulsión.',
  'Piling On':
      'Ensañamiento: permite usar una re-roll para el dado de Armadura o Lesión al realizar un bloqueo.',
};

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
          _buildCasualtyTable(lang),
          const SizedBox(height: 32),
          _buildModifiersSection(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Armour Roll ─────────────────────────────────────────────────────────────

  Widget _buildArmourRollSection(String lang) {
    final steps = [
      _ProcedureStep(
        number: '1',
        title: 'TIRADA DE ARMADURA',
        titleEn: 'Armour Roll',
        icon: PhosphorIcons.shieldChevron(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description:
            'Cuando un jugador es derribado (knocked down), el oponente tira 2D6. '
            'Si el resultado es MAYOR que el Armour Value del jugador, la armadura '
            'se rompe y se pasa a la tirada de Lesión.',
      ),
      _ProcedureStep(
        number: '2',
        title: 'TIRADA DE LESIÓN',
        titleEn: 'Injury Roll',
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Si la armadura se rompe, el oponente tira 2D6 en la tabla de Lesiones '
            'para determinar la gravedad: Stunned, KO o Casualty.',
      ),
      _ProcedureStep(
        number: '3',
        title: 'TABLA DE BAJAS',
        titleEn: 'Casualty Table',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFB71C1C),
        description:
            'Si el resultado es Casualty (10+), se tira 1D6 en la tabla de Bajas '
            'para saber si el jugador está Badly Hurt, sufre Serious Injury o muere.',
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
                tr(lang, 'wikiInjuries.procedure'),
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
            'Secuencia completa cuando un jugador es derribado.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) => _buildProcedureStepCard(s, steps.length)),
        ],
      ),
    );
  }

  Widget _buildProcedureStepCard(_ProcedureStep step, int totalSteps) {
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
                      Expanded(
                        child: Row(
                          children: [
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
                            const SizedBox(width: 8),
                            Text(
                              step.titleEn,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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

  // ── Injury Table ────────────────────────────────────────────────────────────

  Widget _buildInjuryTable(String lang) {
    final injuries = [
      _InjuryEntry(
        roll: '2–6',
        name: 'STUNNED',
        nameEs: 'ATURDIDO',
        icon: PhosphorIcons.smileyXEyes(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'El jugador queda Stunned (boca abajo). Pierde su siguiente '
            'activación para darse la vuelta. No sale del campo.',
      ),
      _InjuryEntry(
        roll: '7–8',
        name: 'KO',
        nameEs: 'FUERA DE COMBATE',
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'El jugador es retirado al banquillo de KO. Al inicio de cada drive '
            'posterior, tira 1D6: con 4+ se recupera y puede volver al campo.',
      ),
      _InjuryEntry(
          roll: '9',
          name: 'BADLY HURT',
          nameEs: 'HERIDO GRAVE',
          icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
          color: const Color.fromARGB(255, 38, 255, 38),
          description:
              'Coloca al jugador en el banquillo de lesionados, no es necesario realizar tirada de lesión.'),
      _InjuryEntry(
        roll: '10–12',
        name: 'CASUALTY!',
        nameEs: '¡BAJA!',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description:
            'El jugador sufre una Casualty. Se retira del campo y se tira en la '
            'tabla de Bajas para determinar el daño permanente. El jugador que '
            'causó la baja recibe 2 SPP.',
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
              Icon(PhosphorIcons.hash(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiInjuries.injuryTable'),
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
            'Se tiran 2D6 cuando la armadura del jugador es rota.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...injuries.map((i) => _buildInjuryRow(i)),
        ],
      ),
    );
  }

  Widget _buildInjuryRow(_InjuryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [entry.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: entry.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: entry.color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                entry.roll,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: entry.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(entry.icon, color: entry.color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      entry.nameEs,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: entry.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildRichDescription(entry.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Casualty Table ──────────────────────────────────────────────────────────

  Widget _buildCasualtyTable(String lang) {
    final casualties = [
      _CasualtyEntry(
        roll: '1–8',
        name: 'BADLY HURT',
        nameEs: 'HERIDO GRAVE',
        color: const Color(0xFF66BB6A),
        description:
            'El jugador queda fuera del resto del partido, pero no sufre ningún '
            'efecto permanente. Puede jugar el siguiente partido sin problema.',
      ),
      _CasualtyEntry(
        roll: '9–10',
        name: 'SERIOUSLY HURT',
        nameEs: 'LESIÓN GRAVE',
        color: const Color(0xFFFFA726),
        description: 'El jugador se pierde el siguiente partido.',
      ),
      _CasualtyEntry(
        roll: '11–12',
        name: 'SERIOUS INJURY',
        nameEs: 'LESIÓN GRAVE',
        color: const Color(0xFFEF5350),
        description:
            'El jugador sufre una Niggling Injury y se pierde el siguiente partido.',
      ),
      _CasualtyEntry(
        roll: '13–14',
        name: 'LASTING INJURY',
        nameEs: 'LESIÓN PERSISTENTE',
        color: const Color.fromARGB(255, 165, 239, 80),
        description:
            'El jugador pierde permanentemente -1 a una de sus características. '
            'Tira 1D6: 1 = -1 MA, 2 = -1 AV, 3 = -1 PA, 4 = -1 AG, '
            '5–6 = vuelve a tirar en esta misma tabla.',
      ),
      _CasualtyEntry(
        roll: '15–16',
        name: 'DEAD!',
        nameEs: '¡MUERTO!',
        color: const Color(0xFFB71C1C),
        description:
            'El jugador muere y es eliminado permanentemente del roster del equipo. '
            'Solo un Apothecary o la habilidad Regeneration pueden salvarlo.',
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
              Icon(PhosphorIcons.skull(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiInjuries.casualtyTable'),
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
            'Se tira 1D6 cuando un jugador sufre una Casualty (10+ en la tabla de Lesión).',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...casualties.map((c) => _buildCasualtyRow(c)),
        ],
      ),
    );
  }

  Widget _buildCasualtyRow(_CasualtyEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: entry.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: entry.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: entry.color.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                entry.roll,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: entry.color,
                ),
              ),
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
                      entry.nameEs,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: entry.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _buildRichDescription(entry.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modifiers ───────────────────────────────────────────────────────────────

  Widget _buildModifiersSection(String lang) {
    final modifiers = [
      _ModifierEntry(
        name: 'MIGHTY BLOW (+1)',
        nameEs: 'GOLPE PODEROSO',
        icon: PhosphorIcons.handFist(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Añade +1 al resultado de la tirada de Armadura O de Lesión '
            '(el entrenador elige cuál). No se puede aplicar a ambas.',
      ),
      _ModifierEntry(
        name: 'CLAW',
        nameEs: 'GARRA',
        icon: PhosphorIcons.pawPrint(PhosphorIconsStyle.fill),
        color: const Color(0xFFAB47BC),
        description:
            'Al hacer una tirada de Armadura tras un bloqueo, el Armour Value '
            'del rival siempre se trata como 8+, independientemente de su AV real.',
      ),
      _ModifierEntry(
        name: 'DIRTY PLAYER (+1)',
        nameEs: 'JUEGO SUCIO',
        icon: PhosphorIcons.sneakerMove(PhosphorIconsStyle.fill),
        color: const Color(0xFF8D6E63),
        description:
            'Añade +1 al resultado de Armadura O de Lesión al realizar un Foul. '
            'Funciona igual que Mighty Blow pero solo en faltas.',
      ),
      _ModifierEntry(
        name: 'STUNTY',
        nameEs: 'PEQUEÑAJO',
        icon: PhosphorIcons.personSimple(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'Los jugadores con Stunty sufren un +1 adicional al resultado de '
            'la tirada de Lesión cuando son derribados.',
      ),
      _ModifierEntry(
        name: 'THICK SKULL',
        nameEs: 'CRÁNEO DURO',
        icon: PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description:
            'El jugador trata resultados de Stunned como KO solo con 9+, '
            'y resultados de KO como Casualty solo con 10+. Reduce efectivamente '
            'los resultados de la tabla de Lesiones en 1.',
      ),
      _ModifierEntry(
        name: 'APOTHECARY',
        nameEs: 'BOTICARIO',
        icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'Se puede usar una vez por partido. Permite repetir el resultado '
            'de la tabla de Bajas y elegir el mejor resultado, o recuperar '
            'inmediatamente a un jugador KO.',
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
            'Habilidades y efectos que modifican las tiradas de Armadura y Lesión.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...modifiers.map((m) => _buildModifierRow(m)),
        ],
      ),
    );
  }

  Widget _buildModifierRow(_ModifierEntry m) {
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
                _buildRichDescription(m.description, fontSize: 11),
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

class _ProcedureStep {
  final String number;
  final String title;
  final String titleEn;
  final IconData icon;
  final Color color;
  final String description;

  const _ProcedureStep({
    required this.number,
    required this.title,
    required this.titleEn,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _InjuryEntry {
  final String roll;
  final String name;
  final String nameEs;
  final IconData icon;
  final Color color;
  final String description;

  const _InjuryEntry({
    required this.roll,
    required this.name,
    required this.nameEs,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _CasualtyEntry {
  final String roll;
  final String name;
  final String nameEs;
  final Color color;
  final String description;

  const _CasualtyEntry({
    required this.roll,
    required this.name,
    required this.nameEs,
    required this.color,
    required this.description,
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

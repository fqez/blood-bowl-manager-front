import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl blocking terms.
const _glossary = <String, String>{
  'Blitz':
      'Acción especial: un jugador puede moverse y realizar un bloqueo en la misma activación. Solo uno por turno.',
  'Block':
      'Habilidad: permite ignorar el resultado "Both Down" al bloquear sin caer.',
  'Dodge':
      'Habilidad: permite ignorar el resultado "Defender Stumbles" al ser bloqueado.',
  'Guard':
      'Habilidad: permite dar asistencias de bloqueo incluso estando en la zona de tackle de un oponente.',
  'Tackle': 'Habilidad: anula la habilidad Dodge del rival al bloquearlo.',
  'Frenzy':
      'Habilidad: obliga a hacer un segundo bloqueo si el primero resulta en Push Back.',
  'Horns': 'Habilidad: añade +1 ST al jugador al realizar un Blitz.',
  'Wrestle':
      'Habilidad: al obtener Both Down, puedes elegir que ambos jugadores caigan sin tirada de armadura.',
  'Juggernaut':
      'Habilidad: al hacer Blitz, Both Down cuenta como Push Back en lugar de derribar a ambos.',
  'Stand Firm':
      'Habilidad: el jugador puede elegir no ser empujado por un Push Back.',
  'Strength':
      'Fuerza (ST) del jugador. Determina cuántos dados de bloqueo se tiran.',
  'Re-roll':
      'Permite repetir una tirada de dados fallida. Cada equipo tiene un número limitado por drive.',
  'Prone':
      'Estado del jugador: tumbado en el suelo, debe gastar movimiento para levantarse.',
  'Stunned':
      'Estado del jugador: tumbado boca abajo, pierde su siguiente activación para levantarse.',
  'Tackle Zone':
      'Zona de control alrededor de un jugador de pie. Cada casilla adyacente es su Tackle Zone.',
};

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
          const SizedBox(height: 32),
          _buildSpecialRulesSection(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Block Dice ──────────────────────────────────────────────────────────────

  Widget _buildBlockDiceSection(String lang) {
    final diceFaces = [
      _DiceFace(
        symbol: _DiceSymbol.attackerDown,
        name: 'ATTACKER DOWN',
        nameEs: 'ATACANTE DERRIBADO',
        color: const Color(0xFFE53935),
        quantity: '×1',
        description:
            'El jugador que realiza el bloqueo es derribado. Se hace tirada de '
            'Armadura contra él. Este es el peor resultado posible para el atacante.',
      ),
      _DiceFace(
        symbol: _DiceSymbol.bothDown,
        name: 'BOTH DOWN',
        nameEs: 'AMBOS CAÍDOS',
        color: const Color(0xFFFF7043),
        quantity: '×1',
        description:
            'Ambos jugadores caen al suelo. Se tira Armadura contra los dos. '
            'La habilidad Block permite ignorar este resultado sin caer. '
            'Wrestle permite que ambos caigan sin tirada de armadura.',
      ),
      _DiceFace(
        symbol: _DiceSymbol.push,
        name: 'PUSH BACK',
        nameEs: 'EMPUJÓN',
        color: const Color(0xFF42A5F5),
        quantity: '×2',
        description:
            'El defensor es empujado un casillero hacia atrás (dirección elegida '
            'por el atacante). No se derriba. Si es empujado fuera del campo, '
            'recibe un golpe de la multitud.',
      ),
      _DiceFace(
        symbol: _DiceSymbol.stumble,
        name: 'DEFENDER STUMBLES',
        nameEs: 'DEFENSOR TROPIEZA',
        color: const Color(0xFFFFA726),
        quantity: '×1',
        description:
            'El defensor es empujado y derribado. Sin embargo, si tiene la '
            'habilidad Dodge, puede usarla para convertirlo en un simple Push Back. '
            'Tackle anula el Dodge.',
      ),
      _DiceFace(
        symbol: _DiceSymbol.pow,
        name: 'POW!',
        nameEs: 'DERRIBADO',
        color: const Color(0xFF66BB6A),
        quantity: '×1',
        description:
            'El defensor es empujado y derribado. Este es el mejor resultado '
            'para el atacante. No puede ser anulado por Dodge.',
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
              Icon(PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiBlocking.blockDice'),
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
            'El dado de Bloqueo tiene 6 caras con 5 resultados distintos (Push Back aparece 2 veces).',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          // Dice faces grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: diceFaces.map((d) => _buildDiceFaceCard(d)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceFaceCard(_DiceFace face) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [face.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: face.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom dice face
          _BlockDieWidget(symbol: face.symbol, color: face.color, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      face.nameEs,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: face.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: face.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        face.quantity,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: face.color,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  face.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                _buildRichDescription(face.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Block Procedure ─────────────────────────────────────────────────────────

  Widget _buildBlockProcedure(String lang) {
    final steps = [
      _BlockStep(
        number: '1',
        title: 'DECLARAR BLOQUEO',
        icon: PhosphorIcons.target(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'Elige un jugador adyacente al oponente como objetivo. El jugador '
            'no puede moverse antes de bloquear (a menos que sea un Blitz).',
      ),
      _BlockStep(
        number: '2',
        title: 'CALCULAR DADOS',
        icon: PhosphorIcons.scales(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Compara la Strength del atacante (+ asistencias) con la del defensor '
            '(+ asistencias). Esto determina cuántos dados se tiran y quién elige.',
      ),
      _BlockStep(
        number: '3',
        title: 'TIRAR DADOS DE BLOQUEO',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'Tira el número de dados correspondiente. El jugador que "elige" '
            'escoge cuál de los resultados aplicar.',
      ),
      _BlockStep(
        number: '4',
        title: 'APLICAR RESULTADO',
        icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Resuelve el resultado elegido: Push Back, derribo, o ambos. '
            'Si hay Push Back, elige la dirección. Si hay derribo, tira Armadura.',
      ),
      _BlockStep(
        number: '5',
        title: 'FOLLOW UP',
        icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description:
            'El atacante puede (opcionalmente) avanzar al casillero que dejó '
            'libre el defensor empujado. Esto es obligatorio con Frenzy.',
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
                tr(lang, 'wikiBlocking.procedure'),
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
            'Pasos para resolver un bloqueo en Blood Bowl.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) => _buildBlockStepCard(s, steps.length)),
        ],
      ),
    );
  }

  Widget _buildBlockStepCard(_BlockStep step, int totalSteps) {
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

  // ── Dice Count Table ────────────────────────────────────────────────────────

  Widget _buildDiceCountSection(String lang) {
    final entries = [
      _DiceCountEntry(
        scenario: 'ST atacante > ST defensor',
        scenarioEn: 'Attacker ST > Defender ST',
        dice: '2 DADOS',
        diceEn: '2 Block Dice',
        color: const Color(0xFF66BB6A),
        description:
            'El atacante tira 2 dados de bloqueo y ELIGE el resultado.',
        chooser: 'Atacante elige',
      ),
      _DiceCountEntry(
        scenario: 'ST atacante = ST defensor',
        scenarioEn: 'Attacker ST = Defender ST',
        dice: '1 DADO',
        diceEn: '1 Block Die',
        color: const Color(0xFFFFA726),
        description:
            'Se tira 1 dado de bloqueo. El resultado se aplica obligatoriamente.',
        chooser: 'Sin elección',
      ),
      _DiceCountEntry(
        scenario: 'ST atacante < ST defensor',
        scenarioEn: 'Attacker ST < Defender ST',
        dice: '2 DADOS',
        diceEn: '2 Block Dice',
        color: const Color(0xFFEF5350),
        description:
            'Se tiran 2 dados de bloqueo, pero el DEFENSOR elige el resultado.',
        chooser: 'Defensor elige',
      ),
      _DiceCountEntry(
        scenario: 'ST atacante ≥ 2× ST defensor',
        scenarioEn: 'Attacker ST ≥ 2× Defender ST',
        dice: '3 DADOS',
        diceEn: '3 Block Dice',
        color: const Color(0xFF2E7D32),
        description:
            'El atacante tira 3 dados de bloqueo y ELIGE el resultado. Dominio total.',
        chooser: 'Atacante elige',
      ),
      _DiceCountEntry(
        scenario: 'ST defensor ≥ 2× ST atacante',
        scenarioEn: 'Defender ST ≥ 2× Attacker ST',
        dice: '3 DADOS',
        diceEn: '3 Block Dice',
        color: const Color(0xFFB71C1C),
        description:
            'Se tiran 3 dados de bloqueo, pero el DEFENSOR elige. Muy arriesgado.',
        chooser: 'Defensor elige',
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
              Icon(PhosphorIcons.scales(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiBlocking.diceCount'),
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
            'La cantidad de dados depende de la comparación de Fuerza (ST) entre atacante y defensor, incluyendo asistencias.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => _buildDiceCountRow(e)),
        ],
      ),
    );
  }

  Widget _buildDiceCountRow(_DiceCountEntry e) {
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
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: e.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: e.color.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  e.dice.split(' ').first,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: e.color,
                  ),
                ),
                Text(
                  'DADOS',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: e.color.withOpacity(0.7),
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
                    Text(
                      e.scenario,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: e.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.chooser,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: e.color,
                    ),
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

  // ── Special Rules ───────────────────────────────────────────────────────────

  Widget _buildSpecialRulesSection(String lang) {
    final rules = [
      _SpecialRule(
        name: 'ASISTENCIAS',
        nameEn: 'Assists',
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'Cada jugador amigo adyacente al defensor que NO esté en la Tackle Zone '
            'de otro oponente (salvo que tenga Guard) suma +1 ST al atacante. '
            'Los asistentes del defensor funcionan igual.',
      ),
      _SpecialRule(
        name: 'BLITZ',
        nameEn: 'Blitz Action',
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Una vez por turno, un jugador puede realizar un Blitz: moverse '
            'Y hacer un bloqueo durante el movimiento (gasta +1 MA para el bloqueo). '
            'Es la única forma de moverse y bloquear en la misma activación.',
      ),
      _SpecialRule(
        name: 'EMPUJÓN FUERA DEL CAMPO',
        nameEn: 'Crowd Push',
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description:
            'Si un jugador es empujado fuera del campo, recibe automáticamente '
            'una tirada de Lesión (sin tirada de Armadura). La multitud no perdona.',
      ),
      _SpecialRule(
        name: 'FOLLOW UP',
        nameEn: 'Follow Up',
        icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description:
            'Tras empujar al defensor, el atacante puede ocupar su casilla original. '
            'Es opcional excepto con la habilidad Frenzy (obligatorio).',
      ),
      _SpecialRule(
        name: 'CADENA DE EMPUJONES',
        nameEn: 'Chain Push',
        icon: PhosphorIcons.arrowsOutLineVertical(PhosphorIconsStyle.fill),
        color: const Color(0xFF26A69A),
        description:
            'Si el defensor es empujado hacia un casillero ocupado por otro jugador, '
            'ese jugador también es empujado. Las cadenas pueden afectar a varios jugadores.',
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
              Icon(PhosphorIcons.info(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiBlocking.specialRules'),
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
            'Reglas adicionales que afectan a los bloqueos.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...rules.map((r) => _buildSpecialRuleRow(r)),
        ],
      ),
    );
  }

  Widget _buildSpecialRuleRow(_SpecialRule r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: r.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: r.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: r.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: r.color.withOpacity(0.35)),
            ),
            child: Center(
              child: Icon(r.icon, color: r.color, size: 18),
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
                      r.name,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: r.color,
                        letterSpacing: 0.5,
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
                const SizedBox(height: 3),
                _buildRichDescription(r.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Block Die Widget ────────────────────────────────────────────────────────

/// Custom widget that renders a Blood Bowl block die face.
class _BlockDieWidget extends StatelessWidget {
  final _DiceSymbol symbol;
  final Color color;
  final double size;

  const _BlockDieWidget({
    required this.symbol,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _BlockDiePainter(symbol: symbol, color: color),
      ),
    );
  }
}

class _BlockDiePainter extends CustomPainter {
  final _DiceSymbol symbol;
  final Color color;

  _BlockDiePainter({required this.symbol, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final unit = size.width / 6;

    switch (symbol) {
      case _DiceSymbol.attackerDown:
        // Skull icon
        _drawSkull(canvas, cx, cy, unit, paint, strokePaint);
        break;
      case _DiceSymbol.bothDown:
        // Two arrows pointing at each other
        _drawBothDown(canvas, cx, cy, unit, paint, strokePaint);
        break;
      case _DiceSymbol.push:
        // Arrow pointing right (push back)
        _drawPush(canvas, cx, cy, unit, paint);
        break;
      case _DiceSymbol.stumble:
        // Lightning bolt / trip symbol
        _drawStumble(canvas, cx, cy, unit, paint);
        break;
      case _DiceSymbol.pow:
        // Star burst / POW
        _drawPow(canvas, cx, cy, unit, paint);
        break;
    }
  }

  void _drawSkull(
      Canvas canvas, double cx, double cy, double u, Paint fill, Paint stroke) {
    // Skull head (circle)
    canvas.drawCircle(Offset(cx, cy - u * 0.3), u * 1.3, fill);
    // Eye holes (dark)
    final eyePaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(Offset(cx - u * 0.5, cy - u * 0.5), u * 0.35, eyePaint);
    canvas.drawCircle(Offset(cx + u * 0.5, cy - u * 0.5), u * 0.35, eyePaint);
    // Nose
    final nosePath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - u * 0.15, cy + u * 0.3)
      ..lineTo(cx + u * 0.15, cy + u * 0.3)
      ..close();
    canvas.drawPath(nosePath, eyePaint);
    // Jaw line
    canvas.drawLine(
        Offset(cx - u * 0.6, cy + u * 0.6),
        Offset(cx + u * 0.6, cy + u * 0.6),
        stroke..color = const Color(0xFF1A1A2E));
    // Teeth
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
          Offset(cx + i * u * 0.25, cy + u * 0.6),
          Offset(cx + i * u * 0.25, cy + u * 0.9),
          Paint()
            ..color = const Color(0xFF1A1A2E)
            ..strokeWidth = 1.5);
    }
  }

  void _drawBothDown(
      Canvas canvas, double cx, double cy, double u, Paint fill, Paint stroke) {
    // Two arrows pointing inward (both players fall)
    final leftArrow = Path()
      ..moveTo(cx - u * 1.8, cy)
      ..lineTo(cx - u * 0.3, cy - u * 0.8)
      ..lineTo(cx - u * 0.3, cy - u * 0.3)
      ..lineTo(cx + u * 0.3, cy - u * 0.3)
      ..lineTo(cx + u * 0.3, cy - u * 0.8)
      ..lineTo(cx + u * 1.8, cy)
      ..lineTo(cx + u * 0.3, cy + u * 0.8)
      ..lineTo(cx + u * 0.3, cy + u * 0.3)
      ..lineTo(cx - u * 0.3, cy + u * 0.3)
      ..lineTo(cx - u * 0.3, cy + u * 0.8)
      ..close();
    canvas.drawPath(leftArrow, fill);
  }

  void _drawPush(Canvas canvas, double cx, double cy, double u, Paint fill) {
    // Arrow pointing right
    final arrow = Path()
      ..moveTo(cx - u * 1.2, cy - u * 0.5)
      ..lineTo(cx + u * 0.2, cy - u * 0.5)
      ..lineTo(cx + u * 0.2, cy - u * 1.2)
      ..lineTo(cx + u * 1.8, cy)
      ..lineTo(cx + u * 0.2, cy + u * 1.2)
      ..lineTo(cx + u * 0.2, cy + u * 0.5)
      ..lineTo(cx - u * 1.2, cy + u * 0.5)
      ..close();
    canvas.drawPath(arrow, fill);
  }

  void _drawStumble(Canvas canvas, double cx, double cy, double u, Paint fill) {
    // Lightning bolt shape (trip/stumble)
    final bolt = Path()
      ..moveTo(cx + u * 0.2, cy - u * 1.8)
      ..lineTo(cx - u * 0.6, cy - u * 0.2)
      ..lineTo(cx + u * 0.2, cy - u * 0.2)
      ..lineTo(cx - u * 0.4, cy + u * 1.8)
      ..lineTo(cx + u * 0.6, cy + u * 0.2)
      ..lineTo(cx - u * 0.2, cy + u * 0.2)
      ..close();
    canvas.drawPath(bolt, fill);
  }

  void _drawPow(Canvas canvas, double cx, double cy, double u, Paint fill) {
    // Star burst (POW!)
    final path = Path();
    const points = 8;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? u * 1.8 : u * 0.8;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);

    // "POW" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: const Color(0xFF1A1A2E),
          fontSize: u * 2,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

enum _DiceSymbol { attackerDown, bothDown, push, stumble, pow }

class _DiceFace {
  final _DiceSymbol symbol;
  final String name;
  final String nameEs;
  final Color color;
  final String quantity;
  final String description;

  const _DiceFace({
    required this.symbol,
    required this.name,
    required this.nameEs,
    required this.color,
    required this.quantity,
    required this.description,
  });
}

class _BlockStep {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const _BlockStep({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _DiceCountEntry {
  final String scenario;
  final String scenarioEn;
  final String dice;
  final String diceEn;
  final Color color;
  final String description;
  final String chooser;

  const _DiceCountEntry({
    required this.scenario,
    required this.scenarioEn,
    required this.dice,
    required this.diceEn,
    required this.color,
    required this.description,
    required this.chooser,
  });
}

class _SpecialRule {
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String description;

  const _SpecialRule({
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.description,
  });
}

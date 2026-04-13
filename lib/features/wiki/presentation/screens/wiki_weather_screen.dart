import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl terms with short explanations.
const _glossary = <String, String>{
  'Petty Cash':
      'Dinero temporal que recibe el equipo con menor Valor de Equipo (TV) para equilibrar el partido.',
  'Inducements':
      'Contrataciones especiales de un solo partido: Jugadores Estrella, Sobornos, pociones, etc.',
  'Bribe':
      'Soborno al árbitro. Permite ignorar una expulsión por Foul una vez por partido.',
  'Re-roll':
      'Permite repetir una tirada de dados fallida. Cada equipo tiene un número limitado por drive.',
  'FAME':
      'Factor de Audiencia del Equipo. Bonus basado en la diferencia de Fan Factor entre equipos.',
  'Blitz':
      'Acción especial: un jugador puede moverse y realizar un bloqueo en la misma activación.',
  'Cheerleaders':
      'Animadoras del equipo. Suman bonus en eventos de Kickoff como Cheering Fans.',
  'Assistant Coaches':
      'Entrenadores asistentes. Suman bonus en eventos de Kickoff como Brilliant Coaching.',
  'Línea de Scrimmage':
      'La línea central del campo. Debe haber al menos 3 jugadores propios ahí al inicio.',
  'Stunned':
      'Estado del jugador: tumbado boca abajo, pierde su siguiente activación para levantarse.',
  'Prone':
      'Estado del jugador: tumbado en el suelo, debe gastar movimiento para levantarse.',
  'Jugadores Estrella':
      'Mercenarios legendarios que se contratan por un solo partido como Inducement.',
};

class WikiWeatherScreen extends ConsumerWidget {
  const WikiWeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
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
                  _buildWeatherTable(lang),
                  const SizedBox(height: 32),
                  _buildPreGameSection(lang),
                  const SizedBox(height: 32),
                  _buildKickoffSequence(lang),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

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
              tr(lang, 'wikiWeather.title'),
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

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF1565C0).withOpacity(0.3),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                tr(lang, 'wikiWeather.title'),
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
            tr(lang, 'wikiWeather.subtitle'),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Weather Table ───────────────────────────────────────────────────────────

  Widget _buildWeatherTable(String lang) {
    final weatherData = [
      _WeatherEntry(
        roll: '2',
        name: 'CALOR ABRASADOR',
        nameEn: 'Sweltering Heat',
        icon: PhosphorIcons.thermometerHot(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: 'Hace un calor insoportable. Al comienzo de cada drive, '
            'tira 1D6 por cada jugador en el campo. Con un resultado de 1, '
            'el jugador queda KO por el calor.',
      ),
      _WeatherEntry(
        roll: '3',
        name: 'SOL CEGADOR',
        nameEn: 'Very Sunny',
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: 'Un sol brillante deslumbra a los jugadores. Se aplica un '
            'modificador de -1 a todos los intentos de pase.',
      ),
      _WeatherEntry(
        roll: '4 – 10',
        name: 'CONDICIONES PERFECTAS',
        nameEn: 'Perfect Conditions',
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        color: const Color(0xFF4CAF50),
        description: 'Tiempo ideal para jugar al Blood Bowl. No se aplica '
            'ningún modificador por clima.',
      ),
      _WeatherEntry(
        roll: '11',
        name: 'LLUVIA TORRENCIAL',
        nameEn: 'Pouring Rain',
        icon: PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'La lluvia empapa el campo. Se aplica un modificador de -1 '
            'a todos los intentos de atrapar el balón, recoger el balón y '
            'los intentos de pase.',
      ),
      _WeatherEntry(
        roll: '12',
        name: 'VENTISCA',
        nameEn: 'Blizzard',
        icon: PhosphorIcons.snowflake(PhosphorIconsStyle.fill),
        color: const Color(0xFF90CAF9),
        description: 'Una ventisca azota el campo. Solo se puede hacer pases '
            'cortos o rápidos (Quick Pass y Short Pass). '
            'Además, se aplica un modificador de -1 al intento de atrapar el balón.',
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
                tr(lang, 'wikiWeather.weatherTable'),
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
            'Antes de cada partido, ambos entrenadores tiran 2D6 para determinar las condiciones meteorológicas.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...weatherData.map((w) => _buildWeatherRow(w)),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(_WeatherEntry w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [w.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: w.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dice roll badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: w.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: w.color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                w.roll,
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: w.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(w.icon, color: w.color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      w.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: w.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      w.nameEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildRichDescription(w.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pre-game sequence ─────────────────────────────────────────────────────

  Widget _buildPreGameSection(String lang) {
    final steps = [
      _PreGameStep(
        number: '1',
        title: 'PETTY CASH',
        icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: 'Ambos entrenadores revelan su Valor de Equipo (TV). '
            'El equipo con menor TV recibe la diferencia entre ambos TVs como '
            'Petty Cash, que puede gastar en Inducements para ese partido.',
      ),
      _PreGameStep(
        number: '2',
        title: 'COMPRAR INDUCEMENTS',
        icon: PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description: 'El entrenador que recibió Petty Cash gasta su dinero en '
            'Inducements (Jugadores Estrella, Sobornos, pociones, etc.). '
            'El otro entrenador también puede comprar Inducements con su propio tesoro.',
      ),
      _PreGameStep(
        number: '3',
        title: 'TIRADA DE CLIMA',
        icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: 'Tira 2D6 y consulta la tabla de clima para determinar '
            'las condiciones meteorológicas del partido. El resultado se aplica '
            'durante todo el encuentro.',
      ),
      _PreGameStep(
        number: '4',
        title: 'SORTEO DE CAMPO',
        icon: PhosphorIcons.coinVertical(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: 'Ambos entrenadores tiran 1D6 (repitiendo empates). '
            'El ganador elige si hace el kickoff o si recibe. '
            'En la segunda mitad se invierten los roles.',
      ),
      _PreGameStep(
        number: '5',
        title: 'COLOCACIÓN DE JUGADORES',
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: 'El entrenador que hace el kickoff coloca primero a '
            'sus jugadores en su mitad del campo (mín. 3 en la Línea de Scrimmage, '
            'máx. 11 en total). Después, el equipo receptor se coloca igual.',
      ),
      _PreGameStep(
        number: '6',
        title: 'KICKOFF',
        icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'El equipo que patea realiza el kickoff, lanzando el balón al '
            'campo rival. Se tira en la Tabla de Kickoff (2D6) para un evento '
            'especial (Riot, Perfect Defence, Blitz!, etc.).',
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
                tr(lang, 'wikiWeather.preGame'),
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
            'Pasos a seguir antes de que comience la acción en el campo.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) => _buildPreGameStepCard(s)),
        ],
      ),
    );
  }

  Widget _buildPreGameStepCard(_PreGameStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
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
              if (int.parse(step.number) < 6)
                Container(
                  width: 2,
                  height: 24,
                  color: step.color.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
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
                          fontFamily: AppTextStyles.displayFont,
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

  // ── Kickoff table ─────────────────────────────────────────────────────────

  Widget _buildKickoffSequence(String lang) {
    final events = [
      _KickoffEvent(
        roll: '2',
        name: 'GET THE REF!',
        color: const Color(0xFFE53935),
        description:
            'Ambos equipos reciben un Bribe gratuito para este partido.',
      ),
      _KickoffEvent(
        roll: '3',
        name: 'RIOT!',
        color: const Color(0xFFFF7043),
        description:
            'El reloj del partido se descontrola. Tira 1D6: 1-3 el turno avanza 1, '
            '4-6 retrocede 1 (no puede bajar de 0).',
      ),
      _KickoffEvent(
        roll: '4',
        name: 'PERFECT DEFENCE',
        color: const Color(0xFF66BB6A),
        description:
            'El equipo que hace el kickoff puede reorganizar a todos sus '
            'jugadores respetando las reglas de colocación.',
      ),
      _KickoffEvent(
        roll: '5',
        name: 'HIGH KICK',
        color: const Color(0xFF42A5F5),
        description:
            'El equipo receptor puede mover un jugador (que no esté en la LOS) '
            'directamente bajo el balón para intentar atraparlo.',
      ),
      _KickoffEvent(
        roll: '6',
        name: 'CHEERING FANS',
        color: const Color(0xFFAB47BC),
        description:
            'Cada entrenador tira 1D6 + nº de Cheerleaders de Dedicación. '
            'El ganador recibe un uso extra de Re-roll para este drive.',
      ),
      _KickoffEvent(
        roll: '7',
        name: 'CHANGING WEATHER',
        color: const Color(0xFF78909C),
        description:
            'Tira de nuevo en la tabla de clima. Las nuevas condiciones '
            'se aplican inmediatamente.',
      ),
      _KickoffEvent(
        roll: '8',
        name: 'BRILLIANT COACHING',
        color: const Color(0xFFD4AF37),
        description: 'Cada entrenador tira 1D6 + nº de Assistant Coaches. '
            'El ganador recibe un uso extra de Re-roll para este drive.',
      ),
      _KickoffEvent(
        roll: '9',
        name: 'QUICK SNAP!',
        color: const Color(0xFF26A69A),
        description: 'El equipo receptor puede mover a todos sus jugadores un '
            'casillero en cualquier dirección antes de que caiga el balón.',
      ),
      _KickoffEvent(
        roll: '10',
        name: 'BLITZ!',
        color: const Color(0xFFEF5350),
        description: 'El equipo que hace el kickoff puede mover a todos sus '
            'jugadores un casillero en cualquier dirección. Uno de ellos puede '
            'realizar una acción de Blitz.',
      ),
      _KickoffEvent(
        roll: '11',
        name: 'OFFICIOUS REF',
        color: const Color(0xFFFF8A65),
        description: 'Cada entrenador tira 1D6. El que saque menor resultado '
            'pierde un jugador aleatorio al Prone por tarjeta (si empatan, no pasa nada).',
      ),
      _KickoffEvent(
        roll: '12',
        name: 'PITCH INVASION!',
        color: const Color(0xFFE53935),
        description: 'Tira 1D6 por cada jugador en el campo de ambos equipos. '
            'Si saca 6 (ó 6+ con modificador por FAME) el jugador queda Stunned.',
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
              Icon(PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiWeather.kickoff'),
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
            'Después del kickoff, se tiran 2D6 para determinar un evento especial.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...events.map((e) => _buildKickoffRow(e)),
        ],
      ),
    );
  }

  Widget _buildKickoffRow(_KickoffEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: e.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: e.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roll badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: e.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.color.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                e.roll,
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: e.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: e.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                _buildRichDescription(e.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds a [RichText] where glossary terms are highlighted and wrapped in
/// [Tooltip] widgets so users can tap/hover to see explanations.
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

  // Build a regex that matches any glossary key (longest first).
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
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

// ── Data classes ─────────────────────────────────────────────────────────────

class _WeatherEntry {
  final String roll;
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String description;

  const _WeatherEntry({
    required this.roll,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _PreGameStep {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const _PreGameStep({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _KickoffEvent {
  final String roll;
  final String name;
  final Color color;
  final String description;

  const _KickoffEvent({
    required this.roll,
    required this.name,
    required this.color,
    required this.description,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_dice_board.dart';
import '../widgets/wiki_page_layout.dart';
import '../widgets/wiki_timeline_section.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl terms with short explanations.
Map<String, String> _glossary(String lang) {
  final es = lang == 'es';

  return <String, String>{
    'Petty Cash': es
        ? 'Dinero temporal que recibe el equipo con menor Valor de Equipo para equilibrar el partido.'
        : 'Temporary money the lower Team Value side receives to balance the match.',
    'Inducements': es
        ? 'Contrataciones especiales de un solo partido: Jugadores Estrella, Sobornos, pociones y similares.'
        : 'Special one-match hires such as Star Players, Bribes, potions, and similar options.',
    'Bribe': es
        ? 'Soborno al arbitro. Permite ignorar una expulsion por Foul una vez por partido.'
        : 'A bribe for the referee. It can ignore a sending-off from a Foul once per game.',
    'Re-roll': es
        ? 'Permite repetir una tirada fallida. Cada equipo tiene un numero limitado por drive.'
        : 'Allows a failed roll to be repeated. Each team has a limited number per drive.',
    'FAME': es
        ? 'Factor de audiencia del equipo. Bono basado en la diferencia de aficion entre ambos equipos.'
        : 'Fan advantage based on the difference in support between both teams.',
    'Blitz': es
        ? 'Accion especial: un jugador puede moverse y realizar un placaje en la misma activacion.'
        : 'Special action: a player can move and perform a Block in the same activation.',
    'Cheerleaders': es
        ? 'Animadoras del equipo. Dan bonificacion en eventos como Cheering Fans.'
        : 'Team cheerleaders. They add bonuses to events such as Cheering Fans.',
    'Assistant Coaches': es
        ? 'Entrenadores asistentes. Dan bonificacion en eventos como Brilliant Coaching.'
        : 'Assistant coaches. They add bonuses to events such as Brilliant Coaching.',
    'Línea de Scrimmage': es
        ? 'La linea central del campo. Debe haber al menos 3 jugadores propios ahi al inicio.'
        : 'The centre line of the pitch. You must place at least 3 players there during setup.',
    'Stunned': es
        ? 'Estado del jugador: boca abajo y sin siguiente activacion.'
        : 'Player state: face down and losing their next activation.',
    'Prone': es
        ? 'Estado del jugador: en el suelo y debe gastar movimiento para levantarse.'
        : 'Player state: on the ground and must spend movement to stand up.',
    'Jugadores Estrella': es
        ? 'Mercenarios legendarios que se contratan como Inducement por un solo partido.'
        : 'Legendary mercenaries hired as a one-match Inducement.',
  };
}

class WikiWeatherScreen extends ConsumerWidget {
  const WikiWeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return WikiPageLayout(
      title: tr(lang, 'wikiWeather.title'),
      heroIcon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiWeather.subtitle'),
      accentColor: AppColors.accent,
      gradientColor: const Color(0xFF1565C0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreGameSection(lang),
          const SizedBox(height: 32),
          _buildWeatherTable(lang),
          const SizedBox(height: 32),
          _buildKickoffSequence(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Pre-game sequence ─────────────────────────────────────────────────────

  Widget _buildPreGameSection(String lang) {
    final es = lang == 'es';
    final steps = [
      WikiTimelineEntry(
        marker: '1',
        title: es ? 'PETTY CASH' : 'PETTY CASH',
        icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: es
            ? 'Ambos entrenadores revelan su Valor de Equipo. El equipo con menor TV recibe la diferencia como Petty Cash para gastarla en Inducements.'
            : 'Both coaches reveal their Team Value. The team with the lower TV receives the difference as Petty Cash to spend on Inducements.',
      ),
      WikiTimelineEntry(
        marker: '2',
        title: es ? 'COMPRAR INDUCEMENTS' : 'BUY INDUCEMENTS',
        icon: PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        description: es
            ? 'El entrenador que recibio Petty Cash gasta ese dinero en Inducements. El otro entrenador tambien puede comprar con su propio tesoro.'
            : 'The coach who received Petty Cash spends it on Inducements. The other coach may also buy Inducements with their own treasury.',
      ),
      WikiTimelineEntry(
        marker: '3',
        title: es ? 'TIRADA DE CLIMA' : 'WEATHER ROLL',
        icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Tira 2D6 y consulta la tabla de clima para determinar las condiciones meteorologicas del partido.'
            : 'Roll 2D6 and consult the Weather table to determine the match conditions.',
      ),
      WikiTimelineEntry(
        marker: '4',
        title: es ? 'SORTEO DE CAMPO' : 'KICK OR RECEIVE',
        icon: PhosphorIcons.coinVertical(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Ambos entrenadores tiran 1D6. El ganador decide si patea o recibe. En la segunda parte se invierten los roles.'
            : 'Both coaches roll 1D6. The winner decides whether to kick or receive. Roles swap in the second half.',
      ),
      WikiTimelineEntry(
        marker: '5',
        title: es ? 'COLOCACION DE JUGADORES' : 'SET UP PLAYERS',
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El equipo que patea se coloca primero en su mitad del campo. Debe cumplir las reglas de colocacion antes de que el rival se despliegue.'
            : 'The kicking team sets up first in its own half. It must follow the usual setup rules before the receiving team deploys.',
      ),
      WikiTimelineEntry(
        marker: '6',
        title: es ? 'KICKOFF' : 'KICK-OFF',
        icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'El equipo que patea hace el kickoff y luego se tira en la tabla de Kickoff para resolver un evento especial.'
            : 'The kicking team performs the kick-off, then the Kick-off table is rolled to resolve a special event.',
      ),
    ];

    return WikiTimelineSection(
      headerIcon: PhosphorIcons.listNumbers(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiWeather.preGame'),
      subtitle: es
          ? 'Pasos a seguir antes de que comience la accion en el campo.'
          : 'Steps to follow before the action begins on the pitch.',
      entries: steps,
      railColor: Colors.white.withOpacity(0.58),
      railWidth: 52,
      circleSize: 24,
      lineWidth: 3,
        itemSpacing: 6,
      descriptionBuilder: (context, entry, fontSize) => _buildRichDescription(
          entry.description,
          lang: lang,
          fontSize: fontSize),
    );
  }

  // ── Weather Table ───────────────────────────────────────────────────────────

  Widget _buildWeatherTable(String lang) {
    final es = lang == 'es';
    final weatherData = [
      WikiDiceBoardEntry(
        roll: '2',
        title: es ? 'CALOR ABRASADOR' : 'SWELTERING HEAT',
        subtitle: es ? 'Sweltering Heat' : 'CALOR ABRASADOR',
        icon: PhosphorIcons.thermometerHot(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: es
            ? 'Hace un calor insoportable. Al final de cada drive, algunos jugadores pueden retirarse a Reservas por el calor.'
            : 'The heat is intense. At the end of each drive, some players may be sent to Reserves because of it.',
      ),
      WikiDiceBoardEntry(
        roll: '3',
        title: es ? 'SOL CEGADOR' : 'VERY SUNNY',
        subtitle: es ? 'Very Sunny' : 'SOL CEGADOR',
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'La luz deslumbra a los jugadores. Se aplica un modificador de -1 a las pruebas de pase.'
            : 'The sunlight dazzles players. Apply a -1 modifier to Passing Ability tests.',
      ),
      WikiDiceBoardEntry(
        roll: '4 – 10',
        title: es ? 'CONDICIONES PERFECTAS' : 'PERFECT CONDITIONS',
        subtitle: es ? 'Perfect Conditions' : 'CONDICIONES PERFECTAS',
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        color: const Color(0xFF4CAF50),
        description: es
            ? 'Tiempo ideal para jugar. No se aplica ningun efecto adicional.'
            : 'Ideal weather for Blood Bowl. No additional effect applies.',
      ),
      WikiDiceBoardEntry(
        roll: '11',
        title: es ? 'LLUVIA TORRENCIAL' : 'POURING RAIN',
        subtitle: es ? 'Pouring Rain' : 'LLUVIA TORRENCIAL',
        icon: PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'La lluvia deja el balon resbaladizo. Se aplica un -1 a recoger, atrapar e interceptar pases.'
            : 'The rain makes the ball slippery. Apply -1 to pick-up, catch, and intercept attempts.',
      ),
      WikiDiceBoardEntry(
        roll: '12',
        title: es ? 'VENTISCA' : 'BLIZZARD',
        subtitle: es ? 'Blizzard' : 'VENTISCA',
        icon: PhosphorIcons.snowflake(PhosphorIconsStyle.fill),
        color: const Color(0xFF90CAF9),
        description: es
            ? 'La ventisca vuelve el campo traicionero. Solo se permiten pases rapidos o cortos y Rush es mas peligroso.'
            : 'The blizzard makes footing dangerous. Only Quick or Short Passes are allowed and Rush attempts become harder.',
      ),
    ];

    return WikiDiceBoard(
      headerIcon: PhosphorIcons.hash(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiWeather.weatherTable'),
      subtitle: es
          ? 'Antes de cada partido, ambos entrenadores tiran 2D6 para determinar las condiciones meteorologicas.'
          : 'Before each match, both coaches roll 2D6 to determine the weather conditions.',
      diceAssetPath: 'assets/images/dice/2D6.png',
      entries: weatherData,
    );
  }

  // ── Kickoff table ─────────────────────────────────────────────────────────

  Widget _buildKickoffSequence(String lang) {
    final es = lang == 'es';
    final events = [
      WikiDiceBoardEntry(
        roll: '2',
        title: es ? 'A POR EL ARBITRO' : 'GET THE REF!',
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: es
            ? 'Ambos equipos reciben un Bribe gratuito para este partido.'
            : 'Each team immediately gains one free Bribe for this game.',
      ),
      WikiDiceBoardEntry(
        roll: '3',
        title: es ? 'TIEMPO MUERTO' : 'TIME-OUT',
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        color: const Color(0xFFFF7043),
        description: es
            ? 'El marcador de turno puede avanzar o retroceder un espacio, segun indique el evento.'
            : 'Turn markers may move forward or backward one space, depending on the event result.',
      ),
      WikiDiceBoardEntry(
        roll: '4',
        title: es ? 'DEFENSA SOLIDA' : 'SOLID DEFENCE',
        icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El equipo que patea puede recolocar a varios jugadores respetando las reglas de colocacion.'
            : 'The kicking team may reset a number of players while still following setup restrictions.',
      ),
      WikiDiceBoardEntry(
        roll: '5',
        title: es ? 'PATADA ALTA' : 'HIGH KICK',
        icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Un jugador libre del equipo receptor puede colocarse bajo el balon para intentar atraparlo.'
            : 'One open player on the receiving team may move under the ball to try to catch it.',
      ),
      WikiDiceBoardEntry(
        roll: '6',
        title: es ? 'AFICIONADOS ANIMANDO' : 'CHEERING FANS',
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        color: const Color(0xFFAB47BC),
        description: es
            ? 'Ambos entrenadores comparan su tirada y las animadoras. El ganador obtiene una ayuda en su siguiente accion de Placaje.'
            : 'Both coaches compare their roll plus cheerleaders. The winner gains a bonus for the next Block action.',
      ),
      WikiDiceBoardEntry(
        roll: '7',
        title: es ? 'ENTRENAMIENTO BRILLANTE' : 'BRILLIANT COACHING',
        icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description: es
            ? 'Ambos entrenadores comparan su tirada y asistentes. El ganador obtiene un Re-roll de equipo para esta entrada.'
            : 'Both coaches compare their roll plus assistant coaches. The winner gains a Team Re-roll for this drive.',
      ),
      WikiDiceBoardEntry(
        roll: '8',
        title: es ? 'TIEMPO CAMBIANTE' : 'CHANGING WEATHER',
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: es
            ? 'Vuelve a tirarse en la tabla de clima. Si sale Condiciones Perfectas, el balon se dispersa antes de aterrizar.'
            : 'Roll on the Weather table again. If Perfect Conditions is rolled, the ball scatters before landing.',
      ),
      WikiDiceBoardEntry(
        roll: '9',
        title: es ? 'CIERRE RAPIDO' : 'QUICK SNAP',
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        color: const Color(0xFF26A69A),
        description: es
            ? 'El equipo receptor puede mover varios jugadores una casilla antes de que caiga el balon.'
            : 'The receiving team may move several players one square before the ball lands.',
      ),
      WikiDiceBoardEntry(
        roll: '10',
        title: es ? 'CARGA' : 'CHARGE!',
        icon: PhosphorIcons.sword(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'El equipo que patea puede activar varios jugadores de inmediato para moverse, e incluso hacer un Blitz.'
            : 'The kicking team may immediately activate several players to move, and one of them may Blitz.',
      ),
      WikiDiceBoardEntry(
        roll: '11',
        title: es ? 'APERITIVO SOSPECHOSO' : 'DODGY SNACK',
        icon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
        color: const Color(0xFFFF8A65),
        description: es
            ? 'Un jugador aleatorio puede empezar la entrada debilitado o terminar en Reservas por el mal tentempie.'
            : 'A random player may begin the drive weakened or even end up in Reserves after a bad snack.',
      ),
      WikiDiceBoardEntry(
        roll: '12',
        title: es ? 'INVASION DE CAMPO' : 'PITCH INVASION',
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        color: const Color(0xFFE53935),
        description: es
            ? 'La aficion entra en el campo y varios jugadores pueden quedar Cuerpo a Tierra y Aturdidos.'
            : 'The crowd spills onto the pitch and several players may be Placed Prone and Stunned.',
      ),
    ];

    return WikiDiceBoard(
      headerIcon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
      title: tr(lang, 'wikiWeather.kickoff'),
      subtitle: es
          ? 'Despues del kickoff, se tiran 2D6 para determinar un evento especial.'
          : 'After the kick-off, roll 2D6 to determine a special event.',
      diceAssetPath: 'assets/images/dice/2D6.png',
      entries: events,
      descriptionBuilder: (context, entry, fontSize) => _buildRichDescription(
        entry.description,
        lang: lang,
        fontSize: fontSize,
      ),
    );
  }
}

/// Builds a [RichText] where glossary terms are highlighted and wrapped in
/// [Tooltip] widgets so users can tap/hover to see explanations.
Widget _buildRichDescription(
  String text, {
  required String lang,
  double fontSize = 13,
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

  // Build a regex that matches any glossary key (longest first).
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

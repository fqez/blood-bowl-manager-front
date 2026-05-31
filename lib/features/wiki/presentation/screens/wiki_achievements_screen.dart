import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl advancement terms.
Map<String, String> _glossary(String lang) {
  final es = lang == 'es';

  return <String, String>{
    'SPP': es
        ? 'Puntos de experiencia que los jugadores ganan por acciones destacadas.'
        : 'Experience points players earn for standout actions.',
    'Touchdown': es
        ? 'Anotacion: llevar el balon a la zona rival. Otorga 3 SPP.'
        : 'A score in the opponent end zone. Grants 3 SPP.',
    'Casualty': es
        ? 'Lesion grave causada a un rival. Otorga 2 SPP.'
        : 'A serious injury caused to an opponent. Grants 2 SPP.',
    'Completion': es
        ? 'Pase completado con exito. Otorga 1 SPP al lanzador.'
        : 'A successfully completed pass. Grants 1 SPP to the thrower.',
    'Interception': es
        ? 'Interceptar un pase rival. Otorga 2 SPP.'
        : 'Intercepting an opposing pass. Grants 2 SPP.',
    'MVP': es
        ? 'Jugador mas valioso. Un jugador aleatorio del equipo recibe 4 SPP al final del partido.'
        : 'Most Valuable Player. A random player on the team gains 4 SPP after the match.',
    'Primary': es
        ? 'Categoria primaria: mas facil y barata de mejorar.'
        : 'Primary category: easier and cheaper to improve.',
    'Secondary': es
        ? 'Categoria secundaria: mas costosa de mejorar.'
        : 'Secondary category: more expensive to improve.',
    'Random': es
        ? 'Mejora aleatoria: se decide tirando en una tabla.'
        : 'Random improvement: determined by rolling on a table.',
    'Chosen': es
        ? 'Mejora elegida libremente por el entrenador.'
        : 'Improvement freely chosen by the coach.',
    'TV': es
        ? 'Valor de Equipo: suma de jugadores, habilidades y extras.'
        : 'Team Value: the sum of players, skills, and extra costs.',
    'Niggling Injury': es
        ? 'Lesion persistente que empeora futuras Casualties.'
        : 'A lingering injury that worsens future Casualty results.',
  };
}

class WikiAchievementsScreen extends ConsumerWidget {
  const WikiAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return WikiPageLayout(
      title: tr(lang, 'wikiAchievements.title'),
      heroIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      subtitle: tr(lang, 'wikiAchievements.subtitle'),
      accentColor: const Color(0xFFD4AF37),
      gradientColor: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSppTable(lang),
          const SizedBox(height: 32),
          _buildAdvancementTable(lang),
          const SizedBox(height: 32),
          _buildImprovementOptions(lang),
          const SizedBox(height: 32),
          _buildSpecialRules(lang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── SPP Earning Table ───────────────────────────────────────────────────────

  Widget _buildSppTable(String lang) {
    final es = lang == 'es';
    final actions = [
      _SppAction(
        name: 'TOUCHDOWN',
        nameEs: es ? 'ANOTACION' : 'TOUCHDOWN',
        spp: '3',
        icon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description: es
            ? 'El jugador que lleva el balon a la zona rival recibe 3 SPP. Es la forma principal de ganar experiencia.'
            : 'The player who carries the ball into the opponent end zone gains 3 SPP. This is the main way to gain experience.',
      ),
      _SppAction(
        name: 'CASUALTY',
        nameEs: es ? 'BAJA' : 'CASUALTY',
        spp: '2',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'El jugador que causa una Casualty a un rival recibe 2 SPP.'
            : 'The player who causes a Casualty to an opponent gains 2 SPP.',
      ),
      _SppAction(
        name: 'INTERCEPTION',
        nameEs: es ? 'INTERCEPCION' : 'INTERCEPTION',
        spp: '2',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'El jugador que intercepta un pase rival con exito recibe 2 SPP.'
            : 'A player who successfully intercepts an opposing pass gains 2 SPP.',
      ),
      _SppAction(
        name: 'COMPLETION',
        nameEs: es ? 'PASE COMPLETADO' : 'COMPLETION',
        spp: '1',
        icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'El lanzador recibe 1 SPP cuando un companero atrapa con exito su pase.'
            : 'The thrower gains 1 SPP when a team-mate successfully catches the pass.',
      ),
      _SppAction(
        name: 'DEFLECTION',
        nameEs: es ? 'DEFLEXION' : 'DEFLECTION',
        spp: '1',
        icon: PhosphorIcons.arrowBendUpLeft(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description: es
            ? 'El jugador que desvia un pase rival recibe 1 SPP.'
            : 'A player who deflects an opposing pass gains 1 SPP.',
      ),
      _SppAction(
        name: 'MVP',
        nameEs: es ? 'MEJOR JUGADOR' : 'MVP',
        spp: '4',
        icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: es
            ? 'Al final del partido, un jugador aleatorio de cada equipo recibe 4 SPP como MVP.'
            : 'At the end of the match, one random player on each team gains 4 SPP as MVP.',
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
              Icon(PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiAchievements.sppTable'),
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
                ? 'Puntos de experiencia ganados por cada accion destacada durante un partido.'
                : 'Experience points gained for each standout action during a match.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...actions.map((a) => _buildSppRow(a, lang)),
        ],
      ),
    );
  }

  Widget _buildSppRow(_SppAction a, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [a.color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: a.color.withOpacity(0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          final badge = Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: a.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: a.color.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  a.spp,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: a.color,
                  ),
                ),
                Text(
                  'SPP',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: a.color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(a.icon, color: a.color, size: 18),
                  Text(
                    a.nameEs,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: a.color,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    a.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildRichDescription(a.description, lang: lang),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 14),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  // ── Advancement Table ───────────────────────────────────────────────────────

  Widget _buildAdvancementTable(String lang) {
    final es = lang == 'es';
    final levels = [
      _AdvancementLevel(
        spp: '0–5',
        title: es ? 'NOVATO' : 'ROOKIE',
        titleEn: es ? 'Rookie' : 'NOVATO',
        color: const Color(0xFF78909C),
        description: es
            ? 'El jugador es inexperto. No puede gastar SPP en mejoras.'
            : 'The player is inexperienced and cannot spend SPP on improvements yet.',
      ),
      _AdvancementLevel(
        spp: '6',
        title: es ? 'EXPERIMENTADO' : 'EXPERIENCED',
        titleEn: es ? 'Experienced' : 'EXPERIMENTADO',
        color: const Color(0xFF66BB6A),
        description: es
            ? 'Primera mejora disponible. Puede elegir habilidad primaria aleatoria o elegida.'
            : 'First improvement unlocked. The player may take a random or chosen Primary skill.',
      ),
      _AdvancementLevel(
        spp: '16',
        title: es ? 'VETERANO' : 'VETERAN',
        titleEn: es ? 'Veteran' : 'VETERANO',
        color: const Color(0xFF42A5F5),
        description: es
            ? 'Segunda mejora. Se desbloquea la habilidad secundaria aleatoria.'
            : 'Second improvement. Random Secondary skills are now unlocked.',
      ),
      _AdvancementLevel(
        spp: '31',
        title: es ? 'ESTRELLA EMERGENTE' : 'EMERGING STAR',
        titleEn: es ? 'Emerging Star' : 'ESTRELLA EMERGENTE',
        color: const Color(0xFFFFA726),
        description: es
            ? 'Tercera mejora. Se desbloquea la habilidad secundaria elegida.'
            : 'Third improvement. Chosen Secondary skills are now unlocked.',
      ),
      _AdvancementLevel(
        spp: '51',
        title: es ? 'ESTRELLA' : 'STAR',
        titleEn: es ? 'Star' : 'ESTRELLA',
        color: const Color(0xFFD4AF37),
        description: es
            ? 'Cuarta mejora. Se desbloquean las mejoras de caracteristica.'
            : 'Fourth improvement. Characteristic increases become available.',
      ),
      _AdvancementLevel(
        spp: '76',
        title: es ? 'SUPER ESTRELLA' : 'SUPER STAR',
        titleEn: es ? 'Super Star' : 'SUPER ESTRELLA',
        color: const Color(0xFFEF5350),
        description: es
            ? 'Quinta mejora. Acceso a todas las opciones disponibles.'
            : 'Fifth improvement. Full access to all available options.',
      ),
      _AdvancementLevel(
        spp: '176',
        title: es ? 'LEYENDA' : 'LEGEND',
        titleEn: es ? 'Legend' : 'LEYENDA',
        color: const Color(0xFF7E57C2),
        description: es
            ? 'Sexta y ultima mejora. El jugador ha alcanzado el maximo nivel de experiencia.'
            : 'Sixth and final improvement. The player has reached the highest experience tier.',
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
              Icon(PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiAchievements.advancementTable'),
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
                ? 'SPP necesarios para alcanzar cada nivel de experiencia y desbloquear mejoras.'
                : 'SPP needed to reach each experience tier and unlock improvements.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...levels.map((l) => _buildAdvancementRow(l, lang)),
        ],
      ),
    );
  }

  Widget _buildAdvancementRow(_AdvancementLevel level, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: level.color.withOpacity(0.15)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          final badge = Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: level.color.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Text(
                  level.spp,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: level.color,
                  ),
                ),
                Text(
                  'SPP',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: level.color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    level.title,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    level.titleEn,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              _buildRichDescription(level.description,
                  lang: lang, fontSize: 11),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 12), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(child: content)
            ],
          );
        },
      ),
    );
  }

  // ── Improvement Options ─────────────────────────────────────────────────────

  Widget _buildImprovementOptions(String lang) {
    final es = lang == 'es';
    final options = [
      _ImprovementOption(
        name: es ? 'HABILIDAD ALEATORIA PRIMARIA' : 'RANDOM PRIMARY SKILL',
        nameEn: es ? 'Random Primary Skill' : 'HABILIDAD ALEATORIA PRIMARIA',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        cost: '+10K TV',
        description: es
            ? 'Tira 1D6 en la tabla Primary. Es la opcion mas barata, pero no controlas el resultado.'
            : 'Roll 1D6 on the Primary table. It is the cheapest option, but you do not control the result.',
      ),
      _ImprovementOption(
        name: es ? 'HABILIDAD ELEGIDA PRIMARIA' : 'CHOSEN PRIMARY SKILL',
        nameEn: es ? 'Chosen Primary Skill' : 'HABILIDAD ELEGIDA PRIMARIA',
        icon: PhosphorIcons.check(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        cost: '+20K TV',
        description: es
            ? 'Elige cualquier habilidad Primary del jugador. Da control total sobre la mejora.'
            : 'Choose any of the player\'s Primary skills. This gives full control over the upgrade.',
      ),
      _ImprovementOption(
        name: es ? 'HABILIDAD ALEATORIA SECUNDARIA' : 'RANDOM SECONDARY SKILL',
        nameEn:
            es ? 'Random Secondary Skill' : 'HABILIDAD ALEATORIA SECUNDARIA',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        cost: '+20K TV',
        description: es
            ? 'Tira 1D6 en la tabla Secondary. Disponible desde nivel Veterano.'
            : 'Roll 1D6 on the Secondary table. Available from Veteran level onward.',
      ),
      _ImprovementOption(
        name: es ? 'HABILIDAD ELEGIDA SECUNDARIA' : 'CHOSEN SECONDARY SKILL',
        nameEn: es ? 'Chosen Secondary Skill' : 'HABILIDAD ELEGIDA SECUNDARIA',
        icon: PhosphorIcons.check(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        cost: '+40K TV',
        description: es
            ? 'Elige cualquier habilidad Secondary. Es mas cara, pero abre acceso fuera de categoria.'
            : 'Choose any Secondary skill. It costs more, but opens access beyond the usual category.',
      ),
      _ImprovementOption(
        name: es ? 'CARACTERISTICA ALEATORIA' : 'RANDOM CHARACTERISTIC',
        nameEn: es ? 'Random Characteristic' : 'CARACTERISTICA ALEATORIA',
        icon: PhosphorIcons.arrowUp(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        cost: '+10K TV',
        description: es
            ? 'Tira 1D6 para obtener una mejora de caracteristica aleatoria. Disponible desde nivel Estrella.'
            : 'Roll 1D6 to get a random Characteristic increase. Available from Star level onward.',
      ),
      _ImprovementOption(
        name: es ? 'CARACTERISTICA ELEGIDA' : 'CHOSEN CHARACTERISTIC',
        nameEn: es ? 'Chosen Characteristic' : 'CARACTERISTICA ELEGIDA',
        icon: PhosphorIcons.arrowFatUp(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        cost: 'Variable',
        description: es
            ? 'Elige directamente una caracteristica para mejorar. Disponible desde nivel Estrella.'
            : 'Choose directly which Characteristic to improve. Available from Star level onward.',
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
              Icon(PhosphorIcons.wrench(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                tr(lang, 'wikiAchievements.improvements'),
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
                ? 'Opciones disponibles al subir de nivel. Cada opcion incrementa el TV del jugador.'
                : 'Upgrade options available when leveling up. Each one increases the player\'s TV.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...options.map((o) => _buildImprovementRow(o, lang)),
        ],
      ),
    );
  }

  Widget _buildImprovementRow(_ImprovementOption o, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: o.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: o.color.withOpacity(0.15)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          final badge = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: o.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: o.color.withOpacity(0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(o.icon, color: o.color, size: 16),
                const SizedBox(height: 2),
                Text(
                  o.cost,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: o.color,
                  ),
                ),
              ],
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.name,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: o.color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                o.nameEn,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 3),
              _buildRichDescription(o.description, lang: lang, fontSize: 11),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 12), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(child: content)
            ],
          );
        },
      ),
    );
  }

  // ── Special Rules ───────────────────────────────────────────────────────────

  Widget _buildSpecialRules(String lang) {
    final es = lang == 'es';
    final rules = [
      _SpecialRule(
        name: es ? 'LIMITE DE MEJORAS' : 'IMPROVEMENT CAP',
        nameEn: es ? 'Improvement Cap' : 'LIMITE DE MEJORAS',
        icon: PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description: es
            ? 'Cada jugador puede tener un maximo de 6 mejoras.'
            : 'Each player may have a maximum of 6 improvements.',
      ),
      _SpecialRule(
        name: es ? 'LIMITE DE CARACTERISTICA' : 'CHARACTERISTIC LIMIT',
        nameEn: es ? 'Characteristic Limit' : 'LIMITE DE CARACTERISTICA',
        icon: PhosphorIcons.arrowsVertical(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: es
            ? 'Cada caracteristica solo puede mejorar hasta cierto limite sobre su valor base.'
            : 'Each Characteristic can only improve by a limited amount above its base value.',
      ),
      _SpecialRule(
        name: es ? 'INCREMENTO DE TV' : 'TV INCREASE',
        nameEn: es ? 'TV Increase' : 'INCREMENTO DE TV',
        icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: es
            ? 'Cada mejora incrementa el TV del jugador y del equipo.'
            : 'Each improvement increases both the player\'s and team\'s TV.',
      ),
      _SpecialRule(
        name: es ? 'MVP ALEATORIO' : 'RANDOM MVP',
        nameEn: es ? 'Random MVP' : 'MVP ALEATORIO',
        icon: PhosphorIcons.shuffle(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description: es
            ? 'El MVP se otorga a un jugador aleatorio al final del partido.'
            : 'MVP is awarded to a random player at the end of the match.',
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
                tr(lang, 'wikiAchievements.specialRules'),
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
                ? 'Reglas adicionales sobre experiencia y mejoras.'
                : 'Additional rules about experience and improvements.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...rules.map((r) => _buildSpecialRuleRow(r, lang)),
        ],
      ),
    );
  }

  Widget _buildSpecialRuleRow(_SpecialRule r, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: r.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: r.color.withOpacity(0.15)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          final badge = Container(
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
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
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
              _buildRichDescription(r.description, lang: lang, fontSize: 11),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 12), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(child: content)
            ],
          );
        },
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

class _SppAction {
  final String name;
  final String nameEs;
  final String spp;
  final IconData icon;
  final Color color;
  final String description;

  const _SppAction({
    required this.name,
    required this.nameEs,
    required this.spp,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _AdvancementLevel {
  final String spp;
  final String title;
  final String titleEn;
  final Color color;
  final String description;

  const _AdvancementLevel({
    required this.spp,
    required this.title,
    required this.titleEn,
    required this.color,
    required this.description,
  });
}

class _ImprovementOption {
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String cost;
  final String description;

  const _ImprovementOption({
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.cost,
    required this.description,
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

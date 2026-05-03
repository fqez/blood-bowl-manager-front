import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wiki_page_layout.dart';

// ignore_for_file: deprecated_member_use

/// Glossary of Blood Bowl advancement terms.
const _glossary = <String, String>{
  'SPP':
      'Star Player Points – puntos de experiencia que ganan los jugadores por acciones destacadas.',
  'Touchdown':
      'Anotación (TD): llevar el balón a la zona de anotación rival. Otorga 3 SPP.',
  'Casualty':
      'Baja: causar una Casualty a un rival (resultado 10+ en tabla de lesión). Otorga 2 SPP.',
  'Completion':
      'Pase completado: completar un pase exitoso que es atrapado. Otorga 1 SPP.',
  'Interception': 'Interceptar un pase rival. Otorga 2 SPP.',
  'MVP':
      'Most Valuable Player: al final del partido, un jugador aleatorio del equipo recibe 4 SPP.',
  'Primary':
      'Categoría de habilidades primaria del jugador. Se accede más fácilmente (más barato).',
  'Secondary':
      'Categoría de habilidades secundaria del jugador. Es más difícil y costoso acceder.',
  'Random':
      'Habilidad aleatoria: se tira en la tabla de habilidades del tipo elegido.',
  'Chosen':
      'Habilidad elegida: el entrenador escoge libremente qué habilidad adquirir.',
  'TV':
      'Team Value – Valor de Equipo. Suma del coste de todos los jugadores, habilidades, re-rolls, etc.',
  'Niggling Injury':
      'Lesión persistente: se acumulan y añaden +1 a futuras tiradas de Casualty.',
};

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
    final actions = [
      _SppAction(
        name: 'TOUCHDOWN',
        nameEs: 'ANOTACIÓN',
        spp: '3',
        icon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        description:
            'El jugador que lleva el balón a la zona de anotación rival '
            'recibe 3 SPP. Es la forma principal de ganar experiencia.',
      ),
      _SppAction(
        name: 'CASUALTY',
        nameEs: 'BAJA',
        spp: '2',
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'El jugador que causa una Casualty (10+ en la tabla de Lesión) '
            'a un rival recibe 2 SPP.',
      ),
      _SppAction(
        name: 'INTERCEPTION',
        nameEs: 'INTERCEPCIÓN',
        spp: '2',
        icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'El jugador que intercepta un pase rival con éxito recibe 2 SPP.',
      ),
      _SppAction(
        name: 'COMPLETION',
        nameEs: 'PASE COMPLETADO',
        spp: '1',
        icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description: 'El lanzador recibe 1 SPP cuando completa un pase que es '
            'atrapado con éxito por un compañero.',
      ),
      _SppAction(
        name: 'DEFLECTION',
        nameEs: 'DEFLEXIÓN',
        spp: '1',
        icon: PhosphorIcons.arrowBendUpLeft(PhosphorIconsStyle.fill),
        color: const Color(0xFF78909C),
        description:
            'El jugador que deflecta un pase rival (sin llegar a interceptarlo '
            'completamente) recibe 1 SPP.',
      ),
      _SppAction(
        name: 'MVP',
        nameEs: 'MEJOR JUGADOR',
        spp: '4',
        icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description:
            'Al final del partido, un jugador aleatorio de cada equipo '
            'recibe 4 SPP como MVP (Most Valuable Player). Se da incluso a '
            'jugadores que no participaron activamente.',
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
            'Puntos de experiencia (SPP) ganados por cada acción destacada durante un partido.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...actions.map((a) => _buildSppRow(a)),
        ],
      ),
    );
  }

  Widget _buildSppRow(_SppAction a) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(a.icon, color: a.color, size: 18),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
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
                _buildRichDescription(a.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Advancement Table ───────────────────────────────────────────────────────

  Widget _buildAdvancementTable(String lang) {
    final levels = [
      _AdvancementLevel(
        spp: '0–5',
        title: 'NOVATO',
        titleEn: 'Rookie',
        color: const Color(0xFF78909C),
        description: 'El jugador es inexperto. No puede gastar SPP en mejoras.',
      ),
      _AdvancementLevel(
        spp: '6',
        title: 'EXPERIMENTADO',
        titleEn: 'Experienced',
        color: const Color(0xFF66BB6A),
        description:
            'Primera mejora disponible. Puede elegir: habilidad aleatoria primaria '
            'o habilidad elegida primaria.',
      ),
      _AdvancementLevel(
        spp: '16',
        title: 'VETERANO',
        titleEn: 'Veteran',
        color: const Color(0xFF42A5F5),
        description:
            'Segunda mejora. Se desbloquea además: habilidad aleatoria secundaria.',
      ),
      _AdvancementLevel(
        spp: '31',
        title: 'ESTRELLA EMERGENTE',
        titleEn: 'Emerging Star',
        color: const Color(0xFFFFA726),
        description:
            'Tercera mejora. Se desbloquea además: habilidad elegida secundaria.',
      ),
      _AdvancementLevel(
        spp: '51',
        title: 'ESTRELLA',
        titleEn: 'Star',
        color: const Color(0xFFD4AF37),
        description:
            'Cuarta mejora. Se desbloquea además: mejora de característica (+1 MA, AG, PA, AV o ST).',
      ),
      _AdvancementLevel(
        spp: '76',
        title: 'SUPER ESTRELLA',
        titleEn: 'Super Star',
        color: const Color(0xFFEF5350),
        description:
            'Quinta mejora. Acceso a todas las opciones de mejora disponibles.',
      ),
      _AdvancementLevel(
        spp: '176',
        title: 'LEYENDA',
        titleEn: 'Legend',
        color: const Color(0xFF7E57C2),
        description:
            'Sexta y última mejora. El jugador ha alcanzado el máximo nivel de experiencia.',
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
            'SPP necesarios para alcanzar cada nivel de experiencia y desbloquear mejoras.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...levels.map((l) => _buildAdvancementRow(l)),
        ],
      ),
    );
  }

  Widget _buildAdvancementRow(_AdvancementLevel level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: level.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 8),
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
                _buildRichDescription(level.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Improvement Options ─────────────────────────────────────────────────────

  Widget _buildImprovementOptions(String lang) {
    final options = [
      _ImprovementOption(
        name: 'HABILIDAD ALEATORIA PRIMARIA',
        nameEn: 'Random Primary Skill',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFF66BB6A),
        cost: '+10K TV',
        description: 'Tira 1D6 en la tabla de habilidades Primary del jugador. '
            'Opción más barata pero sin control sobre el resultado.',
      ),
      _ImprovementOption(
        name: 'HABILIDAD ELEGIDA PRIMARIA',
        nameEn: 'Chosen Primary Skill',
        icon: PhosphorIcons.check(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        cost: '+20K TV',
        description:
            'Elige cualquier habilidad de las categorías Primary del jugador. '
            'Control total sobre la mejora.',
      ),
      _ImprovementOption(
        name: 'HABILIDAD ALEATORIA SECUNDARIA',
        nameEn: 'Random Secondary Skill',
        icon: PhosphorIcons.diceSix(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        cost: '+20K TV',
        description:
            'Tira 1D6 en la tabla de habilidades Secondary del jugador. '
            'Disponible desde nivel Veterano (16 SPP).',
      ),
      _ImprovementOption(
        name: 'HABILIDAD ELEGIDA SECUNDARIA',
        nameEn: 'Chosen Secondary Skill',
        icon: PhosphorIcons.check(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        cost: '+40K TV',
        description: 'Elige cualquier habilidad de las categorías Secondary. '
            'Opción más costosa pero da acceso a habilidades fuera de categoría.',
      ),
      _ImprovementOption(
        name: 'CARACTERÍSTICA ALEATORIA',
        nameEn: 'Random Characteristic',
        icon: PhosphorIcons.arrowUp(PhosphorIconsStyle.fill),
        color: const Color(0xFF7E57C2),
        cost: '+10K TV',
        description:
            'Tira 1D6: 1-2 = +1 MA, 3 = +1 PA, 4 = +1 AG, 5-6 = +1 AV. '
            'Disponible desde nivel Estrella (51 SPP).',
      ),
      _ImprovementOption(
        name: 'CARACTERÍSTICA ELEGIDA',
        nameEn: 'Chosen Characteristic',
        icon: PhosphorIcons.arrowFatUp(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        cost: 'Variable',
        description: 'Elige una característica: +1 MA (+20K), +1 PA (+20K), '
            '+1 AG (+40K), +1 AV (+10K), +1 ST (+80K). '
            'Disponible desde nivel Estrella (51 SPP).',
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
            'Opciones disponibles al subir de nivel. Cada opción incrementa el TV del jugador.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...options.map((o) => _buildImprovementRow(o)),
        ],
      ),
    );
  }

  Widget _buildImprovementRow(_ImprovementOption o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: o.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: o.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                _buildRichDescription(o.description, fontSize: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Special Rules ───────────────────────────────────────────────────────────

  Widget _buildSpecialRules(String lang) {
    final rules = [
      _SpecialRule(
        name: 'LÍMITE DE MEJORAS',
        nameEn: 'Improvement Cap',
        icon: PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
        color: const Color(0xFFEF5350),
        description:
            'Cada jugador puede tener un máximo de 6 mejoras (una por cada nivel, '
            'de Experienced a Legend). No se pueden acumular más.',
      ),
      _SpecialRule(
        name: 'LÍMITE DE CARACTERÍSTICA',
        nameEn: 'Characteristic Limit',
        icon: PhosphorIcons.arrowsVertical(PhosphorIconsStyle.fill),
        color: const Color(0xFFFFA726),
        description:
            'Cada característica solo puede mejorarse +2 sobre su valor base. '
            'Si un resultado aleatorio da una característica que ya está al máximo, '
            'se elige otra opción.',
      ),
      _SpecialRule(
        name: 'INCREMENTO DE TV',
        nameEn: 'TV Increase',
        icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
        color: const Color(0xFFD4AF37),
        description: 'Cada mejora incrementa el TV del jugador (y del equipo). '
            'Esto puede hacer que el oponente reciba más Petty Cash para Inducements.',
      ),
      _SpecialRule(
        name: 'MVP ALEATORIO',
        nameEn: 'Random MVP',
        icon: PhosphorIcons.shuffle(PhosphorIconsStyle.fill),
        color: const Color(0xFF42A5F5),
        description:
            'El MVP se otorga a un jugador aleatorio al final del partido. '
            'Puede ser cualquier jugador del roster, incluso uno que esté KO o lesionado.',
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
            'Reglas adicionales sobre experiencia y mejoras.',
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

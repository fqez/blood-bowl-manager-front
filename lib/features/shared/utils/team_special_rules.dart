import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../my_teams/domain/models/user_team.dart';

const chaosFavouredRosters = {'chaos_chosen', 'chaos_renegades'};

const chaosFavouredLabels = <String, String>{
  'chaos_undivided': 'Favoured of Chaos Undivided',
  'khorne': 'Favoured of Khorne',
  'nurgle': 'Favoured of Nurgle',
  'tzeentch': 'Favoured of Tzeentch',
  'slaanesh': 'Favoured of Slaanesh',
  'hashut': 'Favoured of Hashut',
};

const _favouredStarRequirements = <String, String>{
  'bilerot_vomitflesh': 'nurgle',
  'guffle_pusmaw': 'nurgle',
  'withergrasp_doubledrool': 'nurgle',
  'max_spleenripper': 'khorne',
  'scyla_anfingrimm': 'khorne',
  'hthark_the_unstoppable': 'hashut',
  'zzharg_madeye': 'hashut',
};

class _TeamSpecialRuleInfo {
  final List<String> aliases;
  final String descriptionEs;
  final String descriptionEn;

  const _TeamSpecialRuleInfo({
    required this.aliases,
    required this.descriptionEs,
    required this.descriptionEn,
  });
}

const _teamSpecialRuleInfos = <_TeamSpecialRuleInfo>[
  _TeamSpecialRuleInfo(
    aliases: [
      'brawlin brutes',
      'brutos peleones',
      'brutos de rina',
      'brutos de trifulca'
    ],
    descriptionEs:
        'Durante el Juego de Liga, un equipo con esta regla especial ganara Puntos de Estrellato (SPP) de forma ligeramente diferente. Los jugadores de este equipo ganaran 3 SPP por causar una Baja en lugar de los 2 habituales. Ademas, los jugadores de este equipo solo ganaran 2 SPP por anotar un Touchdown en lugar de los 3 habituales.',
    descriptionEn:
        'During League Play, a team with this special rule will earn SPP slightly differently. Players on this team will earn 3 SPP for causing a Casualty rather than the usual 2. Additionally, players on this team will only earn 2 SPP for scoring a Touchdown rather than the usual 3.',
  ),
  _TeamSpecialRuleInfo(
    aliases: [
      'bribery and corruption',
      'bribery corruption',
      'sobornos y corrupcion',
      'soborno y corrupcion'
    ],
    descriptionEs:
        'Una vez por partido, cuando un equipo con esta regla especial saque un 1 al Protestar la Decision, puede volver a lanzar el D6.',
    descriptionEn:
        'Once per game, when a team with this special rule rolls a 1 to Argue the Call, they may re-roll the D6.',
  ),
  _TeamSpecialRuleInfo(
    aliases: [
      'favoured of',
      'favoured of hashut',
      'favoured of khorne',
      'favoured of nurgle',
      'favoured of slaanesh',
      'favoured of tzeentch',
      'favoured of undivided',
      'favourito de',
      'favorito de',
      'favorecido por',
      'favourito de hashut',
      'favorito de hashut',
      'favorito de khorne',
      'favorito de nurgle',
      'favorito de slaanesh',
      'favorito de tzeentch',
      'favorito de indivisible',
      'favorecido por hashut',
      'favorecido por khorne',
      'favorecido por nurgle',
      'favorecido por slaanesh',
      'favorecido por tzeentch',
      'favorecido por indivisible',
    ],
    descriptionEs:
        'Al crear una Lista de Reclutamiento de Equipo, un equipo con esta regla especial que tenga una opcion debe elegir un alineamiento de las opciones dadas y no puede cambiarlo mas adelante. Si un equipo puede elegir cualquier alineamiento, puede elegir entre los siguientes: Hashut, Khorne, Nurgle, Slaanesh, Tzeentch, Indivisible.',
    descriptionEn:
        'When creating a Team Draft List, a team with this special rule that has a choice must choose an alignment from the options given and cannot change it later on. If a team has a choice of any alignment, they can choose any of the following: Hashut, Khorne, Nurgle, Slaanesh, Tzeentch, Undivided.',
  ),
  _TeamSpecialRuleInfo(
    aliases: ['low cost linemen', 'lineas de bajo coste'],
    descriptionEs:
        'En Juego de Liga, cuando un equipo con esta regla especial calcula su Valor de Equipo Actual, el Coste de Contratacion de cualquier jugador Linea del equipo se considera 0 piezas de oro. Cualquier aumento de valor se incluye de forma normal.',
    descriptionEn:
        'In League Play, when a team with this special rule calculates its Current Team Value, treat the Hiring Fee of any Lineman players on the team as 0 gold pieces. Any value increase is included as normal.',
  ),
  _TeamSpecialRuleInfo(
    aliases: ['masters of undeath', 'maestros de la no muerte'],
    descriptionEs:
        'Una vez por partido, si un jugador rival con Fuerza (ST) 4 o menos que no tenga el Rasgo Escurridizo sufre un resultado de Muerto al tirar en la Tabla de Bajas, un equipo con esta regla especial puede Alzar a los Muertos. Si lo hace, puede anadir inmediatamente un jugador Linea de su lista de equipo a su caja de Reservas.',
    descriptionEn:
        'Once per game, if an opposition player with an ST of 4 or less that does not have the Stunty Trait suffers a Dead result when rolling on the Casualty Table, a team with this special rule can Raise the Dead. If they do, they may immediately add a single Lineman player from their team\'s Team Roster to their Reserves Box.',
  ),
  _TeamSpecialRuleInfo(
    aliases: ['swarming', 'enjambre'],
    descriptionEs:
        'Durante la Secuencia de Inicio de la Entrada, despues de que ambos equipos hayan colocado a sus jugadores, un equipo con esta regla especial puede colocar un D3 adicional de jugadores Linea desde su caja de Reservas en el campo, siguiendo todas las reglas habituales de colocacion.',
    descriptionEn:
        'During the Start of Drive Sequence, after both teams have set up their players, a team with this special rule can set up an additional D3 Lineman players from their Reserves Box on the pitch, following all the usual rules for setting up players.',
  ),
  _TeamSpecialRuleInfo(
    aliases: ['team captain', 'capitan del equipo'],
    descriptionEs:
        'Puedes nombrar Capitan del Equipo a cualquier jugador de tu roster inicial, excepto un Tipo Grande. El Capitan del Equipo gana inmediatamente la habilidad Lider sin aumentar su coste. Ademas, mientras tu Capitan del Equipo este en el campo, cada vez que uses una Repeticion de Equipo puedes tirar un D6; con un 6 natural esa repeticion es gratis.',
    descriptionEn:
        'You may nominate any player on your starting roster, except a Big Guy, to be your Team Captain. A Team Captain immediately gains the Leader skill without increasing their cost. Additionally, while your Team Captain is on the pitch, whenever you use a Team Re-roll you may roll a D6; on a natural 6 the Team Re-roll is free.',
  ),
];

const _brawlinBrutesAliases = <String>[
  'brawlin brutes',
  'brutos peleones',
  'brutos de rina',
  'brutos de trifulca',
];

const _mastersOfUndeathAliases = <String>[
  'masters of undeath',
  'maestros de la no muerte',
];

String _normalizeSpecialRule(String value) {
  final lower = value
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ ]+'), ' ');

  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(replacements[char] ?? char);
  }

  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool hasBrawlinBrutesRule(Iterable<String> specialRules) {
  for (final rule in specialRules) {
    final normalizedRule = _normalizeSpecialRule(rule);
    for (final alias in _brawlinBrutesAliases) {
      if (normalizedRule.contains(alias)) return true;
    }
  }
  return false;
}

bool hasMastersOfUndeathRule(Iterable<String> specialRules) {
  for (final rule in specialRules) {
    final normalizedRule = _normalizeSpecialRule(rule);
    for (final alias in _mastersOfUndeathAliases) {
      if (normalizedRule.contains(alias)) return true;
    }
  }
  return false;
}

bool isLinemanMarker(Iterable<String?> values) {
  final normalized = values
      .whereType<String>()
      .map(_normalizeSpecialRule)
      .where((value) => value.isNotEmpty)
      .join(' ');
  return normalized.contains('lineman') || normalized.contains('linea');
}

int adjustedSppForSpecialRules({
  required Iterable<String> specialRules,
  required String eventType,
  required int defaultSpp,
}) {
  if (!hasBrawlinBrutesRule(specialRules)) return defaultSpp;
  switch (eventType) {
    case 'casualty':
      return 3;
    case 'touchdown':
      return 2;
    default:
      return defaultSpp;
  }
}

_TeamSpecialRuleInfo? _teamSpecialRuleInfo(String rule) {
  final normalizedRule = _normalizeSpecialRule(rule);
  for (final info in _teamSpecialRuleInfos) {
    for (final alias in info.aliases) {
      if (normalizedRule.contains(alias)) return info;
    }
  }
  return null;
}

Future<void> showTeamSpecialRuleDialog(
  BuildContext context, {
  required String rule,
  required String lang,
}) async {
  final info = _teamSpecialRuleInfo(rule);
  if (info == null) return;

  final description = lang == 'es' ? info.descriptionEs : info.descriptionEn;
  final closeLabel = lang == 'es' ? 'Cerrar' : 'Close';

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        rule,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          description,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            closeLabel,
            style: const TextStyle(color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
}

bool rosterCanChooseFavoured(String? rosterId) =>
    rosterId != null && chaosFavouredRosters.contains(rosterId);

String? favouredLabel(String? favouredOf) => chaosFavouredLabels[favouredOf];

String? starPlayerFavouredRequirement(Map<String, dynamic> starPlayer) {
  final starId =
      starPlayer['id'] as String? ?? starPlayer['_id'] as String? ?? '';
  return _favouredStarRequirements[starId];
}

bool starPlayerAvailableForRosterAnyFavoured(
  Map<String, dynamic> starPlayer, {
  required String rosterId,
}) {
  if (!rosterCanChooseFavoured(rosterId)) {
    return starPlayerAvailableForRoster(starPlayer, rosterId: rosterId);
  }

  return chaosFavouredLabels.keys.any(
    (favouredOf) => starPlayerAvailableForRoster(
      starPlayer,
      rosterId: rosterId,
      favouredOf: favouredOf,
    ),
  );
}

bool starPlayerAvailableForRoster(
  Map<String, dynamic> starPlayer, {
  required String rosterId,
  String? favouredOf,
}) {
  final playsFor =
      (starPlayer['plays_for'] as List<dynamic>? ?? []).map((e) => '$e');
  if (!playsFor.contains(rosterId)) return false;
  if (!rosterCanChooseFavoured(rosterId)) return true;

  final starId =
      starPlayer['id'] as String? ?? starPlayer['_id'] as String? ?? '';
  final requirement = _favouredStarRequirements[starId];
  if (requirement == null) return true;
  if (requirement == 'any') return chaosFavouredLabels.containsKey(favouredOf);
  return favouredOf == requirement;
}

bool starPlayerAvailableForUserTeam(
  Map<String, dynamic> starPlayer,
  UserTeamDetail team,
) =>
    starPlayerAvailableForRoster(
      starPlayer,
      rosterId: team.baseRosterId,
      favouredOf: team.favouredOf,
    );

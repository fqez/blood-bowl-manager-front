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
  'hakflem_skuttlespike': 'any',
  'bilerot_vomitflesh': 'nurgle',
  'guffle_pusmaw': 'nurgle',
  'withergrasp_doubledrool': 'nurgle',
  'max_spleenripper': 'khorne',
  'scyla_anfingrimm': 'khorne',
  'hthark_the_unstoppable': 'hashut',
  'zzharg_madeye': 'hashut',
};

bool rosterCanChooseFavoured(String? rosterId) =>
    rosterId != null && chaosFavouredRosters.contains(rosterId);

String? favouredLabel(String? favouredOf) => chaosFavouredLabels[favouredOf];

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

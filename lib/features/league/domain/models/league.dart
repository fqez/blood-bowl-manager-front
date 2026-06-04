import 'package:freezed_annotation/freezed_annotation.dart';

part 'league.freezed.dart';
part 'league.g.dart';

@freezed
class League with _$League {
  const League._();

  const factory League({
    required String id,
    required String name,
    required String ownerId,
    @Default('') String ownerUsername,
    @Default([]) List<String> commissionerIds,
    @Default([]) List<String> commissionerUsernames,
    @Default(false) bool isCommissioner,
    @Default(LeagueStatus.draft) LeagueStatus status,
    @Default(1) int season,
    int? currentRound,
    @Default(8) int maxTeams,
    @Default('round_robin') String format,
    String? inviteCode,
    @Default([]) List<LeagueTeam> teams,
    @Default([]) List<LeagueStanding> standings,
    @Default([]) List<Match> matches,
    LeagueRules? rules,
    String? description,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) = _League;

  factory League.fromJson(Map<String, dynamic> json) =>
      _$LeagueFromJson(_normalizeLeagueJson(json));

  int get teamsCount => teams.length;

  int get maxRounds {
    if (matches.isEmpty) return 0;
    return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  }
}

@freezed
class LeagueRules with _$LeagueRules {
  const factory LeagueRules({
    @Default(1000000) int startingBudget,
    @Default(false) bool resurrection,
    @Default(true) bool inducements,
    @Default(true) bool spiralingExpenses,
    int? maxTeamValue,
  }) = _LeagueRules;

  factory LeagueRules.fromJson(Map<String, dynamic> json) =>
      _$LeagueRulesFromJson(_normalizeLeagueRulesJson(json));
}

@freezed
class LeagueTeam with _$LeagueTeam {
  const LeagueTeam._();

  const factory LeagueTeam({
    required String teamId,
    required String teamName,
    required String userId,
    @Default('') String username,
    @Default('') String baseRosterId,
    String? icon,
    DateTime? joinedAt,
  }) = _LeagueTeam;

  factory LeagueTeam.fromJson(Map<String, dynamic> json) =>
      _$LeagueTeamFromJson(_normalizeLeagueTeamJson(json));
}

@freezed
class LeagueStanding with _$LeagueStanding {
  const LeagueStanding._();

  const factory LeagueStanding({
    required String teamId,
    required String teamName,
    @Default(0) int wins,
    @Default(0) int draws,
    @Default(0) int losses,
    @Default(0) int points,
    @Default(0) int touchdownsFor,
    @Default(0) int touchdownsAgainst,
    @Default(0) int touchdownDiff,
    @Default(0) int casualtiesFor,
    @Default(0) int casualtiesAgainst,
    @Default(0) int gamesPlayed,
  }) = _LeagueStanding;

  factory LeagueStanding.fromJson(Map<String, dynamic> json) =>
      _$LeagueStandingFromJson(_normalizeLeagueStandingJson(json));
}

enum LeagueStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('finished')
  finished,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@freezed
class Match with _$Match {
  const Match._();

  const factory Match({
    required String id,
    required int round,
    required MatchTeamInfo home,
    required MatchTeamInfo away,
    @Default('scheduled') String status,
    @Default(0) int scoreHome,
    @Default(0) int scoreAway,
    String? weather,
    String? kickoffEvent,
    @Default(false) bool homeReady,
    @Default(false) bool awayReady,
    @Default([]) List<String> homeSquad,
    @Default([]) List<String> awaySquad,
    @Default(0) int currentHalf,
    @Default(0) int currentTurn,
    @Default('home') String currentTeam,
    @Default(1) int homeTurn,
    @Default(1) int awayTurn,
    DateTime? turnStartedAt,
    @Default([]) List<int> homeTurnSeconds,
    @Default([]) List<int> awayTurnSeconds,
    @Default(0) int rerollsUsedHome,
    @Default(0) int rerollsUsedAway,
    @Default({}) Map<String, int> homeInducementPurchases,
    @Default({}) Map<String, int> awayInducementPurchases,
    @Default({}) Map<String, int> homeInducementUses,
    @Default({}) Map<String, int> awayInducementUses,
    @Default({}) Map<String, List<String>> homeInducementDetails,
    @Default({}) Map<String, List<String>> awayInducementDetails,
    String? mvpHome,
    String? mvpAway,
    int? gate,
    DateTime? aftermatchSppAppliedAt,
    DateTime? aftermatchWinningsAppliedAt,
    @Default({}) Map<String, dynamic> aftermatchHomeReport,
    @Default({}) Map<String, dynamic> aftermatchAwayReport,
    DateTime? aftermatchHomeSubmittedAt,
    DateTime? aftermatchAwaySubmittedAt,
    @Default([]) List<MatchEvent> events,
    DateTime? scheduledAt,
    DateTime? playedAt,
    DateTime? startedAt,
  }) = _Match;

  factory Match.fromJson(Map<String, dynamic> json) =>
      _$MatchFromJson(_normalizeMatchJson(json));

  bool get isPlayed => status == 'completed';
  bool get isPending => status == 'scheduled' || status == 'pending';
  bool get isInProgress => status == 'in_progress';
  String get scoreDisplay =>
      isPlayed || isInProgress ? '$scoreHome - $scoreAway' : '? - ?';
}

@freezed
class MatchEvent with _$MatchEvent {
  const factory MatchEvent({
    required String id,
    required String type,
    required String team,
    String? playerId,
    String? playerName,
    String? victimId,
    String? victimName,
    String? injury,
    String? detail,
    @Default(0) int half,
    @Default(0) int turn,
    DateTime? timestamp,
    String? createdBy,
    String? createdByName,
  }) = _MatchEvent;

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(_normalizeMatchEventJson(json));
}

@freezed
class MatchTeamInfo with _$MatchTeamInfo {
  const factory MatchTeamInfo({
    required String teamId,
    required String teamName,
    @Default('') String userId,
    @Default('') String username,
    @Default('') String baseRosterId,
  }) = _MatchTeamInfo;

  factory MatchTeamInfo.fromJson(Map<String, dynamic> json) =>
      _$MatchTeamInfoFromJson(_normalizeMatchTeamInfoJson(json));
}

enum MatchStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
}

@freezed
class LeagueInvitation with _$LeagueInvitation {
  const factory LeagueInvitation({
    required String id,
    required String leagueId,
    required String leagueName,
    required String invitedBy,
    DateTime? createdAt,
  }) = _LeagueInvitation;

  factory LeagueInvitation.fromJson(Map<String, dynamic> json) =>
      _$LeagueInvitationFromJson(_normalizeLeagueInvitationJson(json));
}

@freezed
class LeagueActivity with _$LeagueActivity {
  const factory LeagueActivity({
    required String id,
    required String type,
    required String message,
    required DateTime createdAt,
    Map<String, dynamic>? data,
  }) = _LeagueActivity;

  factory LeagueActivity.fromJson(Map<String, dynamic> json) =>
      _$LeagueActivityFromJson(_normalizeLeagueActivityJson(json));
}

Map<String, dynamic> _normalizeLeagueJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'ownerId': ['owner_id'],
      'ownerUsername': ['owner_username'],
      'commissionerIds': ['commissioner_ids'],
      'commissionerUsernames': ['commissioner_usernames'],
      'isCommissioner': ['is_commissioner'],
      'currentRound': ['current_round'],
      'maxTeams': ['max_teams'],
      'inviteCode': ['invite_code'],
      'createdAt': ['created_at'],
      'startedAt': ['started_at'],
      'endedAt': ['ended_at'],
    });

Map<String, dynamic> _normalizeLeagueRulesJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'startingBudget': ['starting_budget'],
      'spiralingExpenses': ['spiraling_expenses'],
      'maxTeamValue': ['max_team_value'],
    });

Map<String, dynamic> _normalizeLeagueTeamJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'teamId': ['team_id'],
      'teamName': ['team_name'],
      'userId': ['user_id'],
      'baseRosterId': ['base_roster_id'],
      'joinedAt': ['joined_at'],
    });

Map<String, dynamic> _normalizeLeagueStandingJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'teamId': ['team_id'],
      'teamName': ['team_name'],
      'touchdownsFor': ['touchdowns_for'],
      'touchdownsAgainst': ['touchdowns_against'],
      'touchdownDiff': ['touchdown_diff'],
      'casualtiesFor': ['casualties_for'],
      'casualtiesAgainst': ['casualties_against'],
      'gamesPlayed': ['games_played'],
    });

Map<String, dynamic> _normalizeMatchJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'scoreHome': ['score_home'],
      'scoreAway': ['score_away'],
      'kickoffEvent': ['kickoff_event'],
      'homeReady': ['home_ready'],
      'awayReady': ['away_ready'],
      'homeSquad': ['home_squad'],
      'awaySquad': ['away_squad'],
      'currentHalf': ['current_half'],
      'currentTurn': ['current_turn'],
      'currentTeam': ['current_team'],
      'homeTurn': ['home_turn'],
      'awayTurn': ['away_turn'],
      'turnStartedAt': ['turn_started_at'],
      'homeTurnSeconds': ['home_turn_seconds'],
      'awayTurnSeconds': ['away_turn_seconds'],
      'rerollsUsedHome': ['rerolls_used_home'],
      'rerollsUsedAway': ['rerolls_used_away'],
      'homeInducementPurchases': ['home_inducement_purchases'],
      'awayInducementPurchases': ['away_inducement_purchases'],
      'homeInducementUses': ['home_inducement_uses'],
      'awayInducementUses': ['away_inducement_uses'],
      'homeInducementDetails': ['home_inducement_details'],
      'awayInducementDetails': ['away_inducement_details'],
      'mvpHome': ['mvp_home'],
      'mvpAway': ['mvp_away'],
      'aftermatchSppAppliedAt': ['aftermatch_spp_applied_at'],
      'aftermatchWinningsAppliedAt': ['aftermatch_winnings_applied_at'],
      'aftermatchHomeReport': ['aftermatch_home_report'],
      'aftermatchAwayReport': ['aftermatch_away_report'],
      'aftermatchHomeSubmittedAt': ['aftermatch_home_submitted_at'],
      'aftermatchAwaySubmittedAt': ['aftermatch_away_submitted_at'],
      'scheduledAt': ['scheduled_at'],
      'playedAt': ['played_at'],
      'startedAt': ['started_at'],
    });

Map<String, dynamic> _normalizeMatchEventJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'playerId': ['player_id'],
      'playerName': ['player_name'],
      'victimId': ['victim_id'],
      'victimName': ['victim_name'],
      'createdBy': ['created_by'],
      'createdByName': ['created_by_name'],
    });

Map<String, dynamic> _normalizeMatchTeamInfoJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'teamId': ['team_id'],
      'teamName': ['team_name'],
      'userId': ['user_id'],
      'baseRosterId': ['base_roster_id'],
    });

Map<String, dynamic> _normalizeLeagueInvitationJson(
        Map<String, dynamic> json) =>
    _withAliases(json, {
      'leagueId': ['league_id'],
      'leagueName': ['league_name'],
      'invitedBy': ['invited_by'],
      'createdAt': ['created_at'],
    });

Map<String, dynamic> _normalizeLeagueActivityJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'createdAt': ['created_at'],
    });

Map<String, dynamic> _withAliases(
  Map<String, dynamic> json,
  Map<String, List<String>> aliases,
) {
  final normalized = {...json};
  for (final MapEntry(:key, :value) in aliases.entries) {
    normalized[key] ??= _firstValue(json, value);
  }
  return normalized;
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

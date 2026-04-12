import 'package:freezed_annotation/freezed_annotation.dart';

part 'league.freezed.dart';
part 'league.g.dart';

@freezed
class League with _$League {
  const League._();

  const factory League({
    required String id,
    required String name,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'owner_username') @Default('') String ownerUsername,
    @Default(LeagueStatus.draft) LeagueStatus status,
    @Default(1) int season,
    @JsonKey(name: 'current_round') int? currentRound,
    @JsonKey(name: 'max_teams') @Default(8) int maxTeams,
    @Default('round_robin') String format,
    @JsonKey(name: 'invite_code') String? inviteCode,
    @Default([]) List<LeagueTeam> teams,
    @Default([]) List<LeagueStanding> standings,
    @Default([]) List<Match> matches,
    LeagueRules? rules,
    String? description,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
  }) = _League;

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);

  int get teamsCount => teams.length;

  int get maxRounds {
    if (matches.isEmpty) return 0;
    return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  }
}

@freezed
class LeagueRules with _$LeagueRules {
  const factory LeagueRules({
    @JsonKey(name: 'starting_budget') @Default(1000000) int startingBudget,
    @Default(false) bool resurrection,
    @Default(true) bool inducements,
    @JsonKey(name: 'spiraling_expenses') @Default(true) bool spiralingExpenses,
    @JsonKey(name: 'max_team_value') int? maxTeamValue,
  }) = _LeagueRules;

  factory LeagueRules.fromJson(Map<String, dynamic> json) => _$LeagueRulesFromJson(json);
}

@freezed
class LeagueTeam with _$LeagueTeam {
  const LeagueTeam._();

  const factory LeagueTeam({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'user_id') required String userId,
    @Default('') String username,
    @JsonKey(name: 'base_roster_id') @Default('') String baseRosterId,
    String? icon,
    @JsonKey(name: 'joined_at') DateTime? joinedAt,
  }) = _LeagueTeam;

  factory LeagueTeam.fromJson(Map<String, dynamic> json) => _$LeagueTeamFromJson(json);
}

@freezed
class LeagueStanding with _$LeagueStanding {
  const LeagueStanding._();

  const factory LeagueStanding({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @Default(0) int wins,
    @Default(0) int draws,
    @Default(0) int losses,
    @Default(0) int points,
    @JsonKey(name: 'touchdowns_for') @Default(0) int touchdownsFor,
    @JsonKey(name: 'touchdowns_against') @Default(0) int touchdownsAgainst,
    @JsonKey(name: 'touchdown_diff') @Default(0) int touchdownDiff,
    @JsonKey(name: 'casualties_for') @Default(0) int casualtiesFor,
    @JsonKey(name: 'casualties_against') @Default(0) int casualtiesAgainst,
    @JsonKey(name: 'games_played') @Default(0) int gamesPlayed,
  }) = _LeagueStanding;

  factory LeagueStanding.fromJson(Map<String, dynamic> json) => _$LeagueStandingFromJson(json);
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
    @JsonKey(name: 'score_home') @Default(0) int scoreHome,
    @JsonKey(name: 'score_away') @Default(0) int scoreAway,
    @JsonKey(name: 'scheduled_at') DateTime? scheduledAt,
    @JsonKey(name: 'played_at') DateTime? playedAt,
  }) = _Match;

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  bool get isPlayed => status == 'completed';
  bool get isPending => status == 'scheduled' || status == 'pending';
  String get scoreDisplay => isPlayed ? '$scoreHome - $scoreAway' : '? - ?';
}

@freezed
class MatchTeamInfo with _$MatchTeamInfo {
  const factory MatchTeamInfo({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @Default('') String username,
  }) = _MatchTeamInfo;

  factory MatchTeamInfo.fromJson(Map<String, dynamic> json) => _$MatchTeamInfoFromJson(json);
}

enum MatchStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
}

@freezed
class LeagueInvitation with _$LeagueInvitation {
  const factory LeagueInvitation({
    required String id,
    @JsonKey(name: 'league_id') required String leagueId,
    @JsonKey(name: 'league_name') required String leagueName,
    @JsonKey(name: 'invited_by') required String invitedBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _LeagueInvitation;

  factory LeagueInvitation.fromJson(Map<String, dynamic> json) => _$LeagueInvitationFromJson(json);
}

@freezed
class LeagueActivity with _$LeagueActivity {
  const factory LeagueActivity({
    required String id,
    required String type,
    required String message,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    Map<String, dynamic>? data,
  }) = _LeagueActivity;

  factory LeagueActivity.fromJson(Map<String, dynamic> json) => _$LeagueActivityFromJson(json);
}

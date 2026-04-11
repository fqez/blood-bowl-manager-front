import 'package:freezed_annotation/freezed_annotation.dart';

part 'league.freezed.dart';
part 'league.g.dart';

@freezed
class League with _$League {
  const League._();

  const factory League({
    required String id,
    required String name,
    @JsonKey(name: 'commissioner_id') required String commissionerId,
    @Default(LeagueStatus.active) LeagueStatus status,
    @JsonKey(name: 'current_season') @Default(1) int currentSeason,
    @JsonKey(name: 'current_round') @Default(1) int currentRound,
    @JsonKey(name: 'max_rounds') @Default(12) int maxRounds,
    @JsonKey(name: 'starting_budget') @Default(1000000) int startingBudget,
    @Default([]) List<LeagueTeam> teams,
    String? description,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _League;

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);

  int get teamsCount => teams.length;
  bool get canStartNewRound => teams.every((t) => t.matchesPlayedThisRound >= 1);
}

@freezed
class LeagueTeam with _$LeagueTeam {
  const LeagueTeam._();

  const factory LeagueTeam({
    required String id,
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'coach_name') required String coachName,
    @JsonKey(name: 'base_team_name') required String baseTeamName,
    @JsonKey(name: 'team_value') @Default(0) int teamValue,
    @Default(0) int wins,
    @Default(0) int draws,
    @Default(0) int losses,
    @JsonKey(name: 'touchdowns_for') @Default(0) int touchdownsFor,
    @JsonKey(name: 'touchdowns_against') @Default(0) int touchdownsAgainst,
    @JsonKey(name: 'casualties_for') @Default(0) int casualtiesFor,
    @JsonKey(name: 'casualties_against') @Default(0) int casualtiesAgainst,
    @JsonKey(name: 'matches_played_this_round') @Default(0) int matchesPlayedThisRound,
  }) = _LeagueTeam;

  factory LeagueTeam.fromJson(Map<String, dynamic> json) => _$LeagueTeamFromJson(json);

  int get points => wins * 3 + draws;
  int get gamesPlayed => wins + draws + losses;
  int get touchdownDifference => touchdownsFor - touchdownsAgainst;
}

enum LeagueStatus {
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('finished')
  finished,
}

@freezed
class Match with _$Match {
  const Match._();

  const factory Match({
    required String id,
    @JsonKey(name: 'league_id') required String leagueId,
    required int round,
    @JsonKey(name: 'home_team_id') required String homeTeamId,
    @JsonKey(name: 'home_team_name') required String homeTeamName,
    @JsonKey(name: 'away_team_id') required String awayTeamId,
    @JsonKey(name: 'away_team_name') required String awayTeamName,
    @JsonKey(name: 'home_score') int? homeScore,
    @JsonKey(name: 'away_score') int? awayScore,
    @Default(MatchStatus.scheduled) MatchStatus status,
    @JsonKey(name: 'played_at') DateTime? playedAt,
    @JsonKey(name: 'validated_by_home') @Default(false) bool validatedByHome,
    @JsonKey(name: 'validated_by_away') @Default(false) bool validatedByAway,
  }) = _Match;

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  bool get isPlayed => status == MatchStatus.played || status == MatchStatus.validated;
  bool get isPending => status == MatchStatus.scheduled || status == MatchStatus.pendingValidation;
  String get scoreDisplay => isPlayed ? '$homeScore - $awayScore' : '? - ?';
}

enum MatchStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('pending_validation')
  pendingValidation,
  @JsonValue('played')
  played,
  @JsonValue('validated')
  validated,
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

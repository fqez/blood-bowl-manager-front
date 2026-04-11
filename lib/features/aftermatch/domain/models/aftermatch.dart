import 'package:freezed_annotation/freezed_annotation.dart';

part 'aftermatch.freezed.dart';
part 'aftermatch.g.dart';

@freezed
class AftermatchData with _$AftermatchData {
  const AftermatchData._();

  const factory AftermatchData({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'home_team_id') required String homeTeamId,
    @JsonKey(name: 'away_team_id') required String awayTeamId,
    @JsonKey(name: 'home_score') @Default(0) int homeScore,
    @JsonKey(name: 'away_score') @Default(0) int awayScore,
    @JsonKey(name: 'home_touchdowns') @Default([]) List<TouchdownRecord> homeTouchdowns,
    @JsonKey(name: 'away_touchdowns') @Default([]) List<TouchdownRecord> awayTouchdowns,
    @JsonKey(name: 'home_injuries') @Default([]) List<InjuryRecord> homeInjuries,
    @JsonKey(name: 'away_injuries') @Default([]) List<InjuryRecord> awayInjuries,
    @JsonKey(name: 'home_spp') @Default([]) List<SppRecord> homeSpp,
    @JsonKey(name: 'away_spp') @Default([]) List<SppRecord> awaySpp,
    @JsonKey(name: 'home_mvp_id') String? homeMvpId,
    @JsonKey(name: 'away_mvp_id') String? awayMvpId,
    @JsonKey(name: 'home_winnings') @Default(0) int homeWinnings,
    @JsonKey(name: 'away_winnings') @Default(0) int awayWinnings,
    @JsonKey(name: 'fan_factor_roll') int? fanFactorRoll,
  }) = _AftermatchData;

  factory AftermatchData.fromJson(Map<String, dynamic> json) => _$AftermatchDataFromJson(json);

  int get totalHomeTouchdowns => homeTouchdowns.fold(0, (sum, t) => sum + t.count);
  int get totalAwayTouchdowns => awayTouchdowns.fold(0, (sum, t) => sum + t.count);

  bool get scoresMatch =>
      totalHomeTouchdowns == homeScore &&
      totalAwayTouchdowns == awayScore;
}

@freezed
class TouchdownRecord with _$TouchdownRecord {
  const factory TouchdownRecord({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'player_name') required String playerName,
    @JsonKey(name: 'is_home_team') @Default(true) bool isHomeTeam,
    @Default(1) int count,
  }) = _TouchdownRecord;

  factory TouchdownRecord.fromJson(Map<String, dynamic> json) => _$TouchdownRecordFromJson(json);
}

@freezed
class InjuryRecord with _$InjuryRecord {
  const factory InjuryRecord({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'player_name') required String playerName,
    required InjuryType type,
    String? details,
    @JsonKey(name: 'stat_decrease') String? statDecrease,
  }) = _InjuryRecord;

  factory InjuryRecord.fromJson(Map<String, dynamic> json) => _$InjuryRecordFromJson(json);
}

enum InjuryType {
  @JsonValue('badly_hurt')
  badlyHurt,
  @JsonValue('miss_next_game')
  missNextGame,
  @JsonValue('niggling_injury')
  nigglingInjury,
  @JsonValue('stat_decrease')
  statDecrease,
  @JsonValue('dead')
  dead,
}

@freezed
class SppRecord with _$SppRecord {
  const SppRecord._();

  const factory SppRecord({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'player_name') required String playerName,
    @Default(0) int completions,
    @Default(0) int touchdowns,
    @Default(0) int casualties,
    @Default(0) int interceptions,
    @Default(false) bool mvp,
    @Default(0) int bonus,
  }) = _SppRecord;

  factory SppRecord.fromJson(Map<String, dynamic> json) => _$SppRecordFromJson(json);

  int get totalSpp {
    return (completions * 1) +
           (touchdowns * 3) +
           (casualties * 2) +
           (interceptions * 2) +
           (mvp ? 4 : 0) +
           bonus;
  }
}

@freezed
class MatchValidation with _$MatchValidation {
  const MatchValidation._();

  const factory MatchValidation({
    @JsonKey(name: 'touchdowns_match') @Default(false) bool touchdownsMatch,
    @JsonKey(name: 'mvp_assigned') @Default(false) bool mvpAssigned,
    @JsonKey(name: 'opponent_winnings_set') @Default(false) bool opponentWinningsSet,
    @Default([]) List<String> warnings,
    @Default([]) List<String> errors,
  }) = _MatchValidation;

  factory MatchValidation.fromJson(Map<String, dynamic> json) => _$MatchValidationFromJson(json);

  bool get isValid => touchdownsMatch && mvpAssigned && errors.isEmpty;
}

// Simple class for tracking individual bonus SPP entries in the UI
class BonusSppRecord {
  final String playerId;
  final String playerName;
  final int amount;
  final String reason;

  const BonusSppRecord({
    required this.playerId,
    required this.playerName,
    required this.amount,
    required this.reason,
  });
}

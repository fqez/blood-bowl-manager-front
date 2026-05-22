import 'package:freezed_annotation/freezed_annotation.dart';

part 'aftermatch.freezed.dart';
part 'aftermatch.g.dart';

@freezed
class AftermatchData with _$AftermatchData {
  const AftermatchData._();

  const factory AftermatchData({
    required String matchId,
    required String homeTeamId,
    required String awayTeamId,
    @Default(0) int homeScore,
    @Default(0) int awayScore,
    @Default([]) List<TouchdownRecord> homeTouchdowns,
    @Default([]) List<TouchdownRecord> awayTouchdowns,
    @Default([]) List<InjuryRecord> homeInjuries,
    @Default([]) List<InjuryRecord> awayInjuries,
    @Default([]) List<SppRecord> homeSpp,
    @Default([]) List<SppRecord> awaySpp,
    String? homeMvpId,
    String? awayMvpId,
    @Default(0) int homeWinnings,
    @Default(0) int awayWinnings,
    int? fanFactorRoll,
  }) = _AftermatchData;

  factory AftermatchData.fromJson(Map<String, dynamic> json) =>
      _$AftermatchDataFromJson(_normalizeAftermatchDataJson(json));

  int get totalHomeTouchdowns =>
      homeTouchdowns.fold(0, (sum, t) => sum + t.count);
  int get totalAwayTouchdowns =>
      awayTouchdowns.fold(0, (sum, t) => sum + t.count);

  bool get scoresMatch =>
      totalHomeTouchdowns == homeScore && totalAwayTouchdowns == awayScore;
}

@freezed
class TouchdownRecord with _$TouchdownRecord {
  const factory TouchdownRecord({
    required String playerId,
    required String playerName,
    @Default(true) bool isHomeTeam,
    @Default(1) int count,
  }) = _TouchdownRecord;

  factory TouchdownRecord.fromJson(Map<String, dynamic> json) =>
      _$TouchdownRecordFromJson(_normalizeTouchdownRecordJson(json));
}

@freezed
class InjuryRecord with _$InjuryRecord {
  const factory InjuryRecord({
    required String playerId,
    required String playerName,
    required InjuryType type,
    String? details,
    String? statDecrease,
  }) = _InjuryRecord;

  factory InjuryRecord.fromJson(Map<String, dynamic> json) =>
      _$InjuryRecordFromJson(_normalizeInjuryRecordJson(json));
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
    required String playerId,
    required String playerName,
    @Default(0) int completions,
    @Default(0) int touchdowns,
    @Default(0) int casualties,
    @Default(0) int interceptions,
    @Default(false) bool mvp,
    @Default(0) int bonus,
  }) = _SppRecord;

  factory SppRecord.fromJson(Map<String, dynamic> json) =>
      _$SppRecordFromJson(_normalizeSppRecordJson(json));

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
    @Default(false) bool touchdownsMatch,
    @Default(false) bool mvpAssigned,
    @Default(false) bool opponentWinningsSet,
    @Default([]) List<String> warnings,
    @Default([]) List<String> errors,
  }) = _MatchValidation;

  factory MatchValidation.fromJson(Map<String, dynamic> json) =>
      _$MatchValidationFromJson(_normalizeMatchValidationJson(json));

  bool get isValid => touchdownsMatch && mvpAssigned && errors.isEmpty;
}

Map<String, dynamic> _normalizeAftermatchDataJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'matchId': ['match_id'],
      'homeTeamId': ['home_team_id'],
      'awayTeamId': ['away_team_id'],
      'homeScore': ['home_score'],
      'awayScore': ['away_score'],
      'homeTouchdowns': ['home_touchdowns'],
      'awayTouchdowns': ['away_touchdowns'],
      'homeInjuries': ['home_injuries'],
      'awayInjuries': ['away_injuries'],
      'homeSpp': ['home_spp'],
      'awaySpp': ['away_spp'],
      'homeMvpId': ['home_mvp_id'],
      'awayMvpId': ['away_mvp_id'],
      'homeWinnings': ['home_winnings'],
      'awayWinnings': ['away_winnings'],
      'fanFactorRoll': ['fan_factor_roll'],
    });

Map<String, dynamic> _normalizeTouchdownRecordJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'playerId': ['player_id'],
      'playerName': ['player_name'],
      'isHomeTeam': ['is_home_team'],
    });

Map<String, dynamic> _normalizeInjuryRecordJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'playerId': ['player_id'],
      'playerName': ['player_name'],
      'statDecrease': ['stat_decrease'],
    });

Map<String, dynamic> _normalizeSppRecordJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'playerId': ['player_id'],
      'playerName': ['player_name'],
    });

Map<String, dynamic> _normalizeMatchValidationJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'touchdownsMatch': ['touchdowns_match'],
      'mvpAssigned': ['mvp_assigned'],
      'opponentWinningsSet': ['opponent_winnings_set'],
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

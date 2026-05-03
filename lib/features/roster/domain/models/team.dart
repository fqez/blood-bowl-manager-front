import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
class Team with _$Team {
  const Team._();

  const factory Team({
    required String id,
    required String name,
    required String baseTeamId,
    @Default('') String baseTeamName,
    required String ownerId,
    @Default(1000000) int treasury,
    @Default(0) int teamValue,
    @Default(0) int currentTeamValue,
    @Default(0) int rerolls,
    @Default(0) int rerollCost,
    @Default(0) int fanFactor,
    @Default(0) int assistantCoaches,
    @Default(0) int cheerleaders,
    @Default(false) bool apothecary,
    @Default([]) List<Character> characters,
    String? primaryColor,
    String? secondaryColor,
    DateTime? createdAt,
    String? leagueId,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) =>
      _$TeamFromJson(_normalizeTeamJson(json));

  int get activePlayersCount =>
      characters.where((c) => c.status == PlayerStatus.healthy).length;
  int get injuredPlayersCount =>
      characters.where((c) => c.status == PlayerStatus.injured).length;
  bool get isValidRoster => activePlayersCount >= 11;
}

@freezed
class Character with _$Character {
  const Character._();

  const factory Character({
    required String id,
    required String name,
    @Default('') String position,
    @Default('') String positionId,
    @Default(0) int number,
    required Stats stats,
    @Default([]) List<Skill> skills,
    @Default(0) int spp,
    @Default(1) int level,
    @Default(0) int cost,
    @Default([]) List<String> normalSkills,
    @Default([]) List<String> doubleSkills,
    @Default(PlayerStatus.healthy) PlayerStatus status,
    String? injuryDetails,
    @Default(false) bool missNextGame,
  }) = _Character;

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(_normalizeCharacterJson(json));

  int get value =>
      cost + (skills.fold<int>(0, (sum, skill) => sum + (skill.cost ?? 0)));
  bool get canLevelUp => spp >= sppForNextLevel;

  int get sppForNextLevel {
    switch (level) {
      case 1:
        return 6;
      case 2:
        return 16;
      case 3:
        return 31;
      case 4:
        return 51;
      case 5:
        return 76;
      default:
        return 176;
    }
  }
}

@freezed
class Stats with _$Stats {
  const factory Stats({
    @Default(6) int ma,
    @Default(3) int st,
    @Default(3) int ag,
    @Default(4) int pa,
    @Default(9) int av,
  }) = _Stats;

  factory Stats.fromJson(Map<String, dynamic> json) =>
      _$StatsFromJson(_normalizeStatsJson(json));
}

@freezed
class Skill with _$Skill {
  const factory Skill({
    required String id,
    required String name,
    @Default('') String family,
    String? description,
    int? cost,
    @Default(false) bool isStarting,
  }) = _Skill;

  factory Skill.fromJson(Map<String, dynamic> json) =>
      _$SkillFromJson(_normalizeSkillJson(json));
}

enum PlayerStatus {
  @JsonValue('healthy')
  healthy,
  @JsonValue('injured')
  injured,
  @JsonValue('mng')
  mng,
  @JsonValue('dead')
  dead,
}

@freezed
class BaseTeam with _$BaseTeam {
  const factory BaseTeam({
    required String id,
    required String name,
    required int rerollCost,
    @Default(true) bool apothecaryAllowed,
    @Default([]) List<String> specialRules,
    @Default([]) List<BasePosition> positions,
    String? description,
    int? tier,
    String? icon,
    String? wallpaper,
  }) = _BaseTeam;

  factory BaseTeam.fromJson(Map<String, dynamic> json) =>
      _$BaseTeamFromJson(_normalizeBaseTeamJson(json));
}

@freezed
class BasePosition with _$BasePosition {
  const factory BasePosition({
    required String id,
    required String name,
    required int cost,
    required int maxQuantity,
    required Stats stats,
    @Default([]) List<BasePerk> startingPerks,
    @Default([]) List<String> normalSkills,
    @Default([]) List<String> doubleSkills,
    String? position,
    String? image,
  }) = _BasePosition;

  factory BasePosition.fromJson(Map<String, dynamic> json) =>
      _$BasePositionFromJson(_normalizeBasePositionJson(json));
}

@freezed
class BasePerk with _$BasePerk {
  const factory BasePerk({
    required String id,
    required String name,
    required String category,
  }) = _BasePerk;

  factory BasePerk.fromJson(Map<String, dynamic> json) =>
      _$BasePerkFromJson(json);
}

Map<String, dynamic> _normalizeTeamJson(Map<String, dynamic> json) => {
      ...json,
      'baseTeamId': json['baseTeamId'] ??
          json['base_team_id'] ??
          json['base_roster_id'] ??
          '',
      'baseTeamName': json['baseTeamName'] ??
          json['base_team_name'] ??
          _deriveBaseTeamName(json['base_roster_id']),
      'ownerId': json['ownerId'] ?? json['owner_id'] ?? json['user_id'] ?? '',
      'teamValue': json['teamValue'] ?? json['team_value'],
      'currentTeamValue':
          json['currentTeamValue'] ?? json['current_team_value'],
      'rerollCost': json['rerollCost'] ?? json['reroll_cost'],
      'fanFactor': json['fanFactor'] ?? json['fan_factor'],
      'assistantCoaches': json['assistantCoaches'] ?? json['assistant_coaches'],
      'characters': json['characters'] ?? json['players'],
      'primaryColor': json['primaryColor'] ?? json['primary_color'],
      'secondaryColor': json['secondaryColor'] ?? json['secondary_color'],
      'createdAt': json['createdAt'] ?? json['created_at'],
      'leagueId': json['leagueId'] ?? json['league_id'],
    };

Map<String, dynamic> _normalizeCharacterJson(Map<String, dynamic> json) => {
      ...json,
      'position': json['position'] ?? _readPositionLabel(json),
      'positionId':
          json['positionId'] ?? json['position_id'] ?? json['base_type'] ?? '',
      'skills': json['skills'] ?? json['perks'],
      'cost': json['cost'] ?? json['current_value'],
      'normalSkills': json['normalSkills'] ?? json['normal_skills'],
      'doubleSkills': json['doubleSkills'] ?? json['double_skills'],
      'injuryDetails': json['injuryDetails'] ?? json['injury_details'],
      'missNextGame': json['missNextGame'] ?? json['miss_next_game'],
    };

Map<String, dynamic> _normalizeStatsJson(Map<String, dynamic> json) => {
      ...json,
      'ma': _parseStatValue(json['ma'] ?? json['MA'], fallback: 6),
      'st': _parseStatValue(json['st'] ?? json['ST'], fallback: 3),
      'ag': _parseStatValue(json['ag'] ?? json['AG'], fallback: 3),
      'pa': _parsePaValue(json['pa'] ?? json['PA']),
      'av': _parseStatValue(json['av'] ?? json['AV'], fallback: 9),
    };

Map<String, dynamic> _normalizeSkillJson(Map<String, dynamic> json) => {
      ...json,
      'family': json['family'] ?? json['category'] ?? '',
    };

Map<String, dynamic> _normalizeBaseTeamJson(Map<String, dynamic> json) => {
      ...json,
      'rerollCost': json['rerollCost'] ?? json['reroll_cost'],
      'apothecaryAllowed':
          json['apothecaryAllowed'] ?? json['apothecary_allowed'],
      'specialRules': json['specialRules'] ?? json['special_rules'],
      'positions': json['positions'] ?? json['players'],
    };

Map<String, dynamic> _normalizeBasePositionJson(Map<String, dynamic> json) => {
      ...json,
      'id': json['id'] ?? json['type'] ?? '',
      'maxQuantity': json['maxQuantity'] ?? json['max'],
      'startingPerks': json['startingPerks'] ?? json['perks'],
      'normalSkills': json['normalSkills'] ?? json['primary_access'],
      'doubleSkills': json['doubleSkills'] ?? json['secondary_access'],
    };

String _deriveBaseTeamName(Object? rawRosterId) {
  final rosterId = rawRosterId as String?;
  if (rosterId == null || rosterId.isEmpty) return '';

  return rosterId
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _readPositionLabel(Map<String, dynamic> json) {
  final baseType = json['base_type'];
  if (baseType is String && baseType.isNotEmpty) {
    return baseType
        .split('-')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  final position = json['position'];
  return position is String ? position : '';
}

int _parseStatValue(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value.replaceAll('+', '')) ?? fallback;
  }
  return fallback;
}

int _parsePaValue(Object? value) {
  if (value == null || value == '-') return 0;
  return _parseStatValue(value, fallback: 4);
}

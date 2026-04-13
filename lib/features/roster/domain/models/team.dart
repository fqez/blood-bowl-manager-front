import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
class Team with _$Team {
  const Team._();

  const factory Team({
    required String id,
    required String name,
    @JsonKey(name: 'base_team_id', readValue: _readBaseTeamId)
    required String baseTeamId,
    @JsonKey(name: 'base_team_name', readValue: _readBaseTeamName)
    @Default('')
    String baseTeamName,
    @JsonKey(name: 'owner_id', readValue: _readOwnerId) required String ownerId,
    @Default(1000000) int treasury,
    @JsonKey(name: 'team_value') @Default(0) int teamValue,
    @JsonKey(name: 'current_team_value') @Default(0) int currentTeamValue,
    @Default(0) int rerolls,
    @JsonKey(name: 'reroll_cost') @Default(0) int rerollCost,
    @JsonKey(name: 'fan_factor') @Default(0) int fanFactor,
    @JsonKey(name: 'assistant_coaches') @Default(0) int assistantCoaches,
    @Default(0) int cheerleaders,
    @Default(false) bool apothecary,
    @JsonKey(readValue: _readCharacters)
    @Default([])
    List<Character> characters,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'league_id') String? leagueId,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

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
    @JsonKey(readValue: _readPosition) @Default('') String position,
    @JsonKey(name: 'position_id', readValue: _readPositionId)
    @Default('')
    String positionId,
    @Default(0) int number,
    required Stats stats,
    @JsonKey(readValue: _readSkills) @Default([]) List<Skill> skills,
    @Default(0) int spp,
    @Default(1) int level,
    @JsonKey(readValue: _readCost) @Default(0) int cost,
    @JsonKey(name: 'normal_skills') @Default([]) List<String> normalSkills,
    @JsonKey(name: 'double_skills') @Default([]) List<String> doubleSkills,
    @Default(PlayerStatus.healthy) PlayerStatus status,
    @JsonKey(name: 'injury_details') String? injuryDetails,
    @JsonKey(name: 'miss_next_game') @Default(false) bool missNextGame,
  }) = _Character;

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);

  int get value =>
      cost + (skills.fold<int>(0, (sum, s) => sum + (s.cost ?? 0)));
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
    // Soporta tanto minúsculas (frontend) como mayúsculas (backend API)
    @JsonKey(readValue: _readMaValue) @Default(6) int ma,
    @JsonKey(readValue: _readStValue) @Default(3) int st,
    @JsonKey(readValue: _readAgValue) @Default(3) int ag,
    @JsonKey(readValue: _readPaValue) @Default(4) int pa,
    @JsonKey(readValue: _readAvValue) @Default(9) int av,
  }) = _Stats;

  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);
}

// Helpers para Team (campos con nombres distintos entre endpoints)
Object? _readBaseTeamId(Map<dynamic, dynamic> json, String key) =>
    json['base_team_id'] ?? json['base_roster_id'] ?? '';
Object? _readBaseTeamName(Map<dynamic, dynamic> json, String key) {
  if (json['base_team_name'] != null) return json['base_team_name'];
  // Derive from base_roster_id: "shambling_undead" → "Shambling Undead"
  final rid = json['base_roster_id'] as String?;
  if (rid != null && rid.isNotEmpty) {
    return rid
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
  return '';
}

Object? _readOwnerId(Map<dynamic, dynamic> json, String key) =>
    json['owner_id'] ?? json['user_id'] ?? '';
Object? _readCharacters(Map<dynamic, dynamic> json, String key) =>
    json['characters'] ?? json['players'] ?? [];

// Helpers para Character (campos con nombres distintos entre endpoints)
Object? _readPosition(Map<dynamic, dynamic> json, String key) {
  // /user-teams devuelve "base_type", /characters devuelve "position"
  final bt = json['base_type'];
  if (bt is String && bt.isNotEmpty) {
    return bt
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
  return json['position'] ?? '';
}

Object? _readPositionId(Map<dynamic, dynamic> json, String key) =>
    json['position_id'] ?? json['base_type'] ?? '';
Object? _readCost(Map<dynamic, dynamic> json, String key) =>
    json['cost'] ?? json['current_value'] ?? 0;
Object? _readSkills(Map<dynamic, dynamic> json, String key) =>
    json['skills'] ?? json['perks'] ?? [];

// Helpers para leer stats del backend (pueden venir como "4+" o como int)
Object? _readMaValue(Map<dynamic, dynamic> json, String key) =>
    json['ma'] ?? json['MA'];
Object? _readStValue(Map<dynamic, dynamic> json, String key) =>
    json['st'] ?? json['ST'];
Object? _readAgValue(Map<dynamic, dynamic> json, String key) {
  final val = json['ag'] ?? json['AG'];
  if (val is String) return int.tryParse(val.replaceAll('+', '')) ?? 3;
  return val;
}

Object? _readPaValue(Map<dynamic, dynamic> json, String key) {
  final val = json['pa'] ?? json['PA'];
  if (val == null || val == '-') return 0;
  if (val is String) return int.tryParse(val.replaceAll('+', '')) ?? 4;
  return val;
}

Object? _readAvValue(Map<dynamic, dynamic> json, String key) {
  final val = json['av'] ?? json['AV'];
  if (val is String) return int.tryParse(val.replaceAll('+', '')) ?? 9;
  return val;
}

@freezed
class Skill with _$Skill {
  const factory Skill({
    required String id,
    required String name,
    @JsonKey(readValue: _readFamily) @Default('') String family,
    String? description,
    int? cost,
    @Default(false) bool isStarting,
  }) = _Skill;

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
}

// Helper: el backend usa "category", el frontend "family"
Object? _readFamily(Map<dynamic, dynamic> json, String key) =>
    json['family'] ?? json['category'] ?? '';

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
    @JsonKey(name: 'reroll_cost') required int rerollCost,
    @Default(true) @JsonKey(name: 'apothecary_allowed') bool apothecaryAllowed,
    @JsonKey(name: 'special_rules') @Default([]) List<String> specialRules,
    @JsonKey(name: 'players') @Default([]) List<BasePosition> positions,
    String? description,
    @JsonKey(name: 'tier') int? tier,
    String? icon,
    String? wallpaper,
  }) = _BaseTeam;

  factory BaseTeam.fromJson(Map<String, dynamic> json) =>
      _$BaseTeamFromJson(json);
}

@freezed
class BasePosition with _$BasePosition {
  const factory BasePosition({
    // Backend usa 'type' como id del jugador
    @JsonKey(name: 'type') required String id,
    required String name,
    required int cost,
    @JsonKey(name: 'max') required int maxQuantity,
    required Stats stats,
    // Backend envía 'perks' con objetos, pero mantenemos compatibilidad
    @JsonKey(name: 'perks') @Default([]) List<BasePerk> startingPerks,
    @JsonKey(name: 'primary_access') @Default([]) List<String> normalSkills,
    @JsonKey(name: 'secondary_access') @Default([]) List<String> doubleSkills,
    String? position,
    String? image,
  }) = _BasePosition;

  factory BasePosition.fromJson(Map<String, dynamic> json) =>
      _$BasePositionFromJson(json);
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

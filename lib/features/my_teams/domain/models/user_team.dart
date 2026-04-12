import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────── Stats ───────────────────────────

class UserPlayerStats {
  final int ma;
  final int st;
  final String ag;
  final String? pa;
  final String av;

  const UserPlayerStats({
    required this.ma,
    required this.st,
    required this.ag,
    this.pa,
    required this.av,
  });

  factory UserPlayerStats.fromJson(Map<String, dynamic> json) {
    return UserPlayerStats(
      ma: (json['MA'] as num?)?.toInt() ?? 6,
      st: (json['ST'] as num?)?.toInt() ?? 3,
      ag: json['AG']?.toString() ?? '4+',
      pa: json['PA']?.toString(),
      av: json['AV']?.toString() ?? '9+',
    );
  }
}

// ─────────────────────────── Perk ────────────────────────────

class UserPlayerPerk {
  final String id;
  final String name;
  final String? category;

  const UserPlayerPerk({
    required this.id,
    required this.name,
    this.category,
  });

  factory UserPlayerPerk.fromJson(Map<String, dynamic> json) => UserPlayerPerk(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String?,
      );
}

// ─────────────────────────── Career ──────────────────────────

class UserPlayerCareer {
  final int games;
  final int touchdowns;
  final int casualties;
  final int interceptions;
  final int completions;
  final int mvpAwards;

  const UserPlayerCareer({
    this.games = 0,
    this.touchdowns = 0,
    this.casualties = 0,
    this.interceptions = 0,
    this.completions = 0,
    this.mvpAwards = 0,
  });

  factory UserPlayerCareer.fromJson(Map<String, dynamic> json) =>
      UserPlayerCareer(
        games: (json['games'] as num?)?.toInt() ?? 0,
        touchdowns: (json['touchdowns'] as num?)?.toInt() ?? 0,
        casualties: (json['casualties'] as num?)?.toInt() ?? 0,
        interceptions: (json['interceptions'] as num?)?.toInt() ?? 0,
        completions: (json['completions'] as num?)?.toInt() ?? 0,
        mvpAwards: (json['mvp_awards'] as num?)?.toInt() ?? 0,
      );
}

// ─────────────────────────── Player ──────────────────────────

class UserPlayer {
  final String id;
  final String baseType;
  final String name;
  final int number;
  final int currentValue;
  final UserPlayerStats stats;
  final List<UserPlayerPerk> perks;
  final int spp;
  final String status;
  final String? image;
  final UserPlayerCareer career;

  const UserPlayer({
    required this.id,
    required this.baseType,
    required this.name,
    required this.number,
    required this.currentValue,
    required this.stats,
    required this.perks,
    required this.spp,
    required this.status,
    this.image,
    required this.career,
  });

  factory UserPlayer.fromJson(Map<String, dynamic> json) => UserPlayer(
        id: json['id'] as String,
        baseType: json['base_type'] as String? ?? '',
        name: json['name'] as String? ?? '',
        number: (json['number'] as num?)?.toInt() ?? 0,
        currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
        stats: UserPlayerStats.fromJson(
            json['stats'] as Map<String, dynamic>? ?? {}),
        perks: (json['perks'] as List<dynamic>? ?? [])
            .map((e) => UserPlayerPerk.fromJson(e as Map<String, dynamic>))
            .toList(),
        spp: (json['spp'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'healthy',
        image: json['image'] as String?,
        career: json['career'] != null
            ? UserPlayerCareer.fromJson(
                json['career'] as Map<String, dynamic>)
            : const UserPlayerCareer(),
      );

  /// Convert base_type "skeleton-lineman" → "Skeleton Lineman"
  String get positionLabel => baseType
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  bool get isActive => status == 'healthy';
  bool get isDead => status == 'dead';

  Color get statusColor {
    switch (status) {
      case 'healthy':
        return AppColors.healthy;
      case 'badly_hurt':
      case 'seriously_injured':
      case 'missing_next_game':
        return AppColors.injured;
      case 'dead':
        return AppColors.dead;
      default:
        return AppColors.textMuted;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'healthy':
        return 'Activo';
      case 'badly_hurt':
        return 'Herido Leve';
      case 'seriously_injured':
        return 'Herido Grave';
      case 'missing_next_game':
        return 'MNG';
      case 'dead':
        return 'Muerto';
      default:
        return status;
    }
  }
}

// ─────────────────────────── Summary ─────────────────────────

class UserTeamSummary {
  final String id;
  final String name;
  final String baseRosterId;
  final int teamValue;
  final int treasury;
  final int playerCount;
  final String? icon;
  final DateTime createdAt;

  const UserTeamSummary({
    required this.id,
    required this.name,
    required this.baseRosterId,
    required this.teamValue,
    required this.treasury,
    required this.playerCount,
    this.icon,
    required this.createdAt,
  });

  factory UserTeamSummary.fromJson(Map<String, dynamic> json) =>
      UserTeamSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        baseRosterId: json['base_roster_id'] as String,
        teamValue: (json['team_value'] as num?)?.toInt() ?? 0,
        treasury: (json['treasury'] as num?)?.toInt() ?? 1000000,
        playerCount: (json['player_count'] as num?)?.toInt() ?? 0,
        icon: json['icon'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  /// e.g. "shambling-undead" → "Shambling Undead"
  String get raceLabel => baseRosterId
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────── Detail ──────────────────────────

class UserTeamDetail {
  final String id;
  final String userId;
  final String baseRosterId;
  final String name;
  final List<UserPlayer> players;
  final int treasury;
  final int teamValue;
  final int rerolls;
  final int rerollCost;
  final int fanFactor;
  final int cheerleaders;
  final int assistantCoaches;
  final bool apothecary;
  final bool apothecaryAllowed;
  final int dedicatedFans;
  final String? icon;
  final String? wallpaper;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTeamDetail({
    required this.id,
    required this.userId,
    required this.baseRosterId,
    required this.name,
    required this.players,
    required this.treasury,
    required this.teamValue,
    required this.rerolls,
    required this.rerollCost,
    required this.fanFactor,
    required this.cheerleaders,
    required this.assistantCoaches,
    required this.apothecary,
    required this.apothecaryAllowed,
    required this.dedicatedFans,
    this.icon,
    this.wallpaper,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserTeamDetail.fromJson(Map<String, dynamic> json) => UserTeamDetail(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        baseRosterId: json['base_roster_id'] as String,
        name: json['name'] as String,
        players: (json['players'] as List<dynamic>? ?? [])
            .map((e) => UserPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        treasury: (json['treasury'] as num?)?.toInt() ?? 1000000,
        teamValue: (json['team_value'] as num?)?.toInt() ?? 0,
        rerolls: (json['rerolls'] as num?)?.toInt() ?? 0,
        rerollCost: (json['reroll_cost'] as num?)?.toInt() ?? 0,
        fanFactor: (json['fan_factor'] as num?)?.toInt() ?? 0,
        cheerleaders: (json['cheerleaders'] as num?)?.toInt() ?? 0,
        assistantCoaches: (json['assistant_coaches'] as num?)?.toInt() ?? 0,
        apothecary: json['apothecary'] as bool? ?? false,
        apothecaryAllowed: json['apothecary_allowed'] as bool? ?? true,
        dedicatedFans: (json['dedicated_fans'] as num?)?.toInt() ?? 1,
        icon: json['icon'] as String?,
        wallpaper: json['wallpaper'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  String get raceLabel => baseRosterId
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  int get activePlayerCount =>
      players.where((p) => p.status == 'healthy').length;
}

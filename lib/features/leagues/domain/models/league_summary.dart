// Plain Dart models matching the backend LeagueSummary / LeagueByCodePreview schemas.
// These are separate from the existing freezed League model used by LeagueOverviewScreen.

class LeagueSummaryModel {
  final String id;
  final String name;
  final String ownerUsername;
  final String status;
  final String format;
  final int teamCount;
  final int maxTeams;
  final int season;
  final String? inviteCode;
  final DateTime createdAt;
  // User-specific fields
  final bool isOwner;
  final String? userTeamName;
  final int? currentRound;

  const LeagueSummaryModel({
    required this.id,
    required this.name,
    required this.ownerUsername,
    required this.status,
    required this.format,
    required this.teamCount,
    required this.maxTeams,
    required this.season,
    this.inviteCode,
    required this.createdAt,
    this.isOwner = false,
    this.userTeamName,
    this.currentRound,
  });

  factory LeagueSummaryModel.fromJson(Map<String, dynamic> json) =>
      LeagueSummaryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerUsername: json['owner_username'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        format: json['format'] as String? ?? 'round_robin',
        teamCount: (json['team_count'] as num?)?.toInt() ?? 0,
        maxTeams: (json['max_teams'] as num?)?.toInt() ?? 8,
        season: (json['season'] as num?)?.toInt() ?? 1,
        inviteCode: json['invite_code'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        isOwner: json['is_owner'] as bool? ?? false,
        userTeamName: json['user_team_name'] as String?,
        currentRound: (json['current_round'] as num?)?.toInt(),
      );

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Inscripción';
      case 'active':
        return 'Activa';
      case 'completed':
        return 'Finalizada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String get formatLabel {
    switch (format) {
      case 'round_robin':
        return 'Liga';
      case 'knockout':
        return 'Eliminatoria';
      case 'swiss':
        return 'Suiza';
      default:
        return format;
    }
  }
}

class LeagueByCodePreview {
  final String id;
  final String name;
  final String ownerUsername;
  final String status;
  final String format;
  final int teamCount;
  final int maxTeams;
  final int season;
  final String inviteCode;

  const LeagueByCodePreview({
    required this.id,
    required this.name,
    required this.ownerUsername,
    required this.status,
    required this.format,
    required this.teamCount,
    required this.maxTeams,
    required this.season,
    required this.inviteCode,
  });

  factory LeagueByCodePreview.fromJson(Map<String, dynamic> json) =>
      LeagueByCodePreview(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerUsername: json['owner_username'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        format: json['format'] as String? ?? 'round_robin',
        teamCount: (json['team_count'] as num?)?.toInt() ?? 0,
        maxTeams: (json['max_teams'] as num?)?.toInt() ?? 8,
        season: (json['season'] as num?)?.toInt() ?? 1,
        inviteCode: json['invite_code'] as String? ?? '',
      );

  bool get isFull => teamCount >= maxTeams;
  bool get isDraft => status == 'draft';

  String get formatLabel {
    switch (format) {
      case 'round_robin':
        return 'Liga';
      case 'knockout':
        return 'Eliminatoria';
      case 'swiss':
        return 'Suiza';
      default:
        return format;
    }
  }
}

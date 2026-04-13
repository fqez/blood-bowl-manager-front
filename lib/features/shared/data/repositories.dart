import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../league/domain/models/league.dart';
import '../../leagues/domain/models/league_summary.dart';
import '../../roster/domain/models/team.dart';
import '../../my_teams/domain/models/user_team.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(dio: ref.watch(dioProvider));
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(dio: ref.watch(dioProvider));
});

/// Fetches all perks from the backend.
final allPerksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getPerks();
});

/// Fetches all star players from the backend.
final allStarPlayersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayers();
});

/// Fetches star players available for a specific team.
final starPlayersForTeamProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayersForTeam(teamId);
});

class LeagueRepository {
  final Dio _dio;

  LeagueRepository({required Dio dio}) : _dio = dio;

  Future<List<League>> getMyLeagues() async {
    try {
      final response = await _dio.get('/leagues/my');
      return (response.data as List)
          .map((json) => League.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<League> getLeague(String leagueId) async {
    try {
      final response = await _dio.get('/leagues/$leagueId');
      return League.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> getLeagueFormat(String leagueId) async {
    try {
      final response = await _dio.get('/leagues/$leagueId');
      return (response.data as Map<String, dynamic>)['format'] as String? ??
          'round_robin';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Match>> getLeagueMatches(String leagueId, {int? round}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (round != null) queryParams['round'] = round;

      final response = await _dio.get(
        '/leagues/$leagueId/matches',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((json) => Match.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<LeagueTeam>> getLeagueStandings(String leagueId) async {
    try {
      final response = await _dio.get('/leagues/$leagueId/standings');
      return (response.data as List)
          .map((json) => LeagueTeam.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<LeagueInvitation>> getInvitations() async {
    try {
      final response = await _dio.get('/leagues/invitations');
      return (response.data as List)
          .map((json) => LeagueInvitation.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _dio.post('/leagues/invitations/$invitationId/accept');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _dio.post('/leagues/invitations/$invitationId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<League> createLeague({
    required String name,
    String? description,
    int? startingBudget,
    int? maxRounds,
  }) async {
    try {
      final response = await _dio.post('/leagues', data: {
        'name': name,
        if (description != null) 'description': description,
        if (startingBudget != null) 'starting_budget': startingBudget,
        if (maxRounds != null) 'max_rounds': maxRounds,
      });
      return League.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> joinLeague(String leagueId, String teamId) async {
    try {
      await _dio.post('/leagues/$leagueId/join', data: {
        'team_id': teamId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── New invite-code methods ──

  Future<List<LeagueSummaryModel>> getMyLeaguesSummary() async {
    try {
      final response = await _dio.get('/leagues/my');
      return (response.data as List)
          .map((json) =>
              LeagueSummaryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LeagueSummaryModel> createLeagueFull({
    required String name,
    String? description,
    required String format,
    required int maxTeams,
    required int startingBudget,
    required bool resurrection,
    required bool inducements,
    required bool spiralingExpenses,
  }) async {
    try {
      final response = await _dio.post('/leagues/', data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'format': format,
        'max_teams': maxTeams,
        'rules': {
          'starting_budget': startingBudget,
          'resurrection': resurrection,
          'inducements': inducements,
          'spiraling_expenses': spiralingExpenses,
        },
      });
      return LeagueSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LeagueByCodePreview> getLeagueByCode(String code) async {
    try {
      final response = await _dio.get('/leagues/by-code/$code');
      return LeagueByCodePreview.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> joinLeagueWithCode(
      String leagueId, String teamId, String inviteCode) async {
    try {
      await _dio.post('/leagues/$leagueId/teams', data: {
        'team_id': teamId,
        'invite_code': inviteCode,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LeagueSummaryModel> updateLeagueSettings(
    String leagueId, {
    String? name,
    String? description,
    int? maxTeams,
  }) async {
    try {
      final response = await _dio.patch('/leagues/$leagueId', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (maxTeams != null) 'max_teams': maxTeams,
      });
      return LeagueSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteLeague(String leagueId) async {
    try {
      await _dio.delete('/leagues/$leagueId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> archiveLeague(String leagueId) async {
    try {
      await _dio.post('/leagues/$leagueId/archive');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<League> startLeague(String leagueId) async {
    try {
      final response = await _dio.post('/leagues/$leagueId/start');
      return League.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> leaveLeague(String leagueId, String teamId) async {
    try {
      await _dio.delete('/leagues/$leagueId/teams/$teamId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Live Match methods ──

  Future<League> startMatch(String leagueId, String matchId) async {
    try {
      final response =
          await _dio.post('/leagues/$leagueId/matches/$matchId/start');
      return League.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> getMatchDetail(String leagueId, String matchId) async {
    try {
      final response = await _dio.get('/leagues/$leagueId/matches/$matchId');
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> addMatchEvent(
    String leagueId,
    String matchId, {
    required String type,
    required String team,
    String? playerId,
    String? playerName,
    String? victimId,
    String? victimName,
    String? injury,
    String? detail,
    int half = 0,
    int turn = 0,
  }) async {
    try {
      final response = await _dio.post(
        '/leagues/$leagueId/matches/$matchId/events',
        data: {
          'type': type,
          'team': team,
          if (playerId != null) 'player_id': playerId,
          if (playerName != null) 'player_name': playerName,
          if (victimId != null) 'victim_id': victimId,
          if (victimName != null) 'victim_name': victimName,
          if (injury != null) 'injury': injury,
          if (detail != null) 'detail': detail,
          'half': half,
          'turn': turn,
        },
      );
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> deleteMatchEvent(
    String leagueId,
    String matchId,
    String eventId,
  ) async {
    try {
      final response = await _dio.delete(
        '/leagues/$leagueId/matches/$matchId/events/$eventId',
      );
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> updateMatchState(
    String leagueId,
    String matchId, {
    int? scoreHome,
    int? scoreAway,
    int? currentHalf,
    int? currentTurn,
    String? weather,
    String? kickoffEvent,
    int? rerollsUsedHome,
    int? rerollsUsedAway,
    String? mvpHome,
    String? mvpAway,
    int? gate,
  }) async {
    try {
      final response = await _dio.patch(
        '/leagues/$leagueId/matches/$matchId/state',
        data: {
          if (scoreHome != null) 'score_home': scoreHome,
          if (scoreAway != null) 'score_away': scoreAway,
          if (currentHalf != null) 'current_half': currentHalf,
          if (currentTurn != null) 'current_turn': currentTurn,
          if (weather != null) 'weather': weather,
          if (kickoffEvent != null) 'kickoff_event': kickoffEvent,
          if (rerollsUsedHome != null) 'rerolls_used_home': rerollsUsedHome,
          if (rerollsUsedAway != null) 'rerolls_used_away': rerollsUsedAway,
          if (mvpHome != null) 'mvp_home': mvpHome,
          if (mvpAway != null) 'mvp_away': mvpAway,
          if (gate != null) 'gate': gate,
        },
      );
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<League> completeMatch(String leagueId, String matchId) async {
    try {
      final response =
          await _dio.post('/leagues/$leagueId/matches/$matchId/complete');
      return League.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class TeamRepository {
  final Dio _dio;

  TeamRepository({required Dio dio}) : _dio = dio;

  Future<List<Team>> getMyTeams() async {
    try {
      final response = await _dio.get('/teams/my');
      return (response.data as List)
          .map((json) => Team.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      final response = await _dio.get('/user-teams/$teamId');
      return Team.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Creates a new team via the authenticated /user-teams endpoint.
  /// Returns the new team's ID.
  Future<String> createUserTeam({
    required String name,
    required String baseRosterId,
  }) async {
    try {
      final response = await _dio.post('/user-teams/', data: {
        'name': name,
        'base_roster_id': baseRosterId,
      });
      return response.data['id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Hires a single player for a team.
  Future<void> hirePlayer(
    String teamId, {
    required String baseType,
    required String name,
    required int number,
  }) async {
    try {
      await _dio.post('/user-teams/$teamId/players', data: {
        'base_type': baseType,
        'name': name,
        'number': number,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Hires a star player for a team.
  Future<void> hireStarPlayer(
    String teamId, {
    required String starPlayerId,
    required String name,
    required int number,
  }) async {
    try {
      await _dio.post('/user-teams/$teamId/players/star', data: {
        'star_player_id': starPlayerId,
        'name': name,
        'number': number,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Updates team staff counts (rerolls, apothecary, cheerleaders, coaches, fan_factor).
  Future<UserTeamDetail> patchTeamStaff(
    String teamId, {
    int? rerolls,
    int? cheerleaders,
    int? assistantCoaches,
    bool? apothecary,
    int? fanFactor,
  }) async {
    try {
      final response = await _dio.patch('/user-teams/$teamId', data: {
        if (rerolls != null) 'rerolls': rerolls,
        if (cheerleaders != null) 'cheerleaders': cheerleaders,
        if (assistantCoaches != null) 'assistant_coaches': assistantCoaches,
        if (apothecary != null) 'apothecary': apothecary,
        if (fanFactor != null) 'fan_factor': fanFactor,
      });
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fires (removes) a player from a user team.
  Future<void> fireUserPlayer(String teamId, String playerId) async {
    try {
      await _dio.delete('/user-teams/$teamId/players/$playerId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Updates a player's name and/or jersey number.
  Future<UserTeamDetail> updatePlayer(
    String teamId,
    String playerId, {
    String? name,
    int? number,
  }) async {
    try {
      final response = await _dio.patch(
        '/user-teams/$teamId/players/$playerId',
        data: {
          if (name != null) 'name': name,
          if (number != null) 'number': number,
        },
      );
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns a summary list of all teams owned by the current user.
  Future<List<UserTeamSummary>> getUserTeams() async {
    try {
      final response = await _dio.get('/user-teams/');
      return (response.data as List)
          .map((e) => UserTeamSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns the full detail of a single user team.
  Future<UserTeamDetail> getUserTeamDetail(String teamId) async {
    try {
      final response = await _dio.get('/user-teams/$teamId');
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Team> updateTeam(String teamId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/teams/$teamId', data: updates);
      return Team.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> addCharacter(
      String teamId, String positionId, String name) async {
    try {
      final response = await _dio.post('/teams/$teamId/characters', data: {
        'position_id': positionId,
        'name': name,
      });
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeCharacter(String teamId, String characterId) async {
    try {
      await _dio.delete('/teams/$teamId/characters/$characterId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> updateCharacter(
    String teamId,
    String characterId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.patch(
        '/teams/$teamId/characters/$characterId',
        data: updates,
      );
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> addSkill(
      String teamId, String characterId, String skillId) async {
    try {
      final response = await _dio.post(
        '/teams/$teamId/characters/$characterId/skills',
        data: {'skill_id': skillId},
      );
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyReroll(String teamId) async {
    try {
      await _dio.post('/teams/$teamId/reroll');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyApothecary(String teamId) async {
    try {
      await _dio.post('/teams/$teamId/apothecary');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyStaff(String teamId, String staffType) async {
    try {
      await _dio.post('/teams/$teamId/staff', data: {'type': staffType});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BaseTeam>> getBaseTeams() async {
    try {
      final response = await _dio.get('/base-rosters');
      return (response.data as List)
          .map((json) => BaseTeam.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BaseTeam> getBaseTeamDetail(String rosterId) async {
    try {
      final response = await _dio.get('/base-rosters/$rosterId');
      return BaseTeam.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches all perks/skills from the backend.
  Future<List<Map<String, dynamic>>> getPerks() async {
    try {
      final response = await _dio.get('/perks/');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Star Players ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStarPlayers() async {
    try {
      final response = await _dio.get('/star-players/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAllStarPlayerDetails() async {
    try {
      final response = await _dio.get('/star-players/details');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getStarPlayer(String starPlayerId) async {
    try {
      final response = await _dio.get('/star-players/$starPlayerId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getStarPlayersForTeam(
      String teamId) async {
    try {
      final response = await _dio.get('/star-players/team/$teamId');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Tactics ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTactic(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/tactics/', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyTactics() async {
    try {
      final response = await _dio.get('/tactics/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getTactic(String tacticId) async {
    try {
      final response = await _dio.get('/tactics/$tacticId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateTactic(
      String tacticId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch('/tactics/$tacticId', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteTactic(String tacticId) async {
    try {
      await _dio.delete('/tactics/$tacticId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Adds a perk to a player on a user team.
  Future<UserTeamDetail> addPerkToPlayer(
    String teamId,
    String playerId, {
    required String perkId,
    required String perkName,
    String? category,
  }) async {
    try {
      final response = await _dio.post(
        '/user-teams/$teamId/players/$playerId/perks',
        data: {
          'perk_id': perkId,
          'perk_name': perkName,
          if (category != null) 'category': category,
        },
      );
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../league/domain/models/league.dart';
import '../../roster/domain/models/team.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(dio: ref.watch(dioProvider));
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(dio: ref.watch(dioProvider));
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
      final response = await _dio.get('/teams/$teamId');
      return Team.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Team> createTeam({
    required String name,
    required String baseTeamId,
    String? leagueId,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    try {
      final response = await _dio.post('/teams', data: {
        'name': name,
        'base_team_id': baseTeamId,
        if (leagueId != null) 'league_id': leagueId,
        if (primaryColor != null) 'primary_color': primaryColor,
        if (secondaryColor != null) 'secondary_color': secondaryColor,
      });
      return Team.fromJson(response.data);
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

  Future<Character> addCharacter(String teamId, String positionId, String name) async {
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

  Future<Character> addSkill(String teamId, String characterId, String skillId) async {
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
}

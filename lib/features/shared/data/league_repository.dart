import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../league/domain/models/league.dart';
import '../../leagues/domain/models/league_summary.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(dio: ref.watch(dioProvider));
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
    bool? homeReady,
    bool? awayReady,
    List<String>? homeSquad,
    List<String>? awaySquad,
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
          if (homeReady != null) 'home_ready': homeReady,
          if (awayReady != null) 'away_ready': awayReady,
          if (homeSquad != null) 'home_squad': homeSquad,
          if (awaySquad != null) 'away_squad': awaySquad,
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

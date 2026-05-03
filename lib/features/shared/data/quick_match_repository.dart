import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../league/domain/models/league.dart';

final quickMatchRepositoryProvider = Provider<QuickMatchRepository>((ref) {
  return QuickMatchRepository(dio: ref.watch(dioProvider));
});

class QuickMatchRepository {
  final Dio _dio;

  QuickMatchRepository({required Dio dio}) : _dio = dio;

  Future<Match> createQuickMatch({
    required String homeTeamId,
    required String awayTeamId,
  }) async {
    try {
      final response = await _dio.post('/quick-matches/', data: {
        'home_team_id': homeTeamId,
        'away_team_id': awayTeamId,
      });
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Match>> listQuickMatches() async {
    try {
      final response = await _dio.get('/quick-matches/');
      return (response.data as List)
          .map((json) => Match.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> getMatchDetail(String matchId) async {
    try {
      final response = await _dio.get('/quick-matches/$matchId');
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> startMatch(String matchId) async {
    try {
      final response = await _dio.post('/quick-matches/$matchId/start');
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> addMatchEvent(
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
        '/quick-matches/$matchId/events',
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

  Future<Match> deleteMatchEvent(String matchId, String eventId) async {
    try {
      final response =
          await _dio.delete('/quick-matches/$matchId/events/$eventId');
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Match> updateMatchState(
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
        '/quick-matches/$matchId/state',
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

  Future<Match> completeMatch(String matchId) async {
    try {
      final response = await _dio.post('/quick-matches/$matchId/complete');
      return Match.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteQuickMatch(String matchId) async {
    try {
      await _dio.delete('/quick-matches/$matchId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

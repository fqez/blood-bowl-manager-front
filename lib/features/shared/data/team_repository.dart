import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../my_teams/domain/models/user_team.dart';
import '../../roster/domain/models/team.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(dio: ref.watch(dioProvider));
});

final allPerksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getPerks();
});

final allStarPlayersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayers();
});

final starPlayersForTeamProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayersForTeam(teamId);
});

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

  Future<void> fireUserPlayer(String teamId, String playerId) async {
    try {
      await _dio.delete('/user-teams/$teamId/players/$playerId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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
      final response = await _dio.get('/base-rosters/');
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

  Future<List<Map<String, dynamic>>> getPerks() async {
    try {
      final response = await _dio.get('/perks/');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

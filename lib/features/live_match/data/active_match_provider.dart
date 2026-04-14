import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveMatch {
  final String leagueId;
  final String matchId;
  const ActiveMatch({required this.leagueId, required this.matchId});
}

final activeMatchProvider = StateProvider<ActiveMatch?>((ref) => null);

/// Holds IDs of players temporarily hired during the pre-match phase.
/// Keyed by team ID → set of player IDs.
/// Persists across navigation from live match → aftermatch screen.
class TempHiredPlayersData {
  final Map<String, Set<String>> _data = {};

  Set<String> getForTeam(String teamId) => _data.putIfAbsent(teamId, () => {});

  void addPlayer(String teamId, String playerId) {
    _data.putIfAbsent(teamId, () => {}).add(playerId);
  }

  void clear() => _data.clear();

  List<String> allTeamIds() => _data.keys.toList();
}

final tempHiredPlayersProvider =
    StateProvider<TempHiredPlayersData>((ref) => TempHiredPlayersData());

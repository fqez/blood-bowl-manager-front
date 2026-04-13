import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveMatch {
  final String leagueId;
  final String matchId;
  const ActiveMatch({required this.leagueId, required this.matchId});
}

final activeMatchProvider = StateProvider<ActiveMatch?>((ref) => null);

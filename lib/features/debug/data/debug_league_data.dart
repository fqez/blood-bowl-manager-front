import '../../league/domain/models/league.dart';

const debugLeagueId = 'debug-league-8-teams';

League buildDebugLeague() {
  final teams = _debugTeams();
  final matches = buildDebugLeagueMatches();
  final standings = _debugStandings();

  return League(
    id: debugLeagueId,
    name: 'Liga Debug 8 Equipos',
    ownerId: 'debug-commissioner',
    ownerUsername: 'Debug Commissioner',
    status: LeagueStatus.active,
    season: 1,
    currentRound: 2,
    maxTeams: 8,
    format: 'round_robin',
    inviteCode: 'DEBUG8',
    teams: teams,
    standings: standings,
    matches: matches,
    rules: const LeagueRules(startingBudget: 1000000),
    description:
        'Liga local de debug con 8 equipos mock para acelerar pruebas UI.',
    createdAt: DateTime(2026, 1, 1),
    startedAt: DateTime(2026, 1, 8),
  );
}

List<Match> buildDebugLeagueMatches() {
  final teams = _debugTeams();
  final pairings = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7],
    [0, 2],
    [1, 4],
    [3, 6],
    [5, 7],
    [0, 3],
    [1, 5],
    [2, 6],
    [4, 7],
    [0, 4],
    [1, 6],
    [2, 7],
    [3, 5],
    [0, 5],
    [1, 7],
    [2, 4],
    [3, 6],
    [0, 6],
    [1, 2],
    [3, 7],
    [4, 5],
    [0, 7],
    [1, 3],
    [2, 5],
    [4, 6],
  ];

  return List.generate(pairings.length, (index) {
    final round = (index ~/ 4) + 1;
    final pairing = pairings[index];
    final home = teams[pairing[0]];
    final away = teams[pairing[1]];
    final status = round == 1
        ? 'completed'
        : round == 2 && index % 4 == 0
            ? 'in_progress'
            : 'scheduled';
    final isActive = status == 'completed' || status == 'in_progress';
    final startedAt = isActive ? DateTime(2026, 1, 10 + round, 18) : null;
    final events = isActive
        ? _debugMatchEvents(
            matchIndex: index,
            status: status,
            startedAt: startedAt!,
          )
        : const <MatchEvent>[];

    return Match(
      id: 'debug-match-${index + 1}',
      round: round,
      home: MatchTeamInfo(
        teamId: home.teamId,
        teamName: home.teamName,
        userId: home.userId,
        username: home.username,
        baseRosterId: home.baseRosterId,
      ),
      away: MatchTeamInfo(
        teamId: away.teamId,
        teamName: away.teamName,
        userId: away.userId,
        username: away.username,
        baseRosterId: away.baseRosterId,
      ),
      status: status,
      scoreHome: status == 'completed'
          ? events
              .where(
                  (event) => event.type == 'touchdown' && event.team == 'home')
              .length
          : status == 'in_progress'
              ? 1
              : 0,
      scoreAway: status == 'completed'
          ? events
              .where(
                  (event) => event.type == 'touchdown' && event.team == 'away')
              .length
          : 0,
      currentHalf: status == 'in_progress' ? 1 : 0,
      currentTurn: status == 'in_progress' ? 4 : 0,
      rerollsUsedHome: isActive ? 1 + (index % 2) : 0,
      rerollsUsedAway: isActive ? index % 2 : 0,
      gate: isActive ? 11000 + (index * 750) : null,
      events: events,
      scheduledAt: DateTime(2026, 1, 10 + round),
      playedAt: round == 1 ? DateTime(2026, 1, 12) : null,
      startedAt: startedAt,
    );
  });
}

List<MatchEvent> _debugMatchEvents({
  required int matchIndex,
  required String status,
  required DateTime startedAt,
}) {
  final completed = status == 'completed';
  final seed = matchIndex + 1;
  final rawEvents =
      <({String type, String team, int half, int turn, String detail})>[
    (
      type: 'turn_change',
      team: 'home',
      half: 1,
      turn: 1,
      detail: 'Patada inicial'
    ),
    (
      type: 'completion',
      team: 'home',
      half: 1,
      turn: 1,
      detail: 'Pase rapido para salir de la presion'
    ),
    (
      type: 'foul',
      team: seed.isEven ? 'home' : 'away',
      half: 1,
      turn: 1,
      detail: 'Pisoton lejos del arbitro'
    ),
    (
      type: 'completion',
      team: seed.isEven ? 'away' : 'home',
      half: 1,
      turn: 2,
      detail: 'Pase corto completado'
    ),
    (
      type: 'ko',
      team: seed.isEven ? 'home' : 'away',
      half: 1,
      turn: 3,
      detail: 'Bloqueo deja a un rival KO'
    ),
    (
      type: 'turn_change',
      team: 'away',
      half: 1,
      turn: 3,
      detail: 'Turno visitante tras perdida de balon'
    ),
    (
      type: 'completion',
      team: 'away',
      half: 1,
      turn: 4,
      detail: 'Pase a la zona central'
    ),
    (
      type: 'touchdown',
      team: 'home',
      half: 1,
      turn: 4,
      detail: 'Carrera por la banda'
    ),
    (
      type: 'turnover',
      team: 'away',
      half: 1,
      turn: 5,
      detail: 'Cambio de posesion'
    ),
    (
      type: 'ko',
      team: 'away',
      half: 1,
      turn: 6,
      detail: 'Golpe en la linea de scrimmage'
    ),
    (
      type: 'completion',
      team: seed % 2 == 0 ? 'home' : 'away',
      half: 1,
      turn: 7,
      detail: 'Pase largo bajo lluvia de placajes'
    ),
    (
      type: 'turn_change',
      team: 'home',
      half: 1,
      turn: 8,
      detail: 'Ultimo turno de la primera parte'
    ),
    (
      type: 'casualty',
      team: seed % 3 == 0 ? 'away' : 'home',
      half: 2,
      turn: 1,
      detail: 'Bloqueo de apertura con lesion'
    ),
    (
      type: 'turn_change',
      team: 'away',
      half: 2,
      turn: 1,
      detail: 'Recepcion de segunda parte'
    ),
    (
      type: 'completion',
      team: 'away',
      half: 2,
      turn: 2,
      detail: 'Pase seguro al corredor'
    ),
    (
      type: 'foul',
      team: 'away',
      half: 2,
      turn: 3,
      detail: 'Falta sobre jugador derribado'
    ),
    (
      type: 'ko',
      team: seed % 2 == 0 ? 'away' : 'home',
      half: 2,
      turn: 3,
      detail: 'Empujon contra la banda'
    ),
    (
      type: 'interception',
      team: 'home',
      half: 2,
      turn: 4,
      detail: 'Intercepcion en medio campo'
    ),
    (
      type: 'touchdown',
      team: seed % 2 == 0 ? 'away' : 'home',
      half: 2,
      turn: 5,
      detail: 'Cambio de ritmo antes de anotar'
    ),
    (
      type: 'touchdown',
      team: seed % 2 == 0 ? 'away' : 'home',
      half: 2,
      turn: 6,
      detail: 'Anotacion final'
    ),
    (
      type: 'casualty',
      team: seed.isEven ? 'home' : 'away',
      half: 2,
      turn: 7,
      detail: 'Ultimo bloqueo con conmocion'
    ),
    (
      type: 'turnover',
      team: seed.isEven ? 'home' : 'away',
      half: 2,
      turn: 8,
      detail: 'Ultima perdida del partido'
    ),
  ];
  final visibleEvents = completed ? rawEvents : rawEvents.take(10).toList();

  return List.generate(visibleEvents.length, (index) {
    final event = visibleEvents[index];
    final minute =
        ((event.half - 1) * 45 + ((event.turn - 1) * 45 / 8) + 3).round();
    return MatchEvent(
      id: 'debug-match-${matchIndex + 1}-event-${index + 1}',
      type: event.type,
      team: event.team,
      playerName: _debugPlayerName(seed, event.team, index),
      detail: event.detail,
      half: event.half,
      turn: event.turn,
      timestamp: startedAt.add(Duration(minutes: minute)),
      createdByName: event.team == 'home' ? 'Coach local' : 'Coach visitante',
    );
  });
}

String _debugPlayerName(int seed, String team, int index) {
  final homeNames = ['Griff', 'Mighty Zug', 'Helmut', 'Karla', 'Morg'];
  final awayNames = ['Varag', 'Hakflem', 'Eldril', 'Glart', 'Ripper'];
  final names = team == 'home' ? homeNames : awayNames;
  return names[(seed + index) % names.length];
}

List<LeagueTeam> _debugTeams() {
  const data = [
    ('debug-team-1', 'Reikland Reavers', 'human', 'Francho'),
    ('debug-team-2', 'Middenheim Maulers', 'human', 'Marta'),
    ('debug-team-3', 'Karak Crushers', 'dwarf', 'Iker'),
    ('debug-team-4', 'Naggaroth Nightmares', 'dark_elf', 'Lucia'),
    ('debug-team-5', 'Skavenblight Runners', 'skaven', 'Diego'),
    ('debug-team-6', 'Greenfield Stompers', 'orc', 'Sara'),
    ('debug-team-7', 'Athel Loren Arrows', 'wood_elf', 'Alex'),
    ('debug-team-8', 'Nurgle Rotters', 'nurgle', 'Nerea'),
  ];

  return data
      .map(
        (team) => LeagueTeam(
          teamId: team.$1,
          teamName: team.$2,
          userId: 'debug-user-${team.$1.split('-').last}',
          username: team.$4,
          baseRosterId: team.$3,
          joinedAt: DateTime(2026, 1, 2),
        ),
      )
      .toList();
}

List<LeagueStanding> _debugStandings() {
  final teams = _debugTeams();
  final records = [
    (3, 0, 0, 9, 7, 2, 5, 5, 1),
    (2, 1, 0, 7, 5, 2, 3, 4, 2),
    (2, 0, 1, 6, 4, 3, 1, 6, 4),
    (1, 2, 0, 5, 3, 2, 1, 2, 1),
    (1, 1, 1, 4, 4, 4, 0, 3, 3),
    (1, 0, 2, 3, 2, 5, -3, 5, 6),
    (0, 1, 2, 1, 2, 5, -3, 1, 4),
    (0, 1, 2, 1, 1, 5, -4, 4, 9),
  ];

  return List.generate(teams.length, (index) {
    final team = teams[index];
    final record = records[index];
    return LeagueStanding(
      teamId: team.teamId,
      teamName: team.teamName,
      wins: record.$1,
      draws: record.$2,
      losses: record.$3,
      points: record.$4,
      touchdownsFor: record.$5,
      touchdownsAgainst: record.$6,
      touchdownDiff: record.$7,
      casualtiesFor: record.$8,
      casualtiesAgainst: record.$9,
      gamesPlayed: record.$1 + record.$2 + record.$3,
    );
  });
}

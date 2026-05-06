import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';
import '../../../live_match/data/active_match_provider.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/match_event_dialog.dart';

// ─── Provider ───────────────────────────────────────────────

final _matchDetailProvider =
    FutureProvider.family<Match, ({String leagueId, String matchId})>(
        (ref, p) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getMatchDetail(p.leagueId, p.matchId);
});

final _quickMatchDetailProvider =
    FutureProvider.family<Match, String>((ref, matchId) async {
  final repo = ref.read(quickMatchRepositoryProvider);
  return repo.getMatchDetail(matchId);
});

// ─── Helper classes ─────────────────────────────────────────

class _SppTally {
  final String playerId;
  final String playerName;
  final String team;
  int completions = 0;
  int touchdowns = 0;
  int casualties = 0;
  int interceptions = 0;
  int throwTeammate = 0;
  bool mvp = false;
  int bonus = 0;

  _SppTally(this.playerId, this.playerName, this.team);

  int get total =>
      completions * 1 +
      interceptions * 2 +
      casualties * 2 +
      touchdowns * 3 +
      throwTeammate +
      (mvp ? 4 : 0) +
      bonus;
}

class _InjuryEntry {
  final String playerId;
  final String playerName;
  final String team;
  final String type;

  _InjuryEntry({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.type,
  });

  String get injuryLabel {
    switch (type) {
      case 'badly_hurt':
        return 'Badly Hurt';
      case 'miss_next_game':
        return 'Miss Next Game';
      case 'niggling_injury':
        return 'Niggling Injury';
      case 'stat_decrease':
        return 'Stat Decrease';
      case 'dead':
        return 'Dead';
      default:
        return type;
    }
  }

  Color get injuryColor {
    switch (type) {
      case 'badly_hurt':
        return AppColors.warning;
      case 'miss_next_game':
        return AppColors.warning;
      case 'niggling_injury':
        return AppColors.error;
      case 'stat_decrease':
        return AppColors.error;
      case 'dead':
        return AppColors.primaryDark;
      default:
        return AppColors.textMuted;
    }
  }
}

class _BonusSppEntry {
  final String playerId;
  final String playerName;
  final String team;
  final int amount;
  final String? description;

  _BonusSppEntry({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.amount,
    this.description,
  });
}

class _ScoreboardTeamSide extends StatelessWidget {
  const _ScoreboardTeamSide({
    required this.teamName,
    required this.label,
    required this.color,
    required this.rosterId,
    required this.teamNameSize,
    required this.alignEnd,
    required this.compact,
  });

  final String teamName;
  final String label;
  final Color color;
  final String rosterId;
  final double teamNameSize;
  final bool alignEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: color,
            fontSize: compact ? 11 : 14,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? 1.4 : 2,
          ),
        ),
        SizedBox(height: compact ? 7 : 10),
        Text(
          teamName,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: teamNameSize,
            fontWeight: FontWeight.w900,
            height: 1.02,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TeamLogoMark(
            rosterId: rosterId,
            fallbackLabel: teamName,
            color: color,
            size: 56,
          ),
          const SizedBox(height: 10),
          text,
        ],
      );
    }

    final children = [
      _TeamLogoMark(
        rosterId: rosterId,
        fallbackLabel: teamName,
        color: color,
        size: 82,
      ),
      const SizedBox(width: 18),
      Expanded(child: text),
    ];

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

class _TeamLogoMark extends StatelessWidget {
  const _TeamLogoMark({
    required this.rosterId,
    required this.fallbackLabel,
    required this.color,
    required this.size,
  });

  final String rosterId;
  final String fallbackLabel;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackLabel.trim().isEmpty
        ? '?'
        : fallbackLabel.trim().characters.first.toUpperCase();

    Widget fallback() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.5),
                AppColors.surface.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.58), width: 2),
          ),
          child: Text(
            initial,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              color: AppColors.textPrimary,
              fontSize: size * 0.44,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

    if (rosterId.isEmpty) return fallback();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/teams/$rosterId/logo.webp',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}

class _ScoreboardScoreline extends StatelessWidget {
  const _ScoreboardScoreline({
    required this.homeScore,
    required this.awayScore,
    required this.scoreSize,
    required this.compact,
  });

  final int homeScore;
  final int awayScore;
  final double scoreSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScoreDigit(
          score: homeScore,
          color: AppColors.textPrimary,
          size: scoreSize,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
          child: Container(
            width: compact ? 24 : 36,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.textPrimary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ),
        _ScoreDigit(
          score: awayScore,
          color: AppColors.textPrimary,
          size: scoreSize,
        ),
      ],
    );
  }
}

class _ScoreDigit extends StatelessWidget {
  const _ScoreDigit({
    required this.score,
    required this.color,
    required this.size,
  });

  final int score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$score',
      style: TextStyle(
        fontFamily: AppTypography.displayFontFamily,
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 0.82,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 26,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _InfoIconButton extends StatelessWidget {
  const _InfoIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Icon(
              PhosphorIcons.info(),
              color: Colors.white.withValues(alpha: 0.82),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────

class AftermatchScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String matchId;
  final bool isQuickMatch;
  final int? debugRandomSeed;

  const AftermatchScreen({
    super.key,
    required this.leagueId,
    required this.matchId,
    this.isQuickMatch = false,
    this.debugRandomSeed,
  });

  @override
  ConsumerState<AftermatchScreen> createState() => _AftermatchScreenState();
}

class _AftermatchScreenState extends ConsumerState<AftermatchScreen> {
  late final bool _isQM = widget.isQuickMatch;
  late final String leagueId = widget.leagueId;
  late final String matchId = widget.matchId;

  UserTeamDetail? _homeTeam;
  UserTeamDetail? _awayTeam;

  int _scoreHome = 0;
  int _scoreAway = 0;
  int _tdHome = 0;
  int _tdAway = 0;
  int _casHome = 0;
  int _casAway = 0;
  int _compHome = 0;
  int _compAway = 0;
  int _intHome = 0;
  int _intAway = 0;
  int _foulHome = 0;
  int _foulAway = 0;
  int _koHome = 0;
  int _koAway = 0;
  int _rerollsHome = 0;
  int _rerollsAway = 0;
  int _gate = 0;

  // ── Section 2: Winnings ──
  int _homeFanFactor = 1;
  int _awayFanFactor = 1;
  bool _homeStalling = false;
  bool _awayStalling = false;
  int? _homeWinnings;
  int? _awayWinnings;

  // ── Section 3: Dedicated Fans ──
  int? _homeFanRoll;
  int? _awayFanRoll;
  int _homeDedicatedFans = 1;
  int _awayDedicatedFans = 1;

  // ── Section 4: MVP ──
  String? _mvpHomeId;
  String? _mvpAwayId;

  // ── Section 5: Injuries ──
  final List<_InjuryEntry> _injuries = [];

  // ── Section 6: Expensive Mistakes ──
  int? _homeExpensiveRoll;
  int? _awayExpensiveRoll;
  String? _homeExpensiveResult;
  String? _awayExpensiveResult;
  int? _homeExpensiveD3;
  int? _awayExpensiveD3;
  int? _homeCatastropheD6A;
  int? _homeCatastropheD6B;
  int? _awayCatastropheD6A;
  int? _awayCatastropheD6B;

  // ── Section 7: Bonus SPP ──
  final List<_BonusSppEntry> _bonusSpp = [];
  final List<MatchEvent> _postMatchEvents = [];

  bool _initialized = false;
  bool _submitting = false;

  TextStyle get _displayLarge => TextStyle(
        fontFamily: AppTypography.displayFontFamily,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        height: 0.95,
      );

  void _initFromMatch(Match match) {
    if (_initialized) return;
    _initialized = true;

    _scoreHome = match.scoreHome;
    _scoreAway = match.scoreAway;
    _gate = match.gate ?? 0;
    _rerollsHome = match.rerollsUsedHome;
    _rerollsAway = match.rerollsUsedAway;
    _mvpHomeId = match.mvpHome;
    _mvpAwayId = match.mvpAway;

    for (final e in match.events) {
      final isHome = e.team == 'home';
      final eventType = e.type.toLowerCase();
      if (eventType == 'stall' || eventType == 'stalling') {
        isHome ? _homeStalling = true : _awayStalling = true;
      }

      switch (eventType) {
        case 'touchdown':
          isHome ? _tdHome++ : _tdAway++;
        case 'casualty':
          isHome ? _casHome++ : _casAway++;
        case 'completion':
          isHome ? _compHome++ : _compAway++;
        case 'interception':
          isHome ? _intHome++ : _intAway++;
        case 'foul':
          isHome ? _foulHome++ : _foulAway++;
        case 'ko':
          isHome ? _koHome++ : _koAway++;
      }
    }

    if (widget.debugRandomSeed != null) {
      _applyDebugRandomData(widget.debugRandomSeed!);
    }
  }

  void _applyDebugRandomData(int seed) {
    final random = Random(seed);
    _scoreHome = random.nextInt(5);
    _scoreAway = random.nextInt(5);
    if (_scoreHome == 0 && _scoreAway == 0) _scoreHome = 1;

    _tdHome = _scoreHome;
    _tdAway = _scoreAway;
    _casHome = random.nextInt(4);
    _casAway = random.nextInt(4);
    _compHome = random.nextInt(7);
    _compAway = random.nextInt(7);
    _intHome = random.nextInt(2);
    _intAway = random.nextInt(2);
    _foulHome = random.nextInt(4);
    _foulAway = random.nextInt(4);
    _koHome = random.nextInt(5);
    _koAway = random.nextInt(5);
    _rerollsHome = random.nextInt(4);
    _rerollsAway = random.nextInt(4);
    _gate = 8000 + random.nextInt(17000);
    _homeStalling = random.nextBool();
    _awayStalling = random.nextBool();
  }

  Future<void> _loadTeams(Match match) async {
    if (_homeTeam != null) return;
    final repo = ref.read(teamRepositoryProvider);
    final results = await Future.wait([
      repo.getUserTeamDetail(match.home.teamId),
      repo.getUserTeamDetail(match.away.teamId),
    ]);
    if (!mounted) return;
    setState(() {
      _homeTeam = results[0];
      _awayTeam = results[1];
      _homeFanFactor = results[0].dedicatedFans;
      _awayFanFactor = results[1].dedicatedFans;
      _homeDedicatedFans = results[0].dedicatedFans;
      _awayDedicatedFans = results[1].dedicatedFans;
    });
  }

  double _winningsFanBase(int fanFactorHome, int fanFactorAway) {
    return (fanFactorHome + fanFactorAway) / 2;
  }

  int _calcWinnings(
      int fanFactorHome, int fanFactorAway, int myTDs, bool stalling) {
    final base = _winningsFanBase(fanFactorHome, fanFactorAway);
    final stall = stalling ? 0 : 1;
    return ((base + myTDs + stall) * 10000).round();
  }

  Color _expensiveColor(String code) {
    switch (code) {
      case 'crisis_avoided':
        return AppColors.success;
      case 'minor_incident':
        return AppColors.info;
      case 'major_incident':
        return AppColors.warning;
      case 'catastrophe':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  int? _expensiveFinalTreasury({
    required ExpensiveMistakesRules rules,
    required int treasury,
    required String? result,
    required int? d3,
    required int? d6A,
    required int? d6B,
  }) {
    if (treasury < rules.minTreasury) return treasury;
    if (result == null) return null;
    final effect = rules.effects[result];
    switch (effect?.calculation ?? 'none') {
      case 'lose_d3_x_10000':
        if (d3 == null) return null;
        return max(0, treasury - (d3.clamp(1, 3).toInt() * 10000));
      case 'lose_half_round_down_5000':
        final loss = ((treasury / 2) ~/ 5000) * 5000;
        return max(0, treasury - loss);
      case 'keep_2d6_x_10000':
        if (d6A == null || d6B == null) return null;
        return min(treasury,
            (d6A.clamp(1, 6).toInt() + d6B.clamp(1, 6).toInt()) * 10000);
      case 'none':
      default:
        return treasury;
    }
  }

  void _clearHomeExpensiveExtraDice() {
    _homeExpensiveD3 = null;
    _homeCatastropheD6A = null;
    _homeCatastropheD6B = null;
  }

  void _clearAwayExpensiveExtraDice() {
    _awayExpensiveD3 = null;
    _awayCatastropheD6A = null;
    _awayCatastropheD6B = null;
  }

  void _setPostMatchStat(String type, String team, int value) {
    setState(() {
      switch ('$team:$type') {
        case 'home:touchdown':
          _tdHome = value;
          _scoreHome = value;
        case 'away:touchdown':
          _tdAway = value;
          _scoreAway = value;
        case 'home:casualty':
          _casHome = value;
        case 'away:casualty':
          _casAway = value;
        case 'home:completion':
          _compHome = value;
        case 'away:completion':
          _compAway = value;
        case 'home:interception':
          _intHome = value;
        case 'away:interception':
          _intAway = value;
        case 'home:foul':
          _foulHome = value;
        case 'away:foul':
          _foulAway = value;
        case 'home:ko':
          _koHome = value;
        case 'away:ko':
          _koAway = value;
        case 'home:reroll':
          _rerollsHome = value;
        case 'away:reroll':
          _rerollsAway = value;
      }
    });
  }

  void _removeLastPostMatchEvent(String type, String team) {
    for (var i = _postMatchEvents.length - 1; i >= 0; i--) {
      final event = _postMatchEvents[i];
      if (event.type == type && event.team == team) {
        _postMatchEvents.removeAt(i);
        return;
      }
    }
  }

  Future<void> _handlePostMatchStatChanged({
    required Match match,
    required String type,
    required String team,
    required int currentValue,
    required int nextValue,
  }) async {
    if (nextValue <= currentValue) {
      setState(() {
        _removeLastPostMatchEvent(type, team);
      });
      _setPostMatchStat(type, team, nextValue);
      return;
    }

    final lang = ref.read(localeProvider);
    await showMatchEventDialog(
      context: context,
      match: match,
      lang: lang,
      eventType: type,
      initialTeam: team,
      allowTeamSelection: false,
      homePlayers: _playedPlayers(_homeTeam?.players ?? [], match.homeSquad),
      awayPlayers: _playedPlayers(_awayTeam?.players ?? [], match.awaySquad),
      onAdd: (draft) {
        _addPostMatchEvent(draft);
        _setPostMatchStat(type, team, nextValue);
      },
    );
  }

  List<Map<String, dynamic>> _sppDeltasFor(
      Map<String, _SppTally> sppMap, String team) {
    return sppMap.values
        .where((tally) => tally.team == team && tally.total > 0)
        .map((tally) => {
              'player_id': tally.playerId,
              'spp': tally.total,
              'completions': tally.completions,
              'touchdowns': tally.touchdowns,
              'casualties': tally.casualties,
              'interceptions': tally.interceptions,
              'mvp': tally.mvp,
              'bonus_spp': tally.bonus,
            })
        .toList();
  }

  List<Map<String, dynamic>> _postMatchEventPayloads() {
    return _postMatchEvents
        .map((event) => {
              'type': event.type,
              'team': event.team,
              if (event.playerId != null) 'player_id': event.playerId,
              if (event.playerName != null) 'player_name': event.playerName,
              if (event.victimId != null) 'victim_id': event.victimId,
              if (event.victimName != null) 'victim_name': event.victimName,
              if (event.injury != null) 'injury': event.injury,
              if (event.detail != null) 'detail': event.detail,
              'half': event.half,
              'turn': event.turn,
            })
        .toList();
  }

  void _addPostMatchEvent(MatchEventDraft draft) {
    setState(() {
      _postMatchEvents.add(MatchEvent(
        id: 'postmatch-${DateTime.now().microsecondsSinceEpoch}',
        type: draft.type,
        team: draft.team,
        playerId: draft.playerId,
        playerName: draft.playerName,
        victimId: draft.victimId,
        victimName: draft.victimName,
        injury: draft.injury,
        detail: draft.detail,
        half: draft.half,
        turn: draft.turn,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _submitAfterMatch(Match match) async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(leagueRepositoryProvider);
      await repo.updateMatchState(
        leagueId,
        matchId,
        mvpHome: _mvpHomeId,
        mvpAway: _mvpAwayId,
        gate: _gate,
      );

      final teamRepo = ref.read(teamRepositoryProvider);
      final rules = ref.read(expensiveMistakesRulesProvider).valueOrNull;
      if (rules == null) {
        throw Exception('Reglas de errores costosos no cargadas');
      }
      final homeFans = _nextDedicatedFans(
        currentFans: _homeDedicatedFans,
        roll: _homeFanRoll,
        won: _scoreHome > _scoreAway,
        lost: _scoreHome < _scoreAway,
      );
      final awayFans = _nextDedicatedFans(
        currentFans: _awayDedicatedFans,
        roll: _awayFanRoll,
        won: _scoreAway > _scoreHome,
        lost: _scoreAway < _scoreHome,
      );
      final homeTreasury = (_homeTeam?.treasury ?? 0) +
          (_homeWinnings ??
              _calcWinnings(
                  _homeFanFactor, _awayFanFactor, _tdHome, _homeStalling));
      final awayTreasury = (_awayTeam?.treasury ?? 0) +
          (_awayWinnings ??
              _calcWinnings(
                  _awayFanFactor, _homeFanFactor, _tdAway, _awayStalling));
      final homeFinalTreasury = _expensiveFinalTreasury(
        rules: rules,
        treasury: homeTreasury,
        result: _homeExpensiveRoll == null
            ? null
            : rules.resultFor(homeTreasury, _homeExpensiveRoll!),
        d3: _homeExpensiveD3,
        d6A: _homeCatastropheD6A,
        d6B: _homeCatastropheD6B,
      );
      final awayFinalTreasury = _expensiveFinalTreasury(
        rules: rules,
        treasury: awayTreasury,
        result: _awayExpensiveRoll == null
            ? null
            : rules.resultFor(awayTreasury, _awayExpensiveRoll!),
        d3: _awayExpensiveD3,
        d6A: _awayCatastropheD6A,
        d6B: _awayCatastropheD6B,
      );
      if (homeFinalTreasury == null || awayFinalTreasury == null) {
        throw Exception('Completa las tiradas de errores costosos');
      }
      if (_homeTeam != null) {
        await teamRepo.patchTeamStaff(
          _homeTeam!.id,
          dedicatedFans: homeFans,
          treasury: homeFinalTreasury,
        );
      }
      if (_awayTeam != null) {
        await teamRepo.patchTeamStaff(
          _awayTeam!.id,
          dedicatedFans: awayFans,
          treasury: awayFinalTreasury,
        );
      }

      final sppMap = _buildSppTallies(match);
      await repo.applyAftermatchSpp(
        leagueId: leagueId,
        matchId: matchId,
        home: _sppDeltasFor(sppMap, 'home'),
        away: _sppDeltasFor(sppMap, 'away'),
        postMatchEvents: _postMatchEventPayloads(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post-match report submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/league/$leagueId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final matchAsync = _isQM
        ? ref.watch(_quickMatchDetailProvider(matchId))
        : ref.watch(
            _matchDetailProvider((leagueId: leagueId, matchId: matchId)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: matchAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (match) {
          if (!match.isPlayed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (_isQM) {
                  context.go('/quick-match/$matchId/live');
                } else {
                  context.go('/league/$leagueId/match/$matchId/live');
                }
              }
            });
            return const SizedBox.shrink();
          }
          _initFromMatch(match);
          if (!_isQM) {
            _loadTeams(match);
          } else {
            // Load teams for QM if there are temp-hired players to resolve
            final tempData = ref.read(tempHiredPlayersProvider);
            final hasTempPlayers =
                tempData.getForTeam(match.home.teamId).isNotEmpty ||
                    tempData.getForTeam(match.away.teamId).isNotEmpty;
            if (hasTempPlayers) _loadTeams(match);
          }
          return _buildBody(match);
        },
      ),
    );
  }

  Widget _buildBody(Match match) {
    final wide = MediaQuery.of(context).size.width >= 900;

    // Quick match: show only statistics + back button
    if (_isQM) {
      return Column(
        children: [
          _buildAppBar(match),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 64 : 16,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMatchStatsSection(match),
                  const SizedBox(height: 28),
                  _buildTempHiredPlayersSection(match),
                  const SizedBox(height: 36),
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/quick-match'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Volver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // League match: full aftermatch with all sections
    return Column(
      children: [
        _buildAppBar(match),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 64 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMatchStatsSection(match),
                const SizedBox(height: 28),
                _buildWinningsSection(),
                const SizedBox(height: 28),
                _buildDedicatedFansSection(),
                const SizedBox(height: 28),
                _buildMvpSection(match),
                const SizedBox(height: 28),
                _buildExpensiveMistakesSection(),
                const SizedBox(height: 28),
                _buildTempHiredPlayersSection(match),
                const SizedBox(height: 36),
                _buildSubmitButton(match),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar(Match match) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final lang = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                            PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                            color: AppColors.textPrimary),
                        onPressed: _showExitDialog,
                      ),
                      const SizedBox(width: 4),
                      Icon(PhosphorIcons.scroll(PhosphorIconsStyle.fill),
                          color: AppColors.accent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr(lang, 'aftermatch.reportTitle').toUpperCase(),
                          style: _displayLarge.copyWith(
                              fontSize: 24, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 52, top: 4),
                    child: Text(
                      trf(lang, 'aftermatch.matchVersus', {
                        'home': match.home.teamName,
                        'away': match.away.teamName,
                      }),
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                        color: AppColors.textPrimary),
                    onPressed: _showExitDialog,
                  ),
                  const SizedBox(width: 8),
                  Icon(PhosphorIcons.scroll(PhosphorIconsStyle.fill),
                      color: AppColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(lang, 'aftermatch.reportTitle').toUpperCase(),
                      style: _displayLarge.copyWith(
                          fontSize: 28, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      trf(lang, 'aftermatch.matchVersus', {
                        'home': match.home.teamName,
                        'away': match.away.teamName,
                      }),
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 1: Match Statistics
  // ═══════════════════════════════════════════════════════════

  Widget _buildMatchStatsSection(Match match) {
    final lang = ref.watch(localeProvider);

    return _sectionCard(
      icon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
      title: tr(lang, 'aftermatch.matchResultTitle').toUpperCase(),
      color: AppColors.info,
      showHeader: false,
      child: Column(
        children: [
          _buildResultBanner(match),
          const SizedBox(height: 22),

          // Stats grid
          _statRow(tr(lang, 'aftermatch.touchdowns'), _tdHome, _tdAway,
              AppColors.accent, PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'touchdown',
                    team: 'home',
                    currentValue: _tdHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'touchdown',
                    team: 'away',
                    currentValue: _tdAway,
                    nextValue: v,
                  )),
          _statRow(tr(lang, 'aftermatch.casualties'), _casHome, _casAway,
              AppColors.error, PhosphorIcons.skull(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'casualty',
                    team: 'home',
                    currentValue: _casHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'casualty',
                    team: 'away',
                    currentValue: _casAway,
                    nextValue: v,
                  )),
          _statRow(
              tr(lang, 'aftermatch.completions'),
              _compHome,
              _compAway,
              AppColors.info,
              PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'completion',
                    team: 'home',
                    currentValue: _compHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'completion',
                    team: 'away',
                    currentValue: _compAway,
                    nextValue: v,
                  )),
          _statRow(
              tr(lang, 'aftermatch.interceptions'),
              _intHome,
              _intAway,
              AppColors.success,
              PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'interception',
                    team: 'home',
                    currentValue: _intHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'interception',
                    team: 'away',
                    currentValue: _intAway,
                    nextValue: v,
                  )),
          _statRow(
              tr(lang, 'aftermatch.fouls'),
              _foulHome,
              _foulAway,
              AppColors.primaryLight,
              PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'foul',
                    team: 'home',
                    currentValue: _foulHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'foul',
                    team: 'away',
                    currentValue: _foulAway,
                    nextValue: v,
                  )),
          _statRow(
              tr(lang, 'aftermatch.kos'),
              _koHome,
              _koAway,
              AppColors.warning,
              PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'ko',
                    team: 'home',
                    currentValue: _koHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'ko',
                    team: 'away',
                    currentValue: _koAway,
                    nextValue: v,
                  )),
          _statRow(
              tr(lang, 'aftermatch.rerollsUsed'),
              _rerollsHome,
              _rerollsAway,
              AppColors.accent,
              PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _rerollsHome = v),
              onAwayChanged: (v) => setState(() => _rerollsAway = v)),

          const SizedBox(height: 10),
          _postMatchActionButtons(match, lang),
          const SizedBox(height: 10),
          _stallingRow(lang),
          const SizedBox(height: 12),
          // Gate
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                  size: 22, color: AppColors.accent),
              Text(tr(lang, 'aftermatch.gate'),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                width: 140,
                child: _numField(_gate, (v) => setState(() => _gate = v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postMatchActionButtons(Match match, String lang) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          icon: Icon(PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
              size: 18, color: AppColors.info),
          label: const Text(
            'Lanzar compañero',
            style: TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.info.withValues(alpha: 0.42)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => showMatchEventDialog(
            context: context,
            match: match,
            lang: lang,
            eventType: 'throw_teammate',
            homePlayers:
                _playedPlayers(_homeTeam?.players ?? [], match.homeSquad),
            awayPlayers:
                _playedPlayers(_awayTeam?.players ?? [], match.awaySquad),
            onAdd: _addPostMatchEvent,
          ),
        ),
      ],
    );
  }

  Widget _buildResultBanner(Match match) {
    final lang = ref.watch(localeProvider);
    final homeWon = _scoreHome > _scoreAway;
    final awayWon = _scoreAway > _scoreHome;
    final resultText = homeWon
        ? trf(lang, 'aftermatch.teamWins', {'team': match.home.teamName})
        : awayWon
            ? trf(lang, 'aftermatch.teamWins', {'team': match.away.teamName})
            : tr(lang, 'aftermatch.draw');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final scoreSize = isCompact ? 88.0 : 132.0;
        final teamNameSize = isCompact ? 18.0 : 30.0;
        final homeRosterId = match.home.baseRosterId.isNotEmpty
            ? match.home.baseRosterId
            : _homeTeam?.baseRosterId ?? '';
        final awayRosterId = match.away.baseRosterId.isNotEmpty
            ? match.away.baseRosterId
            : _awayTeam?.baseRosterId ?? '';

        final content = isCompact
            ? Column(
                children: [
                  _ScoreboardScoreline(
                    homeScore: _scoreHome,
                    awayScore: _scoreAway,
                    scoreSize: scoreSize,
                    compact: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ScoreboardTeamSide(
                          teamName: match.home.teamName,
                          label: tr(lang, 'aftermatch.home').toUpperCase(),
                          color: AppColors.info,
                          rosterId: homeRosterId,
                          teamNameSize: teamNameSize,
                          alignEnd: false,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _ScoreboardTeamSide(
                          teamName: match.away.teamName,
                          label: tr(lang, 'aftermatch.away').toUpperCase(),
                          color: AppColors.error,
                          rosterId: awayRosterId,
                          teamNameSize: teamNameSize,
                          alignEnd: true,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _ScoreboardTeamSide(
                      teamName: match.home.teamName,
                      label: tr(lang, 'aftermatch.home').toUpperCase(),
                      color: AppColors.info,
                      rosterId: homeRosterId,
                      teamNameSize: teamNameSize,
                      alignEnd: false,
                      compact: false,
                    ),
                  ),
                  const SizedBox(width: 28),
                  _ScoreboardScoreline(
                    homeScore: _scoreHome,
                    awayScore: _scoreAway,
                    scoreSize: scoreSize,
                    compact: false,
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: _ScoreboardTeamSide(
                      teamName: match.away.teamName,
                      label: tr(lang, 'aftermatch.away').toUpperCase(),
                      color: AppColors.error,
                      rosterId: awayRosterId,
                      teamNameSize: teamNameSize,
                      alignEnd: true,
                      compact: false,
                    ),
                  ),
                ],
              );

        return Container(
          padding: EdgeInsets.all(isCompact ? 18 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.info.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.22),
                AppColors.error.withValues(alpha: 0.18),
                AppColors.surface.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                resultText.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isCompact ? 15 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isCompact ? 18 : 26),
              content,
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(
    String label,
    int homeVal,
    int awayVal,
    Color color,
    IconData icon, {
    required ValueChanged<int> onHomeChanged,
    required ValueChanged<int> onAwayChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _miniCounter(homeVal, onHomeChanged, AppColors.info),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 9),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          _miniCounter(awayVal, onAwayChanged, AppColors.error),
        ],
      ),
    );
  }

  Widget _miniCounter(int value, ValueChanged<int> onChanged, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(PhosphorIcons.minus(PhosphorIconsStyle.bold),
            value > 0 ? () => onChanged(value - 1) : null),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.displayFontFamily)),
        ),
        _miniBtn(PhosphorIcons.plus(PhosphorIconsStyle.bold),
            () => onChanged(value + 1)),
      ],
    );
  }

  Widget _stallingRow(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _stallingCheck(
            value: _homeStalling,
            color: AppColors.info,
            onChanged: (v) => setState(() => _homeStalling = v),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.handPalm(PhosphorIconsStyle.fill),
                  size: 19, color: AppColors.warning),
              const SizedBox(width: 9),
              Text(
                tr(lang, 'aftermatch.stalling'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _stallingCheck(
            value: _awayStalling,
            color: AppColors.error,
            onChanged: (v) => setState(() => _awayStalling = v),
          ),
        ],
      ),
    );
  }

  Widget _stallingCheck({
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 78,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.18)
              : AppColors.surface.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                value ? color.withValues(alpha: 0.65) : AppColors.surfaceLight,
          ),
        ),
        child: Icon(
          value
              ? PhosphorIcons.check(PhosphorIconsStyle.bold)
              : PhosphorIcons.x(PhosphorIconsStyle.bold),
          size: 18,
          color: value ? color : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 2: Winnings
  // ═══════════════════════════════════════════════════════════

  Widget _buildWinningsSection() {
    _homeWinnings =
        _calcWinnings(_homeFanFactor, _awayFanFactor, _tdHome, _homeStalling);
    _awayWinnings =
        _calcWinnings(_awayFanFactor, _homeFanFactor, _tdAway, _awayStalling);
    final lang = ref.watch(localeProvider);

    return _sectionCard(
      icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
      title: tr(lang, 'aftermatch.winningsTitle').toUpperCase(),
      color: AppColors.accent,
      centerTitle: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;

          final home = _winningsTeamCol(
            teamName: _homeTeam?.name ?? 'Home',
            myFanFactor: _homeFanFactor,
            opponentFanFactor: _awayFanFactor,
            touchdowns: _tdHome,
            stalling: _homeStalling,
            winnings: _homeWinnings!,
            color: AppColors.info,
          );

          final away = _winningsTeamCol(
            teamName: _awayTeam?.name ?? 'Away',
            myFanFactor: _awayFanFactor,
            opponentFanFactor: _homeFanFactor,
            touchdowns: _tdAway,
            stalling: _awayStalling,
            winnings: _awayWinnings!,
            color: AppColors.error,
          );

          if (isCompact) {
            return Column(
              children: [
                home,
                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceLight, height: 1),
                const SizedBox(height: 16),
                away,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: home),
              Container(width: 1, height: 120, color: AppColors.surfaceLight),
              Expanded(child: away),
            ],
          );
        },
      ),
    );
  }

  Widget _winningsTeamCol({
    required String teamName,
    required int myFanFactor,
    required int opponentFanFactor,
    required int touchdowns,
    required bool stalling,
    required int winnings,
    required Color color,
  }) {
    final lang = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _InfoIconButton(
                onTap: () => _showWinningsInfo(
                  teamName: teamName,
                  myFanFactor: myFanFactor,
                  opponentFanFactor: opponentFanFactor,
                  touchdowns: touchdowns,
                  stalling: stalling,
                  winnings: winnings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_fmtGold(winnings)} ${tr(lang, 'aftermatch.gp')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 74,
                fontWeight: FontWeight.w900,
                fontFamily: AppTypography.displayFontFamily,
                height: 0.86,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.55),
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stalling
                    ? PhosphorIcons.warningCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: 17,
                color: stalling ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                stalling
                    ? tr(lang, 'aftermatch.stallingYes')
                    : tr(lang, 'aftermatch.stallingNo'),
                style: TextStyle(
                  color: stalling ? AppColors.warning : AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWinningsInfo({
    required String teamName,
    required int myFanFactor,
    required int opponentFanFactor,
    required int touchdowns,
    required bool stalling,
    required int winnings,
  }) {
    final lang = ref.read(localeProvider);
    final fanBase = _winningsFanBase(myFanFactor, opponentFanFactor);
    final stallBonus = stalling ? 0 : 1;
    final fanBaseText = _fmtDecimal(fanBase);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.42),
                ),
              ),
              child: Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                trf(lang, 'aftermatch.winningsCalcTitle', {'team': teamName}),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.surface.withValues(alpha: 0.86),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_fmtGold(winnings)} ${tr(lang, 'aftermatch.gp')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 42,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppTypography.displayFontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '($fanBaseText + $touchdowns + $stallBonus) × 10,000',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _winningsCalcLine(
              tr(lang, 'aftermatch.currentFanFactor'),
              '$myFanFactor',
            ),
            _winningsCalcLine(
              tr(lang, 'aftermatch.opponentFanFactor'),
              '$opponentFanFactor',
            ),
            _winningsCalcLine(
              tr(lang, 'aftermatch.fanFactorBase'),
              '($myFanFactor + $opponentFanFactor) / 2 = $fanBaseText',
            ),
            _winningsCalcLine(
              tr(lang, 'aftermatch.touchdowns'),
              '+$touchdowns',
            ),
            _winningsCalcLine(
              tr(lang, 'aftermatch.stalling'),
              stalling
                  ? tr(lang, 'aftermatch.stallingYesShort')
                  : tr(lang, 'aftermatch.stallingNoShort'),
              valueColor: stalling ? AppColors.warning : AppColors.success,
            ),
            _winningsCalcLine(
              tr(lang, 'aftermatch.noStallingBonus'),
              '+$stallBonus',
              valueColor:
                  stallBonus == 0 ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(lang, 'common.close')),
          ),
        ],
      ),
    );
  }

  Widget _winningsCalcLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 3: Dedicated Fans
  // ═══════════════════════════════════════════════════════════

  Widget _buildDedicatedFansSection() {
    final lang = ref.watch(localeProvider);

    return _sectionCard(
      icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
      title: tr(lang, 'aftermatch.dedicatedFansTitle').toUpperCase(),
      color: AppColors.info,
      centerTitle: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;

          final home = _fanRollCol(
            teamName: _homeTeam?.name ?? 'Home',
            currentFans: _homeDedicatedFans,
            roll: _homeFanRoll,
            onRollChanged: (v) => setState(() => _homeFanRoll = v),
            won: _scoreHome > _scoreAway,
            lost: _scoreHome < _scoreAway,
            color: AppColors.info,
          );

          final away = _fanRollCol(
            teamName: _awayTeam?.name ?? 'Away',
            currentFans: _awayDedicatedFans,
            roll: _awayFanRoll,
            onRollChanged: (v) => setState(() => _awayFanRoll = v),
            won: _scoreAway > _scoreHome,
            lost: _scoreAway < _scoreHome,
            color: AppColors.error,
          );

          if (isCompact) {
            return Column(
              children: [
                home,
                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceLight, height: 1),
                const SizedBox(height: 16),
                away,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: home),
              Container(width: 1, height: 100, color: AppColors.surfaceLight),
              Expanded(child: away),
            ],
          );
        },
      ),
    );
  }

  Widget _fanRollCol({
    required String teamName,
    required int currentFans,
    required int? roll,
    required ValueChanged<int?> onRollChanged,
    required bool won,
    required bool lost,
    required Color color,
  }) {
    final lang = ref.watch(localeProvider);
    final isDraw = !won && !lost;
    String resultLabel = tr(lang, 'aftermatch.fansDrawNoChange');
    Color resultColor = AppColors.textMuted;
    final newFans = _nextDedicatedFans(
      currentFans: currentFans,
      roll: roll,
      won: won,
      lost: lost,
    );
    final appliedFans = isDraw ? currentFans : newFans;
    final delta = newFans - currentFans;

    if (isDraw) {
      resultColor = AppColors.textMuted;
    } else if (roll == null) {
      resultLabel = tr(lang, 'aftermatch.fansRollPending');
    } else if (won) {
      if (roll >= currentFans) {
        resultColor = AppColors.success;
        resultLabel = currentFans >= 7
            ? tr(lang, 'aftermatch.fansNoChangeMax')
            : tr(lang, 'aftermatch.fansPlusOne');
      } else {
        resultLabel = tr(lang, 'aftermatch.fansNoChangeLowRoll');
      }
    } else if (lost) {
      if (roll < currentFans) {
        resultColor = AppColors.error;
        resultLabel = currentFans <= 1
            ? tr(lang, 'aftermatch.fansNoChangeMin')
            : tr(lang, 'aftermatch.fansMinusOne');
      } else {
        resultLabel = tr(lang, 'aftermatch.fansNoChangeHighRoll');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            '$appliedFans',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 76,
              fontWeight: FontWeight.w900,
              fontFamily: AppTypography.displayFontFamily,
              height: 0.85,
              shadows: [
                Shadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 26,
                ),
              ],
            ),
          ),
          Text(
            delta == 0
                ? tr(lang, 'aftermatch.currentFansLabel')
                : trf(lang, 'aftermatch.previousFansLabel', {
                    'fans': '$currentFans',
                  }),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (isDraw)
            _fansStatusPill(
              label: tr(lang, 'aftermatch.fansDrawNoChange'),
              color: AppColors.textMuted,
              icon: PhosphorIcons.equals(PhosphorIconsStyle.bold),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(lang, 'aftermatch.d6Roll'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  child: _d6RollField(roll, onRollChanged),
                ),
              ],
            ),
          const SizedBox(height: 10),
          _fansStatusPill(
            label: resultLabel,
            color: resultColor,
            icon: delta > 0
                ? PhosphorIcons.arrowUp(PhosphorIconsStyle.bold)
                : delta < 0
                    ? PhosphorIcons.arrowDown(PhosphorIconsStyle.bold)
                    : PhosphorIcons.minus(PhosphorIconsStyle.bold),
          ),
        ],
      ),
    );
  }

  Widget _fansStatusPill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _d6RollField(int? value, ValueChanged<int?> onChanged) {
    return _dieRollField(value, onChanged, max: 6);
  }

  Widget _dieRollField(
    int? value,
    ValueChanged<int?> onChanged, {
    required int max,
  }) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: 'D$max',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      onChanged: (text) {
        final trimmed = text.trim();
        if (trimmed.isEmpty) {
          onChanged(null);
          return;
        }
        final parsed = int.tryParse(trimmed);
        if (parsed != null) onChanged(parsed.clamp(1, max).toInt());
      },
    );
  }

  int _nextDedicatedFans({
    required int currentFans,
    required int? roll,
    required bool won,
    required bool lost,
  }) {
    if (won && roll != null && roll >= currentFans) {
      return (currentFans + 1).clamp(1, 7).toInt();
    }
    if (lost && roll != null && roll < currentFans) {
      return (currentFans - 1).clamp(1, 7).toInt();
    }
    return currentFans.clamp(1, 7).toInt();
  }

  Map<String, _SppTally> _buildSppTallies(Match match) {
    final sppMap = <String, _SppTally>{};

    _SppTally ensureTally(String playerId, String? playerName, String team) {
      final key = '$team:$playerId';
      sppMap.putIfAbsent(
          key, () => _SppTally(playerId, playerName ?? '?', team));
      return sppMap[key]!;
    }

    void addSpp(
        String? playerId, String? playerName, String team, String type) {
      if (playerId == null) return;
      final tally = ensureTally(playerId, playerName, team);
      switch (type) {
        case 'completion':
          tally.completions++;
        case 'touchdown':
          tally.touchdowns++;
        case 'casualty':
          tally.casualties++;
        case 'interception':
          tally.interceptions++;
      }
    }

    void addThrowTeammateSpp(MatchEvent event) {
      if (event.type != 'throw_teammate' ||
          !_throwTeammateLanded(event.detail)) {
        return;
      }
      if (event.victimId != null) {
        ensureTally(event.victimId!, event.victimName, event.team)
            .throwTeammate++;
      }
      if (_throwTeammateSuperb(event.detail) && event.playerId != null) {
        ensureTally(event.playerId!, event.playerName, event.team)
            .throwTeammate++;
      }
    }

    for (final e in [...match.events, ..._postMatchEvents]) {
      if (e.type == 'throw_teammate') {
        addThrowTeammateSpp(e);
      } else {
        addSpp(e.playerId, e.playerName, e.team, e.type);
      }
    }

    if (_mvpHomeId != null) {
      final key = 'home:$_mvpHomeId';
      final name = _homeTeam?.players
              .where((p) => p.id == _mvpHomeId)
              .firstOrNull
              ?.name ??
          '?';
      sppMap.putIfAbsent(key, () => _SppTally(_mvpHomeId!, name, 'home'));
      sppMap[key]!.mvp = true;
    }
    if (_mvpAwayId != null) {
      final key = 'away:$_mvpAwayId';
      final name = _awayTeam?.players
              .where((p) => p.id == _mvpAwayId)
              .firstOrNull
              ?.name ??
          '?';
      sppMap.putIfAbsent(key, () => _SppTally(_mvpAwayId!, name, 'away'));
      sppMap[key]!.mvp = true;
    }

    for (final b in _bonusSpp) {
      final key = '${b.team}:${b.playerId}';
      sppMap.putIfAbsent(
          key, () => _SppTally(b.playerId, b.playerName, b.team));
      sppMap[key]!.bonus += b.amount;
    }

    return sppMap;
  }

  bool _throwTeammateLanded(String? detail) {
    final d = detail?.toLowerCase() ?? '';
    return d.contains('cae de pie: sí') ||
        d.contains('cae de pie: si') ||
        d.contains('landed=true') ||
        d.contains('landed=1');
  }

  bool _throwTeammateSuperb(String? detail) {
    final d = detail?.toLowerCase() ?? '';
    return d.contains('soberbio: sí') ||
        d.contains('soberbio: si') ||
        d.contains('superb=true') ||
        d.contains('superb=1');
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 4: MVP
  // ═══════════════════════════════════════════════════════════

  Widget _buildMvpSection(Match match) {
    final lang = ref.watch(localeProvider);
    final sppMap = _buildSppTallies(match);
    final tempData = ref.watch(tempHiredPlayersProvider);
    final homeTempIds = tempData.getForTeam(match.home.teamId);
    final awayTempIds = tempData.getForTeam(match.away.teamId);

    return _sectionCard(
      icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
      title: tr(lang, 'aftermatch.mvpTitle').toUpperCase(),
      color: AppColors.accent,
      centerTitle: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;

          final home = _mvpPicker(
            teamName: _homeTeam?.name ?? 'Home',
            players: _playedPlayers(_homeTeam?.players ?? [], match.homeSquad),
            teamKey: 'home',
            teamId: match.home.teamId,
            tempPlayerIds: homeTempIds,
            sppMap: sppMap,
            selectedId: _mvpHomeId,
            onChanged: (v) => setState(() => _mvpHomeId = v),
            color: AppColors.info,
          );

          final away = _mvpPicker(
            teamName: _awayTeam?.name ?? 'Away',
            players: _playedPlayers(_awayTeam?.players ?? [], match.awaySquad),
            teamKey: 'away',
            teamId: match.away.teamId,
            tempPlayerIds: awayTempIds,
            sppMap: sppMap,
            selectedId: _mvpAwayId,
            onChanged: (v) => setState(() => _mvpAwayId = v),
            color: AppColors.error,
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                home,
                const SizedBox(height: 16),
                away,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: home),
              const SizedBox(width: 12),
              Expanded(child: away),
            ],
          );
        },
      ),
    );
  }

  Widget _mvpPicker({
    required String teamName,
    required List<UserPlayer> players,
    required String teamKey,
    required String teamId,
    required Set<String> tempPlayerIds,
    required Map<String, _SppTally> sppMap,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    final lang = ref.watch(localeProvider);
    final activePlayers = players.where((p) => p.status != 'dead').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                teamName,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              icon: Icon(PhosphorIcons.shuffle(PhosphorIconsStyle.bold),
                  size: 17, color: color),
              label: Text(tr(lang, 'aftermatch.randomMvp'),
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                minimumSize: Size.zero,
              ),
              onPressed: activePlayers.isEmpty
                  ? null
                  : () {
                      final shuffled = List.of(activePlayers)..shuffle();
                      onChanged(shuffled.first.id);
                    },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activePlayers.map((p) {
          final selected = p.id == selectedId;
          final isTemp = tempPlayerIds.contains(p.id);
          final isStarPlayer = p.baseType.startsWith('star_');
          final tally =
              sppMap['$teamKey:${p.id}'] ?? _SppTally(p.id, p.name, teamKey);
          return InkWell(
            onTap: () => onChanged(selected ? null : p.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : AppColors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.52)
                      : AppColors.surfaceLight.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  _mvpStarRibbon(selected),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text('#${p.number}',
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: TextStyle(
                                color:
                                    selected ? color : AppColors.textSecondary,
                                fontSize: 17,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                            overflow: TextOverflow.ellipsis),
                        if (isTemp) ...[
                          const SizedBox(height: 5),
                          _tempPlayerSppBadge(isStarPlayer: isStarPlayer),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isTemp) ...[
                    if (!isStarPlayer)
                      _tempActionButton(
                        label: 'Incorporar',
                        color: AppColors.success,
                        icon: PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                        onPressed: () => _keepTempPlayer(p, teamId),
                      ),
                    if (isStarPlayer)
                      _tempActionButton(
                        label: 'Liberar',
                        color: AppColors.error,
                        icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
                        onPressed: () => _releaseTempPlayer(p, teamId),
                      ),
                    const SizedBox(width: 8),
                  ],
                  _sppBadge(
                    tally.total,
                    onTap: () => _showPlayerSppDialog(p, teamKey, tally),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _tempPlayerSppBadge({required bool isStarPlayer}) {
    final color = isStarPlayer ? AppColors.accent : AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStarPlayer
                ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                : PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isStarPlayer ? 'Estrella temporal' : 'Sustituto temporal',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<UserPlayer> _playedPlayers(
      List<UserPlayer> players, List<String> squad) {
    final alive = players.where((p) => p.status != 'dead').toList();
    if (squad.isEmpty) return alive.take(11).toList();

    final squadSet = squad.toSet();
    final selected = alive.where((p) => squadSet.contains(p.id)).toList();
    if (selected.length >= 11) return selected.take(11).toList();

    final missing = alive.where((p) => !squadSet.contains(p.id));
    return [...selected, ...missing].take(11).toList();
  }

  Widget _mvpStarRibbon(bool selected) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.accent.withValues(alpha: 0.22)
            : AppColors.surface.withValues(alpha: 0.65),
        border: Border.all(
          color: selected
              ? AppColors.accent
              : AppColors.surfaceLight.withValues(alpha: 0.65),
        ),
      ),
      child: Icon(
        PhosphorIcons.star(
            selected ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
        size: 18,
        color: selected ? AppColors.accent : AppColors.textMuted,
      ),
    );
  }

  Widget _sppBadge(int points, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.44)),
        ),
        child: Text(
          '$points SPP',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: AppTypography.displayFontFamily,
          ),
        ),
      ),
    );
  }

  void _showPlayerSppDialog(UserPlayer player, String team, _SppTally tally) {
    final lang = ref.read(localeProvider);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${tally.total} SPP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                fontFamily: AppTypography.displayFontFamily,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 16),
            ..._sppReasonRows(tally, lang),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddBonusForPlayerDialog(player, team);
            },
            icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.bold)),
            label: Text(tr(lang, 'aftermatch.addBonusSpp')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(lang, 'common.close')),
          ),
        ],
      ),
    );
  }

  List<Widget> _sppReasonRows(_SppTally tally, String lang) {
    final rows = <Widget>[];
    void add(String label, int count, int pointsEach, Color color) {
      if (count <= 0) return;
      rows.add(_sppReasonRow(label, count, count * pointsEach, color));
    }

    add(tr(lang, 'aftermatch.completions'), tally.completions, 1,
        AppColors.info);
    add(tr(lang, 'aftermatch.interceptions'), tally.interceptions, 2,
        AppColors.success);
    add(tr(lang, 'aftermatch.casualties'), tally.casualties, 2,
        AppColors.error);
    add(tr(lang, 'aftermatch.touchdowns'), tally.touchdowns, 3,
        AppColors.accent);
    add('Lanzar compañero', tally.throwTeammate, 1, AppColors.info);
    if (tally.mvp) rows.add(_sppReasonRow('MVP', 1, 4, AppColors.accent));
    if (tally.bonus > 0) {
      rows.add(_sppReasonRow(tr(lang, 'aftermatch.bonusSpp'), 1, tally.bonus,
          AppColors.primaryLight));
      final descriptions = _bonusSpp
          .where((b) => b.playerId == tally.playerId && b.team == tally.team)
          .map((b) => b.description?.trim())
          .whereType<String>()
          .where((d) => d.isNotEmpty)
          .toList();
      for (final description in descriptions) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: Text(
            '“$description”',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ));
      }
    }
    if (rows.isEmpty) {
      rows.add(Text(
        tr(lang, 'aftermatch.noSppReasons'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted),
      ));
    }
    return rows;
  }

  Widget _sppReasonRow(String label, int count, int points, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count > 1 ? '$label ×$count' : label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '+$points',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: AppTypography.displayFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBonusForPlayerDialog(UserPlayer player, String team) {
    final lang = ref.read(localeProvider);
    int amount = 1;
    String description = '';
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(tr(lang, 'aftermatch.addBonusSpp'),
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(player.name,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _miniCounter(
                amount,
                (v) => setDialogState(() => amount = v.clamp(1, 99).toInt()),
                AppColors.accent,
              ),
              const SizedBox(height: 16),
              TextField(
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: tr(lang, 'aftermatch.bonusDescription'),
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  hintText: tr(lang, 'aftermatch.bonusDescriptionHint'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
                onChanged: (v) => description = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(lang, 'common.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _bonusSpp.add(_BonusSppEntry(
                    playerId: player.id,
                    playerName: player.name,
                    team: team,
                    amount: amount,
                    description:
                        description.trim().isEmpty ? null : description.trim(),
                  ));
                });
                Navigator.of(context).pop();
              },
              child: Text(tr(lang, 'common.add')),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 5: SPP Summary
  // ═══════════════════════════════════════════════════════════

  Widget _buildSppSection(Match match) {
    final sppMap = <String, _SppTally>{};
    void addSpp(
        String? playerId, String? playerName, String team, String type) {
      if (playerId == null) return;
      final key = '$team:$playerId';
      sppMap.putIfAbsent(
          key, () => _SppTally(playerId, playerName ?? '?', team));
      switch (type) {
        case 'completion':
          sppMap[key]!.completions++;
        case 'touchdown':
          sppMap[key]!.touchdowns++;
        case 'casualty':
          sppMap[key]!.casualties++;
        case 'interception':
          sppMap[key]!.interceptions++;
      }
    }

    for (final e in match.events) {
      addSpp(e.playerId, e.playerName, e.team, e.type);
    }

    // MVPs
    if (_mvpHomeId != null) {
      final key = 'home:$_mvpHomeId';
      final name = _homeTeam?.players
              .where((p) => p.id == _mvpHomeId)
              .firstOrNull
              ?.name ??
          '?';
      sppMap.putIfAbsent(key, () => _SppTally(_mvpHomeId!, name, 'home'));
      sppMap[key]!.mvp = true;
    }
    if (_mvpAwayId != null) {
      final key = 'away:$_mvpAwayId';
      final name = _awayTeam?.players
              .where((p) => p.id == _mvpAwayId)
              .firstOrNull
              ?.name ??
          '?';
      sppMap.putIfAbsent(key, () => _SppTally(_mvpAwayId!, name, 'away'));
      sppMap[key]!.mvp = true;
    }

    // Bonus SPP
    for (final b in _bonusSpp) {
      final key = '${b.team}:${b.playerId}';
      sppMap.putIfAbsent(
          key, () => _SppTally(b.playerId, b.playerName, b.team));
      sppMap[key]!.bonus += b.amount;
    }

    final entries = sppMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return _sectionCard(
      icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
      title: 'SPP SUMMARY',
      color: AppColors.accent,
      subtitle: 'Comp=1, Throw TM=1, Int=2, Cas=2, TD=3, MVP=4',
      child: Column(
        children: [
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No SPP awarded yet',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                              width: 80,
                              child: Text('Player',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))),
                          const Spacer(),
                          ..._sppHeaders(),
                        ],
                      ),
                    ),
                    ...entries.map((e) => _sppRow(e)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _addBonusSppRow(),
          ),
        ],
      ),
    );
  }

  List<Widget> _sppHeaders() {
    const headers = ['Comp', 'Int', 'Cas', 'TD', 'MVP', 'Bonus', 'Total'];
    return headers
        .map((h) => SizedBox(
              width: 40,
              child: Text(h,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ))
        .toList();
  }

  Widget _sppRow(_SppTally e) {
    final isHome = e.team == 'home';
    final color = isHome ? AppColors.info : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(e.playerName,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          const Spacer(),
          _sppCell(e.completions),
          _sppCell(e.interceptions),
          _sppCell(e.casualties),
          _sppCell(e.touchdowns),
          _sppCell(e.mvp ? 1 : 0),
          _sppCell(e.bonus),
          SizedBox(
            width: 40,
            child: Text('${e.total}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTypography.displayFontFamily)),
          ),
        ],
      ),
    );
  }

  Widget _sppCell(int count) {
    return SizedBox(
      width: 40,
      child: Text(
        count > 0 ? '$count' : '−',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: count > 0 ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 12),
      ),
    );
  }

  Widget _addBonusSppRow() {
    final allPlayers = [
      ...(_homeTeam?.players ?? []).map((p) => (p, 'home')),
      ...(_awayTeam?.players ?? []).map((p) => (p, 'away')),
    ];
    return OutlinedButton.icon(
      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
          size: 14, color: AppColors.accent),
      label: const Text('Add Bonus SPP',
          style: TextStyle(color: AppColors.accent, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      onPressed: () => _showAddBonusSppDialog(allPlayers),
    );
  }

  void _showAddBonusSppDialog(List<(UserPlayer, String)> allPlayers) {
    String? selectedId;
    String team = 'home';
    String name = '';
    int amount = 1;
    String description = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Bonus SPP',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(
                  labelText: 'Player',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
                items: allPlayers
                    .map((e) => DropdownMenuItem(
                          value: '${e.$2}:${e.$1.id}',
                          child: Text(
                              '${e.$1.name} (${e.$2 == "home" ? "H" : "A"})',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final parts = v.split(':');
                  setDialogState(() {
                    team = parts[0];
                    selectedId = parts.sublist(1).join(':');
                    name = allPlayers
                        .firstWhere(
                            (e) => e.$1.id == selectedId && e.$2 == team)
                        .$1
                        .name;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Amount:',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  _miniCounter(amount, (v) => setDialogState(() => amount = v),
                      AppColors.accent),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: tr(
                      ref.read(localeProvider), 'aftermatch.bonusDescription'),
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  hintText: tr(ref.read(localeProvider),
                      'aftermatch.bonusDescriptionHint'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => description = v,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      setState(() {
                        _bonusSpp.add(_BonusSppEntry(
                          playerId: selectedId!,
                          playerName: name,
                          team: team,
                          amount: amount,
                          description: description.trim().isEmpty
                              ? null
                              : description.trim(),
                        ));
                      });
                      Navigator.pop(ctx);
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 6: Injuries
  // ═══════════════════════════════════════════════════════════

  Widget _buildInjuriesSection() {
    return _sectionCard(
      icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
      title: 'LASTING INJURIES',
      color: AppColors.error,
      subtitle: 'Record permanent injuries from this match',
      child: Column(
        children: [
          ..._injuries.asMap().entries.map((entry) {
            final i = entry.key;
            final inj = entry.value;
            final isHome = inj.team == 'home';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: (isHome ? AppColors.info : AppColors.error)
                        .withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isHome ? AppColors.info : AppColors.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inj.playerName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(inj.injuryLabel,
                            style: TextStyle(
                                color: inj.injuryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                        size: 16, color: AppColors.error),
                    onPressed: () => setState(() => _injuries.removeAt(i)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                size: 14, color: AppColors.error),
            label: const Text('Add Injury',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            onPressed: _showAddInjuryDialog,
          ),
        ],
      ),
    );
  }

  void _showAddInjuryDialog() {
    final allPlayers = [
      ...(_homeTeam?.players ?? []).map((p) => (p, 'home')),
      ...(_awayTeam?.players ?? []).map((p) => (p, 'away')),
    ];

    String? selectedId;
    String team = 'home';
    String name = '';
    String injuryType = 'miss_next_game';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Injury',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(
                  labelText: 'Player',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
                items: allPlayers
                    .map((e) => DropdownMenuItem(
                          value: '${e.$2}:${e.$1.id}',
                          child: Text(
                              '${e.$1.name} (${e.$2 == "home" ? "H" : "A"})',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final parts = v.split(':');
                  setDialogState(() {
                    team = parts[0];
                    selectedId = parts.sublist(1).join(':');
                    name = allPlayers
                        .firstWhere(
                            (e) => e.$1.id == selectedId && e.$2 == team)
                        .$1
                        .name;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: injuryType,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(
                  labelText: 'Injury Type',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'badly_hurt',
                      child: Text('Badly Hurt',
                          style: TextStyle(color: AppColors.textPrimary))),
                  DropdownMenuItem(
                      value: 'miss_next_game',
                      child: Text('Miss Next Game',
                          style: TextStyle(color: AppColors.textPrimary))),
                  DropdownMenuItem(
                      value: 'niggling_injury',
                      child: Text('Niggling Injury',
                          style: TextStyle(color: AppColors.textPrimary))),
                  DropdownMenuItem(
                      value: 'stat_decrease',
                      child: Text('Stat Decrease',
                          style: TextStyle(color: AppColors.textPrimary))),
                  DropdownMenuItem(
                      value: 'dead',
                      child: Text('Dead',
                          style: TextStyle(color: AppColors.textPrimary))),
                ],
                onChanged: (v) =>
                    setDialogState(() => injuryType = v ?? injuryType),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      setState(() {
                        _injuries.add(_InjuryEntry(
                          playerId: selectedId!,
                          playerName: name,
                          team: team,
                          type: injuryType,
                        ));
                      });
                      Navigator.pop(ctx);
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 7: Expensive Mistakes
  // ═══════════════════════════════════════════════════════════

  Widget _buildExpensiveMistakesSection() {
    final lang = ref.watch(localeProvider);
    final rulesAsync = ref.watch(expensiveMistakesRulesProvider);
    final homeTreasury = (_homeTeam?.treasury ?? 0) + (_homeWinnings ?? 0);
    final awayTreasury = (_awayTeam?.treasury ?? 0) + (_awayWinnings ?? 0);

    return _sectionCard(
      icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
      title: tr(lang, 'aftermatch.expensiveMistakesTitle').toUpperCase(),
      color: AppColors.warning,
      centerTitle: true,
      child: rulesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.warning),
          ),
        ),
        error: (error, _) => Text(
          'Error: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
        data: (rules) => LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;
            final homeResult = _homeExpensiveRoll == null
                ? null
                : rules.resultFor(homeTreasury, _homeExpensiveRoll!);
            final awayResult = _awayExpensiveRoll == null
                ? null
                : rules.resultFor(awayTreasury, _awayExpensiveRoll!);

            final home = _expensiveCol(
              rules: rules,
              teamName: _homeTeam?.name ?? 'Home',
              treasury: homeTreasury,
              roll: _homeExpensiveRoll,
              result: homeResult,
              d3: _homeExpensiveD3,
              d6A: _homeCatastropheD6A,
              d6B: _homeCatastropheD6B,
              onRollChanged: (v) {
                setState(() {
                  _homeExpensiveRoll = v;
                  _homeExpensiveResult =
                      v == null ? null : rules.resultFor(homeTreasury, v);
                  _clearHomeExpensiveExtraDice();
                });
              },
              onD3Changed: (v) => setState(() => _homeExpensiveD3 = v),
              onD6AChanged: (v) => setState(() => _homeCatastropheD6A = v),
              onD6BChanged: (v) => setState(() => _homeCatastropheD6B = v),
              color: AppColors.info,
            );

            final away = _expensiveCol(
              rules: rules,
              teamName: _awayTeam?.name ?? 'Away',
              treasury: awayTreasury,
              roll: _awayExpensiveRoll,
              result: awayResult,
              d3: _awayExpensiveD3,
              d6A: _awayCatastropheD6A,
              d6B: _awayCatastropheD6B,
              onRollChanged: (v) {
                setState(() {
                  _awayExpensiveRoll = v;
                  _awayExpensiveResult =
                      v == null ? null : rules.resultFor(awayTreasury, v);
                  _clearAwayExpensiveExtraDice();
                });
              },
              onD3Changed: (v) => setState(() => _awayExpensiveD3 = v),
              onD6AChanged: (v) => setState(() => _awayCatastropheD6A = v),
              onD6BChanged: (v) => setState(() => _awayCatastropheD6B = v),
              color: AppColors.error,
            );

            if (isCompact) {
              return Column(
                children: [
                  home,
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceLight, height: 1),
                  const SizedBox(height: 16),
                  away,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: home),
                Container(width: 1, height: 170, color: AppColors.surfaceLight),
                Expanded(child: away),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _expensiveCol({
    required ExpensiveMistakesRules rules,
    required String teamName,
    required int treasury,
    required int? roll,
    required String? result,
    required int? d3,
    required int? d6A,
    required int? d6B,
    required ValueChanged<int?> onRollChanged,
    required ValueChanged<int?> onD3Changed,
    required ValueChanged<int?> onD6AChanged,
    required ValueChanged<int?> onD6BChanged,
    required Color color,
  }) {
    final lang = ref.watch(localeProvider);
    final applies = treasury >= rules.minTreasury;
    final effect = result == null ? null : rules.effects[result];
    final finalTreasury = _expensiveFinalTreasury(
      rules: rules,
      treasury: treasury,
      result: result,
      d3: d3,
      d6A: d6A,
      d6B: d6B,
    );
    final loss = finalTreasury == null ? null : treasury - finalTreasury;
    final resultColor = !applies
        ? AppColors.success
        : result != null
            ? _expensiveColor(result)
            : AppColors.textMuted;
    final resultLabel = !applies
        ? tr(lang, 'aftermatch.expensiveSafe')
        : effect != null
            ? effect.localizedLabel(lang)
            : tr(lang, 'aftermatch.expensiveRollPending');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_fmtGold(treasury)} ${tr(lang, 'aftermatch.gp')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                fontFamily: AppTypography.displayFontFamily,
                height: 0.85,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 26,
                  ),
                ],
              ),
            ),
          ),
          Text(
            tr(lang, 'aftermatch.treasuryAfterWinnings'),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (applies)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(lang, 'aftermatch.d6Roll'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  child: _d6RollField(roll, onRollChanged),
                ),
              ],
            )
          else
            _fansStatusPill(
              label: tr(lang, 'aftermatch.expensiveNotApplicable'),
              color: AppColors.success,
              icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
            ),
          const SizedBox(height: 10),
          _fansStatusPill(
            label: resultLabel,
            color: resultColor,
            icon: result != null
                ? PhosphorIcons.warningCircle(PhosphorIconsStyle.fill)
                : PhosphorIcons.minus(PhosphorIconsStyle.bold),
          ),
          if (effect?.localizedDescription(lang).isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              effect!.localizedDescription(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (effect?.calculation == 'lose_d3_x_10000') ...[
            const SizedBox(height: 12),
            _expensiveDiceRow(
              label: tr(lang, 'aftermatch.d3Roll'),
              value: d3,
              max: 3,
              onChanged: onD3Changed,
            ),
          ],
          if (effect?.calculation == 'keep_2d6_x_10000') ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 10,
              children: [
                _expensiveDiceRow(
                  label: tr(lang, 'aftermatch.firstD6'),
                  value: d6A,
                  max: 6,
                  onChanged: onD6AChanged,
                ),
                _expensiveDiceRow(
                  label: tr(lang, 'aftermatch.secondD6'),
                  value: d6B,
                  max: 6,
                  onChanged: onD6BChanged,
                ),
              ],
            ),
          ],
          if (finalTreasury != null) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _fansStatusPill(
                  label:
                      '${tr(lang, 'aftermatch.finalTreasury')}: ${_fmtGold(finalTreasury)} ${tr(lang, 'aftermatch.gp')}',
                  color: AppColors.accent,
                  icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
                ),
                if (loss != null && loss > 0)
                  _fansStatusPill(
                    label:
                        '${tr(lang, 'aftermatch.treasuryLost')}: ${_fmtGold(loss)} ${tr(lang, 'aftermatch.gp')}',
                    color: AppColors.error,
                    icon:
                        PhosphorIcons.arrowFatLineDown(PhosphorIconsStyle.fill),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _expensiveDiceRow({
    required String label,
    required int? value,
    required int max,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: _dieRollField(value, onChanged, max: max),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Temporary Hired Players
  // ═══════════════════════════════════════════════════════════

  Widget _buildTempHiredPlayersSection(Match match) {
    final tempData = ref.read(tempHiredPlayersProvider);
    final homeId = match.home.teamId;
    final awayId = match.away.teamId;
    final homeTempIds = tempData.getForTeam(homeId);
    final awayTempIds = tempData.getForTeam(awayId);

    if (homeTempIds.isEmpty && awayTempIds.isEmpty) {
      return const SizedBox.shrink();
    }

    List<UserPlayer> homeTempPlayers = [];
    List<UserPlayer> awayTempPlayers = [];
    if (_homeTeam != null) {
      homeTempPlayers =
          _homeTeam!.players.where((p) => homeTempIds.contains(p.id)).toList();
    }
    if (_awayTeam != null) {
      awayTempPlayers =
          _awayTeam!.players.where((p) => awayTempIds.contains(p.id)).toList();
    }

    if (homeTempPlayers.isEmpty && awayTempPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      icon: PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
      title: 'TEMPORARY HIRES',
      subtitle: 'Players hired for this match only',
      color: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (homeTempPlayers.isNotEmpty) ...[
            Text(
              _homeTeam?.name ?? match.home.teamName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...homeTempPlayers.map((p) => _buildTempPlayerRow(p, homeId,
                isStarPlayer: p.baseType.startsWith('star_'))),
            const SizedBox(height: 16),
          ],
          if (awayTempPlayers.isNotEmpty) ...[
            Text(
              _awayTeam?.name ?? match.away.teamName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...awayTempPlayers.map((p) => _buildTempPlayerRow(p, awayId,
                isStarPlayer: p.baseType.startsWith('star_'))),
          ],
        ],
      ),
    );
  }

  Widget _buildTempPlayerRow(UserPlayer player, String teamId,
      {required bool isStarPlayer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isStarPlayer
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.info.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${player.number}',
                style: TextStyle(
                  color: isStarPlayer ? AppColors.accent : AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                Text(
                  isStarPlayer ? '★ Star Player' : player.positionLabel,
                  style: TextStyle(
                    color:
                        isStarPlayer ? AppColors.accent : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isStarPlayer)
            _tempActionButton(
              label: 'Release',
              color: AppColors.error,
              icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
              onPressed: () => _releaseTempPlayer(player, teamId),
            )
          else ...[
            _tempActionButton(
              label: 'Keep',
              color: AppColors.success,
              icon: PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
              onPressed: () => _keepTempPlayer(player, teamId),
            ),
            const SizedBox(width: 8),
            _tempActionButton(
              label: 'Release',
              color: AppColors.error,
              icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
              onPressed: () => _releaseTempPlayer(player, teamId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tempActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _keepTempPlayer(UserPlayer player, String teamId) {
    final tempData = ref.read(tempHiredPlayersProvider);
    setState(() {
      tempData.getForTeam(teamId).remove(player.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${player.name} added permanently to roster'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _releaseTempPlayer(UserPlayer player, String teamId) async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.fireUserPlayer(teamId, player.id);
      final tempData = ref.read(tempHiredPlayersProvider);
      setState(() {
        tempData.getForTeam(teamId).remove(player.id);
        // Remove from loaded team data so UI updates
        if (_homeTeam != null && teamId == _homeTeam!.id) {
          _homeTeam = null; // force reload
        }
        if (_awayTeam != null && teamId == _awayTeam!.id) {
          _awayTeam = null; // force reload
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} released'),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error releasing player: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Submit
  // ═══════════════════════════════════════════════════════════

  Widget _buildSubmitButton(Match match) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: 20),
        label: Text(
          _submitting ? 'SUBMITTING...' : 'SUBMIT POST-MATCH REPORT',
          style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _submitting ? null : () => _submitAfterMatch(match),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    String? subtitle,
    bool centerTitle = false,
    bool showHeader = true,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            centerTitle
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: _displayLarge.copyWith(
                              fontSize: 28, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: _displayLarge.copyWith(
                                    fontSize: 22,
                                    color: AppColors.textPrimary)),
                            if (subtitle != null)
                              Text(subtitle,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  Widget _numField(int value, ValueChanged<int> onChanged, {int max = 999999}) {
    return TextField(
      controller: TextEditingController(text: '$value'),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surfaceLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surfaceLight)),
      ),
      onSubmitted: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed.clamp(0, max));
      },
    );
  }

  String _fmtGold(int v) {
    if (v == 0) return '0';
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return v < 0 ? '-${buf.toString()}' : buf.toString();
  }

  String _fmtDecimal(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Exit Post-Match?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('All data on this page will be lost.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/league/$leagueId');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

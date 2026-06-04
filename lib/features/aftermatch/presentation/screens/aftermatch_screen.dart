import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../league/domain/models/league.dart';
import '../../../live_match/data/active_match_provider.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../my_teams/presentation/screens/my_team_detail_screen.dart'
    show userTeamDetailProvider;
import '../../../my_teams/presentation/screens/my_teams_screen.dart'
    show myUserTeamsProvider;
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/match_event_dialog.dart';

// ─── Provider ───────────────────────────────────────────────

final _matchDetailProvider = FutureProvider.autoDispose
    .family<Match, ({String leagueId, String matchId})>((ref, p) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getMatchDetail(p.leagueId, p.matchId);
});

final _quickMatchDetailProvider =
    FutureProvider.autoDispose.family<Match, String>((ref, matchId) async {
  final repo = ref.read(quickMatchRepositoryProvider);
  return repo.getMatchDetail(matchId);
});

final _leagueProvider =
    FutureProvider.autoDispose.family<League, String>((ref, leagueId) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getLeague(leagueId);
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

  _SppTally(this.playerId, this.playerName, this.team);

  int get total =>
      completions * 1 +
      interceptions * 2 +
      casualties * 2 +
      touchdowns * 3 +
      throwTeammate +
      (mvp ? 4 : 0);
}

class _InjuryEntry {
  final String playerId;
  final String playerName;
  final String team;
  final int casualtyRoll;

  _InjuryEntry({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.casualtyRoll,
  });

  String injuryLabel(InjuryRules rules, String lang) {
    final casualty = rules.casualtyResultFor(casualtyRoll);
    return casualty?.localizedLabel(lang) ?? 'D16 $casualtyRoll';
  }

  Color injuryColor(InjuryRules rules) {
    switch (rules.casualtyResultFor(casualtyRoll)?.code) {
      case 'badly_hurt':
        return AppColors.warning;
      case 'seriously_hurt':
        return AppColors.warning;
      case 'serious_injury':
        return AppColors.error;
      case 'lasting_injury':
        return AppColors.error;
      case 'dead':
        return AppColors.primaryDark;
      default:
        return AppColors.textMuted;
    }
  }
}

enum _AftermatchRosterSortColumn {
  candidate,
  number,
  name,
  kind,
  spp,
}

class _LeaguePointLine {
  final String label;
  final int points;

  const _LeaguePointLine(this.label, this.points);
}

class _PendingPlayerPurchase {
  final String baseType;
  final String positionName;
  final String? name;
  final int? number;
  final int cost;

  const _PendingPlayerPurchase({
    required this.baseType,
    required this.positionName,
    required this.cost,
    this.name,
    this.number,
  });
}

class _PendingTeamPurchases {
  final List<_PendingPlayerPurchase> players = [];
  int rerolls = 0;
  int cheerleaders = 0;
  int assistantCoaches = 0;
  bool apothecary = false;

  bool get isEmpty =>
      players.isEmpty &&
      rerolls == 0 &&
      cheerleaders == 0 &&
      assistantCoaches == 0 &&
      !apothecary;
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
  BaseTeam? _homeBaseRoster;
  BaseTeam? _awayBaseRoster;
  final _homePendingPurchases = _PendingTeamPurchases();
  final _awayPendingPurchases = _PendingTeamPurchases();

  int _scoreHome = 0;
  int _scoreAway = 0;
  int _tdHome = 0;
  int _tdAway = 0;
  int _casHome = 0;
  int _casAway = 0;
  int _compHome = 0;
  int _compAway = 0;
  int _throwHome = 0;
  int _throwAway = 0;
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

  // ── Section 3: Dedicated Fans ──
  int? _homeFanRoll;
  int? _awayFanRoll;
  int _homeDedicatedFans = 1;
  int _awayDedicatedFans = 1;

  // ── Section 4: MVP ──
  String? _mvpHomeId;
  String? _mvpAwayId;
  final Set<String> _mvpHomeCandidateIds = {};
  final Set<String> _mvpAwayCandidateIds = {};
  _AftermatchRosterSortColumn _homeMvpRosterSortColumn =
      _AftermatchRosterSortColumn.number;
  _AftermatchRosterSortColumn _awayMvpRosterSortColumn =
      _AftermatchRosterSortColumn.number;
  bool _homeMvpRosterSortAscending = true;
  bool _awayMvpRosterSortAscending = true;

  // ── Section 5: Injuries ──
  final List<_InjuryEntry> _injuries = [];

  // ── Section 6: Expensive Mistakes ──
  int? _homeExpensiveRoll;
  int? _awayExpensiveRoll;
  int? _homeExpensiveD3;
  int? _awayExpensiveD3;
  int? _homeCatastropheD6A;
  int? _homeCatastropheD6B;
  int? _awayCatastropheD6A;
  int? _awayCatastropheD6B;

  // ── Post-match events ──
  final List<MatchEvent> _postMatchEvents = [];

  // ── Journeymen: keep/release decisions ──
  final Map<String, String> _temporaryPlayerDecisions = {};

  bool _initialized = false;
  bool _submitting = false;

  TextStyle get _displayLarge => TextStyle(
        fontFamily: AppTypography.displayFontFamily,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        height: 0.95,
      );

  String? _currentUserId() => ref.read(authStateProvider).valueOrNull?.user?.id;

  bool _isMatchParticipant(Match match) {
    final currentUserId = _currentUserId();
    if (currentUserId == null) return false;
    return match.home.userId == currentUserId ||
        match.away.userId == currentUserId;
  }

  bool _isCommissioner(Match match, League? league) {
    if (_isQM) return false;
    final currentUserId = _currentUserId();
    return currentUserId != null &&
        league?.ownerId == currentUserId &&
        !_isMatchParticipant(match);
  }

  bool _canManageSide(Match match, String side, League? league) {
    if (_isCommissioner(match, league)) return true;
    final currentUserId = _currentUserId();
    if (currentUserId == null) return false;
    return side == 'home'
        ? match.home.userId == currentUserId
        : match.away.userId == currentUserId;
  }

  Map<String, dynamic> _savedAftermatchReport(Match match, String side) {
    return side == 'home'
        ? match.aftermatchHomeReport
        : match.aftermatchAwayReport;
  }

  void _applySavedAftermatchReport(String side, Map<String, dynamic> report) {
    final purchases =
        side == 'home' ? _homePendingPurchases : _awayPendingPurchases;
    if (report.isEmpty) return;

    final expensive =
        (report['expensive_mistakes'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final purchasesJson =
        (report['purchases'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final temporaryPlayers = (report['temporary_players'] as List?) ?? const [];

    if (side == 'home') {
      _mvpHomeId = (report['mvp'] as String?) ?? _mvpHomeId;
      _homeStalling = (report['stalling'] as bool?) ?? _homeStalling;
      _homeFanRoll =
          (report['dedicated_fans_roll'] as num?)?.toInt() ?? _homeFanRoll;
      _homeExpensiveRoll =
          (expensive['roll'] as num?)?.toInt() ?? _homeExpensiveRoll;
      _homeExpensiveD3 = (expensive['d3'] as num?)?.toInt() ?? _homeExpensiveD3;
      _homeCatastropheD6A = (expensive['catastrophe_d6_a'] as num?)?.toInt() ??
          _homeCatastropheD6A;
      _homeCatastropheD6B = (expensive['catastrophe_d6_b'] as num?)?.toInt() ??
          _homeCatastropheD6B;
    } else {
      _mvpAwayId = (report['mvp'] as String?) ?? _mvpAwayId;
      _awayStalling = (report['stalling'] as bool?) ?? _awayStalling;
      _awayFanRoll =
          (report['dedicated_fans_roll'] as num?)?.toInt() ?? _awayFanRoll;
      _awayExpensiveRoll =
          (expensive['roll'] as num?)?.toInt() ?? _awayExpensiveRoll;
      _awayExpensiveD3 = (expensive['d3'] as num?)?.toInt() ?? _awayExpensiveD3;
      _awayCatastropheD6A = (expensive['catastrophe_d6_a'] as num?)?.toInt() ??
          _awayCatastropheD6A;
      _awayCatastropheD6B = (expensive['catastrophe_d6_b'] as num?)?.toInt() ??
          _awayCatastropheD6B;
    }

    purchases.players.clear();
    purchases.rerolls = (purchasesJson['rerolls'] as num?)?.toInt() ?? 0;
    purchases.cheerleaders =
        (purchasesJson['cheerleaders'] as num?)?.toInt() ?? 0;
    purchases.assistantCoaches =
        (purchasesJson['assistant_coaches'] as num?)?.toInt() ?? 0;
    purchases.apothecary = purchasesJson['apothecary'] == true;

    for (final entry in temporaryPlayers.whereType<Map>()) {
      final decision = entry['decision'] as String?;
      final playerId = entry['player_id'] as String?;
      if (decision != null && playerId != null) {
        _temporaryPlayerDecisions[playerId] = decision;
      }
    }
  }

  void _hydrateSavedPurchasesFromRoster(
    String side,
    Map<String, dynamic> report,
    BaseTeam? roster,
  ) {
    final purchases =
        side == 'home' ? _homePendingPurchases : _awayPendingPurchases;
    purchases.players.clear();
    final purchasesJson =
        (report['purchases'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final players = (purchasesJson['players'] as List?) ?? const [];

    for (final entry in players.whereType<Map>()) {
      final data = entry.cast<String, dynamic>();
      final baseType = data['base_type'] as String? ?? '';
      final position =
          roster?.positions.where((p) => p.id == baseType).firstOrNull;
      purchases.players.add(
        _PendingPlayerPurchase(
          baseType: baseType,
          positionName: position?.name ?? baseType,
          cost: position?.cost ?? 0,
          name: data['name'] as String?,
          number: (data['number'] as num?)?.toInt(),
        ),
      );
    }
  }

  void _initFromMatch(Match match) {
    if (_initialized) return;
    _initialized = true;

    _scoreHome = match.scoreHome;
    _scoreAway = match.scoreAway;
    _tdHome = match.scoreHome;
    _tdAway = match.scoreAway;
    _gate = match.gate ?? 0;
    _rerollsHome = match.rerollsUsedHome;
    _rerollsAway = match.rerollsUsedAway;
    _mvpHomeId = match.mvpHome;
    _mvpAwayId = match.mvpAway;

    _applySavedAftermatchReport('home', _savedAftermatchReport(match, 'home'));
    _applySavedAftermatchReport('away', _savedAftermatchReport(match, 'away'));

    for (final e in match.events) {
      final isHome = e.team == 'home';
      final eventType = e.type.toLowerCase();
      if (eventType == 'stall' || eventType == 'stalling') {
        isHome ? _homeStalling = true : _awayStalling = true;
      }

      switch (eventType) {
        case 'casualty':
          isHome ? _casHome++ : _casAway++;
        case 'completion':
          isHome ? _compHome++ : _compAway++;
        case 'throw_teammate':
          isHome ? _throwHome++ : _throwAway++;
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
    _throwHome = random.nextInt(3);
    _throwAway = random.nextInt(3);
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

  Future<({UserTeamDetail home, UserTeamDetail away})>
      _loadVisibleMatchTeams() {
    if (_isQM) {
      return ref
          .read(quickMatchRepositoryProvider)
          .getMatchTeamDetails(matchId);
    }
    return ref
        .read(leagueRepositoryProvider)
        .getMatchTeamDetails(leagueId, matchId);
  }

  Future<void> _loadTeams(Match match) async {
    if (_homeTeam != null &&
        _awayTeam != null &&
        _homeBaseRoster != null &&
        _awayBaseRoster != null) {
      return;
    }
    final visibleTeams = await _loadVisibleMatchTeams();
    final repo = ref.read(teamRepositoryProvider);
    final rosterResults = await Future.wait([
      repo.getBaseTeamDetail(visibleTeams.home.baseRosterId),
      repo.getBaseTeamDetail(visibleTeams.away.baseRosterId),
    ]);
    if (!mounted) return;
    setState(() {
      _homeTeam = visibleTeams.home;
      _awayTeam = visibleTeams.away;
      _homeBaseRoster = rosterResults[0];
      _awayBaseRoster = rosterResults[1];
      _homeFanFactor = visibleTeams.home.dedicatedFans;
      _awayFanFactor = visibleTeams.away.dedicatedFans;
      _homeDedicatedFans = visibleTeams.home.dedicatedFans;
      _awayDedicatedFans = visibleTeams.away.dedicatedFans;
      _hydrateSavedPurchasesFromRoster(
        'home',
        _savedAftermatchReport(match, 'home'),
        rosterResults[0],
      );
      _hydrateSavedPurchasesFromRoster(
        'away',
        _savedAftermatchReport(match, 'away'),
        rosterResults[1],
      );
    });
  }

  double _winningsFanBase(
    int fanFactorHome,
    int fanFactorAway, [
    WinningsRules? rules,
  ]) {
    return rules?.fanBase(fanFactorHome, fanFactorAway) ??
        (fanFactorHome + fanFactorAway) / 2;
  }

  int _calcWinnings(
    int fanFactorHome,
    int fanFactorAway,
    int myTDs,
    bool stalling, [
    WinningsRules? rules,
  ]) {
    return rules?.calculate(
          teamFanFactor: fanFactorHome,
          opponentFanFactor: fanFactorAway,
          touchdowns: myTDs,
          stalling: stalling,
        ) ??
        (((fanFactorHome + fanFactorAway) / 2 + myTDs + (stalling ? 0 : 1)) *
                10000)
            .round();
  }

  int _currentHomeWinnings([WinningsRules? rules]) => _calcWinnings(
        _homeFanFactor,
        _awayFanFactor,
        _tdHome,
        _homeStalling,
        rules,
      );

  int _currentAwayWinnings([WinningsRules? rules]) => _calcWinnings(
        _awayFanFactor,
        _homeFanFactor,
        _tdAway,
        _awayStalling,
        rules,
      );

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

  void _setPostMatchStat(
    String type,
    String team,
    int value,
  ) {
    final safeValue = max(0, value);
    setState(() {
      switch ('$team:$type') {
        case 'home:touchdown':
          _tdHome = safeValue;
          _scoreHome = safeValue;
        case 'away:touchdown':
          _tdAway = safeValue;
          _scoreAway = safeValue;
        case 'home:casualty':
          _casHome = safeValue;
        case 'away:casualty':
          _casAway = safeValue;
        case 'home:completion':
          _compHome = safeValue;
        case 'away:completion':
          _compAway = safeValue;
        case 'home:throw_teammate':
          _throwHome = safeValue;
        case 'away:throw_teammate':
          _throwAway = safeValue;
        case 'home:interception':
          _intHome = safeValue;
        case 'away:interception':
          _intAway = safeValue;
        case 'home:foul':
          _foulHome = safeValue;
        case 'away:foul':
          _foulAway = safeValue;
        case 'home:ko':
          _koHome = safeValue;
        case 'away:ko':
          _koAway = safeValue;
        case 'home:reroll':
          _rerollsHome = safeValue;
        case 'away:reroll':
          _rerollsAway = safeValue;
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
        if (!(type == 'casualty' && draft.accidentalCasualty)) {
          _setPostMatchStat(type, team, nextValue);
        }
        return true;
      },
    );
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

  List<Map<String, dynamic>> _injuryPayloads() {
    return _injuries
        .map((injury) => {
              'team': injury.team,
              'player_id': injury.playerId,
              'casualty_roll': injury.casualtyRoll,
            })
        .toList();
  }

  _PendingTeamPurchases _pendingPurchases(String teamSide) =>
      teamSide == 'home' ? _homePendingPurchases : _awayPendingPurchases;

  UserTeamDetail? _teamForSide(String teamSide) =>
      teamSide == 'home' ? _homeTeam : _awayTeam;

  BaseTeam? _rosterForSide(String teamSide) =>
      teamSide == 'home' ? _homeBaseRoster : _awayBaseRoster;

  int _baseTreasuryAfterWinnings(String teamSide, [WinningsRules? rules]) {
    final team = _teamForSide(teamSide);
    if (team == null) return 0;
    final winnings = teamSide == 'home'
        ? _currentHomeWinnings(rules)
        : _currentAwayWinnings(rules);
    return team.treasury + winnings;
  }

  int _temporaryKeepCost(String teamSide) {
    final team = _teamForSide(teamSide);
    if (team == null) return 0;
    final decisions = _storedTemporaryPlayerDecisionsForSide(teamSide);
    return team.players
        .where((player) =>
            player.temporaryForMatch && decisions[player.id] == 'keep')
        .fold<int>(0, (sum, player) => sum + player.currentValue);
  }

  int _pendingPurchaseCost(String teamSide) {
    final team = _teamForSide(teamSide);
    final purchases = _pendingPurchases(teamSide);
    if (team == null) return 0;
    final staffCost = purchases.players.fold<int>(
          0,
          (sum, player) => sum + player.cost,
        ) +
        (purchases.rerolls * team.rerollCost * 2) +
        (purchases.cheerleaders * 10000) +
        (purchases.assistantCoaches * 10000) +
        (purchases.apothecary ? 50000 : 0);
    return staffCost;
  }

  int _treasuryBeforeExpensiveMistakes(String teamSide,
      [WinningsRules? rules]) {
    final remaining = _baseTreasuryAfterWinnings(teamSide, rules) -
        _temporaryKeepCost(teamSide) -
        _pendingPurchaseCost(teamSide);
    return max(0, remaining);
  }

  Map<String, String> _storedTemporaryPlayerDecisionsForSide(String teamSide) {
    final matchAsync = _isQM
        ? ref.read(_quickMatchDetailProvider(matchId)).valueOrNull
        : ref
            .read(_matchDetailProvider((leagueId: leagueId, matchId: matchId)))
            .valueOrNull;
    if (matchAsync == null) return {};
    final decisions = _storedTemporaryPlayerDecisions(matchAsync);
    final team = _teamForSide(teamSide);
    if (team == null) return {};
    final filtered = <String, String>{};
    for (final player in team.players) {
      final decision = decisions[player.id];
      if (decision != null) filtered[player.id] = decision;
    }
    return filtered;
  }

  Map<String, dynamic> _teamPurchasesPayload(String teamSide) {
    final purchases = _pendingPurchases(teamSide);
    return {
      'players': purchases.players
          .map((player) => {
                'base_type': player.baseType,
                if (player.name != null && player.name!.trim().isNotEmpty)
                  'name': player.name!.trim(),
                if (player.number != null) 'number': player.number,
              })
          .toList(),
      if (purchases.rerolls > 0) 'rerolls': purchases.rerolls,
      if (purchases.cheerleaders > 0) 'cheerleaders': purchases.cheerleaders,
      if (purchases.assistantCoaches > 0)
        'assistant_coaches': purchases.assistantCoaches,
      if (purchases.apothecary) 'apothecary': true,
    };
  }

  Map<String, dynamic> _winningsPayload() {
    return {
      'home_touchdowns': _tdHome,
      'away_touchdowns': _tdAway,
      'home_stalling': _homeStalling,
      'away_stalling': _awayStalling,
      'home_purchases': _teamPurchasesPayload('home'),
      'away_purchases': _teamPurchasesPayload('away'),
      'home_expensive_mistakes': {
        if (_homeExpensiveRoll != null) 'roll': _homeExpensiveRoll,
        if (_homeExpensiveD3 != null) 'd3': _homeExpensiveD3,
        if (_homeCatastropheD6A != null)
          'catastrophe_d6_a': _homeCatastropheD6A,
        if (_homeCatastropheD6B != null)
          'catastrophe_d6_b': _homeCatastropheD6B,
      },
      'away_expensive_mistakes': {
        if (_awayExpensiveRoll != null) 'roll': _awayExpensiveRoll,
        if (_awayExpensiveD3 != null) 'd3': _awayExpensiveD3,
        if (_awayCatastropheD6A != null)
          'catastrophe_d6_a': _awayCatastropheD6A,
        if (_awayCatastropheD6B != null)
          'catastrophe_d6_b': _awayCatastropheD6B,
      },
    };
  }

  Map<String, dynamic> _dedicatedFansPayload() {
    return {
      if (_homeFanRoll != null) 'home_roll': _homeFanRoll,
      if (_awayFanRoll != null) 'away_roll': _awayFanRoll,
    };
  }

  List<Map<String, dynamic>> _temporaryPlayerPayloads(
      Match match, League? league) {
    final decisions = _storedTemporaryPlayerDecisions(match);
    final payloads = <Map<String, dynamic>>[];
    void collect(UserTeamDetail? team, String side) {
      if (team == null || !_canManageSide(match, side, league)) return;
      for (final player in team.players) {
        if (!player.temporaryForMatch) continue;
        final decision = decisions[player.id] ?? 'release';
        payloads.add({
          'team': side,
          'player_id': player.id,
          'decision': decision,
        });
      }
    }

    collect(_homeTeam, 'home');
    collect(_awayTeam, 'away');
    return payloads;
  }

  Map<String, String> _storedTemporaryPlayerDecisions(Match match) {
    final decisions = <String, String>{};
    for (final event in match.events) {
      if (event.type != 'temporary_player_decision' || event.playerId == null) {
        continue;
      }
      final detail = (event.detail ?? '').toLowerCase();
      if (detail.contains('decision=keep')) {
        decisions[event.playerId!] = 'keep';
      } else if (detail.contains('decision=release')) {
        decisions[event.playerId!] = 'release';
      }
    }
    decisions.addAll(_temporaryPlayerDecisions);
    return decisions;
  }

  String? _reportBlockReason(Match match, League? league) {
    if (_homeTeam == null || _awayTeam == null) {
      return 'Cargando plantillas del partido';
    }
    final requireHome = _canManageSide(match, 'home', league);
    final requireAway = _canManageSide(match, 'away', league);
    final homeMvp = _mvpHomeId ??
        match.mvpHome ??
        _savedAftermatchReport(match, 'home')['mvp'];
    final awayMvp = _mvpAwayId ??
        match.mvpAway ??
        _savedAftermatchReport(match, 'away')['mvp'];
    if (requireHome && homeMvp == null) return 'Falta seleccionar el MVP local';
    if (requireAway && awayMvp == null) {
      return 'Falta seleccionar el MVP visitante';
    }
    final overflow = _rosterOverflowReason(match, league);
    if (overflow != null) return overflow;
    return null;
  }

  String? _rosterOverflowReason(Match match, League? league) {
    String? check(UserTeamDetail? team, String side) {
      if (team == null || !_canManageSide(match, side, league)) return null;
      final totalPlayers = _effectiveRosterCount(side);
      if (totalPlayers > 16) {
        final excess = totalPlayers - 16;
        return '${team.name}: superas el máximo de 16 jugadores. '
            'Libera temporales o cancela ${excess == 1 ? '1 alta' : '$excess altas'} antes de enviar.';
      }
      return null;
    }

    return check(_homeTeam, 'home') ?? check(_awayTeam, 'away');
  }

  Future<bool> _confirmSubmitAftermatch(Match match, League? league) async {
    final keepCount = _temporaryPlayerPayloads(match, league)
        .where((entry) => entry['decision'] == 'keep')
        .length;
    final releaseCount = _temporaryPlayerPayloads(match, league)
        .where((entry) => entry['decision'] == 'release')
        .length;
    final isCommissioner = _isCommissioner(match, league);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          isCommissioner
              ? 'Enviar informe final'
              : 'Enviar mi parte del informe',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isCommissioner
              ? 'Esto aplicara SPP, ganancias, lesiones y decisiones de temporales. Despues no se podra cambiar el post-partido.\n\n'
              : 'Se guardara tu parte del informe en el servidor de forma independiente. El comisario podra revisar y enviar el informe completo despues.\n\n'
                  'Sustitutos a conservar: $keepCount\n'
                  'Temporales a liberar: $releaseCount',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Enviar informe'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _setMvpSelection({
    required bool isHome,
    required String? playerId,
  }) async {
    if (playerId == null) return;
    setState(() {
      if (isHome) {
        _mvpHomeId = playerId;
      } else {
        _mvpAwayId = playerId;
      }
    });
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

  Future<void> _submitAfterMatch(Match match, League? league) async {
    final isCommissioner = _isCommissioner(match, league);
    final mySideSubmitted = _canManageSide(match, 'home', league)
        ? match.aftermatchHomeSubmittedAt != null
        : _canManageSide(match, 'away', league)
            ? match.aftermatchAwaySubmittedAt != null
            : false;
    if (!isCommissioner && mySideSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu parte del informe ya fue enviada'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final blockReason = _reportBlockReason(match, league);
    if (blockReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blockReason), backgroundColor: AppColors.error),
      );
      return;
    }
    final confirmed = await _confirmSubmitAftermatch(match, league);
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(leagueRepositoryProvider);
      final canManageHome = _canManageSide(match, 'home', league);
      final canManageAway = _canManageSide(match, 'away', league);
      final rules = ref.read(expensiveMistakesRulesProvider).valueOrNull;
      if (rules == null) {
        throw Exception('Reglas de errores costosos no cargadas');
      }
      final winningsRules = ref.read(winningsRulesProvider).valueOrNull;
      if (winningsRules == null) {
        throw Exception('Reglas de ganancias no cargadas');
      }
      if (ref.read(dedicatedFansRulesProvider).valueOrNull == null) {
        throw Exception('Reglas de seguidores entregados no cargadas');
      }
      if (_scoreHome != _scoreAway && canManageHome && _homeFanRoll == null) {
        throw Exception('Completa la tirada de seguidores del equipo local');
      }
      if (_scoreHome != _scoreAway && canManageAway && _awayFanRoll == null) {
        throw Exception(
            'Completa la tirada de seguidores del equipo visitante');
      }
      final homeTreasury =
          _treasuryBeforeExpensiveMistakes('home', winningsRules);
      final awayTreasury =
          _treasuryBeforeExpensiveMistakes('away', winningsRules);
      final homeFinalTreasury = canManageHome
          ? _expensiveFinalTreasury(
              rules: rules,
              treasury: homeTreasury,
              result: _homeExpensiveRoll == null
                  ? null
                  : rules.resultFor(homeTreasury, _homeExpensiveRoll!),
              d3: _homeExpensiveD3,
              d6A: _homeCatastropheD6A,
              d6B: _homeCatastropheD6B,
            )
          : 0;
      final awayFinalTreasury = canManageAway
          ? _expensiveFinalTreasury(
              rules: rules,
              treasury: awayTreasury,
              result: _awayExpensiveRoll == null
                  ? null
                  : rules.resultFor(awayTreasury, _awayExpensiveRoll!),
              d3: _awayExpensiveD3,
              d6A: _awayCatastropheD6A,
              d6B: _awayCatastropheD6B,
            )
          : 0;
      if ((canManageHome && homeFinalTreasury == null) ||
          (canManageAway && awayFinalTreasury == null)) {
        throw Exception('Completa las tiradas de errores costosos');
      }

      final temporaryPlayers = _temporaryPlayerPayloads(match, league);
      final updated = await repo.applyAftermatch(
        leagueId: leagueId,
        matchId: matchId,
        mvpHome: canManageHome ? (_mvpHomeId ?? match.mvpHome) : null,
        mvpAway: canManageAway ? (_mvpAwayId ?? match.mvpAway) : null,
        gate: _gate,
        postMatchEvents: _postMatchEventPayloads(),
        injuries: _injuryPayloads(),
        winnings: _winningsPayload(),
        dedicatedFans: _dedicatedFansPayload(),
        temporaryPlayers: temporaryPlayers,
      );

      if (!mounted) return;
      ref.invalidate(
          _matchDetailProvider((leagueId: leagueId, matchId: matchId)));
      ref.invalidate(_leagueProvider(leagueId));
      if (updated.aftermatchSppAppliedAt != null) {
        ref.read(tempHiredPlayersProvider).clear();
        ref.invalidate(myUserTeamsProvider);
        ref.invalidate(userTeamDetailProvider(match.home.teamId));
        ref.invalidate(userTeamDetailProvider(match.away.teamId));
        context.go('/league/$leagueId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu parte del informe se ha guardado correctamente.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
    final league =
        _isQM ? null : ref.watch(_leagueProvider(leagueId)).valueOrNull;

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
          return _buildBody(match, league);
        },
      ),
    );
  }

  Widget _buildBody(Match match, League? league) {
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
                _buildLeaguePointsSection(match),
                const SizedBox(height: 28),
                _buildWinningsSection(match, league),
                const SizedBox(height: 28),
                _buildDedicatedFansSection(match, league),
                const SizedBox(height: 28),
                _buildMvpSection(match, league),
                const SizedBox(height: 28),
                _buildRosterManagementSection(match, league),
                const SizedBox(height: 28),
                _buildExpensiveMistakesSection(match, league),
                const SizedBox(height: 36),
                _buildSubmitButton(match, league),
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
          _statRow('Lanzar compañero', _throwHome, _throwAway, AppColors.info,
              PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'throw_teammate',
                    team: 'home',
                    currentValue: _throwHome,
                    nextValue: v,
                  ),
              onAwayChanged: (v) => _handlePostMatchStatChanged(
                    match: match,
                    type: 'throw_teammate',
                    team: 'away',
                    currentValue: _throwAway,
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
          _stallingRow(lang),
        ],
      ),
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
  // SECTION 2: League Points
  // ═══════════════════════════════════════════════════════════

  Widget _buildLeaguePointsSection(Match match) {
    final rulesAsync = ref.watch(leaguePointsRulesProvider);
    final lang = ref.watch(localeProvider);

    return rulesAsync.when(
      loading: () => _sectionCard(
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
        title: (lang == 'es' ? 'PUNTOS DE LIGA' : 'LEAGUE POINTS'),
        color: AppColors.primary,
        centerTitle: true,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
      error: (error, _) => _sectionCard(
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        title: (lang == 'es' ? 'PUNTOS DE LIGA' : 'LEAGUE POINTS'),
        color: AppColors.warning,
        centerTitle: true,
        child: Text(
          '${lang == 'es' ? 'No se pudieron cargar las reglas' : 'Could not load rules'}: $error',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
      data: (rules) {
        final homeLines = _leaguePointLines(
          rules: rules,
          lang: lang,
          touchdownsFor: _tdHome,
          touchdownsAgainst: _tdAway,
          casualtiesFor: _casHome,
        );
        final awayLines = _leaguePointLines(
          rules: rules,
          lang: lang,
          touchdownsFor: _tdAway,
          touchdownsAgainst: _tdHome,
          casualtiesFor: _casAway,
        );

        return _sectionCard(
          icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          title: (lang == 'es' ? 'PUNTOS DE LIGA' : 'LEAGUE POINTS'),
          subtitle: rules.description[lang] ?? rules.description['en'],
          color: AppColors.primary,
          centerTitle: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;
              final home = _leaguePointsTeamCol(
                teamName: _homeTeam?.name ?? match.home.teamName,
                lines: homeLines,
                color: AppColors.info,
              );
              final away = _leaguePointsTeamCol(
                teamName: _awayTeam?.name ?? match.away.teamName,
                lines: awayLines,
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
                  Container(
                      width: 1, height: 150, color: AppColors.surfaceLight),
                  Expanded(child: away),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_LeaguePointLine> _leaguePointLines({
    required LeaguePointsRules rules,
    required String lang,
    required int touchdownsFor,
    required int touchdownsAgainst,
    required int casualtiesFor,
  }) {
    final lines = <_LeaguePointLine>[];
    if (touchdownsFor > touchdownsAgainst) {
      lines.add(
          _LeaguePointLine(lang == 'es' ? 'Victoria' : 'Win', rules.winPoints));
    } else if (touchdownsFor == touchdownsAgainst) {
      lines.add(
          _LeaguePointLine(lang == 'es' ? 'Empate' : 'Draw', rules.drawPoints));
    } else if (rules.lossPoints > 0) {
      lines.add(_LeaguePointLine(
          lang == 'es' ? 'Derrota' : 'Loss', rules.lossPoints));
    }

    if (touchdownsFor > rules.touchdownBonusThreshold &&
        rules.touchdownBonusPoints > 0) {
      lines.add(_LeaguePointLine(
        lang == 'es'
            ? 'Mas de ${rules.touchdownBonusThreshold} TD anotados'
            : 'More than ${rules.touchdownBonusThreshold} TD scored',
        rules.touchdownBonusPoints,
      ));
    }
    if (touchdownsAgainst == 0 && rules.shutoutBonusPoints > 0) {
      lines.add(_LeaguePointLine(
        lang == 'es' ? 'Encajar 0 TD' : 'Concede 0 TD',
        rules.shutoutBonusPoints,
      ));
    }
    if (casualtiesFor >= rules.casualtyBonusThreshold &&
        rules.casualtyBonusPoints > 0) {
      lines.add(_LeaguePointLine(
        lang == 'es'
            ? '${rules.casualtyBonusThreshold}+ lesiones con SPP'
            : '${rules.casualtyBonusThreshold}+ SPP casualties',
        rules.casualtyBonusPoints,
      ));
    }
    return lines;
  }

  Widget _leaguePointsTeamCol({
    required String teamName,
    required List<_LeaguePointLine> lines,
    required Color color,
  }) {
    final total = lines.fold<int>(0, (sum, line) => sum + line.points);
    final lang = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Text(
            teamName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '+$total',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.success,
                fontSize: 74,
                fontWeight: FontWeight.w900,
                fontFamily: AppTypography.displayFontFamily,
                height: 0.86,
                shadows: [
                  Shadow(
                    color: AppColors.success.withValues(alpha: 0.5),
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
          Text(
            lang == 'es' ? 'puntos' : 'points',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '+${line.points}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 2: Winnings
  // ═══════════════════════════════════════════════════════════

  Widget _buildWinningsSection(Match match, League? league) {
    final rules = ref.watch(winningsRulesProvider).valueOrNull;
    final homeWinnings = _currentHomeWinnings(rules);
    final awayWinnings = _currentAwayWinnings(rules);
    final lang = ref.watch(localeProvider);
    final showHome = _canManageSide(match, 'home', league);
    final showAway = _canManageSide(match, 'away', league);

    if (!showHome && !showAway) return const SizedBox.shrink();

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
            winnings: homeWinnings,
            color: AppColors.info,
          );

          final away = _winningsTeamCol(
            teamName: _awayTeam?.name ?? 'Away',
            myFanFactor: _awayFanFactor,
            opponentFanFactor: _homeFanFactor,
            touchdowns: _tdAway,
            stalling: _awayStalling,
            winnings: awayWinnings,
            color: AppColors.error,
          );

          if (showHome && showAway && isCompact) {
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

          if (showHome && showAway) {
            return Row(
              children: [
                Expanded(child: home),
                Container(width: 1, height: 120, color: AppColors.surfaceLight),
                Expanded(child: away),
              ],
            );
          }

          return showHome ? home : away;
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
    final rules = ref.read(winningsRulesProvider).valueOrNull;
    final fanBase = _winningsFanBase(myFanFactor, opponentFanFactor, rules);
    final stallBonus = stalling ? 0 : (rules?.noStallingBonus ?? 1);
    final multiplier = rules?.goldMultiplier ?? 10000;
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
                    '($fanBaseText + $touchdowns + $stallBonus) × ${_fmtGold(multiplier)}',
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

  Widget _buildDedicatedFansSection(Match match, League? league) {
    final lang = ref.watch(localeProvider);
    final rules = ref.watch(dedicatedFansRulesProvider).valueOrNull;
    final showHome = _canManageSide(match, 'home', league);
    final showAway = _canManageSide(match, 'away', league);

    if (!showHome && !showAway) return const SizedBox.shrink();

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
            rules: rules,
            color: AppColors.info,
          );

          final away = _fanRollCol(
            teamName: _awayTeam?.name ?? 'Away',
            currentFans: _awayDedicatedFans,
            roll: _awayFanRoll,
            onRollChanged: (v) => setState(() => _awayFanRoll = v),
            won: _scoreAway > _scoreHome,
            lost: _scoreAway < _scoreHome,
            rules: rules,
            color: AppColors.error,
          );

          if (showHome && showAway && isCompact) {
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

          if (showHome && showAway) {
            return Row(
              children: [
                Expanded(child: home),
                Container(width: 1, height: 100, color: AppColors.surfaceLight),
                Expanded(child: away),
              ],
            );
          }

          return showHome ? home : away;
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
    required DedicatedFansRules? rules,
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
      rules: rules,
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
    DedicatedFansRules? rules,
  }) {
    if (rules != null) {
      return rules.nextValue(
        current: currentFans,
        roll: roll,
        won: won,
        lost: lost,
      );
    }
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

    UserPlayer? findPlayer(String team, String playerId) {
      final players = team == 'home' ? _homeTeam?.players : _awayTeam?.players;
      return players?.where((p) => p.id == playerId).firstOrNull;
    }

    bool generatesSpp(String team, String playerId) {
      final player = findPlayer(team, playerId);
      return player != null && !player.baseType.startsWith('star_');
    }

    _SppTally ensureTally(String playerId, String? playerName, String team) {
      final key = '$team:$playerId';
      sppMap.putIfAbsent(
          key, () => _SppTally(playerId, playerName ?? '?', team));
      return sppMap[key]!;
    }

    void addSpp(
        String? playerId, String? playerName, String team, String type) {
      if (playerId == null) return;
      if (!generatesSpp(team, playerId)) return;
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
        if (generatesSpp(event.team, event.victimId!)) {
          ensureTally(event.victimId!, event.victimName, event.team)
              .throwTeammate++;
        }
      }
      if (_throwTeammateSuperb(event.detail) && event.playerId != null) {
        if (generatesSpp(event.team, event.playerId!)) {
          ensureTally(event.playerId!, event.playerName, event.team)
              .throwTeammate++;
        }
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
      if (generatesSpp('home', _mvpHomeId!)) {
        final key = 'home:$_mvpHomeId';
        final name = _homeTeam?.players
                .where((p) => p.id == _mvpHomeId)
                .firstOrNull
                ?.name ??
            '?';
        sppMap.putIfAbsent(key, () => _SppTally(_mvpHomeId!, name, 'home'));
        sppMap[key]!.mvp = true;
      }
    }
    if (_mvpAwayId != null) {
      if (generatesSpp('away', _mvpAwayId!)) {
        final key = 'away:$_mvpAwayId';
        final name = _awayTeam?.players
                .where((p) => p.id == _mvpAwayId)
                .firstOrNull
                ?.name ??
            '?';
        sppMap.putIfAbsent(key, () => _SppTally(_mvpAwayId!, name, 'away'));
        sppMap[key]!.mvp = true;
      }
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

  Widget _buildMvpSection(Match match, League? league) {
    final lang = ref.watch(localeProvider);
    final sppMap = _buildSppTallies(match);
    final tempData = ref.watch(tempHiredPlayersProvider);
    final homeTempIds = tempData.getForTeam(match.home.teamId);
    final awayTempIds = tempData.getForTeam(match.away.teamId);
    final showHome = _canManageSide(match, 'home', league);
    final showAway = _canManageSide(match, 'away', league);

    if (!showHome && !showAway) return const SizedBox.shrink();

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
            isHome: true,
            teamKey: 'home',
            tempPlayerIds: homeTempIds,
            sppMap: sppMap,
            selectedId: _mvpHomeId,
            candidateIds: _mvpHomeCandidateIds,
            onChanged: (v) => _setMvpSelection(isHome: true, playerId: v),
            color: AppColors.info,
          );

          final away = _mvpPicker(
            teamName: _awayTeam?.name ?? 'Away',
            players: _playedPlayers(_awayTeam?.players ?? [], match.awaySquad),
            isHome: false,
            teamKey: 'away',
            tempPlayerIds: awayTempIds,
            sppMap: sppMap,
            selectedId: _mvpAwayId,
            candidateIds: _mvpAwayCandidateIds,
            onChanged: (v) => _setMvpSelection(isHome: false, playerId: v),
            color: AppColors.error,
          );

          if (showHome && showAway && isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                home,
                const SizedBox(height: 16),
                away,
              ],
            );
          }

          if (showHome && showAway) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: home),
                const SizedBox(width: 12),
                Expanded(child: away),
              ],
            );
          }

          return showHome ? home : away;
        },
      ),
    );
  }

  Widget _mvpPicker({
    required String teamName,
    required List<UserPlayer> players,
    required bool isHome,
    required String teamKey,
    required Set<String> tempPlayerIds,
    required Map<String, _SppTally> sppMap,
    required String? selectedId,
    required Set<String> candidateIds,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    final lang = ref.watch(localeProvider);
    final activePlayers = players.where((p) => p.status != 'dead').toList();
    final mvpEligiblePlayers =
        activePlayers.where((p) => !p.baseType.startsWith('star_')).toList();
    final requiredCandidateCount = min(6, mvpEligiblePlayers.length);
    final validCandidateIds = mvpEligiblePlayers.map((p) => p.id).toSet();
    candidateIds.removeWhere((id) => !validCandidateIds.contains(id));
    final randomCandidates = mvpEligiblePlayers
        .where((player) => candidateIds.contains(player.id))
        .toList();
    final canRandom = requiredCandidateCount > 0 &&
        randomCandidates.length == requiredCandidateCount;
    final sortColumn =
        isHome ? _homeMvpRosterSortColumn : _awayMvpRosterSortColumn;
    final sortAscending =
        isHome ? _homeMvpRosterSortAscending : _awayMvpRosterSortAscending;
    final sortedActivePlayers = _sortAftermatchRosterPlayers(
      activePlayers,
      candidateIds,
      tempPlayerIds,
      sortColumn,
      sortAscending,
    );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.34)),
              ),
              child: Text(
                '${randomCandidates.length}/$requiredCandidateCount',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
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
              onPressed: !canRandom
                  ? null
                  : () {
                      final shuffled = List.of(randomCandidates)..shuffle();
                      onChanged(shuffled.first.id);
                    },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _mvpRosterHeader(isHome, sortColumn, sortAscending, color),
        const SizedBox(height: 6),
        ...sortedActivePlayers.map((p) {
          final selected = p.id == selectedId;
          final isStarPlayer = p.baseType.startsWith('star_');
          final isTemp = tempPlayerIds.contains(p.id) || p.temporaryForMatch;
          final isJourneyman = p.journeyman;
          final isEligibleForMvp = !isStarPlayer;
          final isCandidate = candidateIds.contains(p.id);
          final tally =
              sppMap['$teamKey:${p.id}'] ?? _SppTally(p.id, p.name, teamKey);
          return InkWell(
            onTap: isEligibleForMvp
                ? () => _toggleMvpCandidate(
                      candidateIds: candidateIds,
                      playerId: p.id,
                      maxCandidates: requiredCandidateCount,
                    )
                : null,
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
                  Checkbox(
                    value: isCandidate,
                    onChanged: isEligibleForMvp
                        ? (_) => _toggleMvpCandidate(
                              candidateIds: candidateIds,
                              playerId: p.id,
                              maxCandidates: requiredCandidateCount,
                            )
                        : null,
                    activeColor: color,
                    checkColor: Colors.black,
                    side: BorderSide(
                      color: isEligibleForMvp
                          ? color.withValues(alpha: 0.66)
                          : AppColors.surfaceLight,
                    ),
                  ),
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
                          _tempPlayerSppBadge(
                            isStarPlayer: isStarPlayer,
                            isJourneyman: isJourneyman,
                          ),
                        ] else if (isStarPlayer) ...[
                          const SizedBox(height: 5),
                          _tempPlayerSppBadge(
                            isStarPlayer: true,
                            isJourneyman: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _manualMvpButton(
                    selected: selected,
                    enabled: isEligibleForMvp,
                    color: color,
                    onPressed: () => onChanged(p.id),
                  ),
                  if (tally.total > 0) ...[
                    const SizedBox(width: 8),
                    _sppBadge(
                      tally.total,
                      onTap: () => _showPlayerSppDialog(p, teamKey, tally),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _mvpRosterHeader(
    bool isHome,
    _AftermatchRosterSortColumn activeColumn,
    bool ascending,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: _mvpRosterHeaderCell(
              'CAND',
              _AftermatchRosterSortColumn.candidate,
              activeColumn,
              ascending,
              isHome,
              color,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: _mvpRosterHeaderCell(
              '#',
              _AftermatchRosterSortColumn.number,
              activeColumn,
              ascending,
              isHome,
              color,
            ),
          ),
          Expanded(
            child: _mvpRosterHeaderCell(
              'NOMBRE',
              _AftermatchRosterSortColumn.name,
              activeColumn,
              ascending,
              isHome,
              color,
              alignStart: true,
            ),
          ),
          SizedBox(
            width: 92,
            child: _mvpRosterHeaderCell(
              'TIPO',
              _AftermatchRosterSortColumn.kind,
              activeColumn,
              ascending,
              isHome,
              color,
            ),
          ),
          SizedBox(
            width: 52,
            child: _mvpRosterHeaderCell(
              'SPP',
              _AftermatchRosterSortColumn.spp,
              activeColumn,
              ascending,
              isHome,
              color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mvpRosterHeaderCell(
    String label,
    _AftermatchRosterSortColumn column,
    _AftermatchRosterSortColumn activeColumn,
    bool ascending,
    bool isHome,
    Color color, {
    bool alignStart = false,
  }) {
    final active = column == activeColumn;
    return InkWell(
      onTap: () => _setAftermatchRosterSort(isHome, column),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisAlignment:
            alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? color : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 3),
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 10,
            ),
          ],
        ],
      ),
    );
  }

  List<UserPlayer> _sortAftermatchRosterPlayers(
    List<UserPlayer> players,
    Set<String> candidateIds,
    Set<String> tempPlayerIds,
    _AftermatchRosterSortColumn column,
    bool ascending,
  ) {
    final sorted = List<UserPlayer>.from(players);
    sorted.sort((a, b) {
      int result;
      switch (column) {
        case _AftermatchRosterSortColumn.candidate:
          result = (candidateIds.contains(a.id) ? 1 : 0)
              .compareTo(candidateIds.contains(b.id) ? 1 : 0);
        case _AftermatchRosterSortColumn.number:
          result = a.number.compareTo(b.number);
        case _AftermatchRosterSortColumn.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _AftermatchRosterSortColumn.kind:
          result = _aftermatchPlayerKind(a, tempPlayerIds)
              .compareTo(_aftermatchPlayerKind(b, tempPlayerIds));
        case _AftermatchRosterSortColumn.spp:
          result = a.spp.compareTo(b.spp);
      }
      if (result == 0) result = a.number.compareTo(b.number);
      return ascending ? result : -result;
    });
    return sorted;
  }

  String _aftermatchPlayerKind(UserPlayer player, Set<String> tempPlayerIds) {
    final isStarPlayer = player.baseType.startsWith('star_');
    final isTemp =
        tempPlayerIds.contains(player.id) || player.temporaryForMatch;
    if (isStarPlayer) return 'star';
    if (isTemp && player.journeyman) return 'sustituto';
    if (isTemp) return 'mercenario';
    return 'normal';
  }

  void _setAftermatchRosterSort(
      bool isHome, _AftermatchRosterSortColumn column) {
    setState(() {
      if (isHome) {
        if (_homeMvpRosterSortColumn == column) {
          _homeMvpRosterSortAscending = !_homeMvpRosterSortAscending;
        } else {
          _homeMvpRosterSortColumn = column;
          _homeMvpRosterSortAscending = true;
        }
      } else {
        if (_awayMvpRosterSortColumn == column) {
          _awayMvpRosterSortAscending = !_awayMvpRosterSortAscending;
        } else {
          _awayMvpRosterSortColumn = column;
          _awayMvpRosterSortAscending = true;
        }
      }
    });
  }

  void _toggleMvpCandidate({
    required Set<String> candidateIds,
    required String playerId,
    required int maxCandidates,
  }) {
    setState(() {
      if (candidateIds.contains(playerId)) {
        candidateIds.remove(playerId);
      } else if (candidateIds.length < maxCandidates) {
        candidateIds.add(playerId);
      }
    });
  }

  Widget _manualMvpButton({
    required bool selected,
    required bool enabled,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: 'MVP manual',
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          PhosphorIcons.star(
            selected ? PhosphorIconsStyle.fill : PhosphorIconsStyle.bold,
          ),
          size: 18,
        ),
        label: Text(selected ? 'MVP' : 'Manual'),
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? AppColors.accent.withValues(alpha: 0.24)
              : AppColors.surfaceLight.withValues(alpha: 0.42),
          foregroundColor: selected ? AppColors.accent : color,
          disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.42),
          minimumSize: const Size(88, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _tempPlayerSppBadge(
      {required bool isStarPlayer, required bool isJourneyman}) {
    final color = isStarPlayer
        ? AppColors.accent
        : isJourneyman
            ? AppColors.info
            : AppColors.primaryLight;
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
                : isJourneyman
                    ? PhosphorIcons.userSwitch(PhosphorIconsStyle.fill)
                    : PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isStarPlayer
                ? 'Estrella temporal'
                : isJourneyman
                    ? 'Sustituto temporal'
                    : 'Mercenario temporal',
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
    final available = players.where((p) => p.status == 'healthy').toList();
    if (squad.isEmpty) return available;

    final squadSet = squad.toSet();
    return players
        .where((p) =>
            squadSet.contains(p.id) ||
            (p.temporaryForMatch && p.temporaryMatchId == matchId))
        .toList();
  }

  Widget _sppBadge(int points, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              color: AppColors.accent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '+$points SPP',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: AppTypography.displayFontFamily,
              ),
            ),
          ],
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

  // ═══════════════════════════════════════════════════════════
  // SECTION 7: Roster Management
  // ═══════════════════════════════════════════════════════════

  Widget _buildRosterManagementSection(Match match, League? league) {
    final winningsRules = ref.watch(winningsRulesProvider).valueOrNull;
    final canManageHome = _canManageSide(match, 'home', league);
    final canManageAway = _canManageSide(match, 'away', league);
    final tempContent = _buildTempHiredPlayersContent(match, league);

    if (!canManageHome && !canManageAway && tempContent == null) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      icon: PhosphorIcons.userGear(PhosphorIconsStyle.fill),
      title: 'GESTION DE PLANTILLA',
      subtitle:
          'Las compras y los temporales que conserves se descuentan antes de Errores costosos.',
      color: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canManageHome)
            _buildTeamPurchasePanel(
              teamSide: 'home',
              teamName: _homeTeam?.name ?? match.home.teamName,
              color: AppColors.info,
              winningsRules: winningsRules,
            ),
          if (canManageHome && canManageAway) const SizedBox(height: 16),
          if (canManageAway)
            _buildTeamPurchasePanel(
              teamSide: 'away',
              teamName: _awayTeam?.name ?? match.away.teamName,
              color: AppColors.error,
              winningsRules: winningsRules,
            ),
          if (tempContent != null) ...[
            if (canManageHome || canManageAway) const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.surfaceLight),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text(
                  'SUSTITUTOS Y TEMPORALES',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Decide que jugadores temporales se quedan en la plantilla antes de la tirada de tesoreria.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            tempContent,
          ],
        ],
      ),
    );
  }

  Widget _buildTeamPurchasePanel({
    required String teamSide,
    required String teamName,
    required Color color,
    required WinningsRules? winningsRules,
  }) {
    final team = _teamForSide(teamSide);
    final roster = _rosterForSide(teamSide);
    if (team == null || roster == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando datos de $teamName...',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final purchases = _pendingPurchases(teamSide);
    final treasuryAfterWinnings =
        _baseTreasuryAfterWinnings(teamSide, winningsRules);
    final temporaryKeepCost = _temporaryKeepCost(teamSide);
    final purchaseCost = _pendingPurchaseCost(teamSide);
    final remainingTreasury =
        _treasuryBeforeExpensiveMistakes(teamSide, winningsRules);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  teamName,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _fansStatusPill(
                label:
                    'Tesoreria + ganancias: ${_fmtGold(treasuryAfterWinnings)}',
                color: color,
                icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _purchaseCounterChip(
                label: 'Rerrolls',
                subtitle: '${_fmtGold(team.rerollCost * 2)} GP',
                count: purchases.rerolls,
                color: color,
                onAdd: team.rerolls + purchases.rerolls >= 8
                    ? null
                    : () => _incrementTeamPurchase(
                          teamSide,
                          purchaseType: 'reroll',
                          cost: team.rerollCost * 2,
                        ),
                onRemove: purchases.rerolls == 0
                    ? null
                    : () => _decrementTeamPurchase(teamSide,
                        purchaseType: 'reroll'),
              ),
              _purchaseCounterChip(
                label: 'Ayudantes',
                subtitle: '10,000 GP',
                count: purchases.assistantCoaches,
                color: color,
                onAdd: team.assistantCoaches + purchases.assistantCoaches >= 6
                    ? null
                    : () => _incrementTeamPurchase(
                          teamSide,
                          purchaseType: 'assistant',
                          cost: 10000,
                        ),
                onRemove: purchases.assistantCoaches == 0
                    ? null
                    : () => _decrementTeamPurchase(
                          teamSide,
                          purchaseType: 'assistant',
                        ),
              ),
              _purchaseCounterChip(
                label: 'Animadoras',
                subtitle: '10,000 GP',
                count: purchases.cheerleaders,
                color: color,
                onAdd: team.cheerleaders + purchases.cheerleaders >= 6
                    ? null
                    : () => _incrementTeamPurchase(
                          teamSide,
                          purchaseType: 'cheerleader',
                          cost: 10000,
                        ),
                onRemove: purchases.cheerleaders == 0
                    ? null
                    : () => _decrementTeamPurchase(
                          teamSide,
                          purchaseType: 'cheerleader',
                        ),
              ),
              _purchaseToggleChip(
                label: 'Boticario',
                subtitle: team.apothecary
                    ? 'Ya disponible'
                    : !team.apothecaryAllowed
                        ? 'No permitido'
                        : '50,000 GP',
                selected: purchases.apothecary,
                color: color,
                enabled: !team.apothecary && team.apothecaryAllowed,
                onTap: () => _toggleApothecaryPurchase(teamSide),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jugadores permanentes a precio normal del roster.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPlayerPurchaseDialog(teamSide),
                icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                    size: 16),
                label: const Text('Comprar jugador'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
          if (purchases.players.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...List.generate(purchases.players.length, (index) {
              final player = purchases.players[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name?.trim().isNotEmpty == true
                                ? player.name!.trim()
                                : player.positionName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${player.positionName} · ${player.number != null ? '#${player.number}' : 'Numero automatico'} · ${_fmtGold(player.cost)} GP',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar',
                      onPressed: () =>
                          _removePendingPlayerPurchase(teamSide, index),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: AppColors.error, size: 16),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _fansStatusPill(
                label: 'Temporales conservados: ${_fmtGold(temporaryKeepCost)}',
                color: AppColors.warning,
                icon: PhosphorIcons.userCheck(PhosphorIconsStyle.fill),
              ),
              _fansStatusPill(
                label: 'Compras: ${_fmtGold(purchaseCost)}',
                color: AppColors.primary,
                icon: PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
              ),
              _fansStatusPill(
                label:
                    'Antes de errores costosos: ${_fmtGold(remainingTreasury)}',
                color: AppColors.accent,
                icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _purchaseCounterChip({
    required String label,
    required String subtitle,
    required int count,
    required Color color,
    required VoidCallback? onAdd,
    required VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold), size: 14),
            color: color,
          ),
          Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 14),
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _purchaseToggleChip({
    required String label,
    required String subtitle,
    required bool selected,
    required bool enabled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : AppColors.surfaceLight.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: selected ? 0.5 : 0.22)
                : AppColors.surfaceLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                  : PhosphorIcons.plusCircle(PhosphorIconsStyle.bold),
              size: 16,
              color: enabled ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _incrementTeamPurchase(
    String teamSide, {
    required String purchaseType,
    required int cost,
  }) {
    final remaining = _treasuryBeforeExpensiveMistakes(
      teamSide,
      ref.read(winningsRulesProvider).valueOrNull,
    );
    if (remaining < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tesoreria suficiente para esa compra'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final purchases = _pendingPurchases(teamSide);
    setState(() {
      switch (purchaseType) {
        case 'reroll':
          purchases.rerolls++;
        case 'assistant':
          purchases.assistantCoaches++;
        case 'cheerleader':
          purchases.cheerleaders++;
      }
    });
  }

  void _decrementTeamPurchase(String teamSide, {required String purchaseType}) {
    final purchases = _pendingPurchases(teamSide);
    setState(() {
      switch (purchaseType) {
        case 'reroll':
          if (purchases.rerolls > 0) purchases.rerolls--;
        case 'assistant':
          if (purchases.assistantCoaches > 0) purchases.assistantCoaches--;
        case 'cheerleader':
          if (purchases.cheerleaders > 0) purchases.cheerleaders--;
      }
    });
  }

  void _toggleApothecaryPurchase(String teamSide) {
    final remaining = _treasuryBeforeExpensiveMistakes(
      teamSide,
      ref.read(winningsRulesProvider).valueOrNull,
    );
    final purchases = _pendingPurchases(teamSide);
    if (!purchases.apothecary && remaining < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tesoreria suficiente para comprar boticario'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      purchases.apothecary = !purchases.apothecary;
    });
  }

  int _effectiveRosterCount(String teamSide) {
    final team = _teamForSide(teamSide);
    if (team == null) return 0;
    final decisions = _storedTemporaryPlayerDecisionsForSide(teamSide);
    final permanent =
        team.players.where((player) => !player.temporaryForMatch).length;
    final keptTemporary = team.players
        .where((player) =>
            player.temporaryForMatch && decisions[player.id] == 'keep')
        .length;
    return permanent +
        keptTemporary +
        _pendingPurchases(teamSide).players.length;
  }

  int _effectiveCountForBaseType(String teamSide, String baseType) {
    final team = _teamForSide(teamSide);
    if (team == null) return 0;
    final decisions = _storedTemporaryPlayerDecisionsForSide(teamSide);
    final existing = team.players.where((player) {
      if (player.baseType != baseType) return false;
      if (!player.temporaryForMatch) return true;
      return decisions[player.id] == 'keep';
    }).length;
    final pending = _pendingPurchases(teamSide)
        .players
        .where((player) => player.baseType == baseType)
        .length;
    return existing + pending;
  }

  int _nextAvailablePlannedNumber(String teamSide) {
    final team = _teamForSide(teamSide);
    if (team == null) return 1;
    final decisions = _storedTemporaryPlayerDecisionsForSide(teamSide);
    final used = <int>{
      for (final player in team.players)
        if (!player.temporaryForMatch || decisions[player.id] == 'keep')
          player.number,
      for (final player in _pendingPurchases(teamSide).players)
        if (player.number != null) player.number!,
    };
    for (var number = 1; number <= 99; number++) {
      if (!used.contains(number)) return number;
    }
    return 99;
  }

  Future<void> _showPlayerPurchaseDialog(String teamSide) async {
    final roster = _rosterForSide(teamSide);
    final team = _teamForSide(teamSide);
    if (roster == null || team == null) return;
    final winningsRules = ref.read(winningsRulesProvider).valueOrNull;
    final remaining = _treasuryBeforeExpensiveMistakes(teamSide, winningsRules);
    final rosterCount = _effectiveRosterCount(teamSide);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Comprar jugador para ${team.name}'),
        content: SizedBox(
          width: 720,
          child: rosterCount >= 16
              ? const Text(
                  'La plantilla ya alcanzaria 16 jugadores con las compras planificadas.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: roster.positions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.surfaceLight,
                  ),
                  itemBuilder: (_, index) {
                    final position = roster.positions[index];
                    final count =
                        _effectiveCountForBaseType(teamSide, position.id);
                    final canBuy = count < position.maxQuantity &&
                        remaining >= position.cost;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(position.name),
                      subtitle: Text(
                        '$count/${position.maxQuantity} · ${_fmtGold(position.cost)} GP',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      trailing: ElevatedButton(
                        onPressed: canBuy
                            ? () async {
                                Navigator.of(dialogContext).pop();
                                await _showPlayerPurchaseDetailsDialog(
                                  teamSide,
                                  position,
                                );
                              }
                            : null,
                        child: const Text('Elegir'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showPlayerPurchaseDetailsDialog(
    String teamSide,
    BasePosition position,
  ) async {
    final nameCtrl = TextEditingController();
    final numberCtrl =
        TextEditingController(text: '${_nextAvailablePlannedNumber(teamSide)}');
    try {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Fichar ${position.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numero',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Coste: ${_fmtGold(position.cost)} GP',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Anadir'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      final remaining = _treasuryBeforeExpensiveMistakes(
        teamSide,
        ref.read(winningsRulesProvider).valueOrNull,
      );
      if (_effectiveRosterCount(teamSide) >= 16) {
        throw Exception('La plantilla ya alcanzaria 16 jugadores');
      }
      if (_effectiveCountForBaseType(teamSide, position.id) >=
          position.maxQuantity) {
        throw Exception('Ya has alcanzado el maximo para esa posicion');
      }
      if (remaining < position.cost) {
        throw Exception('No hay tesoreria suficiente para esta compra');
      }

      final parsedNumber = int.tryParse(numberCtrl.text.trim());
      if (parsedNumber == null || parsedNumber < 1 || parsedNumber > 99) {
        throw Exception('El numero debe estar entre 1 y 99');
      }
      final decisions = _storedTemporaryPlayerDecisionsForSide(teamSide);
      final usedNumber = _pendingPurchases(teamSide).players.any(
                (player) => player.number == parsedNumber,
              ) ||
          (_teamForSide(teamSide)?.players.any(
                    (player) =>
                        player.number == parsedNumber &&
                        !player.isDead &&
                        (!player.temporaryForMatch ||
                            decisions[player.id] == 'keep'),
                  ) ??
              false);
      if (usedNumber) {
        throw Exception('Ese numero ya esta ocupado');
      }

      setState(() {
        _pendingPurchases(teamSide).players.add(
              _PendingPlayerPurchase(
                baseType: position.id,
                positionName: position.name,
                name:
                    nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                number: parsedNumber,
                cost: position.cost,
              ),
            );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      nameCtrl.dispose();
      numberCtrl.dispose();
    }
  }

  void _removePendingPlayerPurchase(String teamSide, int index) {
    setState(() {
      final players = _pendingPurchases(teamSide).players;
      if (index >= 0 && index < players.length) {
        players.removeAt(index);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 7: Expensive Mistakes
  // ═══════════════════════════════════════════════════════════

  Widget _buildExpensiveMistakesSection(Match match, League? league) {
    final lang = ref.watch(localeProvider);
    final rulesAsync = ref.watch(expensiveMistakesRulesProvider);
    final winningsRules = ref.watch(winningsRulesProvider).valueOrNull;
    final homeTreasury =
        _treasuryBeforeExpensiveMistakes('home', winningsRules);
    final awayTreasury =
        _treasuryBeforeExpensiveMistakes('away', winningsRules);
    final showHome = _canManageSide(match, 'home', league);
    final showAway = _canManageSide(match, 'away', league);

    if (!showHome && !showAway) return const SizedBox.shrink();

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
                  _clearAwayExpensiveExtraDice();
                });
              },
              onD3Changed: (v) => setState(() => _awayExpensiveD3 = v),
              onD6AChanged: (v) => setState(() => _awayCatastropheD6A = v),
              onD6BChanged: (v) => setState(() => _awayCatastropheD6B = v),
              color: AppColors.error,
            );

            if (showHome && showAway && isCompact) {
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

            if (showHome && showAway) {
              return Row(
                children: [
                  Expanded(child: home),
                  Container(
                      width: 1, height: 170, color: AppColors.surfaceLight),
                  Expanded(child: away),
                ],
              );
            }

            return showHome ? home : away;
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

  Widget? _buildTempHiredPlayersContent(Match match, League? league) {
    final sppMap = _buildSppTallies(match);
    final tempData = ref.read(tempHiredPlayersProvider);
    final homeId = match.home.teamId;
    final awayId = match.away.teamId;
    final homeTempIds = tempData.getForTeam(homeId);
    final awayTempIds = tempData.getForTeam(awayId);
    final showHomeTempPlayers = _canManageSide(match, 'home', league);
    final showAwayTempPlayers = _canManageSide(match, 'away', league);

    List<UserPlayer> homeTempPlayers = [];
    List<UserPlayer> awayTempPlayers = [];
    if (_homeTeam != null && showHomeTempPlayers) {
      homeTempPlayers = _homeTeam!.players
          .where((p) => _isVisibleTemporaryPlayer(p, homeTempIds))
          .toList();
    }
    if (_awayTeam != null && showAwayTempPlayers) {
      awayTempPlayers = _awayTeam!.players
          .where((p) => _isVisibleTemporaryPlayer(p, awayTempIds))
          .toList();
    }

    if (homeTempPlayers.isEmpty && awayTempPlayers.isEmpty) {
      return null;
    }

    return Column(
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
          ...homeTempPlayers.map((p) => _buildTempPlayerRow(
                p,
                match,
                homeId,
                'home',
                spp: sppMap['home:${p.id}']?.total ?? 0,
                isStarPlayer: p.baseType.startsWith('star_'),
              )),
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
          ...awayTempPlayers.map((p) => _buildTempPlayerRow(
                p,
                match,
                awayId,
                'away',
                spp: sppMap['away:${p.id}']?.total ?? 0,
                isStarPlayer: p.baseType.startsWith('star_'),
              )),
        ],
      ],
    );
  }

  Widget _buildTempHiredPlayersSection(Match match) {
    final content = _buildTempHiredPlayersContent(match, null);
    if (content == null) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      icon: PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
      title: 'SUSTITUTOS Y TEMPORALES',
      subtitle: 'Ficha los temporales que quieras conservar.',
      color: AppColors.accent,
      child: content,
    );
  }

  Widget _buildTempPlayerRow(
    UserPlayer player,
    Match match,
    String teamId,
    String teamSide, {
    required int spp,
    required bool isStarPlayer,
  }) {
    final decision =
        _storedTemporaryPlayerDecisions(match)[player.id] ?? 'release';
    final isJourneyman = player.journeyman;
    final isMercenary =
        player.temporaryForMatch && !isStarPlayer && !isJourneyman;
    final decisionLabel = decision == 'keep'
        ? 'Keep'
        : decision == 'release'
            ? 'Release'
            : 'Pendiente';
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
                  isStarPlayer
                      ? '★ Star Player · $decisionLabel'
                      : isJourneyman
                          ? '${player.positionLabel} · Journeyman · $decisionLabel'
                          : isMercenary
                              ? '${player.positionLabel} · Mercenary · $decisionLabel'
                              : player.positionLabel,
                  style: TextStyle(
                    color:
                        isStarPlayer ? AppColors.accent : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Precio: ${_fmtGold(player.currentValue)} ${tr(ref.read(localeProvider), 'aftermatch.gp')} · SPP partido: $spp',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _tempActionButton(
            label: decision == 'keep' ? 'Keep ✓' : 'Keep',
            color: AppColors.success,
            icon: PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
            selected: decision == 'keep',
            onPressed: () {
              _keepTempPlayer(player, teamId, teamSide);
            },
          ),
          const SizedBox(width: 8),
          _tempActionButton(
            label: decision == 'release' ? 'Release ✓' : 'Release',
            color: AppColors.error,
            icon: PhosphorIcons.userMinus(PhosphorIconsStyle.bold),
            selected: decision == 'release',
            onPressed: () {
              _releaseTempPlayer(player, teamId, teamSide);
            },
          ),
        ],
      ),
    );
  }

  Widget _tempActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: selected ? 0.3 : 0.15),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: selected ? color : Colors.transparent),
          ),
        ),
      ),
    );
  }

  bool _isVisibleTemporaryPlayer(UserPlayer player, Set<String> providerIds) {
    return providerIds.contains(player.id) || player.temporaryForMatch;
  }

  Future<void> _keepTempPlayer(
      UserPlayer player, String teamId, String teamSide) async {
    if (!player.temporaryForMatch) {
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
      return;
    }

    setState(() {
      _temporaryPlayerDecisions[player.id] = 'keep';
    });
  }

  Future<void> _releaseTempPlayer(
      UserPlayer player, String teamId, String teamSide) async {
    if (player.temporaryForMatch) {
      setState(() {
        _temporaryPlayerDecisions[player.id] = 'release';
      });
      return;
    }

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

  Widget _buildSubmitButton(Match match, League? league) {
    final blockReason = _reportBlockReason(match, league);
    final isCommissioner = _isCommissioner(match, league);
    final mySideSubmitted = _canManageSide(match, 'home', league)
        ? match.aftermatchHomeSubmittedAt != null
        : _canManageSide(match, 'away', league)
            ? match.aftermatchAwaySubmittedAt != null
            : false;
    final isLocked = !isCommissioner && mySideSubmitted;
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
          _submitting
              ? 'SUBMITTING...'
              : isLocked
                  ? 'INFORME ENVIADO'
                  : blockReason ??
                      (isCommissioner
                          ? 'ENVIAR INFORME FINAL'
                          : 'ENVIAR MI INFORME'),
          style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: blockReason == null ? 16 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: blockReason == null && !isLocked
              ? AppColors.primary
              : AppColors.surfaceLight,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _submitting || isLocked
            ? null
            : () => _submitAfterMatch(match, league),
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

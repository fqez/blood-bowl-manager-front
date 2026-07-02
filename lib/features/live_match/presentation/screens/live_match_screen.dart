import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../roster/domain/models/team.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/match_event_dialog.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';
import '../../../shared/utils/player_position_labels.dart';
import '../../../shared/utils/team_special_rules.dart';
import '../../data/active_match_provider.dart';

part '../widgets/live_match_helpers.dart';
part '../widgets/live_match_pre_match.dart';
part '../widgets/live_match_live_view.dart';
part '../widgets/live_match_team_prep.dart';
part '../widgets/live_match_dialogs.dart';

final _matchDetailProvider = FutureProvider.autoDispose
    .family<Match, ({String leagueId, String matchId})>((ref, params) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getMatchDetail(params.leagueId, params.matchId);
});

final _quickMatchDetailProvider =
    FutureProvider.autoDispose.family<Match, String>((ref, matchId) async {
  final repo = ref.read(quickMatchRepositoryProvider);
  return repo.getMatchDetail(matchId);
});

final _liveMatchLeagueProvider =
    FutureProvider.autoDispose.family<League, String>((ref, leagueId) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getLeague(leagueId);
});

class LiveMatchScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String matchId;
  final bool isQuickMatch;

  const LiveMatchScreen({
    super.key,
    required this.leagueId,
    required this.matchId,
    this.isQuickMatch = false,
  });

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  static const _preMatchPollInterval = Duration(seconds: 5);
  static const _liveMatchPollInterval = Duration(seconds: 3);
  static const _unknownMatchPollInterval = Duration(seconds: 5);

  bool _isSubmitting = false;
  Timer? _pollTimer;
  Timer? _clockTimer;
  Timer? _inducementBudgetTimer;
  Duration _elapsed = Duration.zero;
  final ValueNotifier<Duration> _elapsedNotifier = ValueNotifier(Duration.zero);
  DateTime? _matchStartedAt;

  List<UserPlayer>? _homePlayers;
  List<UserPlayer>? _awayPlayers;
  bool _rosterLoading = false;
  bool _preMatchRefreshInFlight = false;

  // Pre-match preparation state
  UserTeamDetail? _homeTeam;
  UserTeamDetail? _awayTeam;
  BaseTeam? _homeBaseRoster;
  BaseTeam? _awayBaseRoster;
  bool _prepLoading = false;
  Match? _optimisticPreMatch;
  int _optimisticPreMatchRequest = 0;

  // ── Match-day squad selection ──
  final Set<String> _selectedHomePlayers = {};
  final Set<String> _selectedAwayPlayers = {};
  bool _homeSquadSeeded = false;
  bool _awaySquadSeeded = false;
  _PrepRosterSortColumn _homePrepRosterSortColumn =
      _PrepRosterSortColumn.number;
  _PrepRosterSortColumn _awayPrepRosterSortColumn =
      _PrepRosterSortColumn.number;
  bool _homePrepRosterSortAscending = true;
  bool _awayPrepRosterSortAscending = true;

  // ── Temporarily hired players for this match only ──
  final Set<String> _tempHiredHomePlayers = {};
  final Set<String> _tempHiredAwayPlayers = {};

  // ── Match-only inducements bought during pre-match ──
  final Map<String, int> _homeInducementPurchases = {};
  final Map<String, int> _awayInducementPurchases = {};
  final Map<String, int> _homeInducementUses = {};
  final Map<String, int> _awayInducementUses = {};
  final Map<String, List<String>> _homeInducementDetails = {};
  final Map<String, List<String>> _awayInducementDetails = {};
  final Set<String> _inducementMutatingKeys = {};
  int _homeRerollAdjustment = 0;
  int _awayRerollAdjustment = 0;

  // ── Quick-match helpers ──
  bool get _isQM => widget.isQuickMatch;

  String get _aftermatchRoute => _isQM
      ? '/quick-match/${widget.matchId}/aftermatch'
      : '/league/${widget.leagueId}/match/${widget.matchId}/aftermatch';

  String get _backRoute =>
      _isQM ? '/quick-match' : '/league/${widget.leagueId}';

  String get _inducementStoragePrefix =>
      'live_match_inducements:${widget.leagueId}:${widget.matchId}';

  @override
  void initState() {
    super.initState();
    _startPolling();
    if (!_isQM) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeMatchProvider.notifier).state = ActiveMatch(
          leagueId: widget.leagueId,
          matchId: widget.matchId,
        );
      });
      _startInducementBudgetRefresh();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _inducementBudgetTimer?.cancel();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  void _startInducementBudgetRefresh() {
    _inducementBudgetTimer?.cancel();
    _inducementBudgetTimer = Timer.periodic(_preMatchPollInterval, (_) {
      if (!mounted || _isQM) return;
      final match = ref
          .read(_matchDetailProvider(
              (leagueId: widget.leagueId, matchId: widget.matchId)))
          .valueOrNull;
      if (match?.isPending != true) return;
      if (_homeTeam != null &&
          _awayTeam != null &&
          _inducementMutatingKeys.isEmpty) {
        _doRefreshPreMatch();
      } else {
        setState(() {});
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _scheduleNextPoll(Duration.zero);
  }

  void _scheduleNextPoll(Duration delay) {
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, () {
      if (!mounted) return;
      final match = _currentMatchSnapshot();
      if (match?.isPlayed == true) return;
      _refresh();
      _scheduleNextPoll(_pollIntervalFor(match));
    });
  }

  Match? _currentMatchSnapshot() {
    return _isQM
        ? ref.read(_quickMatchDetailProvider(widget.matchId)).valueOrNull
        : ref
            .read(_matchDetailProvider(
                (leagueId: widget.leagueId, matchId: widget.matchId)))
            .valueOrNull;
  }

  Duration _pollIntervalFor(Match? match) {
    if (match == null) return _unknownMatchPollInterval;
    if (match.isPending) return _preMatchPollInterval;
    if (match.isInProgress) return _liveMatchPollInterval;
    return _preMatchPollInterval;
  }

  /// Server sends UTC datetimes without 'Z' Ã¢â€ â€™ Dart parses as local.
  /// Reinterpret the raw values as UTC.
  DateTime _toUtc(DateTime dt) => dt.isUtc
      ? dt
      : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
          dt.millisecond);

  void _startClock(DateTime startedAt) {
    if (_matchStartedAt == startedAt) return;
    _matchStartedAt = startedAt;
    _elapsed = DateTime.now().toUtc().difference(_toUtc(startedAt));
    _elapsedNotifier.value = _elapsed;
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _matchStartedAt == null) return;
      final nextElapsed =
          DateTime.now().toUtc().difference(_toUtc(_matchStartedAt!));
      if (nextElapsed.inSeconds == _elapsed.inSeconds) return;
      _elapsed = nextElapsed;
      _elapsedNotifier.value = nextElapsed;
    });
  }

  void _refresh() {
    if (_isQM) {
      ref.invalidate(_quickMatchDetailProvider);
    } else {
      ref.invalidate(_matchDetailProvider);
    }
  }

  void _syncInducementsFromMatch(Match match) {
    if (_isQM) return;
    if (_inducementMutatingKeys.isNotEmpty) return;
    final nextHomePurchases =
        Map<String, int>.from(match.homeInducementPurchases);
    final nextAwayPurchases =
        Map<String, int>.from(match.awayInducementPurchases);
    final nextHomeUses = Map<String, int>.from(match.homeInducementUses);
    final nextAwayUses = Map<String, int>.from(match.awayInducementUses);
    final nextHomeDetails = _copyInducementDetails(match.homeInducementDetails);
    final nextAwayDetails = _copyInducementDetails(match.awayInducementDetails);

    final serverHasNoInducements = nextHomePurchases.isEmpty &&
        nextAwayPurchases.isEmpty &&
        nextHomeUses.isEmpty &&
        nextAwayUses.isEmpty &&
        nextHomeDetails.isEmpty &&
        nextAwayDetails.isEmpty;
    final localHasInducements = _homeInducementPurchases.isNotEmpty ||
        _awayInducementPurchases.isNotEmpty ||
        _homeInducementUses.isNotEmpty ||
        _awayInducementUses.isNotEmpty ||
        _homeInducementDetails.isNotEmpty ||
        _awayInducementDetails.isNotEmpty;
    if (serverHasNoInducements && localHasInducements) return;

    if (mapEquals(nextHomePurchases, _homeInducementPurchases) &&
        mapEquals(nextAwayPurchases, _awayInducementPurchases) &&
        mapEquals(nextHomeUses, _homeInducementUses) &&
        mapEquals(nextAwayUses, _awayInducementUses) &&
        _inducementDetailsEqual(nextHomeDetails, _homeInducementDetails) &&
        _inducementDetailsEqual(nextAwayDetails, _awayInducementDetails)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _homeInducementPurchases
          ..clear()
          ..addAll(nextHomePurchases);
        _awayInducementPurchases
          ..clear()
          ..addAll(nextAwayPurchases);
        _homeInducementUses
          ..clear()
          ..addAll(nextHomeUses);
        _awayInducementUses
          ..clear()
          ..addAll(nextAwayUses);
        _homeInducementDetails
          ..clear()
          ..addAll(nextHomeDetails);
        _awayInducementDetails
          ..clear()
          ..addAll(nextAwayDetails);
      });
      await _persistInducementBudgetState();
      _debugSyncTrace(
        'inducements synced homePurchases=$_homeInducementPurchases homeUses=$_homeInducementUses awayPurchases=$_awayInducementPurchases awayUses=$_awayInducementUses',
      );
    });
  }

  void _setLocalInducementsFromMatch(Match match) {
    if (_isQM || _inducementMutatingKeys.isNotEmpty) return;
    _homeInducementPurchases
      ..clear()
      ..addAll(match.homeInducementPurchases);
    _awayInducementPurchases
      ..clear()
      ..addAll(match.awayInducementPurchases);
    _homeInducementUses
      ..clear()
      ..addAll(match.homeInducementUses);
    _awayInducementUses
      ..clear()
      ..addAll(match.awayInducementUses);
    _homeInducementDetails
      ..clear()
      ..addAll(_copyInducementDetails(match.homeInducementDetails));
    _awayInducementDetails
      ..clear()
      ..addAll(_copyInducementDetails(match.awayInducementDetails));
  }

  Match _preMatchViewMatch(Match match) {
    final optimistic = _optimisticPreMatch;
    if (match.isPending && optimistic?.id == match.id) {
      return optimistic!.copyWith(
        homeInducementPurchases:
            Map<String, int>.from(_homeInducementPurchases),
        awayInducementPurchases:
            Map<String, int>.from(_awayInducementPurchases),
        homeInducementUses: Map<String, int>.from(_homeInducementUses),
        awayInducementUses: Map<String, int>.from(_awayInducementUses),
        homeInducementDetails: _copyInducementDetails(_homeInducementDetails),
        awayInducementDetails: _copyInducementDetails(_awayInducementDetails),
      );
    }
    return match;
  }

  void _updateLocalState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }

  void _seedSquadSelection({
    required bool isHome,
    required UserTeamDetail team,
    required List<String> persistedSquad,
  }) {
    final alreadySeeded = isHome ? _homeSquadSeeded : _awaySquadSeeded;
    if (alreadySeeded) return;

    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    selectedIds.clear();
    final eligiblePlayers = team.players.where((player) =>
        !player.temporaryForMatch || player.temporaryMatchId == widget.matchId);
    final eligibleIds = eligiblePlayers.map((player) => player.id).toSet();
    if (persistedSquad.isNotEmpty) {
      selectedIds.addAll(persistedSquad.where(eligibleIds.contains));
    } else {
      selectedIds.addAll(
        eligiblePlayers
            .where((player) => player.status == 'healthy')
            .map((player) => player.id),
      );
    }
    selectedIds.addAll(
      eligiblePlayers
          .where((player) =>
              player.temporaryForMatch &&
              player.temporaryMatchId == widget.matchId &&
              player.status == 'healthy')
          .map((player) => player.id),
    );

    if (isHome) {
      _homeSquadSeeded = true;
    } else {
      _awaySquadSeeded = true;
    }
  }

  Future<({UserTeamDetail home, UserTeamDetail away})>
      _loadVisibleMatchTeamDetails() {
    if (_isQM) {
      return ref
          .read(quickMatchRepositoryProvider)
          .getMatchTeamDetails(widget.matchId);
    }
    return ref
        .read(leagueRepositoryProvider)
        .getMatchTeamDetails(widget.leagueId, widget.matchId);
  }

  Future<UserTeamDetail> _loadVisibleTeamDetail({required bool isHome}) async {
    final teams = await _loadVisibleMatchTeamDetails();
    return isHome ? teams.home : teams.away;
  }

  Future<void> _loadRosters(Match match) async {
    if (_rosterLoading || (_homePlayers != null && _awayPlayers != null)) {
      return;
    }
    _rosterLoading = true;
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final teams = await _loadVisibleMatchTeamDetails();
      final baseResults = await Future.wait([
        teamRepo.getBaseTeamDetail(teams.home.baseRosterId),
        teamRepo.getBaseTeamDetail(teams.away.baseRosterId),
      ]);
      await _restoreInducementBudgetState(teams.home, teams.away);
      await _maybeMigrateLegacyInducementsToServer(match);
      if (mounted) {
        setState(() {
          _seedSquadSelection(
            isHome: true,
            team: teams.home,
            persistedSquad: match.homeSquad,
          );
          _seedSquadSelection(
            isHome: false,
            team: teams.away,
            persistedSquad: match.awaySquad,
          );

          // Use in-memory squad selection, fall back to persisted squad from match
          final homeSquad = _selectedHomePlayers;
          final awaySquad = _selectedAwayPlayers;

          _homePlayers = homeSquad.isNotEmpty
              ? teams.home.players
                  .where((p) =>
                      homeSquad.contains(p.id) ||
                      (p.temporaryForMatch &&
                          p.temporaryMatchId == widget.matchId))
                  .toList()
              : teams.home.players.where((p) => p.status == 'healthy').toList();
          _awayPlayers = awaySquad.isNotEmpty
              ? teams.away.players
                  .where((p) =>
                      awaySquad.contains(p.id) ||
                      (p.temporaryForMatch &&
                          p.temporaryMatchId == widget.matchId))
                  .toList()
              : teams.away.players.where((p) => p.status == 'healthy').toList();
          // Keep team details for reroll budget in live view
          _homeTeam ??= teams.home;
          _awayTeam ??= teams.away;
          _homeBaseRoster ??= baseResults[0];
          _awayBaseRoster ??= baseResults[1];
        });
      }
    } catch (_) {}
    _rosterLoading = false;
  }

  Future<void> _loadPreMatchData(Match match) async {
    if (_prepLoading || (_homeTeam != null && _awayTeam != null)) return;
    _prepLoading = true;
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final teams = await _loadVisibleMatchTeamDetails();
      final home = teams.home;
      final away = teams.away;
      // Load base rosters for position catalog
      final baseResults = await Future.wait([
        teamRepo.getBaseTeamDetail(home.baseRosterId),
        teamRepo.getBaseTeamDetail(away.baseRosterId),
      ]);
      await _restoreInducementBudgetState(home, away);
      await _maybeMigrateLegacyInducementsToServer(match);
      _setLocalInducementsFromMatch(match);
      if (mounted) {
        setState(() {
          _seedSquadSelection(
            isHome: true,
            team: home,
            persistedSquad: match.homeSquad,
          );
          _seedSquadSelection(
            isHome: false,
            team: away,
            persistedSquad: match.awaySquad,
          );
          _homeTeam = home;
          _awayTeam = away;
          _homeBaseRoster = baseResults[0];
          _awayBaseRoster = baseResults[1];
        });
      }
    } catch (_) {}
    _prepLoading = false;
  }

  void _refreshPreMatch() {
    // Re-fetch teams without nullifying state to avoid scroll reset
    _prepLoading = false;
    _doRefreshPreMatch();
    _refresh();
  }

  Future<void> _doRefreshPreMatch() async {
    if (_preMatchRefreshInFlight) return;
    if (_homeTeam == null || _awayTeam == null) return;
    _preMatchRefreshInFlight = true;
    try {
      final teams = await _loadVisibleMatchTeamDetails();
      await _restoreInducementBudgetState(teams.home, teams.away);
      if (mounted) {
        setState(() {
          _seedSquadSelection(
            isHome: true,
            team: teams.home,
            persistedSquad: const [],
          );
          _seedSquadSelection(
            isHome: false,
            team: teams.away,
            persistedSquad: const [],
          );
          _homeTeam = teams.home;
          _awayTeam = teams.away;
        });
      }
    } catch (_) {}
    _preMatchRefreshInFlight = false;
  }

  Future<void> _restoreInducementBudgetState(
    UserTeamDetail home,
    UserTeamDetail away,
  ) async {
    if (_isQM) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _inducementStoragePrefix;
    final storedHomePurchases = _decodeInducementPurchases(
        prefs.getStringList('$prefix:homePurchases'));
    final storedAwayPurchases = _decodeInducementPurchases(
        prefs.getStringList('$prefix:awayPurchases'));
    final storedHomeUses =
        _decodeInducementPurchases(prefs.getStringList('$prefix:homeUses'));
    final storedAwayUses =
        _decodeInducementPurchases(prefs.getStringList('$prefix:awayUses'));
    final storedHomeRerollAdjustment =
        prefs.getInt('$prefix:homeRerollAdjustment');
    final storedAwayRerollAdjustment =
        prefs.getInt('$prefix:awayRerollAdjustment');

    if (storedHomePurchases.isNotEmpty && _homeInducementPurchases.isEmpty) {
      _homeInducementPurchases
        ..clear()
        ..addAll(storedHomePurchases);
    }
    if (storedAwayPurchases.isNotEmpty && _awayInducementPurchases.isEmpty) {
      _awayInducementPurchases
        ..clear()
        ..addAll(storedAwayPurchases);
    }
    if (storedHomeUses.isNotEmpty && _homeInducementUses.isEmpty) {
      _homeInducementUses
        ..clear()
        ..addAll(storedHomeUses);
    }
    if (storedAwayUses.isNotEmpty && _awayInducementUses.isEmpty) {
      _awayInducementUses
        ..clear()
        ..addAll(storedAwayUses);
    }
    _homeRerollAdjustment = storedHomeRerollAdjustment ?? _homeRerollAdjustment;
    _awayRerollAdjustment = storedAwayRerollAdjustment ?? _awayRerollAdjustment;
    if (storedHomePurchases.isEmpty && _homeInducementPurchases.isNotEmpty) {
      await prefs.setStringList(
        '$prefix:homePurchases',
        _encodeInducementPurchases(_homeInducementPurchases),
      );
    }
    if (storedAwayPurchases.isEmpty && _awayInducementPurchases.isNotEmpty) {
      await prefs.setStringList(
        '$prefix:awayPurchases',
        _encodeInducementPurchases(_awayInducementPurchases),
      );
    }
    if (storedHomeUses.isEmpty && _homeInducementUses.isNotEmpty) {
      await prefs.setStringList(
        '$prefix:homeUses',
        _encodeInducementPurchases(_homeInducementUses),
      );
    }
    if (storedAwayUses.isEmpty && _awayInducementUses.isNotEmpty) {
      await prefs.setStringList(
        '$prefix:awayUses',
        _encodeInducementPurchases(_awayInducementUses),
      );
    }
    if (storedHomeRerollAdjustment == null) {
      await prefs.setInt('$prefix:homeRerollAdjustment', _homeRerollAdjustment);
    }
    if (storedAwayRerollAdjustment == null) {
      await prefs.setInt('$prefix:awayRerollAdjustment', _awayRerollAdjustment);
    }
  }

  Future<void> _maybeMigrateLegacyInducementsToServer(Match match) async {
    if (_isQM || !mounted) return;
    final hasServerInducements = match.homeInducementPurchases.isNotEmpty ||
        match.awayInducementPurchases.isNotEmpty ||
        match.homeInducementUses.isNotEmpty ||
        match.awayInducementUses.isNotEmpty;
    final hasLocalInducements = _homeInducementPurchases.isNotEmpty ||
        _awayInducementPurchases.isNotEmpty ||
        _homeInducementUses.isNotEmpty ||
        _awayInducementUses.isNotEmpty;
    if (hasServerInducements || !hasLocalInducements) return;

    final prefs = await SharedPreferences.getInstance();
    final migratedKey = '$_inducementStoragePrefix:serverMigrated';
    if (prefs.getBool(migratedKey) == true) return;

    await _updateState(
      homeInducementPurchases: Map<String, int>.from(_homeInducementPurchases),
      awayInducementPurchases: Map<String, int>.from(_awayInducementPurchases),
      homeInducementUses: Map<String, int>.from(_homeInducementUses),
      awayInducementUses: Map<String, int>.from(_awayInducementUses),
    );
    await prefs.setBool(migratedKey, true);
  }

  Future<void> _persistInducementBudgetState() async {
    if (_isQM) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _inducementStoragePrefix;
    await prefs.setStringList(
      '$prefix:homePurchases',
      _encodeInducementPurchases(_homeInducementPurchases),
    );
    await prefs.setStringList(
      '$prefix:awayPurchases',
      _encodeInducementPurchases(_awayInducementPurchases),
    );
    await prefs.setStringList(
      '$prefix:homeUses',
      _encodeInducementPurchases(_homeInducementUses),
    );
    await prefs.setStringList(
      '$prefix:awayUses',
      _encodeInducementPurchases(_awayInducementUses),
    );
    await prefs.setInt('$prefix:homeRerollAdjustment', _homeRerollAdjustment);
    await prefs.setInt('$prefix:awayRerollAdjustment', _awayRerollAdjustment);
  }

  List<String> _encodeInducementPurchases(Map<String, int> purchases) {
    return purchases.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}=${entry.value}')
        .toList();
  }

  Map<String, int> _decodeInducementPurchases(List<String>? encoded) {
    final purchases = <String, int>{};
    for (final entry in encoded ?? const <String>[]) {
      final separator = entry.lastIndexOf('=');
      if (separator <= 0 || separator == entry.length - 1) continue;
      final key = entry.substring(0, separator);
      final value = int.tryParse(entry.substring(separator + 1)) ?? 0;
      if (value > 0) purchases[key] = value;
    }
    return purchases;
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Actions Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _startMatch() async {
    setState(() => _isSubmitting = true);
    try {
      await _persistCurrentSquadsBeforeStart();
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        await repo.startMatch(widget.matchId);
      } else {
        final repo = ref.read(leagueRepositoryProvider);
        await repo.startMatch(widget.leagueId, widget.matchId);
      }
      _refresh();
    } catch (e) {
      if (mounted) _snack('$e');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _persistCurrentSquadsBeforeStart() async {
    var homeTeam = _homeTeam;
    var awayTeam = _awayTeam;
    if (homeTeam == null || awayTeam == null) {
      await _doRefreshPreMatch();
      homeTeam = _homeTeam;
      awayTeam = _awayTeam;
    }
    if (homeTeam == null || awayTeam == null) return;

    final homeSquad = _currentValidSquad(homeTeam, _selectedHomePlayers);
    final awaySquad = _currentValidSquad(awayTeam, _selectedAwayPlayers);
    if (homeSquad.length < 11 || awaySquad.length < 11) {
      throw Exception('Cada equipo debe tener al menos 11 jugadores validos.');
    }

    if (mounted) {
      setState(() {
        _selectedHomePlayers
          ..clear()
          ..addAll(homeSquad);
        _selectedAwayPlayers
          ..clear()
          ..addAll(awaySquad);
      });
    }

    if (_isQM) {
      await ref.read(quickMatchRepositoryProvider).updateMatchState(
            widget.matchId,
            homeSquad: homeSquad,
            awaySquad: awaySquad,
          );
    } else {
      await ref.read(leagueRepositoryProvider).updateMatchState(
            widget.leagueId,
            widget.matchId,
            homeSquad: homeSquad,
            awaySquad: awaySquad,
          );
    }
  }

  List<String> _currentValidSquad(
    UserTeamDetail team,
    Set<String> selectedIds,
  ) {
    final validPlayers = team.players.where((player) =>
        player.status == 'healthy' &&
        (!player.temporaryForMatch ||
            player.temporaryMatchId == widget.matchId));
    final validIds = validPlayers.map((player) => player.id).toSet();
    final squad = selectedIds.where(validIds.contains).toList();
    for (final player in validPlayers) {
      if (player.temporaryForMatch &&
          player.temporaryMatchId == widget.matchId &&
          !squad.contains(player.id)) {
        squad.add(player.id);
      }
    }
    return squad;
  }

  Future<void> _completeMatch() async {
    final lang = ref.read(localeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'liveMatch.completeTitle'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(tr(lang, 'liveMatch.completeConfirm'),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(tr(lang, 'liveMatch.complete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSubmitting = true);
    try {
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        await repo.completeMatch(widget.matchId);
      } else {
        final repo = ref.read(leagueRepositoryProvider);
        await repo.completeMatch(widget.leagueId, widget.matchId);
      }
      _clockTimer?.cancel();
      if (mounted) {
        context.go(_aftermatchRoute);
      }
    } catch (e) {
      if (mounted) _snack('$e');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<Match?> _updateState({
    int? scoreHome,
    int? scoreAway,
    int? currentHalf,
    int? currentTurn,
    String? currentTeam,
    int? homeTurn,
    int? awayTurn,
    String? weather,
    String? kickoffEvent,
    bool? homeReady,
    bool? awayReady,
    List<String>? homeSquad,
    List<String>? awaySquad,
    int? rerollsUsedHome,
    int? rerollsUsedAway,
    Map<String, int>? homeInducementPurchases,
    Map<String, int>? awayInducementPurchases,
    Map<String, int>? homeInducementUses,
    Map<String, int>? awayInducementUses,
    Map<String, List<String>>? homeInducementDetails,
    Map<String, List<String>>? awayInducementDetails,
    String? mvpHome,
    String? mvpAway,
    int? gate,
  }) async {
    try {
      late final Match updated;
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        updated = await repo.updateMatchState(
          widget.matchId,
          scoreHome: scoreHome,
          scoreAway: scoreAway,
          currentHalf: currentHalf,
          currentTurn: currentTurn,
          currentTeam: currentTeam,
          homeTurn: homeTurn,
          awayTurn: awayTurn,
          weather: weather,
          kickoffEvent: kickoffEvent,
          homeReady: homeReady,
          awayReady: awayReady,
          homeSquad: homeSquad,
          awaySquad: awaySquad,
          rerollsUsedHome: rerollsUsedHome,
          rerollsUsedAway: rerollsUsedAway,
          mvpHome: mvpHome,
          mvpAway: mvpAway,
          gate: gate,
        );
      } else {
        final repo = ref.read(leagueRepositoryProvider);
        updated = await repo.updateMatchState(
          widget.leagueId,
          widget.matchId,
          scoreHome: scoreHome,
          scoreAway: scoreAway,
          currentHalf: currentHalf,
          currentTurn: currentTurn,
          currentTeam: currentTeam,
          homeTurn: homeTurn,
          awayTurn: awayTurn,
          weather: weather,
          kickoffEvent: kickoffEvent,
          homeReady: homeReady,
          awayReady: awayReady,
          homeSquad: homeSquad,
          awaySquad: awaySquad,
          rerollsUsedHome: rerollsUsedHome,
          rerollsUsedAway: rerollsUsedAway,
          homeInducementPurchases: homeInducementPurchases,
          awayInducementPurchases: awayInducementPurchases,
          homeInducementUses: homeInducementUses,
          awayInducementUses: awayInducementUses,
          homeInducementDetails: homeInducementDetails,
          awayInducementDetails: awayInducementDetails,
          mvpHome: mvpHome,
          mvpAway: mvpAway,
          gate: gate,
        );
      }
      if (mounted && updated.isPending) {
        setState(() => _optimisticPreMatch = updated);
      }
      _refresh();
      return updated;
    } catch (e) {
      if (mounted) _snack('$e');
      return null;
    }
  }

  Future<void> _updatePreMatchCeremonyState(
    Match match, {
    String? currentTeam,
    String? weather,
    String? kickoffEvent,
  }) async {
    final previous = _preMatchViewMatch(match);
    final next = previous.copyWith(
      currentTeam: currentTeam ?? previous.currentTeam,
      weather: weather ?? previous.weather,
      kickoffEvent: kickoffEvent ?? previous.kickoffEvent,
    );
    final requestId = ++_optimisticPreMatchRequest;

    if (mounted) {
      setState(() => _optimisticPreMatch = next);
    }

    try {
      final updated = _isQM
          ? await ref.read(quickMatchRepositoryProvider).updateMatchState(
                widget.matchId,
                currentTeam: currentTeam,
                weather: weather,
                kickoffEvent: kickoffEvent,
              )
          : await ref.read(leagueRepositoryProvider).updateMatchState(
                widget.leagueId,
                widget.matchId,
                currentTeam: currentTeam,
                weather: weather,
                kickoffEvent: kickoffEvent,
              );

      if (mounted && requestId == _optimisticPreMatchRequest) {
        setState(() => _optimisticPreMatch = updated);
        _refresh();
      }
    } catch (e) {
      if (mounted && requestId == _optimisticPreMatchRequest) {
        setState(() => _optimisticPreMatch = previous);
        _snack('$e');
      }
    }
  }

  Future<bool> _addEvent({
    required String type,
    required String team,
    String? playerId,
    String? playerName,
    String? victimId,
    String? victimName,
    String? injury,
    String? detail,
    required int half,
    required int turn,
    bool showSnack = true,
  }) async {
    try {
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        await repo.addMatchEvent(
          widget.matchId,
          type: type,
          team: team,
          playerId: playerId,
          playerName: playerName,
          victimId: victimId,
          victimName: victimName,
          injury: injury,
          detail: detail,
          half: half,
          turn: turn,
        );
      } else {
        final repo = ref.read(leagueRepositoryProvider);
        await repo.addMatchEvent(
          widget.leagueId,
          widget.matchId,
          type: type,
          team: team,
          playerId: playerId,
          playerName: playerName,
          victimId: victimId,
          victimName: victimName,
          injury: injury,
          detail: detail,
          half: half,
          turn: turn,
        );
      }
      _refresh();
      if (mounted && showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} recorded'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) _snack('Error: $e');
      return false;
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        await repo.deleteMatchEvent(widget.matchId, eventId);
      } else {
        final repo = ref.read(leagueRepositoryProvider);
        await repo.deleteMatchEvent(widget.leagueId, widget.matchId, eventId);
      }
      _refresh();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final matchAsync = _isQM
        ? ref.watch(_quickMatchDetailProvider(widget.matchId))
        : ref.watch(
            _matchDetailProvider(
                (leagueId: widget.leagueId, matchId: widget.matchId)),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: matchAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child:
              Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (match) => _buildMatchContent(match, lang),
      ),
    );
  }

  Widget _buildMatchContent(Match match, String lang) {
    if (!match.isPending && _optimisticPreMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticPreMatch = null);
      });
    }
    final displayMatch = _preMatchViewMatch(match);
    _syncInducementsFromMatch(displayMatch);

    if (displayMatch.isInProgress && displayMatch.startedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startClock(displayMatch.startedAt!);
      });
    }
    if (displayMatch.isInProgress || displayMatch.isPlayed) {
      _loadRosters(displayMatch);
    }
    if (displayMatch.isPending) _loadPreMatchData(displayMatch);

    if (displayMatch.isPending) return _buildPreMatchView(displayMatch, lang);
    if (displayMatch.isPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(_aftermatchRoute);
        }
      });
      return const SizedBox.shrink();
    }
    return _buildLiveView(displayMatch, lang);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../roster/domain/models/team.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';
import '../../data/active_match_provider.dart';

part '../widgets/live_match_helpers.dart';
part '../widgets/live_match_pre_match.dart';
part '../widgets/live_match_live_view.dart';
part '../widgets/live_match_team_prep.dart';
part '../widgets/live_match_dialogs.dart';

final _matchDetailProvider =
    FutureProvider.family<Match, ({String leagueId, String matchId})>(
        (ref, params) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getMatchDetail(params.leagueId, params.matchId);
});

final _quickMatchDetailProvider =
    FutureProvider.family<Match, String>((ref, matchId) async {
  final repo = ref.read(quickMatchRepositoryProvider);
  return repo.getMatchDetail(matchId);
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
  bool _isSubmitting = false;
  Timer? _pollTimer;
  Timer? _clockTimer;
  Duration _elapsed = Duration.zero;
  DateTime? _matchStartedAt;

  List<UserPlayer>? _homePlayers;
  List<UserPlayer>? _awayPlayers;
  bool _rosterLoading = false;

  // Pre-match preparation state
  UserTeamDetail? _homeTeam;
  UserTeamDetail? _awayTeam;
  BaseTeam? _homeBaseRoster;
  BaseTeam? _awayBaseRoster;
  bool _prepLoading = false;

  // ── Match-day squad selection (max 11 per team) ──
  final Set<String> _selectedHomePlayers = {};
  final Set<String> _selectedAwayPlayers = {};

  // ── Temporarily hired players for this match only ──
  final Set<String> _tempHiredHomePlayers = {};
  final Set<String> _tempHiredAwayPlayers = {};

  // ── Quick-match helpers ──
  bool get _isQM => widget.isQuickMatch;

  String get _aftermatchRoute => _isQM
      ? '/quick-match/${widget.matchId}/aftermatch'
      : '/league/${widget.leagueId}/match/${widget.matchId}/aftermatch';

  String get _backRoute =>
      _isQM ? '/quick-match' : '/league/${widget.leagueId}';

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
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refresh();
    });
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
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed =
              DateTime.now().toUtc().difference(_toUtc(_matchStartedAt!));
        });
      }
    });
  }

  void _refresh() {
    if (_isQM) {
      ref.invalidate(_quickMatchDetailProvider);
    } else {
      ref.invalidate(_matchDetailProvider);
    }
  }

  Future<void> _loadRosters(Match match) async {
    if (_rosterLoading || (_homePlayers != null && _awayPlayers != null))
      return;
    _rosterLoading = true;
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final results = await Future.wait([
        teamRepo.getUserTeamDetail(match.home.teamId),
        teamRepo.getUserTeamDetail(match.away.teamId),
      ]);
      if (mounted) {
        setState(() {
          // Use in-memory squad selection, fall back to persisted squad from match
          final homeSquad = _selectedHomePlayers.isNotEmpty
              ? _selectedHomePlayers
              : match.homeSquad.toSet();
          final awaySquad = _selectedAwayPlayers.isNotEmpty
              ? _selectedAwayPlayers
              : match.awaySquad.toSet();

          _homePlayers = homeSquad.isNotEmpty
              ? results[0]
                  .players
                  .where((p) => homeSquad.contains(p.id))
                  .toList()
              : results[0].players;
          _awayPlayers = awaySquad.isNotEmpty
              ? results[1]
                  .players
                  .where((p) => awaySquad.contains(p.id))
                  .toList()
              : results[1].players;
          // Keep team details for reroll budget in live view
          _homeTeam ??= results[0];
          _awayTeam ??= results[1];
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
      final results = await Future.wait([
        teamRepo.getUserTeamDetail(match.home.teamId),
        teamRepo.getUserTeamDetail(match.away.teamId),
      ]);
      final home = results[0];
      final away = results[1];
      // Load base rosters for position catalog
      final baseResults = await Future.wait([
        teamRepo.getBaseTeamDetail(home.baseRosterId),
        teamRepo.getBaseTeamDetail(away.baseRosterId),
      ]);
      if (mounted) {
        setState(() {
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
    if (_homeTeam == null || _awayTeam == null) return;
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final results = await Future.wait([
        teamRepo.getUserTeamDetail(_homeTeam!.id),
        teamRepo.getUserTeamDetail(_awayTeam!.id),
      ]);
      if (mounted) {
        setState(() {
          _homeTeam = results[0];
          _awayTeam = results[1];
        });
      }
    } catch (_) {}
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Actions Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _startMatch() async {
    setState(() => _isSubmitting = true);
    try {
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

  Future<void> _updateState({
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
      if (_isQM) {
        final repo = ref.read(quickMatchRepositoryProvider);
        await repo.updateMatchState(
          widget.matchId,
          scoreHome: scoreHome,
          scoreAway: scoreAway,
          currentHalf: currentHalf,
          currentTurn: currentTurn,
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
        await repo.updateMatchState(
          widget.leagueId,
          widget.matchId,
          scoreHome: scoreHome,
          scoreAway: scoreAway,
          currentHalf: currentHalf,
          currentTurn: currentTurn,
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
      }
      _refresh();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  Future<void> _addEvent({
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} recorded'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
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
    if (match.isInProgress && match.startedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startClock(match.startedAt!);
      });
    }
    if (match.isInProgress || match.isPlayed) _loadRosters(match);
    if (match.isPending) _loadPreMatchData(match);

    if (match.isPending) return _buildPreMatchView(match, lang);
    if (match.isPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(_aftermatchRoute);
        }
      });
      return const SizedBox.shrink();
    }
    return _buildLiveView(match, lang);
  }
}

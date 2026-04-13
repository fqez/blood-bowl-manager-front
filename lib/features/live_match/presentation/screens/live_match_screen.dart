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

final _matchDetailProvider =
    FutureProvider.family<Match, ({String leagueId, String matchId})>(
        (ref, params) async {
  final repo = ref.read(leagueRepositoryProvider);
  return repo.getMatchDetail(params.leagueId, params.matchId);
});

class LiveMatchScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String matchId;

  const LiveMatchScreen({
    super.key,
    required this.leagueId,
    required this.matchId,
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

  @override
  void initState() {
    super.initState();
    _startPolling();
    // Persist active match context for sidebar navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeMatchProvider.notifier).state = ActiveMatch(
        leagueId: widget.leagueId,
        matchId: widget.matchId,
      );
    });
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

  /// Server sends UTC datetimes without 'Z' → Dart parses as local.
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

  void _refresh() => ref.invalidate(_matchDetailProvider);

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
          _homePlayers = results[0].players;
          _awayPlayers = results[1].players;
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

  // ── Actions ──

  Future<void> _startMatch() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(leagueRepositoryProvider);
      await repo.startMatch(widget.leagueId, widget.matchId);
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
      final repo = ref.read(leagueRepositoryProvider);
      await repo.completeMatch(widget.leagueId, widget.matchId);
      _clockTimer?.cancel();
      if (mounted) {
        context.go(
            '/league/${widget.leagueId}/match/${widget.matchId}/aftermatch');
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
    int? rerollsUsedHome,
    int? rerollsUsedAway,
    String? mvpHome,
    String? mvpAway,
    int? gate,
  }) async {
    try {
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
        rerollsUsedHome: rerollsUsedHome,
        rerollsUsedAway: rerollsUsedAway,
        mvpHome: mvpHome,
        mvpAway: mvpAway,
        gate: gate,
      );
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
      final repo = ref.read(leagueRepositoryProvider);
      await repo.deleteMatchEvent(widget.leagueId, widget.matchId, eventId);
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final matchAsync = ref.watch(
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
          context.go(
              '/league/${widget.leagueId}/match/${widget.matchId}/aftermatch');
        }
      });
      return const SizedBox.shrink();
    }
    return _buildLiveView(match, lang);
  }

  // ══════════════════════════════════════════════
  //  PRE-MATCH CEREMONY
  // ══════════════════════════════════════════════

  Widget _buildPreMatchView(Match match, String lang) {
    final weatherSet = match.weather != null && match.weather!.isNotEmpty;
    final kickoffSet =
        match.kickoffEvent != null && match.kickoffEvent!.isNotEmpty;
    final canStart = weatherSet && kickoffSet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/league/${widget.leagueId}'),
                  icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                      size: 16),
                  label: Text(tr(lang, 'liveMatch.round'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 8),
              // Match header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.surface,
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(PhosphorIcons.soccerBall(PhosphorIconsStyle.fill),
                        color: AppColors.primary, size: 56),
                    const SizedBox(height: 16),
                    Text(tr(lang, 'liveMatch.preMatchCeremony'),
                        style: AppTextStyles.displayMedium
                            .copyWith(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Text(
                      '${match.home.teamName}  vs  ${match.away.teamName}',
                      style: AppTextStyles.displayLarge
                          .copyWith(fontSize: 28, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text('${tr(lang, 'liveMatch.round')} ${match.round}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Weather selector
              _sectionHeader(tr(lang, 'liveMatch.selectWeather'),
                  PhosphorIcons.cloudSun(PhosphorIconsStyle.fill)),
              const SizedBox(height: 12),
              _buildVisualCardSelector(
                items: _weatherData,
                selected: match.weather,
                onSelect: (v) => _updateState(weather: v),
              ),
              const SizedBox(height: 8),
              _checkRow(tr(lang, 'liveMatch.weather'), weatherSet, lang),
              const SizedBox(height: 24),

              // Kickoff selector
              _sectionHeader(tr(lang, 'liveMatch.selectKickoff'),
                  PhosphorIcons.lightning(PhosphorIconsStyle.fill)),
              const SizedBox(height: 12),
              _buildVisualCardSelector(
                items: _kickoffData,
                selected: match.kickoffEvent,
                onSelect: (v) => _updateState(kickoffEvent: v),
              ),
              const SizedBox(height: 8),
              _checkRow(tr(lang, 'liveMatch.kickoffEvent'), kickoffSet, lang),
              const SizedBox(height: 32),

              // ── Team Preparation ──
              _sectionHeader(tr(lang, 'liveMatch.teamPreparation'),
                  PhosphorIcons.strategy(PhosphorIconsStyle.fill)),
              const SizedBox(height: 16),

              if (_prepLoading && _homeTeam == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_homeTeam != null && _awayTeam != null) ...[
                // Show both teams; only allow editing for the current user's team
                Builder(builder: (context) {
                  final currentUserId =
                      ref.read(authStateProvider).valueOrNull?.user?.id;
                  return Column(children: [
                    _buildTeamPrepCard(
                      team: _homeTeam!,
                      baseRoster: _homeBaseRoster,
                      match: match,
                      lang: lang,
                      isHome: true,
                      canEdit: match.home.userId == currentUserId,
                    ),
                    const SizedBox(height: 16),
                    _buildTeamPrepCard(
                      team: _awayTeam!,
                      baseRoster: _awayBaseRoster,
                      match: match,
                      lang: lang,
                      isHome: false,
                      canEdit: match.away.userId == currentUserId,
                    ),
                  ]);
                }),
              ],
              const SizedBox(height: 32),

              // Warning
              if (!canStart)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tr(lang, 'liveMatch.ceremonyRequired'),
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 13)),
                    ),
                  ]),
                ),
              const SizedBox(height: 24),

              // Start button
              SizedBox(
                width: 300,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (canStart && !_isSubmitting) ? _startMatch : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(PhosphorIcons.play(PhosphorIconsStyle.fill)),
                  label: Text(tr(lang, 'liveMatch.startMatch'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canStart ? AppColors.primary : AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  LIVE VIEW
  // ══════════════════════════════════════════════

  Widget _buildLiveView(Match match, String lang) {
    return Column(
      children: [
        _buildScoreboard(match, lang),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Half / Turn
                _buildMatchStateRow(match, lang),
                const SizedBox(height: 24),

                // Quick Actions — centered
                _sectionHeader(tr(lang, 'liveMatch.quickAdd'),
                    PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
                const SizedBox(height: 12),
                _buildQuickActions(match, lang),
                const SizedBox(height: 10),
                _buildRerollCards(match),
                const SizedBox(height: 28),

                // Gate + Rerolls
                _buildGateAndRerolls(match, lang),
                const SizedBox(height: 28),

                // Events
                _sectionHeader(tr(lang, 'liveMatch.eventLog'),
                    PhosphorIcons.listBullets(PhosphorIconsStyle.fill)),
                const SizedBox(height: 10),
                _buildUserEventsSection(match, lang),
                const SizedBox(height: 24),

                // Audit (collapsible)
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    initiallyExpanded: false,
                    leading: Icon(
                      PhosphorIcons.clockCounterClockwise(
                          PhosphorIconsStyle.fill),
                      size: 17,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      tr(lang, 'liveMatch.auditTrail'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconColor: AppColors.textMuted,
                    collapsedIconColor: AppColors.textMuted,
                    children: [_buildAuditSection(match, lang)],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        _buildBottomBar(match, lang),
      ],
    );
  }

  // ── SCOREBOARD with team logos ──

  Widget _buildScoreboard(Match match, String lang) {
    final elapsed = _fmtDuration(_elapsed);
    final homeLogo = _teamLogoPath(match.home.baseRosterId);
    final awayLogo = _teamLogoPath(match.away.baseRosterId);
    final weatherOpt = match.weather != null
        ? _findOption(_weatherData, match.weather!)
        : null;
    final kickoffOpt = match.kickoffEvent != null
        ? _findOption(_kickoffData, match.kickoffEvent!)
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/score_banner.jpg'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 90, 191, 216).withValues(alpha: 0.35),
            AppColors.surface.withValues(alpha: 0.95),
            const Color.fromARGB(255, 224, 96, 111).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                        size: 20),
                    onPressed: () => context.go('/league/${widget.leagueId}'),
                    color: AppColors.textSecondary,
                  ),
                  const Spacer(),
                  // Live badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('LIVE',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(elapsed,
                      style: AppTextStyles.displaySmall
                          .copyWith(color: AppColors.accent, fontSize: 22)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowsClockwise(
                        PhosphorIconsStyle.regular)),
                    onPressed: _refresh,
                    color: AppColors.textSecondary,
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams + Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Home
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(homeLogo, 130),
                        const SizedBox(height: 4),
                        Text(match.home.teamName,
                            style: AppTextStyles.displaySmall
                                .copyWith(fontSize: 26),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(match.home.username,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        ..._tdScorers(match, 'home'),
                      ],
                    ),
                  ),

                  // Score area — each team has its own +/-
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Home score
                        Column(
                          children: [
                            Text('${match.scoreHome}',
                                style: AppTextStyles.displayLarge
                                    .copyWith(fontSize: 60, letterSpacing: 2)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _scoreTap(
                                  PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                  match.scoreHome > 0
                                      ? () => _updateState(
                                          scoreHome: match.scoreHome - 1)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                _scoreTap(
                                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                  () => _showAddEventDialog(
                                      match, lang, 'touchdown',
                                      initialTeam: 'home'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('–',
                              style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 40, color: AppColors.textMuted)),
                        ),
                        // Away score
                        Column(
                          children: [
                            Text('${match.scoreAway}',
                                style: AppTextStyles.displayLarge
                                    .copyWith(fontSize: 60, letterSpacing: 2)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _scoreTap(
                                  PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                  match.scoreAway > 0
                                      ? () => _updateState(
                                          scoreAway: match.scoreAway - 1)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                _scoreTap(
                                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                  () => _showAddEventDialog(
                                      match, lang, 'touchdown',
                                      initialTeam: 'away'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Away
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(awayLogo, 130),
                        const SizedBox(height: 4),
                        Text(match.away.teamName,
                            style: AppTextStyles.displaySmall
                                .copyWith(fontSize: 26),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(match.away.username,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        ..._tdScorers(match, 'away'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${tr(lang, 'liveMatch.half')} ${match.currentHalf}  ·  ${tr(lang, 'liveMatch.turn')} ${match.currentTurn}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              // Weather / Kickoff info tiles
              if (match.weather != null || match.kickoffEvent != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (match.weather != null)
                        _infoPill(
                          weatherOpt?.icon ??
                              PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
                          match.weather!,
                          weatherOpt?.color ?? AppColors.textSecondary,
                          weatherOpt?.description,
                        ),
                      if (match.kickoffEvent != null)
                        _infoPill(
                          kickoffOpt?.icon ??
                              PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                          match.kickoffEvent!,
                          kickoffOpt?.color ?? AppColors.textSecondary,
                          kickoffOpt?.description,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamLogo(String assetPath, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          PhosphorIcons.shield(PhosphorIconsStyle.fill),
          size: size * 0.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _scoreTap(IconData icon, VoidCallback? onTap, {double size = 32}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: size * 0.45,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  Widget _infoPill(
      IconData icon, String text, Color color, String? description) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          if (description != null) ...[
            const SizedBox(width: 5),
            Icon(PhosphorIcons.info(PhosphorIconsStyle.regular),
                size: 13, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );

    if (description == null || description.isEmpty) return child;

    return Tooltip(
      richMessage: TextSpan(children: [
        TextSpan(
          text: '$text\n',
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: description,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ]),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(12),
      preferBelow: true,
      child: child,
    );
  }

  List<Widget> _tdScorers(Match match, String team) {
    final isHome = team == 'home';
    final tds = match.events
        .where((e) => e.type == 'touchdown' && e.team == team)
        .toList()
      ..sort((a, b) =>
          (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));
    if (tds.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      ...tds.map(
        (ev) => Align(
          alignment: isHome ? Alignment.centerRight : Alignment.centerLeft,
          child: _tdEntry(ev, match.startedAt, isHome: isHome),
        ),
      ),
    ];
  }

  Widget _tdEntry(MatchEvent ev, DateTime? startedAt, {required bool isHome}) {
    final name = ev.playerName ?? '?';
    final min = (ev.timestamp != null && startedAt != null)
        ? "${ev.timestamp!.difference(startedAt).inMinutes + 1}'"
        : '';
    final children = <Widget>[
      Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          size: 11, color: AppColors.accent),
      const SizedBox(width: 4),
      if (min.isNotEmpty) ...[
        Text(min,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isHome ? children.reversed.toList() : children,
      ),
    );
  }

  _CardOption? _findOption(List<_CardOption> data, String value) {
    try {
      return data.firstWhere((d) => d.value == value);
    } catch (_) {
      return null;
    }
  }

  // ── Half / Turn counters ──

  Widget _buildMatchStateRow(Match match, String lang) {
    return Row(
      children: [
        Expanded(
          child: _counterChip(
            label: tr(lang, 'liveMatch.half'),
            value: match.currentHalf,
            onDec: match.currentHalf > 1
                ? () => _updateState(currentHalf: match.currentHalf - 1)
                : null,
            onInc: match.currentHalf < 2
                ? () => _updateState(currentHalf: match.currentHalf + 1)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _counterChip(
            label: tr(lang, 'liveMatch.turn'),
            value: match.currentTurn,
            onDec: match.currentTurn > 1
                ? () => _updateState(currentTurn: match.currentTurn - 1)
                : null,
            onInc: match.currentTurn < 16
                ? () => _updateState(currentTurn: match.currentTurn + 1)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _counterChip({
    required String label,
    required int value,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.card,
          AppColors.surfaceLight.withValues(alpha: 0.5),
        ]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          _scoreTap(PhosphorIcons.minus(PhosphorIconsStyle.bold), onDec),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$value',
                style: AppTextStyles.displaySmall
                    .copyWith(fontSize: 32, color: AppColors.textPrimary)),
          ),
          _scoreTap(PhosphorIcons.plus(PhosphorIconsStyle.bold), onInc),
        ],
      ),
    );
  }

  Widget _rerollCard({
    required String teamName,
    required int used,
    int? total,
    required Color color,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    final isFull = total != null && used >= total;
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isFull ? 0.7 : 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
              size: 30, color: color),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$used',
                style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 28,
                    color: isFull ? AppColors.error : color,
                    height: 1),
              ),
              if (total != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/$total',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            teamName,
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreTap(PhosphorIcons.minus(PhosphorIconsStyle.bold), onDec,
                  size: 22),
              const SizedBox(width: 10),
              _scoreTap(PhosphorIcons.plus(PhosphorIconsStyle.bold), onInc,
                  size: 22),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Actions (centered wrap) ──

  Widget _buildQuickActions(Match match, String lang) {
    final actions = [
      _QA('TD', PhosphorIcons.trophy(PhosphorIconsStyle.fill), AppColors.accent,
          'touchdown'),
      _QA(
          tr(lang, 'liveMatch.completion'),
          PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
          AppColors.info,
          'completion'),
      _QA(
          tr(lang, 'liveMatch.interception'),
          PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
          AppColors.success,
          'interception'),
      _QA('KO', PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill),
          AppColors.warning, 'ko'),
      _QA(
          tr(lang, 'liveMatch.casualty'),
          PhosphorIcons.skull(PhosphorIconsStyle.fill),
          AppColors.error,
          'casualty'),
      _QA('RIP', PhosphorIcons.skull(PhosphorIconsStyle.fill),
          AppColors.primaryDark, 'rip'),
      _QA('Foul', PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
          AppColors.primaryLight, 'foul'),
    ];

    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ...actions.map((a) => _quickBtn(
                label: a.label,
                icon: a.icon,
                color: a.color,
                onTap: () => _showAddEventDialog(match, lang, a.type),
              )),
        ],
      ),
    );
  }

  Widget _buildRerollCards(Match match) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rerollCard(
            teamName: match.home.teamName,
            used: match.rerollsUsedHome,
            total: _homeTeam?.rerolls,
            color: AppColors.info,
            onDec: match.rerollsUsedHome > 0
                ? () => _updateState(rerollsUsedHome: match.rerollsUsedHome - 1)
                : null,
            onInc: match.rerollsUsedHome < (_homeTeam?.rerolls ?? 99)
                ? () => _updateState(rerollsUsedHome: match.rerollsUsedHome + 1)
                : null,
          ),
          const SizedBox(width: 10),
          _rerollCard(
            teamName: match.away.teamName,
            used: match.rerollsUsedAway,
            total: _awayTeam?.rerolls,
            color: AppColors.error,
            onDec: match.rerollsUsedAway > 0
                ? () => _updateState(rerollsUsedAway: match.rerollsUsedAway - 1)
                : null,
            onInc: match.rerollsUsedAway < (_awayTeam?.rerolls ?? 99)
                ? () => _updateState(rerollsUsedAway: match.rerollsUsedAway + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // ── Weather / Kickoff visual card selector ──

  Widget _buildVisualCardSelector({
    required List<_CardOption> items,
    required String? selected,
    required ValueChanged<String> onSelect,
    bool compact = false,
  }) {
    final cardW = compact ? 90.0 : 110.0;
    final padV = compact ? 10.0 : 14.0;
    final iconSize = compact ? 22.0 : 28.0;
    final fontSize = compact ? 10.0 : 11.0;

    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: items.map((item) {
          final sel = selected == item.value;
          return Material(
            color: sel ? item.color.withValues(alpha: 0.25) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onSelect(item.value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: cardW,
                padding: EdgeInsets.symmetric(vertical: padV, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? item.color : AppColors.surfaceLight,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(item.icon,
                        color: sel ? item.color : AppColors.textMuted,
                        size: iconSize),
                    const SizedBox(height: 4),
                    Text(item.label,
                        style: TextStyle(
                          color: sel ? item.color : AppColors.textSecondary,
                          fontSize: fontSize,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Gate + Rerolls ──

  Widget _buildGateAndRerolls(Match match, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gate
        Row(
          children: [
            Icon(PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(tr(lang, 'liveMatch.gate'),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '${match.gate ?? 0}',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceLight)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceLight)),
                ),
                onSubmitted: (v) {
                  final val = int.tryParse(v);
                  if (val != null) _updateState(gate: val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Events / Audit sections ──

  Widget _buildUserEventsSection(Match match, String lang) {
    final userEvents = match.events
        .where((e) => !_isSystemEvent(e.type))
        .toList()
      ..sort((a, b) =>
          (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    if (userEvents.isEmpty) return _empty(tr(lang, 'liveMatch.noEvents'));
    return Column(
        children: userEvents.map((e) => _eventTile(e, lang)).toList());
  }

  Widget _buildAuditSection(Match match, String lang) {
    final all = List<MatchEvent>.from(match.events)
      ..sort((a, b) =>
          (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    if (all.isEmpty) return _empty(tr(lang, 'liveMatch.noEvents'));
    return Column(children: all.map((e) => _auditTile(e)).toList());
  }

  Widget _eventTile(MatchEvent ev, String lang) {
    final isHome = ev.team == 'home';
    final clr = _evColor(ev.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          clr.withValues(alpha: 0.06),
          AppColors.card.withValues(alpha: 0.5),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: clr.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: clr.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_evIcon(ev.type), size: 17, color: clr),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isHome ? AppColors.info : AppColors.error)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isHome ? 'HOME' : 'AWAY',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isHome ? AppColors.info : AppColors.error)),
                  ),
                  const SizedBox(width: 6),
                  Text(ev.type.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                if (ev.playerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(ev.playerName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                if (ev.detail != null)
                  Text(ev.detail!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          if (ev.half > 0 || ev.turn > 0)
            Text('H${ev.half} T${ev.turn}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _deleteEvent(ev.id),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                  size: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditTile(MatchEvent ev) {
    final clr = _evColor(ev.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_evIcon(ev.type), size: 14, color: clr),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev.type.toUpperCase(),
                    style: TextStyle(
                        color: clr, fontSize: 10, fontWeight: FontWeight.w700)),
                if (ev.detail != null)
                  Text(ev.detail!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          if (ev.createdByName != null)
            Text(ev.createdByName!,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          const SizedBox(width: 6),
          if (ev.timestamp != null)
            Text(_fmtTime(ev.timestamp!),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  // ── Completed view ──

  Widget _buildCompletedView(Match match, String lang) {
    final homeLogo = _teamLogoPath(match.home.baseRosterId);
    final awayLogo = _teamLogoPath(match.away.baseRosterId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/league/${widget.leagueId}'),
                  icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                      size: 16),
                  label: Text(tr(lang, 'liveMatch.round'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tr(lang, 'liveMatch.matchCompleted'),
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(height: 20),
              // Scoreboard
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.card,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(children: [
                        _teamLogo(homeLogo, 60),
                        const SizedBox(height: 8),
                        Text(match.home.teamName,
                            style: AppTextStyles.displaySmall
                                .copyWith(fontSize: 15),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    Text('${match.scoreHome} - ${match.scoreAway}',
                        style:
                            AppTextStyles.displayLarge.copyWith(fontSize: 48)),
                    Expanded(
                      child: Column(children: [
                        _teamLogo(awayLogo, 60),
                        const SizedBox(height: 8),
                        Text(match.away.teamName,
                            style: AppTextStyles.displaySmall
                                .copyWith(fontSize: 15),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(tr(lang, 'liveMatch.eventLog'),
                  PhosphorIcons.listBullets(PhosphorIconsStyle.fill)),
              const SizedBox(height: 12),
              if (match.events.isEmpty)
                _empty(tr(lang, 'liveMatch.noEvents'))
              else
                ...match.events.map((e) => _auditTile(e)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar ──

  Widget _buildBottomBar(Match match, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          Text('${tr(lang, 'liveMatch.events')}: ${match.events.length}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _completeMatch,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    size: 18),
            label: Text(tr(lang, 'liveMatch.complete')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Event Dialog ──

  void _showAddEventDialog(Match match, String lang, String eventType,
      {String initialTeam = 'home'}) {
    String selectedTeam = initialTeam;
    UserPlayer? selectedPlayer;
    UserPlayer? selectedVictim;
    String playerNameText = '';
    String victimNameText = '';
    String? selectedInjury;
    String detail = '';

    final needsVictim = [
      'casualty',
      'ko',
      'rip',
      'badly_hurt',
      'serious_injury',
      'stun'
    ].contains(eventType);
    final needsInjury =
        ['casualty', 'rip', 'badly_hurt', 'serious_injury'].contains(eventType);

    List<UserPlayer> getPlayers(String team) =>
        team == 'home' ? (_homePlayers ?? []) : (_awayPlayers ?? []);
    List<UserPlayer> getOpponents(String team) =>
        team == 'home' ? (_awayPlayers ?? []) : (_homePlayers ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final players = getPlayers(selectedTeam);
          final opponents = getOpponents(selectedTeam);
          final hasRoster = players.isNotEmpty;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _evColor(eventType).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_evIcon(eventType),
                    color: _evColor(eventType), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    '${tr(lang, 'liveMatch.add')} ${eventType.toUpperCase()}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Team selector
                    Row(children: [
                      Expanded(
                          child: _teamChip(
                        label: match.home.teamName,
                        selected: selectedTeam == 'home',
                        onTap: () => setS(() {
                          selectedTeam = 'home';
                          selectedPlayer = null;
                          selectedVictim = null;
                        }),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _teamChip(
                        label: match.away.teamName,
                        selected: selectedTeam == 'away',
                        onTap: () => setS(() {
                          selectedTeam = 'away';
                          selectedPlayer = null;
                          selectedVictim = null;
                        }),
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Player
                    if (hasRoster)
                      DropdownButtonFormField<UserPlayer>(
                        initialValue: selectedPlayer,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            _inputDeco(tr(lang, 'liveMatch.selectPlayer')),
                        items: players
                            .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('#${p.number} — ${p.name}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14))))
                            .toList(),
                        onChanged: (v) => setS(() => selectedPlayer = v),
                      )
                    else
                      TextField(
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            _inputDeco(tr(lang, 'liveMatch.playerName')),
                        onChanged: (v) => playerNameText = v,
                      ),

                    if (needsVictim) ...[
                      const SizedBox(height: 12),
                      if (opponents.isNotEmpty)
                        DropdownButtonFormField<UserPlayer>(
                          initialValue: selectedVictim,
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              _inputDeco(tr(lang, 'liveMatch.selectVictim')),
                          items: opponents
                              .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('#${p.number} — ${p.name}',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14))))
                              .toList(),
                          onChanged: (v) => setS(() => selectedVictim = v),
                        )
                      else
                        TextField(
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              _inputDeco(tr(lang, 'liveMatch.victimName')),
                          onChanged: (v) => victimNameText = v,
                        ),
                    ],
                    if (needsInjury) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedInjury,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            _inputDeco(tr(lang, 'liveMatch.injuryType')),
                        items: _injuryTypes
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i)))
                            .toList(),
                        onChanged: (v) => setS(() => selectedInjury = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: _inputDeco(tr(lang, 'liveMatch.detail')),
                      onChanged: (v) => detail = v,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: Text(tr(lang, 'common.cancel'),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 15)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addEvent(
                    type: eventType,
                    team: selectedTeam,
                    playerId: selectedPlayer?.id,
                    playerName: selectedPlayer != null
                        ? '#${selectedPlayer!.number} ${selectedPlayer!.name}'
                        : (playerNameText.isEmpty ? null : playerNameText),
                    victimId: selectedVictim?.id,
                    victimName: selectedVictim != null
                        ? '#${selectedVictim!.number} ${selectedVictim!.name}'
                        : (victimNameText.isEmpty ? null : victimNameText),
                    injury: selectedInjury,
                    detail: detail.isEmpty ? null : detail,
                    half: match.currentHalf,
                    turn: match.currentTurn,
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _evColor(eventType),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(tr(lang, 'liveMatch.add')),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  TEAM PREPARATION (pre-match)
  // ══════════════════════════════════════════════

  Widget _buildTeamPrepCard({
    required UserTeamDetail team,
    required BaseTeam? baseRoster,
    required Match match,
    required String lang,
    required bool isHome,
    required bool canEdit,
  }) {
    final logoPath = _teamLogoPath(team.baseRosterId);
    final teamColor = isHome ? AppColors.info : AppColors.error;
    final rerollCost = baseRoster?.rerollCost ?? team.rerollCost;
    final activeCount = team.players.where((p) => p.status == 'healthy').length;
    final woundedCount = team.players
        .where((p) => p.status != 'healthy' && p.status != 'dead')
        .length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teamColor.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                teamColor.withValues(alpha: 0.15),
                AppColors.card,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teamColor.withValues(alpha: 0.3)),
                    color: AppColors.surface,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(logoPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          PhosphorIcons.shield(PhosphorIconsStyle.fill),
                          size: 48,
                          color: AppColors.textMuted)),
                ),
                const SizedBox(width: 16),
                // Name + race
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          (baseRoster?.name ?? 'TEAM').toUpperCase(),
                          style: TextStyle(
                            color: teamColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: teamColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(isHome ? 'HOME' : 'AWAY',
                              style: TextStyle(
                                  color: teamColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      Text(team.name,
                          style: AppTextStyles.displayLarge.copyWith(
                              fontSize: 36,
                              color: AppColors.textPrimary,
                              height: 1.1)),
                    ],
                  ),
                ),
                // Team value / Treasury
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TEAM VALUE',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    Text(_fmtGold(team.teamValue),
                        style:
                            AppTextStyles.displaySmall.copyWith(fontSize: 28)),
                    const SizedBox(height: 6),
                    const Text('TREASURY',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    Text(_fmtGold(team.treasury),
                        style: AppTextStyles.displaySmall
                            .copyWith(fontSize: 28, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ──
          if (canEdit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: baseRoster != null
                        ? () => _showHirePlayerDialog(team, baseRoster, lang)
                        : null,
                    icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                        size: 16),
                    label: Text(tr(lang, 'liveMatch.hirePlayer'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ]),
            ),

          const Divider(color: AppColors.surfaceLight, height: 1),

          // ── Inducements ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _sectionHeaderAccent(tr(lang, 'liveMatch.teamPreparation')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _inducementCard(
                  icon: PhosphorIcons.arrowsCounterClockwise(
                      PhosphorIconsStyle.fill),
                  label: tr(lang, 'liveMatch.rerolls').toUpperCase(),
                  price: '${_fmtGold(rerollCost)} GP',
                  count: team.rerolls,
                  color: AppColors.accent,
                  canEdit: canEdit,
                  onDec: team.rerolls > 0
                      ? () => _purchaseStaff(team.id, rerolls: team.rerolls - 1)
                      : null,
                  onInc: team.treasury >= rerollCost && team.rerolls < 8
                      ? () => _purchaseStaff(team.id, rerolls: team.rerolls + 1)
                      : null,
                ),
                _inducementCard(
                  icon:
                      PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill),
                  label: tr(lang, 'liveMatch.coaches').toUpperCase(),
                  price: '10,000 GP',
                  count: team.assistantCoaches,
                  color: AppColors.info,
                  canEdit: canEdit,
                  onDec: team.assistantCoaches > 0
                      ? () => _purchaseStaff(team.id,
                          coaches: team.assistantCoaches - 1)
                      : null,
                  onInc: team.treasury >= 10000 && team.assistantCoaches < 6
                      ? () => _purchaseStaff(team.id,
                          coaches: team.assistantCoaches + 1)
                      : null,
                ),
                _inducementCard(
                  icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                  label: tr(lang, 'liveMatch.cheerleaders').toUpperCase(),
                  price: '10,000 GP',
                  count: team.cheerleaders,
                  color: AppColors.primaryLight,
                  canEdit: canEdit,
                  onDec: team.cheerleaders > 0
                      ? () => _purchaseStaff(team.id,
                          cheerleaders: team.cheerleaders - 1)
                      : null,
                  onInc: team.treasury >= 10000 && team.cheerleaders < 12
                      ? () => _purchaseStaff(team.id,
                          cheerleaders: team.cheerleaders + 1)
                      : null,
                ),
                if (team.apothecaryAllowed)
                  _inducementCard(
                    icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
                    label: tr(lang, 'liveMatch.apothecary').toUpperCase(),
                    price: '50,000 GP',
                    count: team.apothecary ? 1 : 0,
                    color: AppColors.success,
                    canEdit: canEdit,
                    onDec: team.apothecary
                        ? () => _purchaseStaff(team.id, apothecary: false)
                        : null,
                    onInc: !team.apothecary && team.treasury >= 50000
                        ? () => _purchaseStaff(team.id, apothecary: true)
                        : null,
                  ),
                _inducementCard(
                  icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  label: tr(lang, 'liveMatch.fanFactor').toUpperCase(),
                  price: '',
                  count: team.fanFactor,
                  color: AppColors.warning,
                  canEdit: false,
                  onDec: null,
                  onInc: null,
                ),
                _inducementCard(
                  icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  label: 'FANS',
                  price: '',
                  count: team.dedicatedFans,
                  color: AppColors.textSecondary,
                  canEdit: false,
                  onDec: null,
                  onInc: null,
                ),
              ]),
            ),
          ),

          const Divider(color: AppColors.surfaceLight, height: 24),

          // ── Active Roster ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(children: [
              Expanded(
                  child: _sectionHeaderAccent(tr(lang, 'liveMatch.roster'))),
              Text(
                'ACTIVE: $activeCount/${team.players.length}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'WOUNDED: $woundedCount',
                style: TextStyle(
                    color: woundedCount > 0
                        ? AppColors.error
                        : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildRosterTable(team, lang),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showStarPlayerDetail(Map<String, dynamic> sp, String lang) {
    final id = sp['id'] as String? ?? '';
    final name = sp['name'] as String? ?? '';
    final cost = sp['cost'] as int? ?? 0;
    final stats = sp['stats'] as Map<String, dynamic>? ?? {};
    final skills = (sp['skills'] as List?)?.cast<String>() ?? [];
    final types = (sp['player_types'] as List?)?.cast<String>() ?? [];
    final ability = sp['special_ability'] as Map<String, dynamic>?;
    final playsFor = (sp['plays_for'] as List?)?.cast<String>() ?? [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image header
                  Container(
                    height: 200,
                    color: AppColors.card,
                    child: Center(
                      child: Image.asset(
                        'assets/images/star_players/$id.png',
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          PhosphorIcons.star(PhosphorIconsStyle.fill),
                          size: 64,
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + cost
                        Center(
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.displayFont,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                '${(cost ~/ 1000)}K GP',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.displayFont,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              if (types.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                ...types.map((t) => Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(t,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['MA', 'ST', 'AG', 'PA', 'AV'].map((key) {
                            final val = stats[key]?.toString() ?? '-';
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 46,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: AppColors.surfaceLight),
                              ),
                              child: Column(children: [
                                Text(key,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent
                                            .withValues(alpha: 0.7))),
                                Text(val,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary)),
                              ]),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        // Skills
                        if (skills.isNotEmpty) ...[
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: skills
                                .map((s) => InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        showSkillPopup(context, ref,
                                            skillName: s);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.15)),
                                        ),
                                        child: Text(s,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppColors.textSecondary)),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Special ability
                        if (ability != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(
                                      PhosphorIcons.lightning(
                                          PhosphorIconsStyle.fill),
                                      size: 13,
                                      color: AppColors.accent),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      (ability['name'] as String? ?? '')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.displayFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  ability['description'] as String? ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Plays for
                        if (playsFor.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                'Plays for: ',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                              Expanded(
                                child: Text(
                                  playsFor
                                      .map((t) => t.replaceAll('_', ' '))
                                      .map((t) =>
                                          t[0].toUpperCase() + t.substring(1))
                                      .join(', '),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                      height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        // Close
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeaderAccent(String text) => Row(children: [
        Container(width: 3, height: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(text,
            style: AppTextStyles.displaySmall.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic)),
      ]);

  Widget _inducementCard({
    required IconData icon,
    required String label,
    required String price,
    required int count,
    required Color color,
    required bool canEdit,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    return Container(
      width: 105,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (price.isNotEmpty)
            Text(price,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 8)),
          const SizedBox(height: 4),
          Text(count.toString().padLeft(2, '0'),
              style: AppTextStyles.displaySmall
                  .copyWith(fontSize: 24, color: AppColors.textPrimary)),
          if (canEdit) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniBtn(PhosphorIcons.minus(PhosphorIconsStyle.bold), onDec),
                const SizedBox(width: 8),
                _miniBtn(PhosphorIcons.plus(PhosphorIconsStyle.bold), onInc),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 12,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  Widget _buildRosterTable(UserTeamDetail team, String lang) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          columnSpacing: 12,
          horizontalMargin: 12,
          headingRowHeight: 36,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          headingTextStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('PLAYER NAME')),
            DataColumn(label: Text('POSITION')),
            DataColumn(label: Text('MA'), numeric: true),
            DataColumn(label: Text('ST'), numeric: true),
            DataColumn(label: Text('AG'), numeric: true),
            DataColumn(label: Text('PA'), numeric: true),
            DataColumn(label: Text('AV'), numeric: true),
            DataColumn(label: Text('SKILLS / TRAITS')),
            DataColumn(label: Text('SPP'), numeric: true),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('COST'), numeric: true),
          ],
          rows: team.players.map((p) {
            final isHealthy = p.status == 'healthy';
            return DataRow(cells: [
              DataCell(Text(p.number.toString().padLeft(2, '0'),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Text(p.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
              DataCell(Text(p.baseType.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10))),
              DataCell(Text('${p.stats.ma}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Text('${p.stats.st}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Text('${p.stats.ag}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Text(p.stats.pa ?? '-',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Text('${p.stats.av}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Wrap(
                spacing: 4,
                runSpacing: 2,
                children: p.perks
                    .map((perk) => GestureDetector(
                          onTap: () => showSkillPopup(context, ref,
                              skillName: perk.name, family: perk.category),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(perk.name.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ))
                    .toList(),
              )),
              DataCell(Text('${p.spp}',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isHealthy
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(p.status.toUpperCase(),
                    style: TextStyle(
                        color: isHealthy ? AppColors.success : AppColors.error,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              )),
              DataCell(Text(_fmtGold(p.currentValue),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _purchaseStaff(String teamId,
      {int? rerolls, int? cheerleaders, int? coaches, bool? apothecary}) async {
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      await teamRepo.patchTeamStaff(
        teamId,
        rerolls: rerolls,
        cheerleaders: cheerleaders,
        assistantCoaches: coaches,
        apothecary: apothecary,
      );
      _refreshPreMatch();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  Future<void> _showHirePlayerDialog(
      UserTeamDetail team, BaseTeam baseRoster, String lang) async {
    // Count current players per type
    final activePlayers = team.players.where((p) => !p.isDead).toList();
    final countByType = <String, int>{};
    for (final p in activePlayers) {
      countByType[p.baseType] = (countByType[p.baseType] ?? 0) + 1;
    }

    // Fetch star players available for this team
    List<Map<String, dynamic>> starPlayers = [];
    try {
      final repo = ref.read(teamRepositoryProvider);
      final allDetails = await repo.getAllStarPlayerDetails();
      starPlayers = allDetails
          .where((sp) => (sp['plays_for'] as List? ?? [])
              .cast<String>()
              .contains(team.baseRosterId))
          .toList();
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.surface,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                        color: AppColors.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(lang, 'liveMatch.hirePlayer').toUpperCase(),
                              style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 24, color: AppColors.textPrimary)),
                          Text(
                            baseRoster.name.toUpperCase(),
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                    // Treasury badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text('${_fmtGold(team.treasury)} GP',
                            style: AppTextStyles.displaySmall.copyWith(
                                fontSize: 16, color: AppColors.accent)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: AppColors.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceLight, height: 1),

              // ── Roster table ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // DataTable with base positions
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(AppColors.card),
                            dataRowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            columnSpacing: 8,
                            horizontalMargin: 12,
                            headingRowHeight: 40,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 64,
                            headingTextStyle: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                            columns: const [
                              DataColumn(label: Text('POS')),
                              DataColumn(label: Text('QTY'), numeric: true),
                              DataColumn(label: Text('MA'), numeric: true),
                              DataColumn(label: Text('ST'), numeric: true),
                              DataColumn(label: Text('AG'), numeric: true),
                              DataColumn(label: Text('PA'), numeric: true),
                              DataColumn(label: Text('AV'), numeric: true),
                              DataColumn(label: Text('SKILLS')),
                              DataColumn(label: Text('COST'), numeric: true),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              ...baseRoster.positions.map((pos) {
                                final currentCount = countByType[pos.id] ?? 0;
                                final available =
                                    currentCount < pos.maxQuantity;
                                final canAfford = team.treasury >= pos.cost;
                                final canHire = available && canAfford;
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith((_) =>
                                      canHire
                                          ? null
                                          : AppColors.surfaceLight
                                              .withValues(alpha: 0.1)),
                                  cells: [
                                    DataCell(Text(pos.name.toUpperCase(),
                                        style: TextStyle(
                                          color: canHire
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ))),
                                    DataCell(
                                        Text('$currentCount/${pos.maxQuantity}',
                                            style: TextStyle(
                                              color: available
                                                  ? AppColors.textSecondary
                                                  : AppColors.error,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ))),
                                    DataCell(Text('${pos.stats.ma}',
                                        style: _hireStatStyle(canHire))),
                                    DataCell(Text('${pos.stats.st}',
                                        style: _hireStatStyle(canHire))),
                                    DataCell(Text('${pos.stats.ag}',
                                        style: _hireStatStyle(canHire))),
                                    DataCell(Text(
                                        pos.stats.pa > 0
                                            ? '${pos.stats.pa}+'
                                            : '-',
                                        style: _hireStatStyle(canHire))),
                                    DataCell(Text('${pos.stats.av}',
                                        style: _hireStatStyle(canHire))),
                                    DataCell(Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: pos.startingPerks
                                          .map((perk) => GestureDetector(
                                                onTap: () => showSkillPopup(
                                                    context, ref,
                                                    skillName: perk.name,
                                                    family: perk.category),
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: canHire
                                                          ? AppColors.primary
                                                              .withValues(
                                                                  alpha: 0.15)
                                                          : AppColors
                                                              .surfaceLight
                                                              .withValues(
                                                                  alpha: 0.4),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                        perk.name.toUpperCase(),
                                                        style: TextStyle(
                                                            color: canHire
                                                                ? AppColors
                                                                    .textSecondary
                                                                : AppColors
                                                                    .textMuted,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    )),
                                    DataCell(Text(_fmtGold(pos.cost),
                                        style: TextStyle(
                                          color: canAfford
                                              ? AppColors.accent
                                              : AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ))),
                                    DataCell(
                                      canHire
                                          ? SizedBox(
                                              height: 32,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _showHireNameDialog(
                                                        ctx, team, pos, lang),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6)),
                                                ),
                                                child: const Text('HIRE',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            )
                                          : Text(
                                              !available ? 'MAX' : 'NO FUNDS',
                                              style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      // ── Star players section ──
                      if (starPlayers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Section header row (matches DataTable style)
                              Container(
                                color: AppColors.card,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                        PhosphorIcons.star(
                                            PhosphorIconsStyle.fill),
                                        size: 14,
                                        color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    const Text('STAR PLAYERS',
                                        style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                              ...starPlayers.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final sp = entry.value;
                                final spId = sp['id'] as String? ?? '';
                                final spName = sp['name'] as String? ?? '';
                                final spCost =
                                    (sp['cost'] as num?)?.toInt() ?? 0;
                                final spStats =
                                    sp['stats'] as Map<String, dynamic>? ?? {};
                                final spSkills =
                                    (sp['skills'] as List?)?.cast<String>() ??
                                        [];
                                final canAffordStar =
                                    team.treasury >= spCost;
                                final alreadyHired = activePlayers.any(
                                    (p) => p.baseType == 'star_$spId');
                                final canHireStar = canAffordStar &&
                                    !alreadyHired &&
                                    activePlayers.length < 16;
                                final blockLabel = alreadyHired
                                    ? 'HIRED'
                                    : activePlayers.length >= 16
                                        ? 'FULL'
                                        : 'NO FUNDS';
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (idx > 0)
                                      const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: AppColors.surfaceLight),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                        PhosphorIcons.star(
                                            PhosphorIconsStyle.fill),
                                        size: 14,
                                        color: AppColors.accent),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showStarPlayerDetail(sp, lang),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Text(spName.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              )),
                                        ),
                                      ),
                                    ),
                                    Text(_fmtGold(spCost),
                                        style: TextStyle(
                                          color: canAffordStar
                                              ? AppColors.accent
                                              : AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    const Text(' GP',
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10)),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        onPressed: () =>
                                            _showStarPlayerDetail(sp, lang),
                                        padding: EdgeInsets.zero,
                                        iconSize: 16,
                                        style: IconButton.styleFrom(
                                          side: BorderSide(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.3)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                        ),
                                        icon: Icon(
                                            PhosphorIcons.eye(
                                                PhosphorIconsStyle.fill),
                                            color: AppColors.accent,
                                            size: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (canHireStar)
                                      SizedBox(
                                        height: 28,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _showHireStarNameDialog(
                                                  ctx, team, sp, lang),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          child: const Text('HIRE',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          blockLabel,
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    for (final stat in [
                                      'MA',
                                      'ST',
                                      'AG',
                                      'PA',
                                      'AV'
                                    ])
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppColors.surfaceLight),
                                        ),
                                        child: Text(
                                          '$stat:${_fmtStat(spStats[stat])}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    const Spacer(),
                                    ...spSkills.take(3).map((s) => Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4),
                                          child: GestureDetector(
                                            onTap: () => showSkillPopup(
                                                context, ref,
                                                skillName: s),
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Text(s.toUpperCase(),
                                                    style: const TextStyle(
                                                        color: AppColors.accent,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                        )),
                                    if (spSkills.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '+${spSkills.length - 3}',
                                          style: TextStyle(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.6),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _hireStatStyle(bool active) => TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      );

  /// Format a star-player stat value that may be int, "4+", "-", or null.
  String _fmtStat(dynamic val) {
    if (val == null || val == '-') return '-';
    return '$val';
  }

  void _showHireNameDialog(BuildContext parentCtx, UserTeamDetail team,
      BasePosition pos, String lang) {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();

    showDialog(
      context: parentCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final valid = nameCtrl.text.isNotEmpty && numberCtrl.text.isNotEmpty;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              '${pos.name.toUpperCase()} — ${_fmtGold(pos.cost)} GP',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDeco(tr(lang, 'liveMatch.playerName')),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDeco('#'),
                    onChanged: (_) => setS(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr(lang, 'common.cancel'),
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: valid
                    ? () {
                        Navigator.pop(ctx);
                        Navigator.pop(parentCtx);
                        _hirePlayer(
                          team.id,
                          baseType: pos.id,
                          name: nameCtrl.text,
                          number: int.parse(numberCtrl.text),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('HIRE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _hirePlayer(String teamId,
      {required String baseType,
      required String name,
      required int number}) async {
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      await teamRepo.hirePlayer(teamId,
          baseType: baseType, name: name, number: number);
      _refreshPreMatch();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  void _showHireStarNameDialog(BuildContext parentCtx, UserTeamDetail team,
      Map<String, dynamic> sp, String lang) {
    final spId = sp['id'] as String? ?? '';
    final spName = sp['name'] as String? ?? '';
    final spCost = sp['cost'] as int? ?? 0;
    final nameCtrl = TextEditingController(text: spName);
    final numberCtrl = TextEditingController();

    showDialog(
      context: parentCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final valid = nameCtrl.text.isNotEmpty && numberCtrl.text.isNotEmpty;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${spName.toUpperCase()} — ${_fmtGold(spCost)} GP',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDeco(tr(lang, 'liveMatch.playerName')),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDeco('#'),
                    onChanged: (_) => setS(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr(lang, 'common.cancel'),
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: valid
                    ? () {
                        Navigator.pop(ctx);
                        Navigator.pop(parentCtx);
                        _hireStarPlayer(
                          team.id,
                          starPlayerId: spId,
                          name: nameCtrl.text,
                          number: int.parse(numberCtrl.text),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black),
                child: const Text('HIRE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _hireStarPlayer(String teamId,
      {required String starPlayerId,
      required String name,
      required int number}) async {
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      await teamRepo.hireStarPlayer(teamId,
          starPlayerId: starPlayerId, name: name, number: number);
      _refreshPreMatch();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  static final _goldFmt = NumberFormat('#,###');

  String _fmtGold(int amount) => _goldFmt.format(amount);

  // ══════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════

  Widget _sectionHeader(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _checkRow(String label, bool ok, String lang) => Row(children: [
        Icon(
          ok
              ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.circle(PhosphorIconsStyle.regular),
          color: ok ? AppColors.success : AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          ok ? '$label ✓' : '$label — ${tr(lang, 'liveMatch.pending')}',
          style: TextStyle(
              color: ok ? AppColors.success : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ]);

  Widget _empty(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );

  Widget _teamChip(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surfaceLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
      );

  // ── Helpers ──

  String _teamLogoPath(String baseRosterId) {
    if (baseRosterId.isEmpty) return 'assets/teams/human/logo.webp';
    return 'assets/teams/$baseRosterId/logo.webp';
  }

  bool _isSystemEvent(String type) => const {
        'score_change',
        'half_change',
        'turn_change',
        'weather_change',
        'kickoff_change',
        'reroll_change',
      }.contains(type);

  Color _evColor(String type) {
    switch (type) {
      case 'touchdown':
        return AppColors.accent;
      case 'casualty':
      case 'rip':
      case 'serious_injury':
        return AppColors.error;
      case 'ko':
      case 'stun':
      case 'badly_hurt':
        return AppColors.warning;
      case 'completion':
      case 'interception':
        return AppColors.info;
      case 'foul':
        return AppColors.primaryLight;
      case 'score_change':
        return AppColors.accent;
      case 'half_change':
      case 'turn_change':
        return AppColors.info;
      case 'weather_change':
      case 'kickoff_change':
        return AppColors.warning;
      case 'reroll_change':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.textMuted;
    }
  }

  IconData _evIcon(String type) {
    switch (type) {
      case 'touchdown':
        return PhosphorIcons.trophy(PhosphorIconsStyle.fill);
      case 'casualty':
      case 'rip':
      case 'serious_injury':
        return PhosphorIcons.skull(PhosphorIconsStyle.fill);
      case 'ko':
      case 'stun':
      case 'badly_hurt':
        return PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill);
      case 'completion':
        return PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill);
      case 'interception':
        return PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill);
      case 'foul':
        return PhosphorIcons.prohibit(PhosphorIconsStyle.fill);
      case 'score_change':
        return PhosphorIcons.plusMinus(PhosphorIconsStyle.fill);
      case 'half_change':
        return PhosphorIcons.timer(PhosphorIconsStyle.fill);
      case 'turn_change':
        return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
      case 'weather_change':
        return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
      case 'kickoff_change':
        return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
      case 'reroll_change':
        return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.note(PhosphorIconsStyle.fill);
    }
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Data ──

  static const _injuryTypes = [
    'Badly Hurt',
    'Serious Injury',
    'RIP',
    'Miss Next Game',
    'Niggling Injury',
    '-AV',
    '-MA',
    '-AG',
    '-PA',
    '-ST',
  ];

  static final _weatherData = [
    _CardOption(
        'Sweltering Heat',
        'Sweltering Heat',
        PhosphorIcons.thermometerHot(PhosphorIconsStyle.fill),
        const Color(0xFFFF6B35),
        'At the start of each drive, each team rolls a D6 per player. On a 1, that player is placed in the Reserves box.'),
    _CardOption(
        'Very Sunny',
        'Very Sunny',
        PhosphorIcons.sun(PhosphorIconsStyle.fill),
        AppColors.warning,
        'A glaring sun dazzles players. –1 modifier to all Catch, Intercept and Pass rolls.'),
    _CardOption(
        'Perfect',
        'Perfect',
        PhosphorIcons.sunHorizon(PhosphorIconsStyle.fill),
        AppColors.success,
        'Perfect conditions. No special effects on play.'),
    _CardOption(
        'Pouring Rain',
        'Pouring Rain',
        PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
        AppColors.info,
        'Rain makes the ball slippery. –1 modifier to all Catch, Intercept, Pick Up and Pass rolls.'),
    _CardOption(
        'Blizzard',
        'Blizzard',
        PhosphorIcons.snowflake(PhosphorIconsStyle.fill),
        const Color(0xFF90CAF9),
        'Reduced visibility and treacherous pitch. –1 to Catch, Intercept, Pick Up and Pass rolls. Players may only go for it once per activation.'),
  ];

  static final _kickoffData = [
    _CardOption(
        'Get the Ref!',
        'Get the Ref!',
        PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        AppColors.error,
        'The crowd is enraged! Both coaches may use a single free Bribe during this drive.'),
    _CardOption(
        'Time Out!',
        'Time Out!',
        PhosphorIcons.timer(PhosphorIconsStyle.fill),
        AppColors.warning,
        'A player fakes an injury. Move the turn marker 1 space in favor of the last-scoring team (or the receiving team if no score yet).'),
    _CardOption(
        'Solid Defence',
        'Solid Defence',
        PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
        AppColors.info,
        'The kicking team receives D3+3 additional set-up cards to use during this drive.'),
    _CardOption(
        'High Kick',
        'High Kick',
        PhosphorIcons.arrowUp(PhosphorIconsStyle.fill),
        AppColors.success,
        'One player on the receiving team may be placed on the exact square where the ball lands (if unoccupied).'),
    _CardOption(
        'Cheering Fans',
        'Cheering Fans',
        PhosphorIcons.handsPraying(PhosphorIconsStyle.fill),
        AppColors.accent,
        'Both teams roll a D6 and add their Fan Factor. The team with the higher total gains +1 Fan Factor permanently.'),
    _CardOption(
        'Brilliant Coaching',
        'Brilliant Coaching',
        PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
        AppColors.primaryLight,
        'Both teams roll a D6 and add their number of Assistant Coaches. The team with the higher total gains 1 extra Re-roll for this half.'),
    _CardOption(
        'Changing Weather',
        'Changing Weather',
        PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        const Color(0xFF90CAF9),
        'Re-roll on the weather table and immediately apply the new result, even if it is the same condition.'),
    _CardOption(
        'Quick Snap!',
        'Quick Snap!',
        PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        AppColors.warning,
        'The receiving team may make a free Move action with one player before the kick-off takes place.'),
    _CardOption(
        'Blitz!',
        'Blitz!',
        PhosphorIcons.sword(PhosphorIconsStyle.fill),
        AppColors.error,
        'The kicking team gets a free Blitz! action with one player before the ball lands.'),
    _CardOption(
        'Throw a Rock',
        'Throw a Rock',
        PhosphorIcons.asterisk(PhosphorIconsStyle.fill),
        AppColors.primaryDark,
        'An enraged fan hurls a rock at a random player on the opposing team. Roll for injury on that player.'),
    _CardOption(
        'Pitch Invasion',
        'Pitch Invasion',
        PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        AppColors.error,
        'Fans invade the pitch! For each opposing player on the field, roll a D6; on a 5+ that player is placed in the Reserves box.'),
  ];
}

class _CardOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? description;
  const _CardOption(this.value, this.label, this.icon, this.color,
      [this.description]);
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final String type;
  const _QA(this.label, this.icon, this.color, this.type);
}

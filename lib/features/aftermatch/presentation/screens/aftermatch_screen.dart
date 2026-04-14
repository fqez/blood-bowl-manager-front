import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';
import '../../../live_match/data/active_match_provider.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../shared/data/repositories.dart';

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
  bool mvp = false;
  int bonus = 0;

  _SppTally(this.playerId, this.playerName, this.team);

  int get total =>
      completions * 1 +
      interceptions * 2 +
      casualties * 2 +
      touchdowns * 3 +
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

  _BonusSppEntry({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.amount,
  });
}

// ─── Screen ─────────────────────────────────────────────────

class AftermatchScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String matchId;
  final bool isQuickMatch;

  const AftermatchScreen({
    super.key,
    required this.leagueId,
    required this.matchId,
    this.isQuickMatch = false,
  });

  @override
  ConsumerState<AftermatchScreen> createState() => _AftermatchScreenState();
}

class _AftermatchScreenState extends ConsumerState<AftermatchScreen> {
  String get leagueId => widget.leagueId;
  String get matchId => widget.matchId;
  bool get _isQM => widget.isQuickMatch;

  // Teams loaded from API
  UserTeamDetail? _homeTeam;
  UserTeamDetail? _awayTeam;

  // ── Section 1: Editable match stats (pre-filled from live) ──
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
  int _homeFanFactor = 0;
  int _awayFanFactor = 0;
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

  // ── Section 7: Bonus SPP ──
  final List<_BonusSppEntry> _bonusSpp = [];

  bool _initialized = false;
  bool _submitting = false;

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
      switch (e.type) {
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
      _homeFanFactor = results[0].fanFactor;
      _awayFanFactor = results[1].fanFactor;
      _homeDedicatedFans = results[0].dedicatedFans;
      _awayDedicatedFans = results[1].dedicatedFans;
    });
  }

  int _calcWinnings(
      int fanFactorHome, int fanFactorAway, int myTDs, bool stalling) {
    final base = ((fanFactorHome + fanFactorAway) / 2).ceil();
    final stall = stalling ? 0 : 1;
    return (base + myTDs + stall) * 10000;
  }

  String? _getExpensiveResult(int treasury, int roll) {
    if (treasury < 100000) return null;
    const table600 = ['CA', 'CA', 'MA', 'MA', 'MI', 'MI'];
    final ranges = [
      (100000, 195000, ['MI', 'CV', 'CV', 'CV', 'CV', 'CV']),
      (200000, 295000, ['MI', 'MI', 'CV', 'CV', 'CV', 'CV']),
      (300000, 395000, ['MA', 'MI', 'MI', 'CV', 'CV', 'CV']),
      (400000, 495000, ['MA', 'MA', 'MI', 'MI', 'CV', 'CV']),
      (500000, 595000, ['CA', 'MA', 'MA', 'MI', 'MI', 'CV']),
    ];
    if (treasury >= 600000) return table600[roll.clamp(1, 6) - 1];
    for (final (lo, hi, row) in ranges) {
      if (treasury >= lo && treasury <= hi) return row[roll.clamp(1, 6) - 1];
    }
    return null;
  }

  String _expensiveLabel(String code) {
    switch (code) {
      case 'CV':
        return 'Crisis Averted';
      case 'MI':
        return 'Minor Incident';
      case 'MA':
        return 'Major Incident';
      case 'CA':
        return 'Catastrophe';
      default:
        return code;
    }
  }

  Color _expensiveColor(String code) {
    switch (code) {
      case 'CV':
        return AppColors.success;
      case 'MI':
        return AppColors.info;
      case 'MA':
        return AppColors.warning;
      case 'CA':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _submitAfterMatch() async {
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
                _buildMvpSection(),
                const SizedBox(height: 28),
                _buildSppSection(match),
                const SizedBox(height: 28),
                _buildInjuriesSection(),
                const SizedBox(height: 28),
                _buildExpensiveMistakesSection(),
                const SizedBox(height: 28),
                _buildTempHiredPlayersSection(match),
                const SizedBox(height: 36),
                _buildSubmitButton(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
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
                'POST-MATCH REPORT',
                style: AppTextStyles.displayLarge
                    .copyWith(fontSize: 20, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                '${match.home.teamName}  vs  ${match.away.teamName}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
    return _sectionCard(
      icon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
      title: 'MATCH STATISTICS',
      color: AppColors.info,
      child: Column(
        children: [
          // Score
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.surface.withValues(alpha: 0.5),
              ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(match.home.teamName,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$_scoreHome',
                        style: AppTextStyles.displayLarge
                            .copyWith(fontSize: 48, color: AppColors.info)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('–',
                      style: AppTextStyles.displayLarge
                          .copyWith(fontSize: 36, color: AppColors.textMuted)),
                ),
                Column(
                  children: [
                    Text(match.away.teamName,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$_scoreAway',
                        style: AppTextStyles.displayLarge
                            .copyWith(fontSize: 48, color: AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          _statRow('Touchdowns', _tdHome, _tdAway, AppColors.accent,
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _tdHome = v),
              onAwayChanged: (v) => setState(() => _tdAway = v)),
          _statRow('Casualties', _casHome, _casAway, AppColors.error,
              PhosphorIcons.skull(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _casHome = v),
              onAwayChanged: (v) => setState(() => _casAway = v)),
          _statRow('Completions', _compHome, _compAway, AppColors.info,
              PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _compHome = v),
              onAwayChanged: (v) => setState(() => _compAway = v)),
          _statRow('Interceptions', _intHome, _intAway, AppColors.success,
              PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _intHome = v),
              onAwayChanged: (v) => setState(() => _intAway = v)),
          _statRow('Fouls', _foulHome, _foulAway, AppColors.primaryLight,
              PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _foulHome = v),
              onAwayChanged: (v) => setState(() => _foulAway = v)),
          _statRow('KOs', _koHome, _koAway, AppColors.warning,
              PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _koHome = v),
              onAwayChanged: (v) => setState(() => _koAway = v)),
          _statRow('Rerolls Used', _rerollsHome, _rerollsAway, AppColors.accent,
              PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
              onHomeChanged: (v) => setState(() => _rerollsHome = v),
              onAwayChanged: (v) => setState(() => _rerollsAway = v)),

          const SizedBox(height: 12),
          // Gate
          Row(
            children: [
              Icon(PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('Gate',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              SizedBox(
                width: 110,
                child: _numField(_gate, (v) => setState(() => _gate = v)),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _miniCounter(homeVal, onHomeChanged, AppColors.info),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
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
          width: 32,
          alignment: Alignment.center,
          child: Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.displayFont)),
        ),
        _miniBtn(PhosphorIcons.plus(PhosphorIconsStyle.bold),
            () => onChanged(value + 1)),
      ],
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
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

  // ═══════════════════════════════════════════════════════════
  // SECTION 2: Winnings
  // ═══════════════════════════════════════════════════════════

  Widget _buildWinningsSection() {
    _homeWinnings =
        _calcWinnings(_homeFanFactor, _awayFanFactor, _tdHome, _homeStalling);
    _awayWinnings =
        _calcWinnings(_awayFanFactor, _homeFanFactor, _tdAway, _awayStalling);

    return _sectionCard(
      icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
      title: 'WINNINGS',
      color: AppColors.accent,
      subtitle: '(Fan Factor Home + Away) ÷ 2 + TDs + 1 (no stalling) × 10,000',
      child: Row(
        children: [
          Expanded(
              child: _winningsTeamCol(
            teamName: _homeTeam?.name ?? 'Home',
            fanFactor: _homeFanFactor,
            onFanChanged: (v) => setState(() => _homeFanFactor = v),
            stalling: _homeStalling,
            onStallingChanged: (v) => setState(() => _homeStalling = v),
            winnings: _homeWinnings!,
            color: AppColors.info,
          )),
          Container(width: 1, height: 120, color: AppColors.surfaceLight),
          Expanded(
              child: _winningsTeamCol(
            teamName: _awayTeam?.name ?? 'Away',
            fanFactor: _awayFanFactor,
            onFanChanged: (v) => setState(() => _awayFanFactor = v),
            stalling: _awayStalling,
            onStallingChanged: (v) => setState(() => _awayStalling = v),
            winnings: _awayWinnings!,
            color: AppColors.error,
          )),
        ],
      ),
    );
  }

  Widget _winningsTeamCol({
    required String teamName,
    required int fanFactor,
    required ValueChanged<int> onFanChanged,
    required bool stalling,
    required ValueChanged<bool> onStallingChanged,
    required int winnings,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(teamName,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Fan Factor:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              _miniCounter(fanFactor, onFanChanged, color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: stalling,
                  onChanged: (v) => onStallingChanged(v ?? false),
                  activeColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 6),
              const Text('Stalling',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_fmtGold(winnings)} gp',
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.displayFont),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 3: Dedicated Fans
  // ═══════════════════════════════════════════════════════════

  Widget _buildDedicatedFansSection() {
    return _sectionCard(
      icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
      title: 'DEDICATED FANS',
      color: AppColors.info,
      subtitle:
          'Won: +1 if D6 ≥ Current. Lost: −1 if D6 < Current. Draw: no change.',
      child: Row(
        children: [
          Expanded(
              child: _fanRollCol(
            teamName: _homeTeam?.name ?? 'Home',
            currentFans: _homeDedicatedFans,
            roll: _homeFanRoll,
            onRollChanged: (v) => setState(() => _homeFanRoll = v),
            won: _scoreHome > _scoreAway,
            lost: _scoreHome < _scoreAway,
            color: AppColors.info,
          )),
          Container(width: 1, height: 100, color: AppColors.surfaceLight),
          Expanded(
              child: _fanRollCol(
            teamName: _awayTeam?.name ?? 'Away',
            currentFans: _awayDedicatedFans,
            roll: _awayFanRoll,
            onRollChanged: (v) => setState(() => _awayFanRoll = v),
            won: _scoreAway > _scoreHome,
            lost: _scoreAway < _scoreHome,
            color: AppColors.error,
          )),
        ],
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
    String resultLabel = 'Draw — no change';
    Color resultColor = AppColors.textMuted;
    int delta = 0;

    if (won && roll != null) {
      if (roll >= currentFans) {
        resultLabel = '+1 Dedicated Fan';
        resultColor = AppColors.success;
        delta = 1;
      } else {
        resultLabel = 'No change (roll < fans)';
      }
    } else if (lost && roll != null) {
      if (roll < currentFans) {
        resultLabel = '−1 Dedicated Fan';
        resultColor = AppColors.error;
        delta = -1;
      } else {
        resultLabel = 'No change (roll ≥ fans)';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(teamName,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('Current: $currentFans',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('D6 Roll:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                child: _numField(roll ?? 0, (v) => onRollChanged(v), max: 6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(resultLabel,
              style: TextStyle(
                  color: resultColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          if (delta != 0)
            Text('New: ${currentFans + delta}',
                style: TextStyle(
                    color: resultColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION 4: MVP
  // ═══════════════════════════════════════════════════════════

  Widget _buildMvpSection() {
    return _sectionCard(
      icon: PhosphorIcons.medal(PhosphorIconsStyle.fill),
      title: 'MOST VALUABLE PLAYER',
      color: AppColors.accent,
      subtitle:
          'Select MVP for each team (4 SPP). Nominate 6 players, randomise 1.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _mvpPicker(
            teamName: _homeTeam?.name ?? 'Home',
            players: _homeTeam?.players ?? [],
            selectedId: _mvpHomeId,
            onChanged: (v) => setState(() => _mvpHomeId = v),
            color: AppColors.info,
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _mvpPicker(
            teamName: _awayTeam?.name ?? 'Away',
            players: _awayTeam?.players ?? [],
            selectedId: _mvpAwayId,
            onChanged: (v) => setState(() => _mvpAwayId = v),
            color: AppColors.error,
          )),
        ],
      ),
    );
  }

  Widget _mvpPicker({
    required String teamName,
    required List<UserPlayer> players,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    final activePlayers = players.where((p) => p.status != 'dead').toList();
    return Column(
      children: [
        Text(teamName,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(PhosphorIcons.shuffle(PhosphorIconsStyle.bold),
              size: 14, color: color),
          label: Text('Random', style: TextStyle(color: color, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
          ),
          onPressed: activePlayers.isEmpty
              ? null
              : () {
                  final shuffled = List.of(activePlayers)..shuffle();
                  onChanged(shuffled.first.id);
                },
        ),
        const SizedBox(height: 8),
        ...activePlayers.map((p) {
          final selected = p.id == selectedId;
          return InkWell(
            onTap: () => onChanged(selected ? null : p.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: selected
                    ? Border.all(color: color.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Text('#${p.number}',
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(p.name,
                        style: TextStyle(
                            color: selected ? color : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (selected)
                    Icon(PhosphorIcons.medal(PhosphorIconsStyle.fill),
                        size: 14, color: AppColors.accent),
                ],
              ),
            ),
          );
        }),
      ],
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
          else ...[
            // Header
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
          const SizedBox(height: 12),
          _addBonusSppRow(),
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
                    fontFamily: AppTextStyles.displayFont)),
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
    final homeTreasury = (_homeTeam?.treasury ?? 0) + (_homeWinnings ?? 0);
    final awayTreasury = (_awayTeam?.treasury ?? 0) + (_awayWinnings ?? 0);

    return _sectionCard(
      icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
      title: 'EXPENSIVE MISTAKES',
      color: AppColors.warning,
      subtitle: 'If Treasury ≥ 100,000 gp after winnings, roll D6',
      child: Row(
        children: [
          Expanded(
              child: _expensiveCol(
            teamName: _homeTeam?.name ?? 'Home',
            treasury: homeTreasury,
            roll: _homeExpensiveRoll,
            result: _homeExpensiveResult,
            onRollChanged: (v) {
              final res = _getExpensiveResult(homeTreasury, v);
              setState(() {
                _homeExpensiveRoll = v;
                _homeExpensiveResult = res;
              });
            },
            color: AppColors.info,
          )),
          Container(width: 1, height: 80, color: AppColors.surfaceLight),
          Expanded(
              child: _expensiveCol(
            teamName: _awayTeam?.name ?? 'Away',
            treasury: awayTreasury,
            roll: _awayExpensiveRoll,
            result: _awayExpensiveResult,
            onRollChanged: (v) {
              final res = _getExpensiveResult(awayTreasury, v);
              setState(() {
                _awayExpensiveRoll = v;
                _awayExpensiveResult = res;
              });
            },
            color: AppColors.error,
          )),
        ],
      ),
    );
  }

  Widget _expensiveCol({
    required String teamName,
    required int treasury,
    required int? roll,
    required String? result,
    required ValueChanged<int> onRollChanged,
    required Color color,
  }) {
    final applies = treasury >= 100000;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(teamName,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Treasury: ${_fmtGold(treasury)} gp',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          if (!applies)
            const Text('< 100K — Safe',
                style: TextStyle(color: AppColors.success, fontSize: 12))
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('D6:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: _numField(roll ?? 0, (v) => onRollChanged(v), max: 6),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _expensiveColor(result).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_expensiveLabel(result),
                    style: TextStyle(
                        color: _expensiveColor(result),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ],
      ),
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

  Widget _buildSubmitButton() {
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
              fontFamily: AppTextStyles.displayFont,
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
        onPressed: _submitting ? null : _submitAfterMatch,
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
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 16, color: AppColors.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

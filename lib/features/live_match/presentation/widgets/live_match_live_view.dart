part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  LIVE VIEW + SCOREBOARD + EVENTS
// ══════════════════════════════════════════════

extension _LiveMatchLiveView on _LiveMatchScreenState {
  TextStyle get _displayLarge =>
      Theme.of(context).textTheme.displayLarge ?? const TextStyle();

  TextStyle get _displaySmall =>
      Theme.of(context).textTheme.displaySmall ?? const TextStyle();

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
                // Turn tracker
                _buildMatchStateRow(match, lang),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsPanel(match, lang),
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
                    onPressed: () => context.go(_backRoute),
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
                      style: _displaySmall.copyWith(
                          color: AppColors.accent, fontSize: 22)),
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
                            style: _displaySmall.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
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

                  // Score area
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
                                style: _displayLarge.copyWith(
                                  fontSize: 118,
                                  letterSpacing: 2,
                                  height: 0.82,
                                )),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text('–',
                              style: _displayLarge.copyWith(
                                  fontSize: 76, color: AppColors.textMuted)),
                        ),
                        // Away score
                        Column(
                          children: [
                            Text('${match.scoreAway}',
                                style: _displayLarge.copyWith(
                                  fontSize: 118,
                                  letterSpacing: 2,
                                  height: 0.82,
                                )),
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
                            style: _displaySmall.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
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

  // ── Turn tracker ──

  Widget _buildMatchStateRow(Match match, String lang) {
    final activeTeam = match.currentTeam == 'away' ? 'away' : 'home';
    final activeName =
        activeTeam == 'home' ? match.home.teamName : match.away.teamName;
    final activeTurn = activeTeam == 'home' ? match.homeTurn : match.awayTurn;
    final canPass = !(activeTeam == 'away' && activeTurn >= 16);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.card,
            AppColors.surface.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(PhosphorIcons.timer(PhosphorIconsStyle.fill),
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr(lang, 'liveMatch.half')} ${match.currentHalf} · ${tr(lang, 'liveMatch.turn')} $activeTurn',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activo: $activeName · ${_fmtDuration(_activeTurnElapsed(match))}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: canPass ? () => _passTurn(match) : null,
                icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 18),
                label: const Text('Pasar turno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      activeTeam == 'home' ? AppColors.info : AppColors.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _turnTrack(
            teamName: match.home.teamName,
            teamKey: 'home',
            currentTeam: activeTeam,
            teamTurn: match.homeTurn,
            seconds: match.homeTurnSeconds,
            color: AppColors.info,
          ),
          const SizedBox(height: 10),
          _halftimeRail(),
          const SizedBox(height: 10),
          _turnTrack(
            teamName: match.away.teamName,
            teamKey: 'away',
            currentTeam: activeTeam,
            teamTurn: match.awayTurn,
            seconds: match.awayTurnSeconds,
            color: AppColors.error,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _turnTimeSummary(
                  label: match.home.teamName,
                  seconds: match.homeTurnSeconds,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _turnTimeSummary(
                  label: match.away.teamName,
                  seconds: match.awayTurnSeconds,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _passTurn(Match match) async {
    final activeTeam = match.currentTeam == 'away' ? 'away' : 'home';
    final activeTurn = activeTeam == 'home' ? match.homeTurn : match.awayTurn;
    if (activeTeam == 'away' && activeTurn >= 16) return;

    if (activeTeam == 'home') {
      final awayTurn =
          match.awayTurn < activeTurn ? activeTurn : match.awayTurn;
      await _updateState(
        currentTeam: 'away',
        awayTurn: awayTurn,
        currentTurn: awayTurn,
        currentHalf: awayTurn >= 9 ? 2 : 1,
      );
    } else {
      final nextTurn = (activeTurn + 1).clamp(1, 16).toInt();
      await _updateState(
        currentTeam: 'home',
        homeTurn: nextTurn,
        currentTurn: nextTurn,
        currentHalf: nextTurn >= 9 ? 2 : 1,
        rerollsUsedHome: nextTurn == 9 ? 0 : null,
        rerollsUsedAway: nextTurn == 9 ? 0 : null,
      );
    }
  }

  Duration _activeTurnElapsed(Match match) {
    final started = match.turnStartedAt;
    if (started == null) return Duration.zero;
    return DateTime.now().toUtc().difference(_toUtc(started));
  }

  Widget _turnTrack({
    required String teamName,
    required String teamKey,
    required String currentTeam,
    required int teamTurn,
    required List<int> seconds,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final gapCount = 15;
            final gapWidth = 4.0;
            final dividerWidth = 10.0;
            final squareSize =
                ((constraints.maxWidth - (gapCount * gapWidth) - dividerWidth) /
                        16)
                    .clamp(18.0, 34.0);
            final children = <Widget>[];
            for (var turn = 1; turn <= 16; turn++) {
              if (turn == 9) {
                children.add(_halfDivider(height: squareSize));
                children.add(SizedBox(width: gapWidth));
              }
              final completed = seconds.length >= turn;
              final active = currentTeam == teamKey && teamTurn == turn;
              children.add(_turnSquare(
                turn: turn,
                completed: completed,
                active: active,
                seconds: completed ? seconds[turn - 1] : null,
                color: color,
                size: squareSize,
              ));
              if (turn != 16) children.add(SizedBox(width: gapWidth));
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Center(
                  child:
                      Row(mainAxisSize: MainAxisSize.min, children: children),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _turnSquare({
    required int turn,
    required bool completed,
    required bool active,
    required int? seconds,
    required Color color,
    required double size,
  }) {
    final display =
        completed && seconds != null ? _fmtShortSeconds(seconds) : '$turn';
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? color
            : completed
                ? color.withValues(alpha: 0.28)
                : AppColors.surfaceLight.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.85)
              : completed
                  ? color.withValues(alpha: 0.5)
                  : AppColors.surfaceLight,
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14)]
            : null,
      ),
      child: Text(
        display,
        style: TextStyle(
          color:
              active ? Colors.white : (completed ? color : AppColors.textMuted),
          fontSize: completed ? 9 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (!completed || seconds == null) return child;
    return Tooltip(
        message: 'Turno $turn · ${_fmtDuration(Duration(seconds: seconds))}',
        child: child);
  }

  Widget _halfDivider({required double height}) => Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 10,
            ),
          ],
        ),
      );

  Widget _halftimeRail() => Divider(
        color: AppColors.surfaceLight.withValues(alpha: 0.9),
        height: 1,
      );

  Widget _turnTimeSummary({
    required String label,
    required List<int> seconds,
    required Color color,
  }) {
    final total = seconds.fold<int>(0, (sum, value) => sum + value);
    final avg = seconds.isEmpty ? 0 : total ~/ seconds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.timer(PhosphorIconsStyle.fill),
              color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${seconds.length}/16 · avg ${_fmtShortSeconds(avg)}',
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

  String _fmtShortSeconds(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds.remainder(60);
    return s == 0 ? '${m}m' : '$m:${s.toString().padLeft(2, '0')}';
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
                style: _displaySmall.copyWith(
                    fontSize: 32, color: AppColors.textPrimary)),
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
    final remaining =
        total == null ? used : (total - used).clamp(0, total).toInt();
    final isEmpty = total != null && remaining <= 0;
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
        border:
            Border.all(color: color.withValues(alpha: isEmpty ? 0.7 : 0.25)),
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
                '$remaining',
                style: _displayLarge.copyWith(
                    fontSize: 28,
                    color: isEmpty ? AppColors.error : color,
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
            'Restantes · $teamName',
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

  // ── Quick Actions panel ──

  Widget _buildQuickActionsPanel(Match match, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(lang, 'liveMatch.quickAdd').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Registra acciones clave sin romper el ritmo del partido.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickActions(match, lang),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _rerollCard(
                  teamName: match.home.teamName,
                  used: match.rerollsUsedHome,
                  total: _homeTeam?.rerolls,
                  color: AppColors.info,
                  onDec: (_homeTeam?.rerolls ?? 0) > match.rerollsUsedHome
                      ? () => _updateState(
                          rerollsUsedHome: match.rerollsUsedHome + 1)
                      : null,
                  onInc: match.rerollsUsedHome > 0
                      ? () => _updateState(
                          rerollsUsedHome: match.rerollsUsedHome - 1)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _rerollCard(
                  teamName: match.away.teamName,
                  used: match.rerollsUsedAway,
                  total: _awayTeam?.rerolls,
                  color: AppColors.error,
                  onDec: (_awayTeam?.rerolls ?? 0) > match.rerollsUsedAway
                      ? () => _updateState(
                          rerollsUsedAway: match.rerollsUsedAway + 1)
                      : null,
                  onInc: match.rerollsUsedAway > 0
                      ? () => _updateState(
                          rerollsUsedAway: match.rerollsUsedAway - 1)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
      _QA('Lanzar comp.', PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
          AppColors.info, 'throw_teammate'),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return GridView.count(
          crossAxisCount: compact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: compact ? 3.8 : 3.15,
          children: [
            ...actions.map((a) => _quickBtn(
                  label: a.label,
                  icon: a.icon,
                  color: a.color,
                  onTap: () => _showAddEventDialog(match, lang, a.type),
                )),
          ],
        );
      },
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
            onDec: (_homeTeam?.rerolls ?? 0) > match.rerollsUsedHome
                ? () => _updateState(rerollsUsedHome: match.rerollsUsedHome + 1)
                : null,
            onInc: match.rerollsUsedHome > 0
                ? () => _updateState(rerollsUsedHome: match.rerollsUsedHome - 1)
                : null,
          ),
          const SizedBox(width: 10),
          _rerollCard(
            teamName: match.away.teamName,
            used: match.rerollsUsedAway,
            total: _awayTeam?.rerolls,
            color: AppColors.error,
            onDec: (_awayTeam?.rerolls ?? 0) > match.rerollsUsedAway
                ? () => _updateState(rerollsUsedAway: match.rerollsUsedAway + 1)
                : null,
            onInc: match.rerollsUsedAway > 0
                ? () => _updateState(rerollsUsedAway: match.rerollsUsedAway - 1)
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.46),
                color.withValues(alpha: 0.2),
                AppColors.surface.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.26),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.36),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
                  onPressed: () => context.go(_backRoute),
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
                            style: _displaySmall.copyWith(fontSize: 15),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    Text('${match.scoreHome} - ${match.scoreAway}',
                        style: _displayLarge.copyWith(fontSize: 48)),
                    Expanded(
                      child: Column(children: [
                        _teamLogo(awayLogo, 60),
                        const SizedBox(height: 8),
                        Text(match.away.teamName,
                            style: _displaySmall.copyWith(fontSize: 15),
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
}

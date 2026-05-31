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
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Turn tracker
                  _buildMatchStateRow(match, lang),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActionsPanel(match, lang),
                  const SizedBox(height: 28),

                  // Rosters
                  _buildMatchRosterPanel(match, lang),
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
                        const Text('LIVE',
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
            const gapCount = 15;
            const gapWidth = 4.0;
            const dividerWidth = 10.0;
            final squareSize =
                ((constraints.maxWidth - (gapCount * gapWidth) - dividerWidth) /
                        16)
                    .clamp(18.0, 34.0);
            final children = <Widget>[];
            for (var turn = 1; turn <= 16; turn++) {
              if (turn == 9) {
                children.add(_halfDivider(height: squareSize));
                children.add(const SizedBox(width: gapWidth));
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
              if (turn != 16) children.add(const SizedBox(width: gapWidth));
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
      width: 154,
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF151B20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? AppColors.error.withValues(alpha: 0.9)
              : AppColors.surfaceLight.withValues(alpha: 0.56),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
              size: 30, color: color),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining',
                style: _displayLarge.copyWith(
                    fontSize: 34,
                    color: isEmpty ? AppColors.error : color,
                    height: 1),
              ),
              if (total != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/$total',
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            teamName,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreTap(PhosphorIcons.minus(PhosphorIconsStyle.bold), onDec,
                  size: 30),
              const SizedBox(width: 14),
              _scoreTap(PhosphorIcons.plus(PhosphorIconsStyle.bold), onInc,
                  size: 30),
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
      padding: const EdgeInsets.all(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(lang, 'liveMatch.quickAdd').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickActions(match, lang),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 14),
          _buildTeamResources(match, lang),
        ],
      ),
    );
  }

  Widget _buildMatchRosterPanel(Match match, String lang) {
    final homeTeam = _homeTeam;
    final awayTeam = _awayTeam;
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? const [];
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  color: AppColors.info,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'JUGADORES',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_rosterLoading && (homeTeam == null || awayTeam == null))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (homeTeam == null || awayTeam == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Cargando jugadores...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 980;
                final tables = [
                  _buildLiveRosterTable(
                    match: match,
                    team: homeTeam,
                    baseRoster: _homeBaseRoster,
                    teamLabel: match.home.teamName,
                    players: _liveRosterPlayers(homeTeam, true),
                    isHome: true,
                    lang: lang,
                    allPerks: allPerks,
                    accent: AppColors.info,
                    canSeeTemporaryHires: match.home.userId == currentUserId,
                  ),
                  _buildLiveRosterTable(
                    match: match,
                    team: awayTeam,
                    baseRoster: _awayBaseRoster,
                    teamLabel: match.away.teamName,
                    players: _liveRosterPlayers(awayTeam, false),
                    isHome: false,
                    lang: lang,
                    allPerks: allPerks,
                    accent: AppColors.error,
                    canSeeTemporaryHires: match.away.userId == currentUserId,
                  ),
                ];
                if (stacked) {
                  return Column(
                    children: [
                      tables[0],
                      const SizedBox(height: 12),
                      tables[1],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tables[0]),
                    const SizedBox(width: 12),
                    Expanded(child: tables[1]),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLiveRosterTable({
    required Match match,
    required UserTeamDetail team,
    required BaseTeam? baseRoster,
    required String teamLabel,
    required List<UserPlayer> players,
    required bool isHome,
    required String lang,
    required List<Map<String, dynamic>> allPerks,
    required Color accent,
    required bool canSeeTemporaryHires,
  }) {
    players = [...players]..sort((a, b) => a.number.compareTo(b.number));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: accent.withValues(alpha: 0.12),
            child: Text(
              teamLabel.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              columnSpacing: 10,
              horizontalMargin: 10,
              headingRowHeight: 34,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 70,
              headingTextStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('NOMBRE')),
                DataColumn(label: Text('MA'), numeric: true),
                DataColumn(label: Text('ST'), numeric: true),
                DataColumn(label: Text('AG'), numeric: true),
                DataColumn(label: Text('PA'), numeric: true),
                DataColumn(label: Text('AV'), numeric: true),
                DataColumn(label: Text('HABILIDADES')),
                DataColumn(label: Text('ESTADO')),
              ],
              rows: players.map((player) {
                final liveStatus =
                    _liveMatchPlayerStatus(match, player, isHome);
                final hireKind =
                    canSeeTemporaryHires ? _temporaryHireKind(player) : null;
                final hireColor = _temporaryHireColor(hireKind);
                void openPlayer() => _showLivePlayerDialog(
                      team: team,
                      player: player,
                      baseRoster: baseRoster,
                      liveStatus: liveStatus,
                      isHome: isHome,
                      lang: lang,
                      allPerks: allPerks,
                    );

                return DataRow(
                  color: WidgetStateProperty.resolveWith((_) => hireKind == null
                      ? null
                      : hireColor.withValues(alpha: 0.09)),
                  cells: [
                    DataCell(
                      Text(
                        player.number.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onTap: openPlayer,
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hireKind != null) ...[
                              const SizedBox(height: 3),
                              _temporaryHireBadge(hireKind, hireColor),
                            ],
                          ],
                        ),
                      ),
                      onTap: openPlayer,
                    ),
                    DataCell(
                        _statText(
                            player, baseRoster, 'MA', '${player.stats.ma}'),
                        onTap: openPlayer),
                    DataCell(
                        _statText(
                            player, baseRoster, 'ST', '${player.stats.st}'),
                        onTap: openPlayer),
                    DataCell(
                        _statText(player, baseRoster, 'AG', player.stats.ag),
                        onTap: openPlayer),
                    DataCell(
                        _statText(
                            player, baseRoster, 'PA', player.stats.pa ?? '-'),
                        onTap: openPlayer),
                    DataCell(
                        _statText(player, baseRoster, 'AV', player.stats.av),
                        onTap: openPlayer),
                    DataCell(
                      SizedBox(
                        width: 230,
                        child: _buildLiveSkillWrap(
                          player,
                          allPerks,
                          lang,
                          interactive: false,
                        ),
                      ),
                      onTap: openPlayer,
                    ),
                    DataCell(_statusBadge(liveStatus, lang), onTap: openPlayer),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String? _temporaryHireKind(UserPlayer player) {
    if (!player.temporaryForMatch) return null;
    if (player.baseType.startsWith('star_')) return 'ESTRELLA';
    if (player.journeyman) return 'SUSTITUTO';
    return 'MERCENARIO';
  }

  Color _temporaryHireColor(String? kind) {
    switch (kind) {
      case 'ESTRELLA':
        return AppColors.accent;
      case 'MERCENARIO':
        return AppColors.primaryLight;
      case 'SUSTITUTO':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _temporaryHireBadge(String kind, Color color) {
    final icon = switch (kind) {
      'ESTRELLA' => PhosphorIcons.star(PhosphorIconsStyle.fill),
      'MERCENARIO' => PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
      _ => PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(
            kind,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  List<UserPlayer> _liveRosterPlayers(UserTeamDetail team, bool isHome) {
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final loadedPlayers = isHome ? _homePlayers : _awayPlayers;
    final ids = selectedIds.isNotEmpty
        ? selectedIds
        : (loadedPlayers ?? const <UserPlayer>[]).map((p) => p.id).toSet();
    if (ids.isEmpty) return const [];
    return team.players.where((player) => ids.contains(player.id)).toList();
  }

  Widget _statText(
      UserPlayer player, BaseTeam? baseRoster, String stat, String value) {
    return Text(
      value,
      style: TextStyle(
        color: userPlayerStatColor(player, baseRoster, stat, value),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildLiveSkillWrap(
      UserPlayer player, List<Map<String, dynamic>> allPerks, String lang,
      {bool interactive = true}) {
    if (player.perks.isEmpty) {
      return const Text(
        '-',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: player.perks
          .map((perk) => _liveSkillChip(
                perk,
                allPerks,
                lang,
                interactive: interactive,
              ))
          .toList(),
    );
  }

  Widget _liveSkillChip(
      UserPlayerPerk perk, List<Map<String, dynamic>> allPerks, String lang,
      {required bool interactive}) {
    final displayName = localizedPerkName(allPerks, perk.name, lang);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        displayName.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (!interactive) return chip;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showSkillPopup(
          context,
          ref,
          skillName: perk.name,
          family: perk.category,
        );
      }),
      child: chip,
    );
  }

  Widget _statusBadge(String status, String lang) {
    final color = _playerStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _playerStatusLabel(status, lang).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _liveMatchPlayerStatus(Match match, UserPlayer player, bool isHome) {
    final side = isHome ? 'home' : 'away';
    final sentOff = match.events.any((event) =>
        event.type == 'foul' &&
        event.team == side &&
        event.playerId == player.id &&
        event.injury == 'sent_off');
    return sentOff ? 'sent_off' : player.status;
  }

  Future<void> _showLivePlayerDialog({
    required UserTeamDetail team,
    required UserPlayer player,
    required BaseTeam? baseRoster,
    required String liveStatus,
    required bool isHome,
    required String lang,
    required List<Map<String, dynamic>> allPerks,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final statusColor = _playerStatusColor(liveStatus);
          final screenWidth = MediaQuery.of(dialogContext).size.width;
          final popupWidth = screenWidth < 620 ? screenWidth * 0.94 : 620.0;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: popupWidth,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.88,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  player.number.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: TextStyle(
                                        fontFamily:
                                            AppTypography.displayFontFamily,
                                        color: AppColors.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      team.name,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: Icon(
                                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _statusBadge(liveStatus, lang),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _detailStat('MA', '${player.stats.ma}',
                                  color: userPlayerStatColor(player, baseRoster,
                                      'MA', '${player.stats.ma}')),
                              _detailStat('ST', '${player.stats.st}',
                                  color: userPlayerStatColor(player, baseRoster,
                                      'ST', '${player.stats.st}')),
                              _detailStat('AG', player.stats.ag,
                                  color: userPlayerStatColor(player, baseRoster,
                                      'AG', player.stats.ag)),
                              _detailStat('PA', player.stats.pa ?? '-',
                                  color: userPlayerStatColor(player, baseRoster,
                                      'PA', player.stats.pa ?? '-')),
                              _detailStat('AV', player.stats.av,
                                  color: userPlayerStatColor(player, baseRoster,
                                      'AV', player.stats.av)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'HABILIDADES',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLiveSkillWrap(player, allPerks, lang),
                          const SizedBox(height: 18),
                          _buildPlayerIncidentHistory(player, lang),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailStat(String label, String value,
      {Color color = AppColors.textPrimary}) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPlayerIncidentHistory(UserPlayer player, String lang) {
    final history = [...player.injuryHistory]..sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (lang == 'es' ? 'HISTORIAL' : 'HISTORY').toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Text(
            lang == 'es'
                ? 'Sin incidencias registradas'
                : 'No incidents recorded',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          )
        else
          ...history.map((record) => _incidentHistoryRow(record, lang)),
      ],
    );
  }

  Widget _incidentHistoryRow(UserPlayerInjuryRecord record, String lang) {
    final color = _conditionColor(record.type);
    final parts = <String>[
      record.label,
      if (record.roll != null) 'D6 ${record.roll}',
      if (record.reduction != null) record.reduction!,
    ];
    final notes = record.notes?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parts.join(' · '),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _updateLivePlayerStatus({
    required UserTeamDetail team,
    required UserPlayer player,
    required String status,
    String? injuryCategory,
    String? injuryNote,
    int? lastingInjuryRoll,
    required bool isHome,
    required String lang,
  }) async {
    try {
      final updated = await ref.read(teamRepositoryProvider).updatePlayer(
            team.id,
            player.id,
            status: status,
            injuryCategory: injuryCategory,
            injuryNote: injuryNote,
            lastingInjuryRoll: lastingInjuryRoll,
        leagueId: _isQM ? null : widget.leagueId,
        matchId: widget.matchId,
        quickMatchId: _isQM ? widget.matchId : null,
          );
      if (!mounted) return false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateLocalState(() {
          if (isHome) {
            _homeTeam = updated;
            _homePlayers = _liveSquadPlayers(updated, _selectedHomePlayers);
          } else {
            _awayTeam = updated;
            _awayPlayers = _liveSquadPlayers(updated, _selectedAwayPlayers);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(lang == 'es' ? 'Estado actualizado' : 'Status updated'),
          ),
        );
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  List<UserPlayer> _liveSquadPlayers(
      UserTeamDetail team, Set<String> selectedIds) {
    if (selectedIds.isEmpty) {
      return team.players
          .where((player) => player.status == 'healthy')
          .toList();
    }
    return team.players
        .where((player) => selectedIds.contains(player.id))
        .toList();
  }

  String _statusForConditionCategory(String category) {
    switch (category) {
      case 'miss_next_game':
      case 'lasting_injury':
        return 'missing_next_game';
      case 'sent_off':
        return 'sent_off';
      case 'dead':
        return 'dead';
      default:
        return 'healthy';
    }
  }

  Color _conditionColor(String type) {
    switch (type) {
      case 'dead':
        return AppColors.dead;
      case 'lasting_injury':
        return AppColors.error;
      case 'sent_off':
      case 'miss_next_game':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  List<_PlayerStatusOption> _playerStatusOptions(String lang) => [
        _PlayerStatusOption(
          value: 'healthy',
          label: lang == 'es' ? 'Activo' : 'Active',
          color: AppColors.success,
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        ),
        _PlayerStatusOption(
          value: 'badly_hurt',
          label: lang == 'es' ? 'Herido leve' : 'Badly hurt',
          color: AppColors.warning,
          icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
        ),
        _PlayerStatusOption(
          value: 'seriously_injured',
          label: lang == 'es' ? 'Lesionado' : 'Injured',
          color: AppColors.error,
          icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
        ),
        _PlayerStatusOption(
          value: 'missing_next_game',
          label: lang == 'es' ? 'Se pierde el próximo' : 'Miss next game',
          color: AppColors.warning,
          icon: PhosphorIcons.calendarX(PhosphorIconsStyle.fill),
        ),
        _PlayerStatusOption(
          value: 'dead',
          label: lang == 'es' ? 'Muerto' : 'Dead',
          color: AppColors.dead,
          icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
        ),
        _PlayerStatusOption(
          value: 'sent_off',
          label: lang == 'es' ? 'Expulsado' : 'Sent off',
          color: AppColors.warning,
          icon: PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
        ),
      ];

  String _playerStatusLabel(String status, String lang) {
    return _playerStatusOptions(lang)
        .firstWhere(
          (option) => option.value == status,
          orElse: () => _PlayerStatusOption(
            value: status,
            label: status,
            color: AppColors.textMuted,
            icon: PhosphorIcons.circle(PhosphorIconsStyle.regular),
          ),
        )
        .label;
  }

  Color _playerStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return AppColors.success;
      case 'badly_hurt':
      case 'missing_next_game':
        return AppColors.warning;
      case 'seriously_injured':
        return AppColors.error;
      case 'dead':
        return AppColors.dead;
      case 'sent_off':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _buildTeamResources(Match match, String lang) {
    final hasInducements = !_isQM &&
        (_homeInducementPurchases.isNotEmpty ||
            _awayInducementPurchases.isNotEmpty);
    final rulesAsync =
        hasInducements ? ref.watch(inducementRulesProvider) : null;

    return rulesAsync?.when(
          loading: () => _buildTeamResourceColumns(
            match: match,
            lang: lang,
            rulesById: const {},
            prayerResults: const [],
            inducementsLoading: true,
          ),
          error: (_, __) => _buildTeamResourceColumns(
            match: match,
            lang: lang,
            rulesById: const {},
            prayerResults: const [],
          ),
          data: (rules) => _buildTeamResourceColumns(
            match: match,
            lang: lang,
            rulesById: {for (final rule in rules.inducements) rule.id: rule},
            prayerResults: rules.prayersToNuffle,
          ),
        ) ??
        _buildTeamResourceColumns(
          match: match,
          lang: lang,
          rulesById: const {},
          prayerResults: const [],
        );
  }

  Widget _buildTeamResourceColumns({
    required Match match,
    required String lang,
    required Map<String, InducementRule> rulesById,
    required List<PrayerToNuffleResult> prayerResults,
    bool inducementsLoading = false,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final home = _buildTeamResourceColumn(
        match: match,
        teamName: match.home.teamName,
        usedRerolls: match.rerollsUsedHome,
        baseRerolls: _homeTeam?.rerolls ?? 0,
        adjustment: _homeRerollAdjustment,
        purchases: _homeInducementPurchases,
        uses: _homeInducementUses,
        details: _homeInducementDetails,
        rulesById: rulesById,
        prayerResults: prayerResults,
        isHome: true,
        lang: lang,
        color: AppColors.info,
        inducementsLoading: inducementsLoading,
      );
      final away = _buildTeamResourceColumn(
        match: match,
        teamName: match.away.teamName,
        usedRerolls: match.rerollsUsedAway,
        baseRerolls: _awayTeam?.rerolls ?? 0,
        adjustment: _awayRerollAdjustment,
        purchases: _awayInducementPurchases,
        uses: _awayInducementUses,
        details: _awayInducementDetails,
        rulesById: rulesById,
        prayerResults: prayerResults,
        isHome: false,
        lang: lang,
        color: AppColors.error,
        inducementsLoading: inducementsLoading,
      );

      if (compact) {
        return Column(
          children: [home, const SizedBox(height: 12), away],
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
    });
  }

  Widget _buildTeamResourceColumn({
    required Match match,
    required String teamName,
    required int usedRerolls,
    required int baseRerolls,
    required int adjustment,
    required Map<String, int> purchases,
    required Map<String, int> uses,
    required Map<String, List<String>> details,
    required Map<String, InducementRule> rulesById,
    required List<PrayerToNuffleResult> prayerResults,
    required bool isHome,
    required String lang,
    required Color color,
    required bool inducementsLoading,
  }) {
    final total = baseRerolls + adjustment;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rerollCard(
            teamName: teamName,
            used: usedRerolls,
            total: total,
            color: color,
            onDec: total > usedRerolls
                ? () => _updateState(
                      rerollsUsedHome: isHome ? usedRerolls + 1 : null,
                      rerollsUsedAway: isHome ? null : usedRerolls + 1,
                    )
                : null,
            onInc: usedRerolls > 0
                ? () => _updateState(
                      rerollsUsedHome: isHome ? usedRerolls - 1 : null,
                      rerollsUsedAway: isHome ? null : usedRerolls - 1,
                    )
                : null,
          ),
          if (!_isQM && (purchases.isNotEmpty || inducementsLoading)) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _buildLiveInducementTeam(
                match: match,
                purchases: purchases,
                uses: uses,
                details: details,
                rulesById: rulesById,
                prayerResults: prayerResults,
                isHome: isHome,
                lang: lang,
                loading: inducementsLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveInducementTeam({
    required Match match,
    required Map<String, int> purchases,
    required Map<String, int> uses,
    required Map<String, List<String>> details,
    required Map<String, InducementRule> rulesById,
    required List<PrayerToNuffleResult> prayerResults,
    required bool isHome,
    required String lang,
    required bool loading,
  }) {
    final entries =
        purchases.entries.where((entry) => entry.value > 0).toList();
    if (loading) {
      return const LinearProgressIndicator(color: AppColors.primary);
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    final cards = <Widget>[];
    for (final entry in entries) {
      final rule = rulesById[entry.key];
      final total = entry.value;
      if (entry.key == 'prayers_to_nuffle') {
        final prayerDetails = details[entry.key] ?? const <String>[];
        final legacyUsed = uses[entry.key] ?? 0;
        for (var index = 0; index < total; index++) {
          final detail = index < prayerDetails.length
              ? prayerDetails[index]
              : '${lang == 'es' ? 'Plegaria' : 'Prayer'} ${index + 1}';
          final useKey = _inducementInstanceUseKey(entry.key, index);
          final prayerResult = _prayerResultForDetail(detail, prayerResults);
          final used = ((uses[useKey] ?? (legacyUsed > index ? 1 : 0)))
              .clamp(0, 1)
              .toInt();
          cards.add(
            _liveInducementCard(
              match: match,
              id: useKey,
              purchaseId: entry.key,
              rule: rule,
              labelOverride: prayerResult?.localizedName(lang) ?? detail,
              total: 1,
              used: used,
              details: [detail],
              prayerResult: prayerResult,
              isHome: isHome,
              lang: lang,
            ),
          );
        }
        continue;
      }

      final used = (uses[entry.key] ?? 0).clamp(0, total).toInt();
      cards.add(
        _liveInducementCard(
          match: match,
          id: entry.key,
          purchaseId: entry.key,
          rule: rule,
          total: total,
          used: used,
          details: details[entry.key] ?? const [],
          isHome: isHome,
          lang: lang,
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: cards);
  }

  Widget _liveInducementCard({
    required Match match,
    required String id,
    required String purchaseId,
    required InducementRule? rule,
    String? labelOverride,
    required int total,
    required int used,
    required List<String> details,
    PrayerToNuffleResult? prayerResult,
    required bool isHome,
    required String lang,
  }) {
    final color = rule != null ? _inducementColor(rule) : AppColors.accent;
    final remaining = total - used;
    final label = labelOverride ?? rule?.localizedName(lang) ?? id;
    final popupDetails = _inducementPopupDetails(
      rule,
      lang,
      purchaseId,
      details,
      prayerResult,
    );
    return Container(
      width: 154,
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF151B20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remaining <= 0
              ? AppColors.error.withValues(alpha: 0.9)
              : AppColors.surfaceLight.withValues(alpha: 0.56),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rule != null
                    ? _inducementIcon(rule)
                    : PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
                color: color,
                size: 26,
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showInducementInfoDialog(
                  title: label,
                  details: popupDetails,
                  color: color,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.info(PhosphorIconsStyle.bold),
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining',
                style: _displayLarge.copyWith(
                  fontSize: 34,
                  color: remaining <= 0 ? AppColors.error : color,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/$total',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.last,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreTap(
                PhosphorIcons.minus(PhosphorIconsStyle.bold),
                remaining > 0
                    ? () => _changeLiveInducementUse(
                          match: match,
                          isHome: isHome,
                          ruleId: id,
                          purchaseRuleId: purchaseId,
                          ruleName: label,
                          delta: 1,
                        )
                    : null,
                size: 30,
              ),
              const SizedBox(width: 14),
              _scoreTap(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                used > 0
                    ? () => _changeLiveInducementUse(
                          match: match,
                          isHome: isHome,
                          ruleId: id,
                          purchaseRuleId: purchaseId,
                          ruleName: label,
                          delta: -1,
                        )
                    : null,
                size: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _inducementPopupDetails(
    InducementRule? rule,
    String lang,
    String fallbackId, [
    List<String> purchaseDetails = const [],
    PrayerToNuffleResult? prayerResult,
  ]) {
    final base = rule?.localizedDescription(lang).trim();
    final notes = rule?.notes
            .map((note) => note[lang] ?? note['en'] ?? '')
            .where((note) => note.trim().isNotEmpty)
            .map((note) => note.trim())
            .toList() ??
        const <String>[];
    final parts = <String>[
      if (base != null && base.isNotEmpty) base,
      if (prayerResult != null)
        'D16 ${prayerResult.roll}: ${prayerResult.localizedName(lang)}\n${prayerResult.localizedDescription(lang)}',
      ...notes,
      ..._extraInducementRuleDetails(rule?.id ?? fallbackId, lang),
      if (purchaseDetails.isNotEmpty && prayerResult == null)
        '${lang == 'es' ? 'Resultados registrados' : 'Recorded results'}:\n${purchaseDetails.join('\n')}',
    ];
    return parts.isEmpty ? fallbackId : parts.join('\n\n');
  }

  List<String> _extraInducementRuleDetails(String id, String lang) {
    if (id == 'biased_referee') {
      if (lang == 'en') {
        return const [
          'Dodgy League Rep: 120,000 gp, or 80,000 gp for teams with Bribery and Corruption.',
          'Close Scrutiny: if an opposition player fouls and is not sent off, roll D6; on 5+ they are sent off.',
          "I Didn't See a Thing!: apply +1 when you Argue the Call. A natural 1 still fails.",
        ];
      }
      return const [
        'Delegado de Liga Sospechoso: 120.000 po, o 80.000 po para equipos con Soborno y Corrupción.',
        'Escrutinio Cercano: si un rival hace una falta y no es expulsado, tira D6; con 5+ queda expulsado.',
        '¡No he visto nada!: aplica +1 al Protestar al Árbitro. Un 1 natural sigue fallando.',
      ];
    }
    if (id == 'josef_bugman') {
      if (lang == 'en') {
        return const [
          "Bugman's XXXXXX: apply +1 whenever you roll to recover a Knocked-out player for the duration of the game.",
          'Dwarfen Wisdom: once per game, after both teams have set up but before Kick-off, remove D3 players from the pitch and set them up again.',
        ];
      }
      return const [
        "Bugman's XXXXXX: aplica +1 siempre que tires para recuperar a un jugador Inconsciente (KO) durante el partido.",
        'Sabiduría Enana: una vez por partido, después de que ambos equipos se hayan colocado pero antes de la Patada inicial, retira D3 jugadores del campo y vuelve a colocarlos.',
      ];
    }
    if (id != 'sports_wizard') return const [];
    if (lang == 'en') {
      return const [
        'Fireball: At the end of any turn, before the next begins, choose a square. Roll a D6 for each player in that square or adjacent to it. On 4+, the player is hit. Standing players are knocked down and get +1 to the Armour roll; prone or stunned players also make an Armour roll with +1.',
        'Zap!: At the end of any turn, before the next begins, choose one player and roll a D6. If the result equals or beats their ST, or is a natural 6, they become a Frog. If they had the ball, it bounces. A natural 1 or a roll lower than ST has no effect.',
        'Frog: MA 5, ST 1, AG 2+, PA -, AV 5+. Skills: Dodge, Leap, No Ball, Stunty, Titchy, Very Long Legs. If it suffers a Casualty, it is automatically Badly Hurt. At the end of the drive, the player returns to normal in the Reserves box.',
      ];
    }
    return const [
      'Bola de Fuego: Al final de cualquier turno, antes de que empiece el siguiente, elige una casilla. Lanza 1D6 por cada jugador en esa casilla o adyacente. Con 4+, recibe el impacto. Los jugadores de pie son derribados y aplican +1 a la tirada de Armadura; los jugadores cuerpo a tierra o aturdidos también hacen Armadura con +1.',
      '¡Zap!: Al final de cualquier turno, antes de que empiece el siguiente, elige un jugador y lanza 1D6. Si igualas o superas su FU, o sacas un 6 natural, se convierte en Rana. Si tenía el balón, rebota. Un 1 natural o una tirada inferior a la FU no tiene efecto.',
      'Rana: MO 5, FU 1, AG 2+, PA -, AR 5+. Habilidades: Esquivar, Brincar, Sin Balón, Escurridizo, Diminuto y Piernas Muy Largas. Si sufre una Baja, queda Herida de Gravedad automáticamente. Al final de la entrada, el jugador vuelve a la normalidad en Reservas.',
    ];
  }

  Future<void> _showInducementInfoDialog({
    required String title,
    required String details,
    required Color color,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 620),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.info(PhosphorIconsStyle.fill),
                      color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                        color: AppColors.textMuted, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    details,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.38,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeLiveInducementUse({
    required Match match,
    required bool isHome,
    required String ruleId,
    required String purchaseRuleId,
    required String ruleName,
    required int delta,
  }) async {
    final purchases =
        isHome ? _homeInducementPurchases : _awayInducementPurchases;
    final uses = isHome ? _homeInducementUses : _awayInducementUses;
    final total = purchaseRuleId == ruleId ? purchases[ruleId] ?? 0 : 1;
    if (total <= 0) return;
    final current = uses[ruleId] ?? 0;
    final next = (current + delta).clamp(0, total).toInt();
    if (next == current) return;
    final key = 'live:${isHome ? 'home' : 'away'}:$ruleId';
    final nextHomePurchases = Map<String, int>.from(_homeInducementPurchases);
    final nextAwayPurchases = Map<String, int>.from(_awayInducementPurchases);
    final nextHomeUses = Map<String, int>.from(_homeInducementUses);
    final nextAwayUses = Map<String, int>.from(_awayInducementUses);
    final nextUses = isHome ? nextHomeUses : nextAwayUses;
    if (purchaseRuleId != ruleId) nextUses.remove(purchaseRuleId);
    if (next == 0) {
      nextUses.remove(ruleId);
    } else {
      nextUses[ruleId] = next;
    }
    _updateLocalState(() {
      _inducementMutatingKeys.add(key);
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
    });
    try {
      await _persistInducementBudgetState();
      await _updateState(
        homeInducementPurchases: nextHomePurchases,
        awayInducementPurchases: nextAwayPurchases,
        homeInducementUses: nextHomeUses,
        awayInducementUses: nextAwayUses,
      );
      final side = isHome ? 'home' : 'away';
      final teamName = isHome ? match.home.teamName : match.away.teamName;
      final verb = delta > 0 ? 'gastado' : 'restaurado';
      await _addEvent(
        type: 'inducement_change',
        team: side,
        detail: _withMatchAuditContext(
          match,
          _withInducementSyncPayload(
            summary:
                'Incentivo $verb: $ruleName ($next/$total usados) - $teamName',
            team: side,
            ruleId: ruleId,
            purchased: total,
            used: next,
          ),
        ),
        half: match.currentHalf,
        turn: match.currentTurn,
        showSnack: false,
      );
    } finally {
      if (mounted) _updateLocalState(() => _inducementMutatingKeys.remove(key));
    }
  }

  Widget _buildQuickActions(Match match, String lang) {
    final actions = [
      _QA('TD', PhosphorIcons.trophy(PhosphorIconsStyle.fill), AppColors.accent,
          'touchdown', '3 SPP'),
      _QA(
          tr(lang, 'liveMatch.completion'),
          PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill),
          AppColors.info,
          'completion',
          '1 SPP'),
      _QA(
          tr(lang, 'liveMatch.interception'),
          PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
          AppColors.success,
          'interception',
          '2 SPP'),
      _QA('Lanzar comp.', PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
          AppColors.info, 'throw_teammate', '1/+1 SPP'),
      _QA('KO', PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill),
          AppColors.warning, 'ko', null),
      _QA(
          lang == 'es' ? 'Lesión/Baja' : 'Injury/Casualty',
          PhosphorIcons.skull(PhosphorIconsStyle.fill),
          AppColors.error,
          'casualty',
          '2 SPP'),
      _QA('Foul', PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
          AppColors.primaryLight, 'foul', null),
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
          childAspectRatio: compact ? 3.7 : 4.2,
          children: [
            ...actions.map((a) => _quickBtn(
                  label: a.label,
                  icon: a.icon,
                  color: a.color,
                  sppLabel: a.sppLabel,
                  onTap: () => _showAddEventDialog(match, lang, a.type),
                )),
          ],
        );
      },
    );
  }

  Widget _quickBtn({
    required String label,
    required IconData icon,
    required Color color,
    required String? sppLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                left: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (sppLabel != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              sppLabel,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
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
    return Column(
        children: all.map((e) => _auditTile(e, match, lang)).toList());
  }

  Widget _eventTile(MatchEvent ev, String lang) {
    final isHome = ev.team == 'home';
    final clr = _evColor(ev.type);
    final detail = ev.detail == null ? null : _visibleEventDetail(ev.detail!);
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
                if (detail != null && detail.isNotEmpty)
                  Text(detail,
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

  Widget _auditTile(MatchEvent ev, Match match, String lang) {
    final clr = _evColor(ev.type);
    final detail = ev.detail == null ? null : _visibleEventDetail(ev.detail!);
    final metaRows = <Widget>[
      _auditMetaChip(tr(lang, 'liveMatch.auditId'), ev.id),
      _auditMetaChip(
          tr(lang, 'liveMatch.auditTeam'), _teamLabel(match, ev.team)),
      if (ev.half > 0 || ev.turn > 0)
        _auditMetaChip(
          tr(lang, 'liveMatch.auditMoment'),
          'H${ev.half} T${ev.turn}',
        ),
      if (ev.playerName != null || ev.playerId != null)
        _auditMetaChip(
          tr(lang, 'liveMatch.auditPlayer'),
          '${ev.playerName ?? '-'}${ev.playerId == null ? '' : ' (${ev.playerId})'}',
        ),
      if (ev.victimName != null || ev.victimId != null)
        _auditMetaChip(
          tr(lang, 'liveMatch.auditVictim'),
          '${ev.victimName ?? '-'}${ev.victimId == null ? '' : ' (${ev.victimId})'}',
        ),
      if (ev.injury != null)
        _auditMetaChip(tr(lang, 'liveMatch.auditInjury'), ev.injury!),
      if (ev.createdByName != null)
        _auditMetaChip(tr(lang, 'liveMatch.auditUser'), ev.createdByName!),
      if (ev.timestamp != null)
        _auditMetaChip(
          tr(lang, 'liveMatch.auditTime'),
          _fmtAuditDateTime(ev.timestamp!),
        ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_evIcon(ev.type), size: 15, color: clr),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ev.type.toUpperCase(),
                  style: TextStyle(
                    color: clr,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null && detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: metaRows),
        ],
      ),
    );
  }

  Widget _auditMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Bottom bar ──

  Widget _buildBottomBar(Match match, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
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

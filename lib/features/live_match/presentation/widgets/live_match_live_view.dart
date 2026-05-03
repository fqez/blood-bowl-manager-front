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
                            style: _displaySmall.copyWith(fontSize: 26),
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
                                    fontSize: 60, letterSpacing: 2)),
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
                              style: _displayLarge.copyWith(
                                  fontSize: 40, color: AppColors.textMuted)),
                        ),
                        // Away score
                        Column(
                          children: [
                            Text('${match.scoreAway}',
                                style: _displayLarge.copyWith(
                                    fontSize: 60, letterSpacing: 2)),
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
                            style: _displaySmall.copyWith(fontSize: 26),
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
                style: _displayLarge.copyWith(
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

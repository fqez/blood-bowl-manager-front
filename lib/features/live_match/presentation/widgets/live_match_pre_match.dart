part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  PRE-MATCH CEREMONY
// ══════════════════════════════════════════════

extension _LiveMatchPreMatch on _LiveMatchScreenState {
  TextStyle get _displayLarge =>
      Theme.of(context).textTheme.displayLarge ?? const TextStyle();

  TextStyle get _displayMedium =>
      Theme.of(context).textTheme.displayMedium ?? const TextStyle();

  Widget _buildPreMatchView(Match match, String lang) {
    final weatherRules = ref.watch(weatherRulesProvider).valueOrNull;
    final kickoffRules = ref.watch(kickoffEventRulesProvider).valueOrNull;
    final weatherItems = _weatherOptionsFromRules(weatherRules, lang);
    final kickoffItems = _kickoffOptionsFromRules(kickoffRules, lang);
    final weatherSet = match.weather != null && match.weather!.isNotEmpty;
    final kickoffSet =
        match.kickoffEvent != null && match.kickoffEvent!.isNotEmpty;
    final canStart =
        weatherSet && kickoffSet && match.homeReady && match.awayReady;

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
                  onPressed: () => context.go(_backRoute),
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
                        style:
                            _displayMedium.copyWith(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Text(
                      '${match.home.teamName}  vs  ${match.away.teamName}',
                      style: _displayLarge.copyWith(
                          fontSize: 28, color: AppColors.textPrimary),
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

              _sectionHeader(tr(lang, 'liveMatch.kickReceive'),
                  PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.fill)),
              const SizedBox(height: 12),
              _buildKickReceiveSelector(match, lang),
              const SizedBox(height: 24),

              // Weather selector
              _sectionHeader(tr(lang, 'liveMatch.selectWeather'),
                  PhosphorIcons.cloudSun(PhosphorIconsStyle.fill)),
              const SizedBox(height: 12),
              _buildVisualCardSelector(
                items: weatherItems,
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
                items: kickoffItems,
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

              // Checklist
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _checkRow(tr(lang, 'liveMatch.weather'), weatherSet, lang),
                    const SizedBox(height: 6),
                    _checkRow(
                        tr(lang, 'liveMatch.kickoffEvent'), kickoffSet, lang),
                    const SizedBox(height: 6),
                    _checkRow(
                      '${match.home.teamName} ready',
                      match.homeReady,
                      lang,
                    ),
                    const SizedBox(height: 6),
                    _checkRow(
                      '${match.away.teamName} ready',
                      match.awayReady,
                      lang,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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

  // ── Weather / Kickoff visual card selector ──

  Widget _buildKickReceiveSelector(Match match, String lang) {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _kickReceiveButton(
            receiverName: match.home.teamName,
            kickerName: match.away.teamName,
            selected: match.currentTeam != 'away',
            color: AppColors.info,
            onTap: () => _updateState(currentTeam: 'home'),
            lang: lang,
          ),
          _kickReceiveButton(
            receiverName: match.away.teamName,
            kickerName: match.home.teamName,
            selected: match.currentTeam == 'away',
            color: AppColors.error,
            onTap: () => _updateState(currentTeam: 'away'),
            lang: lang,
          ),
        ],
      ),
    );
  }

  Widget _kickReceiveButton({
    required String receiverName,
    required String kickerName,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    required String lang,
  }) {
    return SizedBox(
      width: 240,
      child: Material(
        color: selected ? color.withValues(alpha: 0.25) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 126),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : AppColors.surfaceLight,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.soccerBall(PhosphorIconsStyle.fill),
                  color: selected ? color : AppColors.textMuted,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  tr(lang, 'liveMatch.receiver'),
                  style: TextStyle(
                    color: selected ? color : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  receiverName,
                  style: TextStyle(
                    color: selected ? color : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${tr(lang, 'liveMatch.kicker')}: $kickerName',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    final rollFontSize = compact ? 11.0 : 13.0;

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
                    if (item.rollLabel != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 10,
                          vertical: compact ? 3 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? item.color.withValues(alpha: 0.22)
                              : AppColors.surfaceLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.rollLabel!,
                          style: TextStyle(
                            color: sel ? item.color : AppColors.textMuted,
                            fontSize: rollFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
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
}

part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  TEAM PREPARATION (pre-match)
// ══════════════════════════════════════════════

class _ResolvedInducementOffer {
  final bool available;
  final int? cost;
  final int maxPerTeam;
  final String? reason;
  final String? costOptionLabel;

  const _ResolvedInducementOffer({
    required this.available,
    required this.cost,
    required this.maxPerTeam,
    this.reason,
    this.costOptionLabel,
  });
}

class _InducementBudget {
  final int teamCurrentValue;
  final int opponentCurrentValue;
  final int ctvDifference;
  final int pettyCash;
  final int treasuryAllowance;
  final int totalAvailable;
  final int spent;
  final int treasuryContribution;
  final int remaining;
  final int opponentTreasurySpend;
  final bool isFavorite;
  final bool isUnderdog;
  final bool isTied;

  const _InducementBudget({
    required this.teamCurrentValue,
    required this.opponentCurrentValue,
    required this.ctvDifference,
    required this.pettyCash,
    required this.treasuryAllowance,
    required this.totalAvailable,
    required this.spent,
    required this.treasuryContribution,
    required this.remaining,
    required this.opponentTreasurySpend,
    required this.isFavorite,
    required this.isUnderdog,
    required this.isTied,
  });
}

extension _LiveMatchTeamPrep on _LiveMatchScreenState {
  TextStyle get _displayLarge =>
      Theme.of(context).textTheme.displayLarge ?? const TextStyle();

  TextStyle get _displaySmall =>
      Theme.of(context).textTheme.displaySmall ?? const TextStyle();

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
    final baseRerollCost = baseRoster?.rerollCost ?? team.rerollCost;
    final rerollCost =
        baseRerollCost * (team.leagueMemberships.isNotEmpty ? 2 : 1);
    final rosterPlayers = _preMatchRosterPlayers(team, isHome);
    final availablePlayers = _preMatchAvailablePlayers(team, isHome);
    final rosterPlayerIds = rosterPlayers.map((player) => player.id).toSet();
    final activeCount = availablePlayers.length;
    final woundedCount = rosterPlayers
        .where((p) => p.status != 'healthy' && p.status != 'dead')
        .length;
    final isReady = isHome ? match.homeReady : match.awayReady;
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final selectedRosterIds =
        selectedIds.where(rosterPlayerIds.contains).toList();
    final squadValid = selectedRosterIds.length >= 11;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 640;

                final logo = Container(
                  width: isCompact ? 76 : 100,
                  height: isCompact ? 76 : 100,
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
                );

                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          (baseRoster?.name ?? 'TEAM').toUpperCase(),
                          style: TextStyle(
                            color: teamColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      team.name,
                      style: _displayLarge.copyWith(
                        fontSize: isCompact ? 28 : 36,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                );

                final currentTeamValue = _teamCurrentValue(team);
                final teamValueLabel =
                    tr(lang, 'team.teamValueShort').toUpperCase();
                final currentTeamValueLabel =
                    tr(lang, 'team.currentTeamValueShort').toUpperCase();
                final treasuryLabel =
                    tr(lang, 'liveMatch.treasury').toUpperCase();
                final metrics = Column(
                  crossAxisAlignment: isCompact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    isCompact
                        ? Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _buildMetricBlock(
                                  teamValueLabel, _fmtGold(team.teamValue)),
                              _buildMetricBlock(currentTeamValueLabel,
                                  _fmtGold(currentTeamValue)),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetricBlock(
                                  teamValueLabel, _fmtGold(team.teamValue),
                                  alignEnd: true),
                              const SizedBox(width: 24),
                              _buildMetricBlock(currentTeamValueLabel,
                                  _fmtGold(currentTeamValue),
                                  alignEnd: true),
                            ],
                          ),
                    const SizedBox(height: 6),
                    _buildMetricBlock(treasuryLabel, _fmtGold(team.treasury),
                        alignEnd: !isCompact, valueColor: AppColors.accent),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          logo,
                          const SizedBox(width: 12),
                          Expanded(child: identity),
                        ],
                      ),
                      const SizedBox(height: 16),
                      metrics,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    logo,
                    const SizedBox(width: 16),
                    Expanded(child: identity),
                    metrics,
                  ],
                );
              },
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
                  // icon: PhosphorIcons.arrowsCounterClockwise(
                  //     PhosphorIconsStyle.fill),
                  icon: PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
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
                  onInc: team.treasury >= 10000 && team.cheerleaders < 6
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

          _buildMatchInducementsSection(
            team: team,
            baseRoster: baseRoster,
            lang: lang,
            isHome: isHome,
            canEdit: canEdit,
          ),

          if (!_isQM) const Divider(color: AppColors.surfaceLight, height: 24),

          // ── Active Roster ──
          Builder(builder: (_) {
            final selectedIds =
                isHome ? _selectedHomePlayers : _selectedAwayPlayers;
            final selectedCount =
                selectedIds.where(rosterPlayerIds.contains).length;
            final eligibleCount = availablePlayers.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Row(children: [
                    Expanded(
                        child:
                            _sectionHeaderAccent(tr(lang, 'liveMatch.roster'))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: eligibleCount >= 11
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: eligibleCount >= 11
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'AVAILABLE: $eligibleCount/11',
                        style: TextStyle(
                          color: eligibleCount >= 11
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SQUAD: $selectedCount/11',
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
                if (selectedCount < 11)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Text(
                      'Select at least 11 players before marking the team ready.',
                      style: TextStyle(color: AppColors.warning, fontSize: 11),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildRosterTable(team, baseRoster, lang,
                      isHome: isHome, canEdit: canEdit),
                ),
              ],
            );
          }),

          // ── Ready button ──
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: squadValid
                      ? () => _updateState(
                            homeReady: isHome ? !isReady : null,
                            awayReady: !isHome ? !isReady : null,
                            homeSquad: isHome ? selectedRosterIds : null,
                            awaySquad: !isHome ? selectedRosterIds : null,
                          )
                      : null,
                  icon: Icon(
                    isReady
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                        : PhosphorIcons.flagCheckered(PhosphorIconsStyle.fill),
                    size: 18,
                  ),
                  label: Text(
                    isReady ? 'READY ✓' : 'MARK AS READY',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReady ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isReady
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isReady
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReady
                          ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                          : PhosphorIcons.hourglass(PhosphorIconsStyle.fill),
                      size: 18,
                      color: isReady ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReady ? 'READY' : 'WAITING...',
                      style: TextStyle(
                        color: isReady ? AppColors.success : AppColors.warning,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStarPlayerDetail(Map<String, dynamic> sp, String lang) {
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? [];
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
                              fontFamily: AppTypography.displayFontFamily,
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
                                  fontFamily: AppTypography.displayFontFamily,
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
                            children: skills.map((s) {
                              final displayName =
                                  localizedPerkName(allPerks, s, lang);
                              return InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  showSkillPopup(context, ref, skillName: s);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: Text(displayName,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary)),
                                ),
                              );
                            }).toList(),
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
                                        fontFamily:
                                            AppTypography.displayFontFamily,
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
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                  PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                  size: 12,
                                  color: AppColors.textMuted),
                              const Text(
                                'Plays for: ',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 260),
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

  Widget _buildMatchInducementsSection({
    required UserTeamDetail team,
    required BaseTeam? baseRoster,
    required String lang,
    required bool isHome,
    required bool canEdit,
  }) {
    if (_isQM) return const SizedBox.shrink();

    final rulesAsync = ref.watch(inducementRulesProvider);
    final budget = _matchInducementBudget(
      team: team,
      isHome: isHome,
      lang: lang,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeaderAccent(
                    tr(lang, 'liveMatch.matchInducements')),
              ),
              _inducementBudgetBadge(
                budget: budget,
                team: team,
                lang: lang,
              ),
            ],
          ),
          const SizedBox(height: 10),
          rulesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Text(
              '$e',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
            data: (rules) {
              final purchases =
                  isHome ? _homeInducementPurchases : _awayInducementPurchases;
              final details =
                  isHome ? _homeInducementDetails : _awayInducementDetails;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rules.inducements.map((rule) {
                  final offer = _resolveInducementOffer(
                    rule,
                    team,
                    baseRoster,
                    lang,
                  );
                  final count = purchases[rule.id] ?? 0;
                  final key = '${team.id}:${rule.id}';
                  final isMutating = _inducementMutatingKeys.contains(key);
                  final canDecrease = canEdit &&
                      count > 0 &&
                      rule.id != 'riotous_rookies' &&
                      !isMutating;
                  final canIncrease = canEdit &&
                      offer.available &&
                      offer.cost != null &&
                      count < offer.maxPerTeam &&
                      budget.remaining >= offer.cost! &&
                      !isMutating;

                  return _matchInducementCard(
                    rule: rule,
                    offer: offer,
                    count: count,
                    lang: lang,
                    canEdit: canEdit,
                    canIncrease: canIncrease,
                    canDecrease: canDecrease,
                    isMutating: isMutating,
                    availableBudget: budget.remaining,
                    details: details[rule.id] ?? const [],
                    onDec: canDecrease
                        ? () => _changeMatchInducement(
                              team: team,
                              baseRoster: baseRoster,
                              rule: rule,
                              lang: lang,
                              isHome: isHome,
                              delta: -1,
                            )
                        : null,
                    onInc: canIncrease
                        ? () => _changeMatchInducement(
                              team: team,
                              baseRoster: baseRoster,
                              rule: rule,
                              lang: lang,
                              isHome: isHome,
                              delta: 1,
                            )
                        : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _matchInducementCard({
    required InducementRule rule,
    required _ResolvedInducementOffer offer,
    required int count,
    required String lang,
    required bool canEdit,
    required bool canIncrease,
    required bool canDecrease,
    required bool isMutating,
    required int availableBudget,
    required List<String> details,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    final color = _inducementColor(rule);
    final disabledReason = !offer.available
        ? offer.reason
        : offer.cost == null
            ? tr(lang, 'liveMatch.variableCost')
            : availableBudget < offer.cost!
                ? tr(lang, 'liveMatch.noInducementBudget')
                : null;
    final isDimmed = disabledReason != null && count == 0;

    return Opacity(
      opacity: isDimmed ? 0.55 : 1,
      child: Container(
        width: 174,
        height: 226,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: count > 0
                ? color.withValues(alpha: 0.45)
                : AppColors.surfaceLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_inducementIcon(rule), size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.localizedName(lang).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showInducementInfoDialog(
                    title: rule.localizedName(lang),
                    details: _inducementPopupDetails(rule, lang, rule.id),
                    color: color,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    PhosphorIcons.info(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              offer.cost != null
                  ? '${_fmtGold(offer.cost!)} GP'
                  : tr(lang, 'liveMatch.variableCost'),
              style: TextStyle(
                color:
                    offer.cost != null ? AppColors.accent : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (offer.costOptionLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                offer.costOptionLabel!,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              rule.localizedDescription(lang),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                details.last,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            if (disabledReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  disabledReason,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${count.toString().padLeft(2, '0')}/${offer.maxPerTeam}',
                  style: _displaySmall.copyWith(
                    fontSize: 20,
                    color: count > 0 ? color : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isMutating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else if (canEdit) ...[
                  _miniBtn(PhosphorIcons.minus(PhosphorIconsStyle.bold), onDec),
                  const SizedBox(width: 6),
                  _miniBtn(PhosphorIcons.plus(PhosphorIconsStyle.bold), onInc),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _ResolvedInducementOffer _resolveInducementOffer(
    InducementRule rule,
    UserTeamDetail team,
    BaseTeam? baseRoster,
    String lang,
  ) {
    final available = _isInducementAvailable(rule, team, baseRoster);
    final reason = available
        ? null
        : rule.requiredSpecialRules.isNotEmpty
            ? '${tr(lang, 'liveMatch.requires')}: ${rule.requiredSpecialRules.join(', ')}'
            : tr(lang, 'liveMatch.unavailableForTeam');

    var maxPerTeam = rule.maxPerTeam;
    var cost = rule.cost;
    String? optionLabel;

    if (rule.costOptions.isNotEmpty) {
      final option = _bestCostOption(rule, team, baseRoster);
      if (option != null) {
        cost = option.cost;
        maxPerTeam = option.maxPerTeam ?? maxPerTeam;
        if (option.appliesTo != 'any') {
          optionLabel = option.label[lang] ?? option.label['en'];
        }
      } else {
        cost = null;
      }
    }

    return _ResolvedInducementOffer(
      available: available,
      cost: cost,
      maxPerTeam: maxPerTeam,
      reason: reason,
      costOptionLabel: optionLabel,
    );
  }

  bool _isInducementAvailable(
    InducementRule rule,
    UserTeamDetail team,
    BaseTeam? baseRoster,
  ) {
    if (rule.availability == 'apothecary_allowed') {
      return team.apothecaryAllowed;
    }
    if (rule.availability == 'special_rule' ||
        rule.requiredSpecialRules.isNotEmpty) {
      return rule.requiredSpecialRules.every(
          (requiredRule) => _teamHasSpecialRule(baseRoster, requiredRule));
    }
    return rule.availability == 'any' ||
        rule.availability == 'various_teams' ||
        rule.availability.isEmpty;
  }

  InducementCostOption? _bestCostOption(
    InducementRule rule,
    UserTeamDetail team,
    BaseTeam? baseRoster,
  ) {
    final applicable = rule.costOptions
        .where((option) => _costOptionApplies(option, team, baseRoster))
        .toList();
    if (applicable.isEmpty) return null;
    applicable.sort((a, b) {
      final specificity = _costOptionSpecificity(b.appliesTo) -
          _costOptionSpecificity(a.appliesTo);
      if (specificity != 0) return specificity;
      return a.cost.compareTo(b.cost);
    });
    return applicable.first;
  }

  bool _costOptionApplies(
    InducementCostOption option,
    UserTeamDetail team,
    BaseTeam? baseRoster,
  ) {
    final appliesTo = option.appliesTo;
    if (appliesTo == 'any') return true;
    if (appliesTo.startsWith('special_rule:')) {
      return _teamHasSpecialRule(
        baseRoster,
        appliesTo.substring('special_rule:'.length),
      );
    }
    if (appliesTo.startsWith('roster:')) {
      final rosterId = _normalizeRuleKey(appliesTo.substring('roster:'.length));
      return _normalizeRuleKey(team.baseRosterId) == rosterId ||
          _normalizeRuleKey(baseRoster?.id ?? '') == rosterId;
    }
    return false;
  }

  int _costOptionSpecificity(String appliesTo) {
    if (appliesTo == 'any') return 0;
    if (appliesTo.startsWith('roster:')) return 2;
    if (appliesTo.startsWith('special_rule:')) return 2;
    return 1;
  }

  bool _teamHasSpecialRule(BaseTeam? baseRoster, String requiredRule) {
    final required = _normalizeRuleKey(requiredRule);
    return (baseRoster?.specialRules ?? const []).any((rule) {
      final normalized = _normalizeRuleKey(rule);
      return normalized == required ||
          normalized.contains(required) ||
          required.contains(normalized);
    });
  }

  String _normalizeRuleKey(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  int _matchInducementsTotal(
    UserTeamDetail team,
    BaseTeam? baseRoster,
    bool isHome,
    String lang,
  ) {
    final rules = ref.read(inducementRulesProvider).valueOrNull;
    if (rules == null) return 0;
    final purchases =
        isHome ? _homeInducementPurchases : _awayInducementPurchases;
    var total = 0;
    for (final rule in rules.inducements) {
      final count = purchases[rule.id] ?? 0;
      if (count == 0) continue;
      final offer = _resolveInducementOffer(rule, team, baseRoster, lang);
      if (offer.cost != null) total += offer.cost! * count;
    }
    return total;
  }

  _InducementBudget _matchInducementBudget({
    required UserTeamDetail team,
    required bool isHome,
    required String lang,
  }) {
    final homeTeam = _homeTeam;
    final awayTeam = _awayTeam;
    if (homeTeam == null || awayTeam == null) {
      final ctv = _teamCurrentValue(team);
      return _InducementBudget(
        teamCurrentValue: ctv,
        opponentCurrentValue: 0,
        ctvDifference: 0,
        pettyCash: 0,
        treasuryAllowance: 0,
        totalAvailable: 0,
        spent: 0,
        treasuryContribution: 0,
        remaining: 0,
        opponentTreasurySpend: 0,
        isFavorite: false,
        isUnderdog: false,
        isTied: true,
      );
    }

    final homeCtv = _teamCurrentValue(homeTeam);
    final awayCtv = _teamCurrentValue(awayTeam);
    final homeLocalSpent = _matchInducementsTotal(
      homeTeam,
      _homeBaseRoster,
      true,
      lang,
    );
    final awayLocalSpent = _matchInducementsTotal(
      awayTeam,
      _awayBaseRoster,
      false,
      lang,
    );
    final homeSpent = _trackedInducementSpend(true, homeLocalSpent);
    final awaySpent = _trackedInducementSpend(false, awayLocalSpent);
    final selectedTeam = isHome ? homeTeam : awayTeam;
    final selectedSpent = isHome ? homeSpent : awaySpent;
    final selectedCtv = isHome ? homeCtv : awayCtv;
    final opponentCtv = isHome ? awayCtv : homeCtv;

    if (homeCtv == awayCtv) {
      return _InducementBudget(
        teamCurrentValue: selectedCtv,
        opponentCurrentValue: opponentCtv,
        ctvDifference: 0,
        pettyCash: 0,
        treasuryAllowance: 0,
        totalAvailable: 0,
        spent: selectedSpent,
        treasuryContribution: 0,
        remaining: 0,
        opponentTreasurySpend: 0,
        isFavorite: false,
        isUnderdog: false,
        isTied: true,
      );
    }

    final homeIsFavorite = homeCtv > awayCtv;
    final selectedIsFavorite = isHome == homeIsFavorite;
    final ctvDifference = (homeCtv - awayCtv).abs();

    if (selectedIsFavorite) {
      final totalAvailable = selectedTeam.treasury + selectedSpent;
      final remaining = totalAvailable - selectedSpent;
      return _InducementBudget(
        teamCurrentValue: selectedCtv,
        opponentCurrentValue: opponentCtv,
        ctvDifference: ctvDifference,
        pettyCash: 0,
        treasuryAllowance: totalAvailable,
        totalAvailable: totalAvailable,
        spent: selectedSpent,
        treasuryContribution: selectedSpent,
        remaining: remaining < 0 ? 0 : remaining,
        opponentTreasurySpend: 0,
        isFavorite: true,
        isUnderdog: false,
        isTied: false,
      );
    }

    final favoriteSpent = homeIsFavorite ? homeSpent : awaySpent;
    final pettyCash = ctvDifference + favoriteSpent;
    final treasuryContribution = _treasuryContributionForSpend(
      selectedSpent,
      pettyCash,
      50000,
      isFavorite: false,
    );
    final treasuryAllowance = _treasuryTopUpAllowance(
      selectedTeam,
      treasuryContribution,
    );
    final totalAvailable = pettyCash + treasuryAllowance;
    final remaining = totalAvailable - selectedSpent;
    return _InducementBudget(
      teamCurrentValue: selectedCtv,
      opponentCurrentValue: opponentCtv,
      ctvDifference: ctvDifference,
      pettyCash: pettyCash,
      treasuryAllowance: treasuryAllowance,
      totalAvailable: totalAvailable,
      spent: selectedSpent,
      treasuryContribution: treasuryContribution,
      remaining: remaining < 0 ? 0 : remaining,
      opponentTreasurySpend: favoriteSpent,
      isFavorite: false,
      isUnderdog: true,
      isTied: false,
    );
  }

  int _teamCurrentValue(UserTeamDetail team) =>
      team.currentTeamValue > 0 ? team.currentTeamValue : team.teamValue;

  int _trackedInducementSpend(bool isHome, int localSpent) {
    final tracked = isHome ? _homeInducementSpent : _awayInducementSpent;
    final baseline = isHome
        ? _homeInducementTreasuryBaseline
        : _awayInducementTreasuryBaseline;
    final team = isHome ? _homeTeam : _awayTeam;
    final treasuryDrop =
        baseline != null && team != null ? baseline - team.treasury : 0;
    final restored = treasuryDrop > 0 ? treasuryDrop : 0;
    final bestLocal = tracked > localSpent ? tracked : localSpent;
    return restored > bestLocal ? restored : bestLocal;
  }

  int _treasuryTopUpAllowance(
    UserTeamDetail team,
    int currentTreasuryContribution,
  ) {
    final treasuryCapacity = team.treasury + currentTreasuryContribution;
    if (treasuryCapacity <= 0) return 0;
    return treasuryCapacity < 50000 ? treasuryCapacity : 50000;
  }

  int _treasuryContributionForSpend(
    int spent,
    int pettyCash,
    int treasuryAllowance, {
    required bool isFavorite,
  }) {
    if (spent <= 0) return 0;
    if (isFavorite) return spent;
    final excess = spent - pettyCash;
    if (excess <= 0) return 0;
    return excess > treasuryAllowance ? treasuryAllowance : excess;
  }

  Widget _inducementBudgetBadge({
    required _InducementBudget budget,
    required UserTeamDetail team,
    required String lang,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showInducementBudgetDialog(budget, team, lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tr(lang, 'liveMatch.availableInducementCash').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_fmtGold(budget.remaining)} GP',
                    style: _displaySmall.copyWith(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.info(PhosphorIconsStyle.bold),
                size: 18,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInducementBudgetDialog(
    _InducementBudget budget,
    UserTeamDetail team,
    String lang,
  ) {
    final isEs = lang == 'es';
    final gold = tr(lang, 'liveMatch.costGold').toUpperCase();
    String gp(int value) => '${_fmtGold(value)} $gold';
    final breakdown = team.teamValueBreakdown;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                            color: AppColors.accent, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEs
                                ? 'Cálculo de dinero para incentivos'
                                : 'Inducement cash calculation',
                            style: _displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _budgetSummaryBox(
                      label: isEs
                          ? 'Disponible para comprar'
                          : 'Available to spend',
                      value: gp(budget.remaining),
                    ),
                    const SizedBox(height: 14),
                    _budgetDialogSection(
                      isEs ? '1. Valor de Equipo (VE)' : '1. Team Value (TV)',
                      [
                        _budgetDialogLine(isEs ? 'Jugadores' : 'Players',
                            gp(breakdown.playerValue)),
                        _budgetDialogLine(isEs ? 'Re-rolls' : 'Re-rolls',
                            gp(breakdown.rerollValue)),
                        _budgetDialogLine(
                            isEs ? 'Staff de banda' : 'Sideline staff',
                            gp(breakdown.sidelineStaffValue)),
                        _budgetDialogDivider(),
                        _budgetDialogLine(
                            isEs ? 'VE' : 'TV', gp(team.teamValue),
                            strong: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _budgetDialogSection(
                      isEs
                          ? '2. Valoración Actual de Equipo (VAE)'
                          : '2. Current Team Value (CTV)',
                      [
                        _budgetDialogLine(
                            isEs ? 'VE' : 'TV', gp(team.teamValue)),
                        _budgetDialogLine(
                          isEs
                              ? 'Jugadores no disponibles'
                              : 'Unavailable players',
                          '-${gp(breakdown.unavailablePlayerValue)}',
                          valueColor: AppColors.error,
                        ),
                        _budgetDialogDivider(),
                        _budgetDialogLine(
                          isEs ? 'VAE' : 'CTV',
                          gp(budget.teamCurrentValue),
                          strong: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _budgetDialogSection(
                      isEs
                          ? '3. Comparación con el rival'
                          : '3. Opponent comparison',
                      [
                        _budgetDialogLine(isEs ? 'Tu VAE' : 'Your CTV',
                            gp(budget.teamCurrentValue)),
                        _budgetDialogLine(isEs ? 'VAE rival' : 'Opponent CTV',
                            gp(budget.opponentCurrentValue)),
                        _budgetDialogLine(isEs ? 'Diferencia' : 'Difference',
                            gp(budget.ctvDifference),
                            strong: true),
                        const SizedBox(height: 8),
                        _budgetDialogNote(
                            _inducementBudgetRoleText(budget, isEs)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _budgetDialogSection(
                      isEs
                          ? '4. Fondo y compras'
                          : '4. Cash pool and purchases',
                      _budgetCashPoolLines(budget, team, isEs, gp, gold),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isEs ? 'Cerrar' : 'Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _inducementBudgetRoleText(_InducementBudget budget, bool isEs) {
    if (budget.isTied) {
      return isEs
          ? 'Las VAE son iguales: no hay Fondo para Gastos y ningún equipo puede añadir Tesorería.'
          : 'Both CTVs are equal: there is no Petty Cash and neither team may add Treasury.';
    }
    if (budget.isFavorite) {
      return isEs
          ? 'Tu equipo tiene mayor VAE: solo puedes comprar incentivos con Tesorería.'
          : 'Your team has the higher CTV: inducements can only be bought with Treasury.';
    }
    return isEs
        ? 'Tu equipo tiene menor VAE: recibe Fondo para Gastos y puede añadir hasta 50,000 GP de Tesorería.'
        : 'Your team has the lower CTV: it receives Petty Cash and may add up to 50,000 GP from Treasury.';
  }

  List<Widget> _budgetCashPoolLines(
    _InducementBudget budget,
    UserTeamDetail team,
    bool isEs,
    String Function(int value) gp,
    String gold,
  ) {
    if (budget.isTied) {
      return [
        _budgetDialogNote(isEs
            ? 'Con VAE iguales no hay dinero disponible para incentivos.'
            : 'With equal CTVs there is no inducement cash available.'),
        _budgetDialogLine(isEs ? 'Total disponible' : 'Total available',
            gp(budget.totalAvailable),
            strong: true),
        _budgetDialogLine(isEs ? 'Comprado' : 'Purchased', gp(budget.spent)),
        _budgetDialogDivider(),
        _budgetDialogLine(
            isEs ? 'Disponible final' : 'Final available', gp(budget.remaining),
            strong: true, valueColor: AppColors.accent),
      ];
    }

    if (budget.isFavorite) {
      return [
        _budgetDialogLine(
            isEs ? 'Tesorería actual' : 'Current Treasury', gp(team.treasury)),
        _budgetDialogLine(
            isEs ? 'Ya comprado' : 'Already purchased', gp(budget.spent)),
        _budgetDialogDivider(),
        _budgetDialogLine(
          isEs ? 'Límite de compras' : 'Purchase limit',
          gp(budget.totalAvailable),
          strong: true,
        ),
        _budgetDialogLine(isEs ? 'Comprado' : 'Purchased', gp(budget.spent)),
        _budgetDialogDivider(),
        _budgetDialogLine(
            isEs ? 'Disponible final' : 'Final available', gp(budget.remaining),
            strong: true, valueColor: AppColors.accent),
      ];
    }

    return [
      _budgetDialogLine(isEs ? 'Diferencia de VAE' : 'CTV difference',
          gp(budget.ctvDifference)),
      _budgetDialogLine(isEs ? 'Gasto del favorito' : 'Favorite team spend',
          gp(budget.opponentTreasurySpend)),
      _budgetDialogDivider(),
      _budgetDialogLine(
          isEs ? 'Fondo para Gastos' : 'Petty Cash', gp(budget.pettyCash),
          strong: true),
      _budgetDialogLine(isEs ? 'Extra de Tesorería' : 'Treasury top-up',
          '${gp(budget.treasuryAllowance)} (${isEs ? 'máx' : 'max'} 50,000 $gold)'),
      _budgetDialogDivider(),
      _budgetDialogLine(isEs ? 'Total disponible' : 'Total available',
          gp(budget.totalAvailable),
          strong: true),
      _budgetDialogLine(isEs ? 'Comprado' : 'Purchased', gp(budget.spent)),
      _budgetDialogDivider(),
      _budgetDialogLine(
          isEs ? 'Disponible final' : 'Final available', gp(budget.remaining),
          strong: true, valueColor: AppColors.accent),
    ];
  }

  Widget _budgetSummaryBox({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Text(
            value,
            style: _displaySmall.copyWith(
              color: AppColors.accent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetDialogSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _budgetDialogLine(String label, String value,
      {bool strong = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: strong ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ??
                  (strong ? AppColors.textPrimary : AppColors.textSecondary),
              fontSize: 13,
              fontWeight: strong ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetDialogDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(color: AppColors.surfaceLight, height: 1),
    );
  }

  Widget _budgetDialogNote(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }

  IconData _inducementIcon(InducementRule rule) {
    switch (rule.id) {
      case 'prayers_to_nuffle':
        return PhosphorIcons.handsPraying(PhosphorIconsStyle.fill);
      case 'riotous_rookies':
        return PhosphorIcons.usersThree(PhosphorIconsStyle.fill);
      case 'part_time_assistant_coach':
        return PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill);
      case 'temp_agency_cheerleader':
        return PhosphorIcons.megaphone(PhosphorIconsStyle.fill);
      case 'weather_mage':
        return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
      case 'bribe':
      case 'biased_referee':
        return PhosphorIcons.coins(PhosphorIconsStyle.fill);
      case 'wandering_apothecary':
      case 'plague_doctor':
        return PhosphorIcons.firstAid(PhosphorIconsStyle.fill);
      case 'mercenary_player':
        return PhosphorIcons.userPlus(PhosphorIconsStyle.fill);
      case 'star_player':
        return PhosphorIcons.star(PhosphorIconsStyle.fill);
      case 'sports_wizard':
        return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.diceFive(PhosphorIconsStyle.fill);
    }
  }

  Color _inducementColor(InducementRule rule) {
    switch (rule.category) {
      case 'staff':
        return AppColors.info;
      case 'medical':
        return AppColors.success;
      case 'player':
        return AppColors.primaryLight;
      case 'wizard':
        return AppColors.warning;
      case 'special':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _changeMatchInducement({
    required UserTeamDetail team,
    required BaseTeam? baseRoster,
    required InducementRule rule,
    required String lang,
    required bool isHome,
    required int delta,
  }) async {
    final offer = _resolveInducementOffer(rule, team, baseRoster, lang);
    final cost = offer.cost;
    if (!offer.available || cost == null || delta == 0) return;

    final purchases =
        isHome ? _homeInducementPurchases : _awayInducementPurchases;
    final currentCount = purchases[rule.id] ?? 0;
    final nextCount = currentCount + delta;
    if (nextCount < 0 || nextCount > offer.maxPerTeam) return;

    String? addedDetail;
    _RiotousRookiesRoll? riotousRoll;
    if (delta > 0 && rule.id == 'prayers_to_nuffle') {
      final prayerResults =
          ref.read(inducementRulesProvider).valueOrNull?.prayersToNuffle ??
              const <PrayerToNuffleResult>[];
      final result = await _showPrayerToNuffleDialog(
        results: prayerResults,
        lang: lang,
      );
      if (result == null) return;
      addedDetail = _prayerResultSummary(result, lang);
    }
    if (delta > 0 && rule.id == 'riotous_rookies') {
      riotousRoll = await _showRiotousRookiesDialog(lang: lang);
      if (riotousRoll == null) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      addedDetail = _riotousRookiesSummary(riotousRoll, lang);
    }

    final budget = _matchInducementBudget(
      team: team,
      isHome: isHome,
      lang: lang,
    );
    final currentSpent = budget.spent;
    final nextSpent = currentSpent + (cost * delta);
    if (nextSpent < 0) return;
    if (delta > 0 && nextSpent > budget.totalAvailable) return;

    final nextTreasuryContribution = _treasuryContributionForSpend(
      nextSpent,
      budget.pettyCash,
      budget.treasuryAllowance,
      isFavorite: budget.isFavorite,
    );
    final treasuryDelta =
        nextTreasuryContribution - budget.treasuryContribution;
    final nextTreasury = team.treasury - treasuryDelta;
    if (nextTreasury < 0) return;

    final key = '${team.id}:${rule.id}';
    _updateLocalState(() => _inducementMutatingKeys.add(key));
    try {
      final nextHomePurchases = Map<String, int>.from(_homeInducementPurchases);
      final nextAwayPurchases = Map<String, int>.from(_awayInducementPurchases);
      final nextHomeUses = Map<String, int>.from(_homeInducementUses);
      final nextAwayUses = Map<String, int>.from(_awayInducementUses);
      final nextHomeDetails = _copyInducementDetails(_homeInducementDetails);
      final nextAwayDetails = _copyInducementDetails(_awayInducementDetails);
      final nextPurchases = isHome ? nextHomePurchases : nextAwayPurchases;
      final nextUses = isHome ? nextHomeUses : nextAwayUses;
      final nextDetails = isHome ? nextHomeDetails : nextAwayDetails;
      if (nextCount == 0) {
        nextPurchases.remove(rule.id);
        nextUses.remove(rule.id);
        nextUses.removeWhere(
          (key, _) => key.startsWith('${rule.id}#'),
        );
        nextDetails.remove(rule.id);
      } else {
        nextPurchases[rule.id] = nextCount;
        final currentUses = nextUses[rule.id] ?? 0;
        if (currentUses > nextCount) nextUses[rule.id] = nextCount;
        nextUses.removeWhere((key, _) {
          if (!key.startsWith('${rule.id}#')) return false;
          final index = int.tryParse(key.substring(rule.id.length + 1));
          return index == null || index >= nextCount;
        });
        final ruleDetails = List<String>.from(nextDetails[rule.id] ?? const []);
        if (addedDetail != null) ruleDetails.add(addedDetail);
        if (ruleDetails.length > nextCount) {
          nextDetails[rule.id] = ruleDetails.take(nextCount).toList();
        } else if (ruleDetails.isEmpty) {
          nextDetails.remove(rule.id);
        } else {
          nextDetails[rule.id] = ruleDetails;
        }
      }

      final teamRepo = ref.read(teamRepositoryProvider);
      var updatedTeam = team;
      if (delta < 0 && rule.id == 'riotous_rookies') {
        updatedTeam = await _releaseRiotousRookies(
          team: updatedTeam,
          isHome: isHome,
        );
      }
      updatedTeam = await teamRepo.patchTeamStaff(
        updatedTeam.id,
        treasury: nextTreasury,
      );
      if (riotousRoll != null) {
        updatedTeam = await _hireRiotousRookies(
          team: updatedTeam,
          baseRoster: baseRoster,
          roll: riotousRoll,
          isHome: isHome,
          lang: lang,
        );
      }
      if (!mounted) return;
      _updateLocalState(() {
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
        _optimisticPreMatch = _optimisticPreMatch?.copyWith(
          homeReady: isHome ? false : _optimisticPreMatch!.homeReady,
          awayReady: !isHome ? false : _optimisticPreMatch!.awayReady,
          homeInducementPurchases: nextHomePurchases,
          awayInducementPurchases: nextAwayPurchases,
          homeInducementUses: nextHomeUses,
          awayInducementUses: nextAwayUses,
          homeInducementDetails: nextHomeDetails,
          awayInducementDetails: nextAwayDetails,
        );
        if (isHome) {
          _homeInducementSpent = nextSpent;
          _homeTeam = updatedTeam;
        } else {
          _awayInducementSpent = nextSpent;
          _awayTeam = updatedTeam;
        }
      });
      await _persistInducementBudgetState();
      await _updateState(
        homeReady: isHome ? false : null,
        awayReady: !isHome ? false : null,
        homeInducementPurchases: nextHomePurchases,
        awayInducementPurchases: nextAwayPurchases,
        homeInducementUses: nextHomeUses,
        awayInducementUses: nextAwayUses,
        homeInducementDetails: nextHomeDetails,
        awayInducementDetails: nextAwayDetails,
      );
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) {
        _updateLocalState(() => _inducementMutatingKeys.remove(key));
      }
    }
  }

  String _prayerResultSummary(PrayerToNuffleResult result, String lang) {
    final gold = tr(lang, 'liveMatch.prayerRoll');
    return '$gold ${result.roll}: ${result.localizedName(lang)}';
  }

  String _riotousRookiesSummary(_RiotousRookiesRoll roll, String lang) {
    final label = lang == 'es' ? 'Novatos' : 'Rookies';
    return '$label 2D3 ${roll.firstD3}+${roll.secondD3}+1 = ${roll.count}';
  }

  Future<UserTeamDetail> _releaseRiotousRookies({
    required UserTeamDetail team,
    required bool isHome,
  }) async {
    final teamRepo = ref.read(teamRepositoryProvider);
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    final tempData = ref.read(tempHiredPlayersProvider);
    final playersToRelease = team.players.where((player) {
      final lowerName = player.name.toLowerCase();
      final belongsToMatch = player.temporaryMatchId == null ||
          player.temporaryMatchId == widget.matchId;
      return player.temporaryForMatch &&
          belongsToMatch &&
          player.journeyman &&
          (lowerName.startsWith('novato embravecido') ||
              lowerName.startsWith('riotous rookie'));
    }).toList();

    for (final player in playersToRelease) {
      await teamRepo.fireUserPlayer(team.id, player.id);
    }

    _updateLocalState(() {
      for (final player in playersToRelease) {
        selectedIds.remove(player.id);
        tempIds.remove(player.id);
        tempData.getForTeam(team.id).remove(player.id);
      }
    });
    return _loadVisibleTeamDetail(isHome: isHome);
  }

  BasePosition? _riotousRookiePosition(BaseTeam? baseRoster) {
    if (baseRoster == null) return null;
    for (final position in baseRoster.positions) {
      final marker =
          '${position.position ?? ''} ${position.name}'.toLowerCase();
      if (marker.contains('lineman')) return position;
    }
    return null;
  }

  Future<UserTeamDetail> _hireRiotousRookies({
    required UserTeamDetail team,
    required BaseTeam? baseRoster,
    required _RiotousRookiesRoll roll,
    required bool isHome,
    required String lang,
  }) async {
    final position = _riotousRookiePosition(baseRoster);
    if (position == null) {
      throw Exception(lang == 'es'
          ? 'No se encontro un linea para Novatos Embravecidos'
          : 'No lineman found for Riotous Rookies');
    }

    final teamRepo = ref.read(teamRepositoryProvider);
    final cleanedTeam = await _releaseStaleRiotousRookies(
      team: team,
      isHome: isHome,
    );
    final existingIds = cleanedTeam.players.map((player) => player.id).toSet();
    for (var index = 0; index < roll.count; index++) {
      await teamRepo.hirePlayer(
        cleanedTeam.id,
        baseType: position.id,
        name: lang == 'es'
            ? 'Novato embravecido ${index + 1}'
            : 'Riotous rookie ${index + 1}',
        temporaryForMatch: true,
        temporaryMatchId: widget.matchId,
        riotousRookie: true,
      );
    }

    final refreshedTeam = await _loadVisibleTeamDetail(isHome: isHome);
    final newPlayers = refreshedTeam.players
        .where((player) => !existingIds.contains(player.id))
        .toList();
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    _updateLocalState(() {
      for (final player in newPlayers) {
        tempIds.add(player.id);
        selectedIds.add(player.id);
        ref.read(tempHiredPlayersProvider).addPlayer(cleanedTeam.id, player.id);
      }
    });
    return refreshedTeam;
  }

  Future<UserTeamDetail> _releaseStaleRiotousRookies({
    required UserTeamDetail team,
    required bool isHome,
  }) async {
    final teamRepo = ref.read(teamRepositoryProvider);
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    final tempData = ref.read(tempHiredPlayersProvider);
    final stalePlayers = team.players.where((player) {
      final lowerName = player.name.toLowerCase();
      final isRiotousRookie = lowerName.startsWith('novato embravecido') ||
          lowerName.startsWith('riotous rookie');
      final belongsToCurrentMatch = player.temporaryMatchId == widget.matchId;
      return player.temporaryForMatch &&
          player.journeyman &&
          isRiotousRookie &&
          !belongsToCurrentMatch;
    }).toList();
    if (stalePlayers.isEmpty) return team;

    for (final player in stalePlayers) {
      await teamRepo.fireUserPlayer(team.id, player.id);
    }
    _updateLocalState(() {
      for (final player in stalePlayers) {
        selectedIds.remove(player.id);
        tempIds.remove(player.id);
        tempData.getForTeam(team.id).remove(player.id);
      }
    });
    return _loadVisibleTeamDetail(isHome: isHome);
  }

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
                style: const TextStyle(
                    color: Color.fromARGB(255, 255, 238, 0), fontSize: 13)),
          const SizedBox(height: 4),
          Text(count.toString().padLeft(2, '0'),
              style: _displaySmall.copyWith(
                  fontSize: 24, color: AppColors.textPrimary)),
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

  Widget _buildMetricBlock(String label, String value,
      {bool alignEnd = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        Text(value,
            style: _displaySmall.copyWith(
                fontSize: 28, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildRosterTable(
      UserTeamDetail team, BaseTeam? baseRoster, String lang,
      {required bool isHome, required bool canEdit}) {
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? [];
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    final sortColumn =
        isHome ? _homePrepRosterSortColumn : _awayPrepRosterSortColumn;
    final sortAscending =
        isHome ? _homePrepRosterSortAscending : _awayPrepRosterSortAscending;
    final players = _sortedPrepRosterPlayers(
      _preMatchRosterPlayers(team, isHome),
      baseRoster,
      lang,
      selectedIds,
      sortColumn,
      sortAscending,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          sortColumnIndex: _prepRosterSortColumnIndex(sortColumn),
          sortAscending: sortAscending,
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
          columns: [
            DataColumn(
                label: const Text('✓'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.selected)),
            DataColumn(
                label: const Text('#'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.number)),
            DataColumn(
                label: const Text('PLAYER NAME'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.name)),
            DataColumn(
                label: const Text('POSITION'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.position)),
            DataColumn(
                label: const Text('MA'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.ma)),
            DataColumn(
                label: const Text('ST'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.st)),
            DataColumn(
                label: const Text('AG'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.ag)),
            DataColumn(
                label: const Text('PA'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.pa)),
            DataColumn(
                label: const Text('AV'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.av)),
            DataColumn(
                label: const Text('SKILLS / TRAITS'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.skills)),
            DataColumn(
                label: const Text('SPP'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.spp)),
            DataColumn(
                label: const Text('STATUS'),
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.status)),
            DataColumn(
                label: const Text('COST'),
                numeric: true,
                onSort: (_, __) =>
                    _setPrepRosterSort(isHome, _PrepRosterSortColumn.cost)),
          ],
          rows: players.map((p) {
            final isHealthy = p.status == 'healthy';
            final isSelected = selectedIds.contains(p.id);
            final isTemp =
                canEdit && (tempIds.contains(p.id) || p.temporaryForMatch);
            final isStarPlayer = isTemp && p.baseType.startsWith('star_');
            final isJourneyman = isTemp && p.journeyman;
            final isMercenary = isTemp && !isStarPlayer && !isJourneyman;
            final tempColor = isStarPlayer
                ? AppColors.accent
                : isMercenary
                    ? AppColors.primaryLight
                    : AppColors.info;
            final tempLabel = isStarPlayer
                ? 'STAR'
                : isMercenary
                    ? 'MERC'
                    : 'SUST';
            final canSelect = isHealthy;

            return DataRow(
                color: WidgetStateProperty.resolveWith((_) => isTemp
                    ? tempColor.withValues(alpha: isSelected ? 0.16 : 0.08)
                    : isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null),
                cells: [
                  // Selection checkbox
                  DataCell(
                    canEdit
                        ? Checkbox(
                            value: isSelected,
                            onChanged: isHealthy
                                ? (val) {
                                    _updateLocalState(() {
                                      if (val == true) {
                                        selectedIds.add(p.id);
                                      } else {
                                        selectedIds.remove(p.id);
                                      }
                                    });
                                  }
                                : null,
                            activeColor: AppColors.primary,
                            side: BorderSide(
                              color: canSelect
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted.withValues(alpha: 0.3),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )
                        : Icon(
                            isSelected
                                ? PhosphorIcons.checkCircle(
                                    PhosphorIconsStyle.fill)
                                : PhosphorIcons.circle(
                                    PhosphorIconsStyle.regular),
                            size: 16,
                            color: isSelected
                                ? AppColors.success
                                : AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                  ),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.number.toString().padLeft(2, '0'),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      if (isTemp) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: tempColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(tempLabel,
                              style: TextStyle(
                                  color: tempColor,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      if (isTemp) ...[
                        const SizedBox(width: 6),
                        Icon(
                          isStarPlayer
                              ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                              : isMercenary
                                  ? PhosphorIcons.userPlus(
                                      PhosphorIconsStyle.fill)
                                  : PhosphorIcons.userSwitch(
                                      PhosphorIconsStyle.fill),
                          size: 12,
                          color: tempColor,
                        ),
                      ],
                    ],
                  )),
                  DataCell(Text(
                      localizedPlayerPosition(p,
                          roster: baseRoster, lang: lang),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10))),
                  DataCell(_prepStatText(
                      p, baseRoster, 'MA', p.stats.ma.toString())),
                  DataCell(_prepStatText(
                      p, baseRoster, 'ST', p.stats.st.toString())),
                  DataCell(_prepStatText(
                      p, baseRoster, 'AG', p.stats.ag.toString())),
                  DataCell(
                      _prepStatText(p, baseRoster, 'PA', p.stats.pa ?? '-')),
                  DataCell(_prepStatText(
                      p, baseRoster, 'AV', p.stats.av.toString())),
                  DataCell(Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: p.perks.map((perk) {
                      final displayName =
                          localizedPerkName(allPerks, perk.name, lang);
                      return GestureDetector(
                        onTap: () => showSkillPopup(context, ref,
                            skillName: perk.name, family: perk.category),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(displayName.toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                  DataCell(Text('${p.spp}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHealthy
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.status.toUpperCase(),
                        style: TextStyle(
                            color:
                                isHealthy ? AppColors.success : AppColors.error,
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

  List<UserPlayer> _preMatchRosterPlayers(UserTeamDetail team, bool isHome) {
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    final purchases =
        isHome ? _homeInducementPurchases : _awayInducementPurchases;
    return team.players
        .where((player) =>
            _isVisiblePreMatchRosterPlayer(player, tempIds, purchases))
        .toList();
  }

  List<UserPlayer> _preMatchAvailablePlayers(UserTeamDetail team, bool isHome) {
    return _preMatchRosterPlayers(team, isHome)
        .where((player) => player.status == 'healthy')
        .toList();
  }

  bool _isVisiblePreMatchRosterPlayer(
    UserPlayer player,
    Set<String> tempIds,
    Map<String, int> purchases,
  ) {
    if (player.isDead || player.status == 'dead') return false;
    if (!player.temporaryForMatch) return true;
    if (player.temporaryMatchId != widget.matchId) return false;

    if (_isRiotousRookie(player)) {
      return tempIds.contains(player.id) ||
          (purchases['riotous_rookies'] ?? 0) > 0;
    }

    return true;
  }

  bool _isRiotousRookie(UserPlayer player) {
    final lowerName = player.name.toLowerCase();
    return player.journeyman &&
        (lowerName.startsWith('novato embravecido') ||
            lowerName.startsWith('riotous rookie'));
  }

  Widget _prepStatText(
      UserPlayer player, BaseTeam? baseRoster, String stat, String value) {
    return Text(
      value,
      style: TextStyle(
        color: userPlayerStatColor(player, baseRoster, stat, value),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<UserPlayer> _sortedPrepRosterPlayers(
    List<UserPlayer> players,
    BaseTeam? baseRoster,
    String lang,
    Set<String> selectedIds,
    _PrepRosterSortColumn sortColumn,
    bool ascending,
  ) {
    final sorted = List<UserPlayer>.from(players);
    sorted.sort((a, b) {
      int result;
      switch (sortColumn) {
        case _PrepRosterSortColumn.selected:
          result = (selectedIds.contains(a.id) ? 1 : 0)
              .compareTo(selectedIds.contains(b.id) ? 1 : 0);
        case _PrepRosterSortColumn.number:
          result = a.number.compareTo(b.number);
        case _PrepRosterSortColumn.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _PrepRosterSortColumn.position:
          result = localizedPlayerPosition(a, roster: baseRoster, lang: lang)
              .toLowerCase()
              .compareTo(
                  localizedPlayerPosition(b, roster: baseRoster, lang: lang)
                      .toLowerCase());
        case _PrepRosterSortColumn.ma:
          result = a.stats.ma.compareTo(b.stats.ma);
        case _PrepRosterSortColumn.st:
          result = a.stats.st.compareTo(b.stats.st);
        case _PrepRosterSortColumn.ag:
          result = _prepRollStatValue(a.stats.ag)
              .compareTo(_prepRollStatValue(b.stats.ag));
        case _PrepRosterSortColumn.pa:
          result = _prepRollStatValue(a.stats.pa ?? '-')
              .compareTo(_prepRollStatValue(b.stats.pa ?? '-'));
        case _PrepRosterSortColumn.av:
          result = _prepRollStatValue(a.stats.av)
              .compareTo(_prepRollStatValue(b.stats.av));
        case _PrepRosterSortColumn.skills:
          result = a.perks.length.compareTo(b.perks.length);
        case _PrepRosterSortColumn.spp:
          result = a.spp.compareTo(b.spp);
        case _PrepRosterSortColumn.status:
          result = a.status.compareTo(b.status);
        case _PrepRosterSortColumn.cost:
          result = a.currentValue.compareTo(b.currentValue);
      }
      if (result == 0) result = a.number.compareTo(b.number);
      return ascending ? result : -result;
    });
    return sorted;
  }

  int _prepRollStatValue(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? 99 : int.parse(match.group(0)!);
  }

  int _prepRosterSortColumnIndex(_PrepRosterSortColumn column) => column.index;

  void _setPrepRosterSort(bool isHome, _PrepRosterSortColumn column) {
    _updateLocalState(() {
      if (isHome) {
        if (_homePrepRosterSortColumn == column) {
          _homePrepRosterSortAscending = !_homePrepRosterSortAscending;
        } else {
          _homePrepRosterSortColumn = column;
          _homePrepRosterSortAscending = true;
        }
      } else {
        if (_awayPrepRosterSortColumn == column) {
          _awayPrepRosterSortAscending = !_awayPrepRosterSortAscending;
        } else {
          _awayPrepRosterSortColumn = column;
          _awayPrepRosterSortAscending = true;
        }
      }
    });
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
      // Reset ready flag when team composition changes
      final isHome = _homeTeam?.id == teamId;
      _updateState(
        homeReady: isHome ? false : null,
        awayReady: !isHome ? false : null,
      );
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }
}

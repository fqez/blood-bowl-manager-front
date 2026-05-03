part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  TEAM PREPARATION (pre-match)
// ══════════════════════════════════════════════

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
    final rerollCost = baseRoster?.rerollCost ?? team.rerollCost;
    final activeCount = team.players.where((p) => p.status == 'healthy').length;
    final woundedCount = team.players
        .where((p) => p.status != 'healthy' && p.status != 'dead')
        .length;
    final isReady = isHome ? match.homeReady : match.awayReady;
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final squadValid = selectedIds.isNotEmpty && selectedIds.length <= 11;

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
                      Text(
                        team.name,
                        style: _displayLarge.copyWith(
                          fontSize: 36,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
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
                        style: _displaySmall.copyWith(fontSize: 28)),
                    const SizedBox(height: 6),
                    const Text('TREASURY',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    Text(_fmtGold(team.treasury),
                        style: _displaySmall.copyWith(
                            fontSize: 28, color: AppColors.accent)),
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
          Builder(builder: (_) {
            final selectedIds =
                isHome ? _selectedHomePlayers : _selectedAwayPlayers;
            final tempIds =
                isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
            final selectedCount = selectedIds.length;
            final maxSquad = 11;
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
                        color: selectedCount == maxSquad
                            ? AppColors.success.withValues(alpha: 0.15)
                            : selectedCount > maxSquad
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selectedCount == maxSquad
                              ? AppColors.success.withValues(alpha: 0.3)
                              : selectedCount > maxSquad
                                  ? AppColors.error.withValues(alpha: 0.3)
                                  : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'SQUAD: $selectedCount/$maxSquad',
                        style: TextStyle(
                          color: selectedCount == maxSquad
                              ? AppColors.success
                              : selectedCount > maxSquad
                                  ? AppColors.error
                                  : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                if (selectedCount > maxSquad)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Text(
                      'Too many players selected! Max $maxSquad for a match.',
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildRosterTable(team, lang,
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
                            homeSquad: isHome ? selectedIds.toList() : null,
                            awaySquad: !isHome ? selectedIds.toList() : null,
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

  Widget _buildRosterTable(UserTeamDetail team, String lang,
      {required bool isHome, required bool canEdit}) {
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
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
            DataColumn(label: Text('✓')),
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
            final isSelected = selectedIds.contains(p.id);
            final isTemp = tempIds.contains(p.id);
            final canSelect =
                isHealthy && (isSelected || selectedIds.length < 11);

            return DataRow(
                color: WidgetStateProperty.resolveWith((_) => isSelected
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
                                    setState(() {
                                      if (val == true &&
                                          selectedIds.length < 11) {
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
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('TEMP',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  )),
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(perk.name.toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 9,
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

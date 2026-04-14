part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  DIALOGS (event, hire player, hire star)
// ══════════════════════════════════════════════

extension _LiveMatchDialogs on _LiveMatchScreenState {
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
          final evColor = _evColor(eventType);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: 560,
              constraints: const BoxConstraints(maxHeight: 620),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: evColor.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: evColor.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header with gradient ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          evColor.withValues(alpha: 0.2),
                          AppColors.surface,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              evColor.withValues(alpha: 0.3),
                              evColor.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: evColor.withValues(alpha: 0.4)),
                        ),
                        child:
                            Icon(_evIcon(eventType), color: evColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eventType.toUpperCase(),
                                style: TextStyle(
                                    color: evColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text(
                                '${tr(lang, 'liveMatch.add')} ${eventType.toUpperCase()}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                            color: AppColors.textMuted, size: 20),
                      ),
                    ]),
                  ),

                  // ── Body ──
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
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
                              value: selectedPlayer,
                              dropdownColor: AppColors.card,
                              isExpanded: true,
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDeco(
                                  tr(lang, 'liveMatch.selectPlayer')),
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
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration:
                                  _inputDeco(tr(lang, 'liveMatch.playerName')),
                              onChanged: (v) => playerNameText = v,
                            ),

                          if (needsVictim) ...[
                            const SizedBox(height: 12),
                            if (opponents.isNotEmpty)
                              DropdownButtonFormField<UserPlayer>(
                                value: selectedVictim,
                                dropdownColor: AppColors.card,
                                isExpanded: true,
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                decoration: _inputDeco(
                                    tr(lang, 'liveMatch.selectVictim')),
                                items: opponents
                                    .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text('#${p.number} — ${p.name}',
                                            style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14))))
                                    .toList(),
                                onChanged: (v) =>
                                    setS(() => selectedVictim = v),
                              )
                            else
                              TextField(
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                decoration: _inputDeco(
                                    tr(lang, 'liveMatch.victimName')),
                                onChanged: (v) => victimNameText = v,
                              ),
                          ],
                          if (needsInjury) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedInjury,
                              dropdownColor: AppColors.card,
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration:
                                  _inputDeco(tr(lang, 'liveMatch.injuryType')),
                              items: _injuryTypes
                                  .map((i) => DropdownMenuItem(
                                      value: i, child: Text(i)))
                                  .toList(),
                              onChanged: (v) => setS(() => selectedInjury = v),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration:
                                _inputDeco(tr(lang, 'liveMatch.detail')),
                            onChanged: (v) => detail = v,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Actions ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AppColors.surfaceLight
                                  .withValues(alpha: 0.5))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          child: Text(tr(lang, 'common.cancel'),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 15)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(_evIcon(eventType), size: 18),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addEvent(
                              type: eventType,
                              team: selectedTeam,
                              playerId: selectedPlayer?.id,
                              playerName: selectedPlayer != null
                                  ? '#${selectedPlayer!.number} ${selectedPlayer!.name}'
                                  : (playerNameText.isEmpty
                                      ? null
                                      : playerNameText),
                              victimId: selectedVictim?.id,
                              victimName: selectedVictim != null
                                  ? '#${selectedVictim!.number} ${selectedVictim!.name}'
                                  : (victimNameText.isEmpty
                                      ? null
                                      : victimNameText),
                              injury: selectedInjury,
                              detail: detail.isEmpty ? null : detail,
                              half: match.currentHalf,
                              turn: match.currentTurn,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: evColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: evColor.withValues(alpha: 0.5),
                          ),
                          label: Text(tr(lang, 'liveMatch.add')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Hire Player Dialog ──

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
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 700),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
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
                                  DataColumn(
                                      label: Text('COST'), numeric: true),
                                  DataColumn(label: Text('')),
                                ],
                                rows: [
                                  ...baseRoster.positions.map((pos) {
                                    final currentCount =
                                        countByType[pos.id] ?? 0;
                                    final available =
                                        currentCount < pos.maxQuantity;
                                    final canAfford = team.treasury >= pos.cost;
                                    final canHire = available && canAfford;
                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith(
                                          (_) => canHire
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
                                        DataCell(Text(
                                            '$currentCount/${pos.maxQuantity}',
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
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: canHire
                                                              ? AppColors
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.15)
                                                              : AppColors
                                                                  .surfaceLight
                                                                  .withValues(
                                                                      alpha:
                                                                          0.4),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                            perk.name
                                                                .toUpperCase(),
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
                                                        _showHireNameDialog(ctx,
                                                            team, pos, lang),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColors.primary,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6)),
                                                    ),
                                                    child: const Text('HIRE',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                )
                                              : Text(
                                                  !available
                                                      ? 'MAX'
                                                      : 'NO FUNDS',
                                                  style: const TextStyle(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── Star players section ──
                      if (starPlayers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 8),
                            const Text('STAR PLAYERS',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor:
                                      WidgetStateProperty.all(AppColors.card),
                                  dataRowColor: WidgetStateProperty.all(
                                      Colors.transparent),
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
                                    DataColumn(label: Text('STAR PLAYER')),
                                    DataColumn(label: Text('')),
                                    DataColumn(
                                        label: Text('MA'), numeric: true),
                                    DataColumn(
                                        label: Text('ST'), numeric: true),
                                    DataColumn(
                                        label: Text('AG'), numeric: true),
                                    DataColumn(
                                        label: Text('PA'), numeric: true),
                                    DataColumn(
                                        label: Text('AV'), numeric: true),
                                    DataColumn(label: Text('SKILLS')),
                                    DataColumn(
                                        label: Text('COST'), numeric: true),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: starPlayers.map((sp) {
                                    final spId = sp['id'] as String? ?? '';
                                    final spName = sp['name'] as String? ?? '';
                                    final spCost =
                                        (sp['cost'] as num?)?.toInt() ?? 0;
                                    final spStats =
                                        sp['stats'] as Map<String, dynamic>? ??
                                            {};
                                    final spSkills = (sp['skills'] as List?)
                                            ?.cast<String>() ??
                                        [];
                                    final canAffordStar =
                                        team.treasury >= spCost;
                                    final alreadyHired = activePlayers
                                        .any((p) => p.baseType == 'star_$spId');
                                    final canHireStar = canAffordStar &&
                                        !alreadyHired &&
                                        activePlayers.length < 16;
                                    final blockLabel = alreadyHired
                                        ? 'HIRED'
                                        : activePlayers.length >= 16
                                            ? 'FULL'
                                            : 'NO FUNDS';
                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith(
                                          (_) => canHireStar
                                              ? null
                                              : AppColors.surfaceLight
                                                  .withValues(alpha: 0.1)),
                                      cells: [
                                        DataCell(
                                          GestureDetector(
                                            onTap: () =>
                                                _showStarPlayerDetail(sp, lang),
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      PhosphorIcons.star(
                                                          PhosphorIconsStyle
                                                              .fill),
                                                      size: 12,
                                                      color: AppColors.accent),
                                                  const SizedBox(width: 4),
                                                  Text(spName.toUpperCase(),
                                                      style: TextStyle(
                                                        color: canHireStar
                                                            ? AppColors.accent
                                                            : AppColors
                                                                .textMuted,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: IconButton(
                                              onPressed: () =>
                                                  _showStarPlayerDetail(
                                                      sp, lang),
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              style: IconButton.styleFrom(
                                                side: BorderSide(
                                                    color: AppColors.accent
                                                        .withValues(
                                                            alpha: 0.3)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6)),
                                              ),
                                              icon: Icon(
                                                  PhosphorIcons.eye(
                                                      PhosphorIconsStyle.fill),
                                                  color: AppColors.accent,
                                                  size: 14),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(_fmtStat(spStats['MA']),
                                            style:
                                                _hireStatStyle(canHireStar))),
                                        DataCell(Text(_fmtStat(spStats['ST']),
                                            style:
                                                _hireStatStyle(canHireStar))),
                                        DataCell(Text(_fmtStat(spStats['AG']),
                                            style:
                                                _hireStatStyle(canHireStar))),
                                        DataCell(Text(_fmtStat(spStats['PA']),
                                            style:
                                                _hireStatStyle(canHireStar))),
                                        DataCell(Text(_fmtStat(spStats['AV']),
                                            style:
                                                _hireStatStyle(canHireStar))),
                                        DataCell(Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: spSkills
                                              .map((s) => GestureDetector(
                                                    onTap: () => showSkillPopup(
                                                        context, ref,
                                                        skillName: s),
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: canHireStar
                                                              ? AppColors.accent
                                                                  .withValues(
                                                                      alpha:
                                                                          0.12)
                                                              : AppColors
                                                                  .surfaceLight
                                                                  .withValues(
                                                                      alpha:
                                                                          0.4),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                            s.toUpperCase(),
                                                            style: TextStyle(
                                                                color: canHireStar
                                                                    ? AppColors
                                                                        .accent
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
                                        DataCell(Text(_fmtGold(spCost),
                                            style: TextStyle(
                                              color: canAffordStar
                                                  ? AppColors.accent
                                                  : AppColors.error,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ))),
                                        DataCell(
                                          canHireStar
                                              ? SizedBox(
                                                  height: 32,
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        _showHireStarNameDialog(
                                                            ctx,
                                                            team,
                                                            sp,
                                                            lang),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColors.accent,
                                                      foregroundColor:
                                                          Colors.black,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6)),
                                                    ),
                                                    child: const Text('HIRE',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                )
                                              : Text(
                                                  blockLabel,
                                                  style: const TextStyle(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
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

  // ── Hire Name Dialog (normal player) ──

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
      // After refresh, find the newly added player and mark as temp
      await _doRefreshPreMatch();
      _refresh();
      _markNewPlayerAsTemp(teamId);
      _resetReadyForTeam(teamId);
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  /// Finds the most-recently added player that isn't already tracked
  /// and marks them as a temporary match-day signing.
  void _markNewPlayerAsTemp(String teamId) {
    final isHome = _homeTeam?.id == teamId;
    final team = isHome ? _homeTeam : _awayTeam;
    final selectedIds = isHome ? _selectedHomePlayers : _selectedAwayPlayers;
    final tempIds = isHome ? _tempHiredHomePlayers : _tempHiredAwayPlayers;
    if (team == null) return;
    // The newest player is the one whose ID is not in tempIds or selectedIds yet
    for (final p in team.players.reversed) {
      if (!tempIds.contains(p.id) && !selectedIds.contains(p.id)) {
        setState(() {
          tempIds.add(p.id);
          // Also auto-select if under 11
          if (selectedIds.length < 11) {
            selectedIds.add(p.id);
          }
        });
        // Also persist to provider for post-match screen
        ref.read(tempHiredPlayersProvider).addPlayer(teamId, p.id);
        break;
      }
    }
  }

  // ── Hire Star Player Name Dialog ──

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
      // After refresh, find the newly added star and mark as temp
      await _doRefreshPreMatch();
      _refresh();
      _markNewPlayerAsTemp(teamId);
      _resetReadyForTeam(teamId);
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  /// Resets the ready flag for the given team when its composition changes.
  void _resetReadyForTeam(String teamId) {
    final isHome = _homeTeam?.id == teamId;
    _updateState(
      homeReady: isHome ? false : null,
      awayReady: !isHome ? false : null,
    );
  }
}

part of '../screens/live_match_screen.dart';

// ----------------------------------------------
extension _LiveMatchDialogs on _LiveMatchScreenState {
// ----------------------------------------------

// DIALOGS (event, hire player, hire star)
  TextStyle get _displayLarge =>
      Theme.of(context).textTheme.displayLarge ?? const TextStyle();

  TextStyle get _displaySmall =>
      Theme.of(context).textTheme.displaySmall ?? const TextStyle();

  bool _isLinemanPosition(BasePosition position) {
    final haystack = [position.position, position.name, position.id]
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    return haystack.contains('lineman') ||
        haystack.contains('linea') ||
        haystack.contains('línea');
  }

// ----------------------------------------------

  void _showAddEventDialog(Match match, String lang, String eventType,
      {String initialTeam = 'home'}) {
    showMatchEventDialog(
      context: context,
      match: match,
      lang: lang,
      eventType: eventType,
      initialTeam: initialTeam,
      homePlayers: _homePlayers ?? [],
      awayPlayers: _awayPlayers ?? [],
      onAdd: (draft) async {
        final eventAdded = await _addEvent(
          type: draft.type,
          team: draft.team,
          playerId: draft.playerId,
          playerName: draft.playerName,
          victimId: draft.victimId,
          victimName: draft.victimName,
          injury: draft.sentOff ? 'sent_off' : draft.injury,
          detail: _withMatchAuditContext(match, draft.detail),
          half: draft.half,
          turn: draft.turn,
        );
        if (!eventAdded) return false;
        await _applyDraftPlayerCondition(draft, lang);
        return true;
      },
    );
  }

  Future<bool> _applyDraftPlayerCondition(
    MatchEventDraft draft,
    String lang,
  ) async {
    if (draft.type == 'casualty' && draft.injuryCategory != null) {
      if (draft.victimId == null) return true;
      final victimIsHome = draft.team != 'home';
      final team = victimIsHome ? _homeTeam : _awayTeam;
      final player = _findLivePlayer(
        draft.victimId!,
        victimIsHome ? _homePlayers : _awayPlayers,
        team,
      );
      if (team == null || player == null) {
        _snack(lang == 'es'
            ? 'No se pudo encontrar al jugador lesionado'
            : 'Could not find the injured player');
        return false;
      }
      return _updateLivePlayerStatus(
        team: team,
        player: player,
        status: _statusForConditionCategory(draft.injuryCategory!),
        injuryCategory: draft.injuryCategory,
        injuryNote: draft.injuryNote,
        lastingInjuryRoll: draft.lastingInjuryRoll,
        isHome: victimIsHome,
        lang: lang,
      );
    }

    if (draft.type == 'foul' && draft.sentOff) {
      return true;
    }

    return true;
  }

  UserPlayer? _findLivePlayer(
    String playerId,
    List<UserPlayer>? livePlayers,
    UserTeamDetail? team,
  ) {
    for (final player in [...?livePlayers, ...?team?.players]) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  Future<PrayerToNuffleResult?> _showPrayerToNuffleDialog({
    required List<PrayerToNuffleResult> results,
    required String lang,
  }) async {
    if (results.isEmpty) {
      _snack(lang == 'es'
          ? 'No se pudo cargar la tabla de Plegarias a Nuffle'
          : 'Could not load the Prayers to Nuffle table');
      return null;
    }
    final sorted = List<PrayerToNuffleResult>.from(results)
      ..sort((a, b) => a.roll.compareTo(b.roll));
    final rollCtrl = TextEditingController();
    PrayerToNuffleResult? selected;

    try {
      return await showDialog<PrayerToNuffleResult>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            void selectRoll(String raw) {
              final roll = int.tryParse(raw.trim());
              selected = null;
              if (roll != null) {
                for (final result in sorted) {
                  if (result.roll == roll) {
                    selected = result;
                    break;
                  }
                }
              }
              setS(() {});
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 680,
                constraints: const BoxConstraints(maxHeight: 720),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.38),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.handsPraying(PhosphorIconsStyle.fill),
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (lang == 'es'
                                    ? 'Plegarias a Nuffle'
                                    : 'Prayers to Nuffle')
                                .toUpperCase(),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTypography.displayFontFamily,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: rollCtrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDeco('D16'),
                        onChanged: selectRoll,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final result = sorted[index];
                          final active = selected?.roll == result.roll;
                          return InkWell(
                            onTap: () {
                              rollCtrl.text = '${result.roll}';
                              selected = result;
                              setS(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.accent.withValues(alpha: 0.14)
                                    : AppColors.card.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? AppColors.accent
                                      : AppColors.surfaceLight,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '${result.roll}',
                                      style: TextStyle(
                                        color: active
                                            ? AppColors.accent
                                            : AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.localizedName(lang),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          result.localizedDescription(lang),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            height: 1.25,
                                          ),
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
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            tr(lang, 'common.cancel'),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: selected == null
                              ? null
                              : () => Navigator.pop(ctx, selected),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            tr(lang, 'common.confirm'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      rollCtrl.dispose();
    }
  }

  Future<_RiotousRookiesRoll?> _showRiotousRookiesDialog({
    required String lang,
  }) async {
    final firstCtrl = TextEditingController();
    final secondCtrl = TextEditingController();
    int? first;
    int? second;

    try {
      return await showDialog<_RiotousRookiesRoll>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            void readDice() {
              final firstValue = int.tryParse(firstCtrl.text.trim());
              final secondValue = int.tryParse(secondCtrl.text.trim());
              first = firstValue != null && firstValue >= 1 && firstValue <= 3
                  ? firstValue
                  : null;
              second =
                  secondValue != null && secondValue >= 1 && secondValue <= 3
                      ? secondValue
                      : null;
              setS(() {});
            }

            final roll = first != null && second != null
                ? _RiotousRookiesRoll(first!, second!)
                : null;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.38),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (lang == 'es'
                                    ? 'Novatos embravecidos'
                                    : 'Riotous Rookies')
                                .toUpperCase(),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTypography.displayFontFamily,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == 'es'
                          ? 'Introduce el resultado de 2D3. Se añadira automaticamente 2D3+1 sustitutos.'
                          : 'Enter the 2D3 result. 2D3+1 substitutes will be added automatically.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: firstCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _inputDeco('D3'),
                            onChanged: (_) => readDice(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: secondCtrl,
                            keyboardType: TextInputType.number,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _inputDeco('D3'),
                            onChanged: (_) => readDice(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            roll == null
                                ? '2D3+1'
                                : '${first!}+${second!}+1 = ${roll.count}',
                            style: TextStyle(
                              color: roll == null
                                  ? AppColors.textMuted
                                  : AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTypography.displayFontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            tr(lang, 'common.cancel'),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: roll == null
                              ? null
                              : () => Navigator.pop(ctx, roll),
                          icon: Icon(
                            PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                            size: 16,
                          ),
                          label: Text(lang == 'es' ? 'Añadir' : 'Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      firstCtrl.dispose();
      secondCtrl.dispose();
    }
  }

  // Hire Player Dialog

  Future<void> _showHirePlayerDialog(
      UserTeamDetail team, BaseTeam baseRoster, String lang) async {
    final activePlayers = team.players.where((p) => !p.isDead).toList();
    final eligiblePlayers =
        team.players.where((p) => p.status == 'healthy').toList();
    final needsSubstitutes = eligiblePlayers.length < 11;
    final countByType = <String, int>{};
    for (final p in eligiblePlayers) {
      countByType[p.baseType] = (countByType[p.baseType] ?? 0) + 1;
    }
    final journeymanPositions =
        baseRoster.positions.where(_isLinemanPosition).toList();

    List<Map<String, dynamic>> starPlayers = [];
    try {
      final repo = ref.read(teamRepositoryProvider);
      final allDetails = await repo.getAllStarPlayerDetails();
      starPlayers = allDetails
          .where((sp) => starPlayerAvailableForUserTeam(sp, team))
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
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          Text(
                            tr(lang, 'liveMatch.hirePlayer').toUpperCase(),
                            style: _displayLarge.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            baseRoster.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
                              color: AppColors.accent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${_fmtGold(team.treasury)} GP',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hireSectionHeader(
                        icon: PhosphorIcons.userSwitch(PhosphorIconsStyle.fill),
                        title: 'SUSTITUTOS',
                        subtitle: needsSubstitutes
                            ? 'Gratis hasta completar 11 jugadores disponibles.'
                            : 'Tu equipo ya tiene 11 jugadores disponibles.',
                        color: AppColors.info,
                      ),
                      const SizedBox(height: 8),
                      _hirePositionTable(
                        dialogContext: ctx,
                        team: team,
                        positions: journeymanPositions,
                        countByType: countByType,
                        lang: lang,
                        mercenary: false,
                        canHireSubstitutes: needsSubstitutes,
                      ),
                      const SizedBox(height: 16),
                      _hireSectionHeader(
                        icon: PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                        title: 'MERCENARIOS',
                        subtitle:
                            'Cualquier posición disponible. Coste base + 30,000 GP. Se liberan tras el partido.',
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(height: 8),
                      _hirePositionTable(
                        dialogContext: ctx,
                        team: team,
                        positions: baseRoster.positions,
                        countByType: countByType,
                        lang: lang,
                        mercenary: true,
                        canHireSubstitutes: false,
                      ),
                      if (starPlayers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _hireSectionHeader(
                          icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                          title: 'STAR PLAYERS',
                          subtitle:
                              'Jugadores estrella disponibles para este equipo.',
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 8),
                        _hireStarPlayersTable(
                          dialogContext: ctx,
                          team: team,
                          activePlayers: activePlayers,
                          starPlayers: starPlayers,
                          lang: lang,
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

  Widget _hireSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hirePositionTable({
    required BuildContext dialogContext,
    required UserTeamDetail team,
    required List<BasePosition> positions,
    required Map<String, int> countByType,
    required String lang,
    required bool mercenary,
    required bool canHireSubstitutes,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.card),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
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
              rows: positions.map((pos) {
                final currentCount = countByType[pos.id] ?? 0;
                final available = currentCount < pos.maxQuantity;
                final cost = mercenary ? pos.cost + 30000 : 0;
                final canAfford = !mercenary || team.treasury >= cost;
                final canHire =
                    available && canAfford && (mercenary || canHireSubstitutes);
                final blockLabel = !available
                    ? 'MAX'
                    : !canAfford
                        ? 'NO FUNDS'
                        : !mercenary && !canHireSubstitutes
                            ? '11 OK'
                            : 'BLOCKED';
                return DataRow(
                  color: WidgetStateProperty.resolveWith((_) => canHire
                      ? null
                      : AppColors.surfaceLight.withValues(alpha: 0.1)),
                  cells: [
                    DataCell(Text(pos.name.toUpperCase(),
                        style: TextStyle(
                            color: canHire
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                    DataCell(Text('$currentCount/${pos.maxQuantity}',
                        style: _hireStatStyle(canHire))),
                    DataCell(Text('${pos.stats.ma}',
                        style: _hireStatStyle(canHire))),
                    DataCell(Text('${pos.stats.st}',
                        style: _hireStatStyle(canHire))),
                    DataCell(Text('${pos.stats.ag}+',
                        style: _hireStatStyle(canHire))),
                    DataCell(Text('${pos.stats.pa}+',
                        style: _hireStatStyle(canHire))),
                    DataCell(Text('${pos.stats.av}+',
                        style: _hireStatStyle(canHire))),
                    DataCell(Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: pos.startingPerks
                          .map((perk) => GestureDetector(
                                onTap: () => showSkillPopup(context, ref,
                                    skillName: perk.name),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: canHire
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : AppColors.surfaceLight
                                              .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(perk.name.toUpperCase(),
                                        style: TextStyle(
                                            color: canHire
                                                ? AppColors.primaryLight
                                                : AppColors.textMuted,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ))
                          .toList(),
                    )),
                    DataCell(Text(mercenary ? _fmtGold(cost) : '0',
                        style: TextStyle(
                            color:
                                canAfford ? AppColors.accent : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                    DataCell(canHire
                        ? SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _showHireNameDialog(
                                dialogContext,
                                team,
                                pos,
                                lang,
                                mercenary: mercenary,
                                cost: cost,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mercenary
                                    ? AppColors.primary
                                    : AppColors.info,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('HIRE',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        : Text(blockLabel,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hireStarPlayersTable({
    required BuildContext dialogContext,
    required UserTeamDetail team,
    required List<UserPlayer> activePlayers,
    required List<Map<String, dynamic>> starPlayers,
    required String lang,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.card),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
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
                DataColumn(label: Text('MA'), numeric: true),
                DataColumn(label: Text('ST'), numeric: true),
                DataColumn(label: Text('AG'), numeric: true),
                DataColumn(label: Text('PA'), numeric: true),
                DataColumn(label: Text('AV'), numeric: true),
                DataColumn(label: Text('SKILLS')),
                DataColumn(label: Text('COST'), numeric: true),
                DataColumn(label: Text('')),
              ],
              rows: starPlayers.map((sp) {
                final spId = sp['id'] as String? ?? '';
                final spName = sp['name'] as String? ?? '';
                final spCost = (sp['cost'] as num?)?.toInt() ?? 0;
                final spStats = sp['stats'] as Map<String, dynamic>? ?? {};
                final spSkills = (sp['skills'] as List?)?.cast<String>() ?? [];
                final canAffordStar = team.treasury >= spCost;
                final alreadyHired =
                    activePlayers.any((p) => p.baseType == 'star_$spId');
                final canHireStar =
                    canAffordStar && !alreadyHired && activePlayers.length < 16;
                final blockLabel = alreadyHired
                    ? 'HIRED'
                    : activePlayers.length >= 16
                        ? 'FULL'
                        : 'NO FUNDS';
                return DataRow(
                  color: WidgetStateProperty.resolveWith((_) => canHireStar
                      ? null
                      : AppColors.surfaceLight.withValues(alpha: 0.1)),
                  cells: [
                    DataCell(GestureDetector(
                      onTap: () => _showStarPlayerDetail(sp, lang),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                                size: 12, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(spName.toUpperCase(),
                                style: TextStyle(
                                    color: canHireStar
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        onPressed: () => _showStarPlayerDetail(sp, lang),
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        style: IconButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: Icon(PhosphorIcons.eye(PhosphorIconsStyle.fill),
                            color: AppColors.accent, size: 14),
                      ),
                    )),
                    DataCell(Text(_fmtStat(spStats['MA']),
                        style: _hireStatStyle(canHireStar))),
                    DataCell(Text(_fmtStat(spStats['ST']),
                        style: _hireStatStyle(canHireStar))),
                    DataCell(Text(_fmtStat(spStats['AG']),
                        style: _hireStatStyle(canHireStar))),
                    DataCell(Text(_fmtStat(spStats['PA']),
                        style: _hireStatStyle(canHireStar))),
                    DataCell(Text(_fmtStat(spStats['AV']),
                        style: _hireStatStyle(canHireStar))),
                    DataCell(Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: spSkills
                          .map((s) => GestureDetector(
                                onTap: () =>
                                    showSkillPopup(context, ref, skillName: s),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: canHireStar
                                          ? AppColors.accent
                                              .withValues(alpha: 0.12)
                                          : AppColors.surfaceLight
                                              .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(s.toUpperCase(),
                                        style: TextStyle(
                                            color: canHireStar
                                                ? AppColors.accent
                                                : AppColors.textMuted,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold)),
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
                            fontWeight: FontWeight.bold))),
                    DataCell(canHireStar
                        ? SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _showHireStarNameDialog(
                                  dialogContext, team, sp, lang),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('HIRE',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        : Text(blockLabel,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Hire Name Dialog (normal player)

  void _showHireNameDialog(BuildContext parentCtx, UserTeamDetail team,
      BasePosition pos, String lang,
      {required bool mercenary, required int cost}) {
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
              '${pos.name.toUpperCase()} - ${mercenary ? _fmtGold(cost) : '0'} GP',
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
                          mercenary: mercenary,
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
      required int number,
      required bool mercenary}) async {
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      await teamRepo.hirePlayer(teamId,
          baseType: baseType,
          name: name,
          number: number,
          temporaryForMatch: true,
          temporaryMatchId: widget.matchId,
          mercenary: mercenary);
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
        _updateLocalState(() {
          tempIds.add(p.id);
          selectedIds.add(p.id);
        });
        // Also persist to provider for post-match screen
        ref.read(tempHiredPlayersProvider).addPlayer(teamId, p.id);
        break;
      }
    }
  }

// ----------------------------------------------

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
            title: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.accent, size: 20),
                Text(
                  '${spName.toUpperCase()} - ${_fmtGold(spCost)} GP',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
          starPlayerId: starPlayerId,
          name: name,
          number: number,
          temporaryForMatch: true,
          temporaryMatchId: widget.matchId);
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

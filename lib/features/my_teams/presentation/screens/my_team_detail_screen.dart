// GENERATED: full rewrite to match roster management UI
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../league/domain/models/league.dart';
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';
import '../../../shared/presentation/widgets/team_hero_header.dart';
import '../../../shared/utils/player_position_labels.dart';
import '../../../shared/utils/team_special_rules.dart';
import '../../domain/models/user_team.dart';

final userTeamDetailProvider =
    FutureProvider.autoDispose.family<UserTeamDetail, String>((ref, key) async {
  final repository = ref.watch(teamRepositoryProvider);
  if (key.startsWith('share:')) {
    return repository.getUserTeamByShareCode(key.substring(6));
  }
  if (key.startsWith('league|')) {
    final payload = key.substring(7);
    final splitAt = payload.indexOf('|');
    if (splitAt <= 0 || splitAt >= payload.length - 1) {
      throw StateError('Invalid league team detail key: $key');
    }
    final leagueId = payload.substring(0, splitAt);
    final teamId = payload.substring(splitAt + 1);
    return repository.getUserTeamDetail(teamId, leagueId: leagueId);
  }
  return repository.getUserTeamDetail(key);
});

final _leagueContextProvider =
    FutureProvider.autoDispose.family<League, String>((ref, leagueId) async {
  return ref.watch(leagueRepositoryProvider).getLeague(leagueId);
});

final _baseRosterDetailProvider =
    FutureProvider.family<BaseTeam, String>((ref, rosterId) async {
  return ref.watch(teamRepositoryProvider).getBaseTeamDetail(rosterId);
});

enum _TeamRosterSortColumn {
  number,
  name,
  position,
  ma,
  st,
  ag,
  pa,
  av,
  skills,
  spp,
  status,
  cost,
}

class MyTeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String? shareCode;

  /// When set, this screen is in league context (back → league, owner-gated edits)
  final String? leagueId;
  const MyTeamDetailScreen(
      {super.key, required this.teamId, this.leagueId, this.shareCode});
  @override
  ConsumerState<MyTeamDetailScreen> createState() => _MyTeamDetailScreenState();
}

class _MyTeamDetailScreenState extends ConsumerState<MyTeamDetailScreen> {
  static final _goldFmt = NumberFormat('#,###');
  static const double _columnResizeHandleWidth = 12;
  static const double _defaultNameColumnWidth = 190;
  static const double _defaultPositionColumnWidth = 132;
  static const double _minNameColumnWidth = 150;
  static const double _maxNameColumnWidth = 320;
  static const double _minPositionColumnWidth = 96;
  static const double _maxPositionColumnWidth = 240;
  String _fmtGold(int amount) => _goldFmt.format(amount);

  final _searchController = TextEditingController();
  final _teamNotesController = TextEditingController();
  String _searchQuery = '';
  String _loadedNotes = '';
  bool _showActive = true;
  bool _showInjured = true;
  bool _showDead = false;
  bool _notesDirty = false;
  bool _isMutating = false;
  _TeamRosterSortColumn _rosterSortColumn = _TeamRosterSortColumn.number;
  bool _rosterSortAscending = true;
  double _nameColumnWidth = _defaultNameColumnWidth;
  double _positionColumnWidth = _defaultPositionColumnWidth;

  String get _detailKey => widget.shareCode == null
      ? (widget.leagueId == null
          ? widget.teamId
          : 'league|${widget.leagueId}|${widget.teamId}')
      : 'share:${widget.shareCode!.trim()}';

  @override
  void dispose() {
    _searchController.dispose();
    _teamNotesController.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(userTeamDetailProvider(_detailKey));

  Future<bool> _patch({
    String? name,
    int? rerolls,
    int? fanFactor,
    int? dedicatedFans,
    int? cheerleaders,
    int? assistantCoaches,
    bool? apothecary,
    String? notes,
    String? favouredOf,
  }) async {
    if (_isMutating) return false;
    setState(() => _isMutating = true);
    try {
      final isCommissioner = widget.leagueId != null &&
          (ref
                  .read(_leagueContextProvider(widget.leagueId!))
                  .valueOrNull
                  ?.isCommissioner ??
              false);
      await ref.read(teamRepositoryProvider).patchTeamStaff(
            widget.teamId,
            name: name,
            rerolls: rerolls,
            fanFactor: fanFactor,
            dedicatedFans: dedicatedFans,
            cheerleaders: cheerleaders,
            assistantCoaches: assistantCoaches,
            apothecary: apothecary,
            notes: notes,
            favouredOf: favouredOf,
            leagueId: widget.leagueId,
            commissionerEdit: isCommissioner,
          );
      ref.invalidate(userTeamDetailProvider(_detailKey));
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _syncTeamNotes(String notes) {
    if (_notesDirty) return;
    if (_loadedNotes == notes && _teamNotesController.text == notes) return;
    _loadedNotes = notes;
    _teamNotesController.value = TextEditingValue(
      text: notes,
      selection: TextSelection.collapsed(offset: notes.length),
    );
  }

  Future<void> _saveTeamNotes(UserTeamDetail team, String lang) async {
    final nextNotes = _teamNotesController.text;
    if (!_notesDirty || nextNotes == team.notes) {
      if (_notesDirty && mounted) {
        setState(() => _notesDirty = false);
      }
      return;
    }

    final saved = await _patch(notes: nextNotes);
    if (!saved || !mounted) return;

    setState(() {
      _loadedNotes = nextNotes;
      _notesDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(lang, 'team.notesSaved')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _firePlayer(UserTeamDetail team, UserPlayer player) async {
    final lang = ref.watch(localeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'team.firePlayer'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(trf(lang, 'team.fireConfirm', {'name': player.name}),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(lang, 'common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(tr(lang, 'team.fire')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(teamRepositoryProvider)
          .fireUserPlayer(widget.teamId, player.id, leagueId: widget.leagueId);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final teamAsync = ref.watch(userTeamDetailProvider(_detailKey));
    final isWide = MediaQuery.of(context).size.width >= 800;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    final league = widget.leagueId == null
        ? null
        : ref.watch(_leagueContextProvider(widget.leagueId!)).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err, lang),
        data: (team) {
          _syncTeamNotes(team.notes);
          final isOwner = currentUserId != null &&
              (team.userId == currentUserId || league?.isCommissioner == true);
          final canManageRoster = isOwner &&
              (team.canManageRoster || league?.isCommissioner == true);
          final canHirePlayers = isOwner;
          return Column(children: [
            _buildTopBar(team, isWide, isOwner, canManageRoster, lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamHeader(team, isWide, lang),
                    const SizedBox(height: 12),
                    _buildShareCodeSection(team, lang),
                    const SizedBox(height: 12),
                    _buildTeamOverviewSection(team, isWide, lang),
                    if (isOwner) ...[
                      const SizedBox(height: 20),
                      _buildNotesSection(team, isOwner, lang),
                    ],
                    const SizedBox(height: 20),
                    _buildPlayerSection(
                        team, isWide, isOwner, canHirePlayers, lang),
                    const SizedBox(height: 20),
                    _buildPurchasesSection(
                        team, isWide, isOwner, canHirePlayers, lang),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildShareCodeSection(UserTeamDetail team, String lang) {
    final code = team.shareCode.isNotEmpty ? team.shareCode : team.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
              size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(
            'Codigo para compartir',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          SelectableText(
            code,
            style: const TextStyle(
              color: AppColors.accent,
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: tr(lang, 'createLeague.copyCode'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr(lang, 'createLeague.codeCopied'))),
              );
            },
            icon: Icon(PhosphorIcons.copy(PhosphorIconsStyle.regular),
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Error ──

  Widget _buildError(Object err, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(tr(lang, 'team.errorLoading'),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$err',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold)),
            label: Text(tr(lang, 'common.retry')),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──

  Widget _buildTopBar(UserTeamDetail team, bool isWide, bool isOwner,
      bool canManageRoster, String lang) {
    final isLeague = widget.leagueId != null;
    final textTheme = context.textTheme;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    color: AppColors.textSecondary),
                onPressed: () => isLeague
                    ? context.go('/league/${widget.leagueId}')
                    : context.go('/teams'),
                tooltip: isLeague
                    ? tr(lang, 'team.backToLeague')
                    : tr(lang, 'team.backToTeams'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        isLeague
                            ? tr(lang, 'nav.leagueView')
                            : tr(lang, 'nav.myTeams'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                      Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                          size: 12, color: AppColors.textMuted),
                      Text(
                        isLeague
                            ? tr(lang, 'nav.roster')
                            : tr(lang, 'team.rosterManagement'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ]),
                    Text(
                      team.name,
                      style: (isWide
                              ? textTheme.titleMedium
                              : textTheme.bodyMedium)
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isMutating)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(
                icon: Icon(
                    PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                    size: 18),
                onPressed: _refresh,
                color: AppColors.textMuted,
                tooltip: tr(lang, 'team.refresh'),
              ),
              IconButton(
                icon: Icon(
                    PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.bold),
                    size: 18),
                onPressed: () {},
                color: AppColors.textMuted,
                tooltip: 'Exportar plantilla',
              ),
              if (canManageRoster)
                IconButton(
                  icon: Icon(
                      PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
                      size: 18),
                  onPressed: () => _showEditTeamNameDialog(team),
                  color: AppColors.textMuted,
                  tooltip: tr(lang, 'team.editTeamName'),
                ),
              if (isOwner && team.canChooseFavoured)
                IconButton(
                  icon: Icon(PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                      size: 18),
                  onPressed: () => _showEditFavouredDialog(team),
                  color: AppColors.textMuted,
                  tooltip: 'Editar Favorito de',
                ),
              if (isOwner)
                IconButton(
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold),
                      size: 18),
                  onPressed: team.leagueMemberships.isEmpty && !_isMutating
                      ? () => _confirmDeleteTeam(team)
                      : null,
                  color: AppColors.error,
                  tooltip: team.leagueMemberships.isEmpty
                      ? tr(lang, 'team.deleteTeam')
                      : tr(lang, 'team.deleteBlockedByLeague'),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Team header ──

  Widget _buildTeamHeader(UserTeamDetail team, bool isWide, String lang) {
    final rosterPlayers =
        team.players.where((player) => !player.temporaryForMatch).toList();
    final activeCount =
        rosterPlayers.where((p) => p.status == 'healthy').length;
    final isValid = activeCount >= 11;
    final baseRoster =
        ref.watch(_baseRosterDetailProvider(team.baseRosterId)).valueOrNull;
    final statusChip = _rosterStatusChip(isValid, lang);

    final header = TeamHeroHeader(
      rosterId: team.baseRosterId,
      rosterName: baseRoster?.name ?? team.raceLabel,
      teamName: team.name,
      tier: baseRoster?.tier,
      rerollCost: baseRoster?.rerollCost ?? team.rerollCost,
      teamNameFontFamily: 'RugbySquadOutline',
      teamNameColor: AppColors.primary,
      teamNameFontWeight: FontWeight.normal,
      teamNameFontSize: 92,
      teamNameCompactFontSize: 68,
      teamNameGradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFDB927),
          //Color.fromARGB(255, 255, 255, 255),
          Color(0xFF552583),
        ],
        stops: [0.1, 0.4],
      ),
      trailing: isWide ? statusChip : null,
    );

    if (isWide) return header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        statusChip,
      ],
    );
  }

  Widget _rosterStatusChip(bool isValid, String lang) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isValid
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr(lang, 'team.status'),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: isValid ? AppColors.success : AppColors.warning,
                  shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            isValid
                ? tr(lang, 'team.validRoster')
                : tr(lang, 'team.invalidRoster'),
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isValid ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueChip(TeamLeagueMembership league) {
    final isActive = league.status == 'active';
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? PhosphorIcons.lightning(PhosphorIconsStyle.fill)
                : PhosphorIcons.flag(PhosphorIconsStyle.regular),
            size: 13,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${league.name} · ${league.statusLabel}',
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOverviewSection(
      UserTeamDetail team, bool isWide, String lang) {
    final baseRoster =
        ref.watch(_baseRosterDetailProvider(team.baseRosterId)).valueOrNull;
    final activeLeagues =
        team.leagueMemberships.where((league) => league.status == 'active');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewMetrics(team),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _overviewSectionLabel(
                PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                'LIGA ACTIVA',
                AppColors.primary,
              ),
              if (activeLeagues.isEmpty)
                _softChip('Sin liga activa', AppColors.textMuted)
              else
                ...activeLeagues.map(_buildLeagueChip),
              const SizedBox(width: 8),
              _overviewSectionLabel(
                PhosphorIcons.scroll(PhosphorIconsStyle.fill),
                'REGLAS ESPECIALES',
                AppColors.accent,
              ),
              if (team.specialRules.isEmpty &&
                  (baseRoster == null || baseRoster.specialRules.isEmpty))
                _softChip('Sin reglas especiales', AppColors.textMuted)
              else
                ...(team.specialRules.isNotEmpty
                        ? team.specialRules
                        : baseRoster!.specialRules)
                    .map((rule) => _softChip(
                          rule,
                          AppColors.accent,
                          onTap: () => showTeamSpecialRuleDialog(
                            context,
                            rule: rule,
                            lang: lang,
                          ),
                        )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics(UserTeamDetail team) {
    final lang = ref.watch(localeProvider);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      final width = compact
          ? (constraints.maxWidth - 10) / 2
          : (constraints.maxWidth - 30) / 4;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _overviewMetricCard(
            label: tr(lang, 'team.teamValueShort'),
            value: _fmtGold(team.teamValue),
            info: tr(lang, 'team.teamValueTooltip'),
            icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
            color: AppColors.primary,
            width: width,
          ),
          _overviewMetricCard(
            label: tr(lang, 'team.currentTeamValueShort'),
            value: _fmtGold(team.currentTeamValue),
            info: tr(lang, 'team.currentTeamValueTooltip'),
            icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
            color: AppColors.success,
            width: width,
          ),
          _overviewMetricCard(
            label: 'TESORERÍA',
            value: _fmtGold(team.treasury),
            icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
            color: AppColors.accent,
            width: width,
          ),
          _overviewMetricCard(
            label: 'HINCHAS',
            value: '${team.dedicatedFans}',
            icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
            color: AppColors.warning,
            width: width,
          ),
        ],
      );
    });
  }

  Widget _buildNotesSection(UserTeamDetail team, bool isOwner, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.notePencil(PhosphorIconsStyle.fill),
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                tr(lang, 'team.notesTitle'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (!isOwner)
                Text(
                  tr(lang, 'team.notesReadOnly'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'team.notesHint'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _teamNotesController,
            readOnly: !isOwner,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: tr(lang, 'team.notesPlaceholder'),
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: isOwner
                ? (value) {
                    final dirty = value != _loadedNotes;
                    if (dirty != _notesDirty) {
                      setState(() => _notesDirty = dirty);
                    }
                  }
                : null,
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _notesDirty
                        ? tr(lang, 'team.notesUnsaved')
                        : tr(lang, 'team.notesSavedState'),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          _notesDirty ? AppColors.warning : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _notesDirty && !_isMutating
                      ? () => _saveTeamNotes(team, lang)
                      : null,
                  icon: Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill),
                      size: 16),
                  label: Text(tr(lang, 'common.save')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _overviewMetricCard({
    required String label,
    required String value,
    String? info,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.9)),
            ),
            if (info != null)
              Tooltip(
                message: info,
                child: Icon(PhosphorIcons.info(PhosphorIconsStyle.regular),
                    size: 14, color: AppColors.textMuted),
              ),
          ]),
          const SizedBox(height: 9),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1)),
        ],
      ),
    );
  }

  Widget _overviewSectionLabel(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.8)),
    ]);
  }

  Widget _softChip(String label, Color color, {VoidCallback? onTap}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color == AppColors.textMuted
                  ? AppColors.textSecondary
                  : color)),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: chip,
      ),
    );
  }

  int _rerollPurchaseCost(UserTeamDetail team) {
    final isLeagueTeam = team.leagueMemberships.isNotEmpty;
    return team.rerollCost * (isLeagueTeam ? 2 : 1);
  }

  // ── Player section ──

  Widget _buildPlayerSection(
    UserTeamDetail team,
    bool isWide,
    bool isOwner,
    bool canHirePlayers,
    String lang,
  ) {
    final baseRoster =
        ref.watch(_baseRosterDetailProvider(team.baseRosterId)).valueOrNull;
    final rosterPlayers =
        team.players.where((player) => !player.temporaryForMatch).toList();
    final filtered = _sortRosterPlayers(
      _filterPlayers(rosterPlayers, baseRoster, lang),
      baseRoster,
      lang,
    );
    final totalActive = rosterPlayers.where((p) => !p.isDead).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerToolbar(
          totalActive: totalActive,
          isWide: isWide,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = math.max(
              constraints.maxWidth,
              _minimumRosterTableWidth(isWide),
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    _buildTableHeader(isWide, lang),
                    const Divider(height: 1),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(children: [
                            Icon(
                              PhosphorIcons.usersThree(
                                  PhosphorIconsStyle.light),
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 8),
                            const Text('Sin jugadores que mostrar',
                                style: TextStyle(color: AppColors.textMuted)),
                          ]),
                        ),
                      )
                    else
                      ...filtered.map((p) => _buildPlayerRow(
                          p, team, isWide, isOwner, baseRoster)),
                  ],
                ),
              ),
            );
          },
        ),
        if (rosterPlayers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                  '1 - ${filtered.length} de ${rosterPlayers.length} jugadores',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
          ),
      ],
    );
  }

  Widget _filterPill(
      String label, bool selected, ValueChanged<bool> onChanged) {
    return SizedBox(
      width: 108,
      height: 34,
      child: FilterChip(
        label: Center(child: Text(label, maxLines: 1)),
        selected: selected,
        onSelected: onChanged,
        labelStyle: TextStyle(
            fontSize: 11,
            color: selected ? AppColors.textPrimary : AppColors.textMuted),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        checkmarkColor: AppColors.primary,
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPlayerToolbar({
    required int totalActive,
    required bool isWide,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 220 : 130,
                child: Row(children: [
                  Icon(PhosphorIcons.listBullets(PhosphorIconsStyle.bold),
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('PLANTILLA',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.8)),
                  ),
                ]),
              ),
              _playerCountChip(totalActive),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isWide ? 260 : 220,
                  maxWidth: isWide ? 320 : 360,
                ),
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador...',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass(
                              PhosphorIconsStyle.regular),
                          size: 16,
                          color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              _filterPill('Activos', _showActive,
                  (v) => setState(() => _showActive = v)),
              _filterPill('Lesionados', _showInjured,
                  (v) => setState(() => _showInjured = v)),
              _filterPill(
                  'Muertos', _showDead, (v) => setState(() => _showDead = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerCountChip(int totalActive) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Text('Jugadores: $totalActive/16',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary)),
    );
  }

  Widget _buildPurchasesSection(
    UserTeamDetail team,
    bool isWide,
    bool isOwner,
    bool canHirePlayers,
    String lang,
  ) {
    final rerollCost = _rerollPurchaseCost(team);
    final activeCount = team.players
        .where((p) => !p.temporaryForMatch && p.status == 'healthy')
        .length;
    final isValidRoster = activeCount >= 11;

    final cards = <Widget>[
      _purchaseTile(
        icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
        label: 'REROLLS',
        subtitle: '${rerollCost ~/ 1000}k c/u',
        count: team.rerolls,
        onDec: isOwner && team.rerolls > 0 && !_isMutating
            ? () => _patch(rerolls: team.rerolls - 1)
            : null,
        onInc: isOwner && team.treasury >= rerollCost && !_isMutating
            ? () => _patch(rerolls: team.rerolls + 1)
            : null,
      ),
      _apothecaryPurchaseTile(team, isOwner, lang),
      _purchaseTile(
        icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
        label: 'ANIMADORAS',
        subtitle: '10k c/u (máx. 6)',
        count: team.cheerleaders,
        onDec: isOwner && team.cheerleaders > 0 && !_isMutating
            ? () => _patch(cheerleaders: team.cheerleaders - 1)
            : null,
        onInc: isOwner &&
                team.treasury >= 10000 &&
                team.cheerleaders < 6 &&
                !_isMutating
            ? () => _patch(cheerleaders: team.cheerleaders + 1)
            : null,
      ),
      _purchaseTile(
        icon: PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill),
        label: 'ASISTENTES',
        subtitle: '10k c/u (máx. 6)',
        count: team.assistantCoaches,
        onDec: isOwner && team.assistantCoaches > 0 && !_isMutating
            ? () => _patch(assistantCoaches: team.assistantCoaches - 1)
            : null,
        onInc: isOwner &&
                team.treasury >= 10000 &&
                team.assistantCoaches < 6 &&
                !_isMutating
            ? () => _patch(assistantCoaches: team.assistantCoaches + 1)
            : null,
      ),
      _hirePlayersTile(isOwner, canHirePlayers, lang),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
                size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('COMPRAS Y CONTRATACIONES',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1)),
            const Spacer(),
            Icon(
              isValidRoster
                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                  : PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 16,
              color: isValidRoster ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 6),
            Text('$activeCount jugadores activos',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final perRow = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (12 * (perRow - 1))) / perRow;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _purchaseTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required int count,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    final textTheme = context.textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _purchaseCircleButton(
                  icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                  onTap: onDec),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$count',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        count > 0 ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              _purchaseCircleButton(
                  icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  onTap: onInc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _apothecaryPurchaseTile(
      UserTeamDetail team, bool isOwner, String lang) {
    final canToggle = team.apothecary
        ? isOwner && !_isMutating
        : isOwner &&
            team.apothecaryAllowed &&
            team.treasury >= 50000 &&
            !_isMutating;
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: team.apothecary
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
            color:
                team.apothecaryAllowed ? AppColors.accent : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 6),
          const Text('APOTECARIO',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          Text(team.apothecaryAllowed ? '50k (Max 1)' : 'No disponible',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Switch(
            value: team.apothecary && team.apothecaryAllowed,
            onChanged: canToggle ? (value) => _patch(apothecary: value) : null,
            activeColor: AppColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _hirePlayersTile(bool isOwner, bool canHirePlayers, String lang) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
              color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          const Text('JUGADORES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          const Text('Contratación permanente',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isOwner && canHirePlayers
                ? () => _showHireDialog(context)
                : null,
            icon:
                Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold), size: 14),
            label: Text(tr(lang, 'team.hirePlayer'),
                style: const TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchaseCircleButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.textMuted.withValues(alpha: 0.7)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textMuted.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  List<UserPlayer> _filterPlayers(
      List<UserPlayer> all, BaseTeam? baseRoster, String lang) {
    return all.where((p) {
      if (p.isDead && !_showDead) return false;
      if (!p.isDead && p.status != 'healthy' && !_showInjured) return false;
      if (!p.isDead && p.status == 'healthy' && !_showActive) return false;
      if (_searchQuery.isNotEmpty) {
        final positionLabel =
            localizedPlayerPosition(p, roster: baseRoster, lang: lang);
        if (!p.name.toLowerCase().contains(_searchQuery) &&
            !positionLabel.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<UserPlayer> _sortRosterPlayers(
    List<UserPlayer> players,
    BaseTeam? baseRoster,
    String lang,
  ) {
    final sorted = List<UserPlayer>.from(players);
    sorted.sort((a, b) {
      int result;
      switch (_rosterSortColumn) {
        case _TeamRosterSortColumn.number:
          result = a.number.compareTo(b.number);
        case _TeamRosterSortColumn.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _TeamRosterSortColumn.position:
          result = localizedPlayerPosition(a, roster: baseRoster, lang: lang)
              .toLowerCase()
              .compareTo(
                  localizedPlayerPosition(b, roster: baseRoster, lang: lang)
                      .toLowerCase());
        case _TeamRosterSortColumn.ma:
          result = a.stats.ma.compareTo(b.stats.ma);
        case _TeamRosterSortColumn.st:
          result = a.stats.st.compareTo(b.stats.st);
        case _TeamRosterSortColumn.ag:
          result =
              _rollStatValue(a.stats.ag).compareTo(_rollStatValue(b.stats.ag));
        case _TeamRosterSortColumn.pa:
          result = _rollStatValue(a.stats.pa ?? '-')
              .compareTo(_rollStatValue(b.stats.pa ?? '-'));
        case _TeamRosterSortColumn.av:
          result =
              _rollStatValue(a.stats.av).compareTo(_rollStatValue(b.stats.av));
        case _TeamRosterSortColumn.skills:
          result = a.perks.length.compareTo(b.perks.length);
        case _TeamRosterSortColumn.spp:
          result = a.spp.compareTo(b.spp);
        case _TeamRosterSortColumn.status:
          result = a.status.compareTo(b.status);
        case _TeamRosterSortColumn.cost:
          result = a.currentValue.compareTo(b.currentValue);
      }
      if (result == 0) result = a.number.compareTo(b.number);
      return _rosterSortAscending ? result : -result;
    });
    return sorted;
  }

  int _rollStatValue(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? 99 : int.parse(match.group(0)!);
  }

  void _setRosterSort(_TeamRosterSortColumn column) {
    setState(() {
      if (_rosterSortColumn == column) {
        _rosterSortAscending = !_rosterSortAscending;
      } else {
        _rosterSortColumn = column;
        _rosterSortAscending = true;
      }
    });
  }

  double _minimumRosterTableWidth(bool isWide) {
    const fixedStatsWidth = 38.0 * 5;
    const skillsMinWidth = 220.0;
    const sppWidth = 44.0;
    const statusWidth = 80.0;
    const costWidth = 60.0;
    const actionsWidth = 40.0;
    const gapBeforeSkills = 10.0;
    const numberWidth = 52.0;

    return numberWidth +
        _nameColumnWidth +
        _columnResizeHandleWidth +
        (isWide
            ? _positionColumnWidth + _columnResizeHandleWidth + costWidth
            : 0) +
        fixedStatsWidth +
        gapBeforeSkills +
        skillsMinWidth +
        sppWidth +
        statusWidth +
        actionsWidth;
  }

  void _resizeNameColumn(double delta) {
    setState(() {
      _nameColumnWidth = (_nameColumnWidth + delta)
          .clamp(_minNameColumnWidth, _maxNameColumnWidth);
    });
  }

  void _resizePositionColumn(double delta) {
    setState(() {
      _positionColumnWidth = (_positionColumnWidth + delta)
          .clamp(_minPositionColumnWidth, _maxPositionColumnWidth);
    });
  }

  Widget _columnResizeHandle(ValueChanged<double> onDelta) {
    return SizedBox(
      width: _columnResizeHandleWidth,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) => onDelta(details.delta.dx),
          child: Center(
            child: Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(bool isWide, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 52,
              child: Center(child: _th('#', _TeamRosterSortColumn.number))),
          SizedBox(
              width: _nameColumnWidth,
              child: _th('NOMBRE', _TeamRosterSortColumn.name)),
          _columnResizeHandle(_resizeNameColumn),
          if (isWide)
            SizedBox(
              width: _positionColumnWidth,
              child: _th('POSICIÓN', _TeamRosterSortColumn.position),
            ),
          if (isWide) _columnResizeHandle(_resizePositionColumn),
          _attributeHeader(
              'MA', _attributeTooltip('MA', lang), _TeamRosterSortColumn.ma),
          _attributeHeader(
              'ST', _attributeTooltip('ST', lang), _TeamRosterSortColumn.st),
          _attributeHeader(
              'AG', _attributeTooltip('AG', lang), _TeamRosterSortColumn.ag),
          _attributeHeader(
              'PA', _attributeTooltip('PA', lang), _TeamRosterSortColumn.pa),
          _attributeHeader(
              'AV', _attributeTooltip('AV', lang), _TeamRosterSortColumn.av),
          const SizedBox(width: 10),
          Expanded(
              flex: 3,
              child:
                  _th(tr(lang, 'player.skills'), _TeamRosterSortColumn.skills)),
          SizedBox(
              width: 44,
              child: Center(child: _th('SPP', _TeamRosterSortColumn.spp))),
          SizedBox(
              width: 80,
              child:
                  Center(child: _th('ESTADO', _TeamRosterSortColumn.status))),
          if (isWide)
            SizedBox(
                width: 60,
                child: Center(child: _th('COSTE', _TeamRosterSortColumn.cost))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _th(String t, _TeamRosterSortColumn column) {
    final active = _rosterSortColumn == column;
    return InkWell(
      onTap: () => _setRosterSort(column),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(t,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: active ? AppColors.accent : AppColors.textMuted,
                    letterSpacing: 0)),
          ),
          if (active) ...[
            const SizedBox(width: 3),
            Icon(
              _rosterSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: AppColors.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _attributeHeader(
          String label, String tooltip, _TeamRosterSortColumn column) =>
      SizedBox(
        width: 38,
        child: Tooltip(
          message: tooltip,
          child: Center(child: _th(label, column)),
        ),
      );

  String _attributeTooltip(String label, String lang) {
    final es = lang == 'es';
    switch (label) {
      case 'MA':
        return es ? 'Movimiento' : 'Movement Allowance';
      case 'ST':
        return es ? 'Fuerza' : 'Strength';
      case 'AG':
        return es ? 'Agilidad' : 'Agility';
      case 'PA':
        return es ? 'Capacidad de Pase' : 'Passing Ability';
      case 'AV':
        return es ? 'Valor de Armadura' : 'Armour Value';
      default:
        return label;
    }
  }

  Set<String>? _startingPerkKeys(BaseTeam? roster, UserPlayer player) {
    final position = findBasePositionForPlayer(roster, player);

    if (position == null) return null;

    final keys = <String>{};
    for (final perk in position.startingPerks) {
      keys.add(_perkKey(perk.id));
      keys.add(_perkKey(perk.name));
    }
    keys.remove('');
    return keys;
  }

  String _perkKey(String value) {
    final normalized = value
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[_\s]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]+'), '');
    return normalized.startsWith('perk-')
        ? normalized.substring('perk-'.length)
        : normalized;
  }

  bool? _isAcquiredPerk(UserPlayerPerk perk, Set<String>? startingPerkKeys) {
    if (startingPerkKeys == null) return null;
    return !startingPerkKeys.contains(_perkKey(perk.id)) &&
        !startingPerkKeys.contains(_perkKey(perk.name));
  }

  Widget _buildPlayerRow(
    UserPlayer player,
    UserTeamDetail team,
    bool isWide,
    bool isOwner,
    BaseTeam? baseRoster,
  ) {
    final lang = ref.watch(localeProvider);
    final isDead = player.isDead;
    final canLevelUp = _canLevelUp(player);
    final startingPerkKeys = _startingPerkKeys(baseRoster, player);
    final positionLabel =
        localizedPlayerPosition(player, roster: baseRoster, lang: lang);
    const maxSkillPills = 4;
    final hasHiddenSkills = player.perks.length > maxSkillPills;
    final visiblePerks = hasHiddenSkills
        ? player.perks.take(maxSkillPills - 1).toList()
        : player.perks.take(maxSkillPills).toList();
    final hiddenSkillCount = player.perks.length - visiblePerks.length;
    return InkWell(
      onTap: () {
        final tid = team.id;
        final lid = widget.leagueId;
        if (lid != null) {
          context.go('/league/$lid/team/$tid/player/${player.id}');
        } else {
          context.go('/teams/$tid/player/${player.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: AppColors.surfaceLight),
            left: BorderSide(
              color: isDead
                  ? AppColors.dead.withValues(alpha: 0.5)
                  : player.status != 'healthy'
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Jersey number (American football style)
            SizedBox(
              width: 52,
              child: Center(
                child: _buildJerseyNumber(player),
              ),
            ),
            // Name
            SizedBox(
              width: _nameColumnWidth,
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDead ? AppColors.textMuted : AppColors.textPrimary,
                  decoration: isDead ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: _columnResizeHandleWidth),
            // Position
            if (isWide)
              SizedBox(
                width: _positionColumnWidth,
                child: Text(positionLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            if (isWide) const SizedBox(width: _columnResizeHandleWidth),
            // Stats
            _statCell('${player.stats.ma}',
                color: userPlayerStatColor(
                    player, baseRoster, 'MA', '${player.stats.ma}')),
            _statCell('${player.stats.st}',
                color: userPlayerStatColor(
                    player, baseRoster, 'ST', '${player.stats.st}')),
            _statCell(player.stats.ag,
                color: userPlayerStatColor(
                    player, baseRoster, 'AG', player.stats.ag)),
            _statCell(player.stats.pa ?? '-',
                color: userPlayerStatColor(
                    player, baseRoster, 'PA', player.stats.pa ?? '-')),
            _statCell(player.stats.av,
                color: userPlayerStatColor(
                    player, baseRoster, 'AV', player.stats.av)),
            const SizedBox(width: 10),
            // Skills
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...visiblePerks.map((perk) => _skillBadge(perk,
                      isAcquired: _isAcquiredPerk(perk, startingPerkKeys))),
                  if (hasHiddenSkills) _moreSkillsBadge(hiddenSkillCount, lang),
                ],
              ),
            ),
            // SPP
            SizedBox(
              width: 44,
              child: Center(
                child: Text('${player.spp}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: canLevelUp
                          ? AppColors.success
                          : AppColors.textPrimary,
                    )),
              ),
            ),
            // Status
            SizedBox(
              width: 80,
              child: Center(
                  child: canLevelUp && !isDead
                      ? _levelUpBadge()
                      : _statusBadge(player)),
            ),
            // Cost
            if (isWide)
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(_fmtGold(player.currentValue),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                ),
              ),
            // Actions
            SizedBox(
              width: 40,
              child: Center(
                child: isOwner
                    ? PopupMenuButton<String>(
                        icon: Icon(
                            PhosphorIcons.dotsThreeVertical(
                                PhosphorIconsStyle.bold),
                            size: 16,
                            color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: AppColors.surface,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditPlayerDialog(context, player);
                          } else if (value == 'fire') {
                            _firePlayer(team, player);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(
                                  PhosphorIcons.pencilSimple(
                                      PhosphorIconsStyle.regular),
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Text('Editar',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'fire',
                            child: Row(children: [
                              Icon(
                                  PhosphorIcons.userMinus(
                                      PhosphorIconsStyle.regular),
                                  size: 16,
                                  color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(tr(lang, 'team.fire'),
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13)),
                            ]),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJerseyNumber(UserPlayer player) {
    final isDead = player.isDead;
    final isInjured = !isDead && player.status != 'healthy';
    final borderColor = isDead
        ? AppColors.dead.withValues(alpha: 0.5)
        : isInjured
            ? AppColors.warning.withValues(alpha: 0.6)
            : AppColors.primary.withValues(alpha: 0.4);
    final textColor = isDead
        ? AppColors.textMuted
        : isInjured
            ? AppColors.warning
            : AppColors.textPrimary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDead
                ? AppColors.surfaceLight.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${player.number}',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ),
        if (isDead)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.card, shape: BoxShape.circle),
              child: Icon(PhosphorIcons.skull(PhosphorIconsStyle.fill),
                  size: 10, color: AppColors.dead),
            ),
          )
        else if (isInjured)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.card, shape: BoxShape.circle),
              child: Icon(PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
                  size: 10, color: AppColors.warning),
            ),
          ),
      ],
    );
  }

  Widget _statCell(String value, {Color color = AppColors.textPrimary}) {
    return SizedBox(
      width: 38,
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _skillBadge(UserPlayerPerk perk, {bool? isAcquired}) {
    final lang = ref.watch(localeProvider);
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? [];
    final displayName = localizedPerkName(allPerks, perk.name, lang);
    final acquiredLabel = tr(lang, 'player.acquired').toLowerCase();
    final color = isAcquired == true ? AppColors.accent : AppColors.primary;
    final backgroundOpacity = isAcquired == true ? 0.2 : 0.15;
    final borderOpacity = isAcquired == true ? 0.65 : 0.4;

    return GestureDetector(
      onTap: () => showSkillPopup(context, ref,
          skillName: perk.name, family: perk.category),
      child: Tooltip(
        message:
            isAcquired == true ? '$displayName ($acquiredLabel)' : displayName,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 86),
            child: Container(
              padding: EdgeInsets.only(
                left: isAcquired == true ? 5 : 7,
                right: 7,
                top: 3,
                bottom: 3,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: backgroundOpacity),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: color.withValues(alpha: borderOpacity)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAcquired == true) ...[
                    Icon(
                      PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                      size: 10,
                      color: AppColors.accentLight,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: isAcquired == true
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moreSkillsBadge(int hiddenCount, String lang) {
    final message = lang == 'es'
        ? 'Hay $hiddenCount habilidades mas. Consultalas en la vista del jugador.'
        : '$hiddenCount more skills. Open the player view to see them.';

    return Tooltip(
      message: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.textMuted.withValues(alpha: 0.35)),
        ),
        child: const Text(
          '...',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(UserPlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: player.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(player.statusLabel,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: player.statusColor)),
    );
  }

  Widget _levelUpBadge() {
    return Tooltip(
      message: 'Subir nivel',
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.arrowFatUp(PhosphorIconsStyle.fill),
                size: 10, color: AppColors.warning),
            const SizedBox(width: 3),
            const Flexible(
              child: Text('SUBIR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning)),
            ),
          ],
        ),
      ),
    );
  }

  bool _canLevelUp(UserPlayer p) {
    const nextCosts = {1: 3, 2: 4, 3: 6, 4: 8, 5: 10, 6: 15};
    final next = nextCosts[p.level] ?? 0;
    return next > 0 && p.spp >= next;
  }

  void _showHireDialog(BuildContext context) {
    final teamAsync = ref.read(userTeamDetailProvider(_detailKey));
    final team = teamAsync.valueOrNull;
    final currentUserId = ref.read(authStateProvider).valueOrNull?.user?.id;
    final league = widget.leagueId == null
        ? null
        : ref.read(_leagueContextProvider(widget.leagueId!)).valueOrNull;
    final canManage = currentUserId != null &&
        team != null &&
        (team.userId == currentUserId || league?.isCommissioner == true);
    if (!canManage) {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _HirePlayerDialog(
        teamId: team.id,
        baseRosterId: team.baseRosterId,
        currentPlayers:
            team.players.where((player) => !player.temporaryForMatch).toList(),
        treasury: team.treasury,
        leagueId: widget.leagueId,
        onHired: () {
          _refresh();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _showEditTeamNameDialog(UserTeamDetail team) async {
    final league = widget.leagueId == null
        ? null
        : ref.read(_leagueContextProvider(widget.leagueId!)).valueOrNull;
    if (!team.canManageRoster && league?.isCommissioner != true) return;
    final lang = ref.watch(localeProvider);
    final controller = TextEditingController(text: team.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'team.editTeamName'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 50,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: tr(lang, 'team.teamName'),
              labelStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? tr(lang, 'team.teamNameRequired')
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(tr(lang, 'common.save')),
          ),
        ],
      ),
    );

    final newName = controller.text.trim();
    if (confirmed != true || newName == team.name) return;

    final saved = await _patch(name: newName);
    if (!saved || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(tr(lang, 'team.teamNameUpdated')),
          backgroundColor: AppColors.success),
    );
  }

  Future<void> _showEditFavouredDialog(UserTeamDetail team) async {
    if (!team.canChooseFavoured) return;
    var selected = team.favouredOf;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Editar Favorito de',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: chaosFavouredLabels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setDialogState(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed:
                  selected == null ? null : () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected == null || selected == team.favouredOf) {
      return;
    }

    final saved = await _patch(favouredOf: selected);
    if (!saved || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Regla Favoured of actualizada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _confirmDeleteTeam(UserTeamDetail team) async {
    if (_isMutating) return;
    final lang = ref.watch(localeProvider);

    if (team.leagueMemberships.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'team.deleteBlockedByLeague')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'team.deleteTeam'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          trf(lang, 'team.deleteConfirm', {'name': team.name}),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), size: 16),
            label: Text(tr(lang, 'common.delete')),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isMutating = true);
    try {
      await ref.read(teamRepositoryProvider).deleteUserTeam(team.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'team.deleteDone')),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/teams');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _showEditPlayerDialog(
      BuildContext context, UserPlayer player) async {
    final lang = ref.watch(localeProvider);
    final nameController = TextEditingController(text: player.name);
    final numberController =
        TextEditingController(text: player.number.toString());
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '#${player.number}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr(lang, 'team.editPlayer'),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 18)),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(
                      PhosphorIcons.user(PhosphorIconsStyle.regular),
                      size: 18,
                      color: AppColors.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre no puede estar vacío'
                    : null,
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: numberController,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dorsal',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(
                      PhosphorIcons.tShirt(PhosphorIconsStyle.regular),
                      size: 18,
                      color: AppColors.textMuted),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Introduce un dorsal';
                  }
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 99) {
                    return 'Dorsal entre 1 y 99';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(tr(lang, 'common.save')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final newName = nameController.text.trim();
    final newNumber = int.tryParse(numberController.text.trim());

    final nameChanged = newName != player.name;
    final numberChanged = newNumber != null && newNumber != player.number;

    if (!nameChanged && !numberChanged) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(teamRepositoryProvider).updatePlayer(
            widget.teamId,
            player.id,
            name: nameChanged ? newName : null,
            number: numberChanged ? newNumber : null,
            leagueId: widget.leagueId,
          );
      _refresh();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Jugador actualizado: $newName #${newNumber ?? player.number}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ─────────────────────────── Hire Player Dialog ──────────────────────────────

class _HirePlayerDialog extends ConsumerStatefulWidget {
  final String teamId;
  final String baseRosterId;
  final List<UserPlayer> currentPlayers;
  final int treasury;
  final String? leagueId;
  final VoidCallback onHired;

  const _HirePlayerDialog({
    required this.teamId,
    required this.baseRosterId,
    required this.currentPlayers,
    required this.treasury,
    this.leagueId,
    required this.onHired,
  });

  @override
  ConsumerState<_HirePlayerDialog> createState() => _HirePlayerDialogState();
}

class _HirePlayerDialogState extends ConsumerState<_HirePlayerDialog> {
  bool _isHiring = false;

  int _hiredCount(String positionId) =>
      widget.currentPlayers.where((p) => p.baseType == positionId).length;

  int _nextAvailableNumber() {
    final used = widget.currentPlayers.map((p) => p.number).toSet();
    for (var i = 1; i <= 99; i++) {
      if (!used.contains(i)) return i;
    }
    return 1;
  }

  Future<void> _hire(BasePosition pos) async {
    if (_isHiring) return;
    setState(() => _isHiring = true);
    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.hirePlayer(
        widget.teamId,
        baseType: pos.id,
        number: _nextAvailableNumber(),
        leagueId: widget.leagueId,
      );
      widget.onHired();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isHiring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final rosterAsync =
        ref.watch(_baseRosterDetailProvider(widget.baseRosterId));

    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = screenSize.width >= 900 ? 720.0 : screenSize.width - 32;
    final maxHeight = screenSize.height >= 760 ? 720.0 : screenSize.height - 48;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(lang, 'team.hirePlayer'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text(
                          'Tesorería: ${widget.treasury ~/ 1000}k  •  ${widget.currentPlayers.length}/16 jugadores',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                        size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.surfaceLight),
            // Position list
            Flexible(
              child: rosterAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(trf(lang, 'team.errorPositions', {'err': '$err'}),
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (roster) => ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: roster.positions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.surfaceLight),
                  itemBuilder: (_, i) {
                    final pos = roster.positions[i];
                    final hired = _hiredCount(pos.id);
                    final isFull = widget.currentPlayers.length >= 16;
                    final isMaxed = hired >= pos.maxQuantity;
                    final cantAfford = widget.treasury < pos.cost;
                    final canHire =
                        !isFull && !isMaxed && !cantAfford && !_isHiring;

                    return _buildPositionTile(
                        pos, hired, canHire, isMaxed, cantAfford);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionTile(BasePosition pos, int hired, bool canHire,
      bool isMaxed, bool cantAfford) {
    final lang = ref.watch(localeProvider);
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? [];
    final perkNames = pos.startingPerks
        .map((p) => localizedPerkName(allPerks, p.name, lang))
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMaxed
                  ? AppColors.textMuted.withValues(alpha: 0.3)
                  : canHire
                      ? AppColors.success
                      : AppColors.warning,
            ),
          ),
          // Position info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isMaxed ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Stats row
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _miniStat('MA ${pos.stats.ma}'),
                    _miniStat('ST ${pos.stats.st}'),
                    _miniStat('AG ${pos.stats.ag}+'),
                    _miniStat(
                        pos.stats.pa == 0 ? 'PA -' : 'PA ${pos.stats.pa}+'),
                    _miniStat('AV ${pos.stats.av}+'),
                  ],
                ),
                if (perkNames.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(perkNames,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cost + count + button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pos.cost ~/ 1000}k',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent),
              ),
              const SizedBox(height: 4),
              Text(
                '$hired / ${pos.maxQuantity}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: FilledButton.icon(
                  onPressed: canHire ? () => _hire(pos) : null,
                  icon: _isHiring
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textPrimary))
                      : Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 12),
                  label: Text(tr(lang, 'team.sign'),
                      style: const TextStyle(fontSize: 11)),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        canHire ? AppColors.primary : AppColors.surfaceLight,
                    foregroundColor:
                        canHire ? AppColors.textPrimary : AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(val,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
    );
  }
}

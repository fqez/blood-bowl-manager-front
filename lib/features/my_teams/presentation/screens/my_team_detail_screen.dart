// GENERATED: full rewrite to match roster management UI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/user_team.dart';

final userTeamDetailProvider =
    FutureProvider.family<UserTeamDetail, String>((ref, teamId) async {
  return ref.watch(teamRepositoryProvider).getUserTeamDetail(teamId);
});

class MyTeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  /// When set, this screen is in league context (back → league, owner-gated edits)
  final String? leagueId;
  const MyTeamDetailScreen({super.key, required this.teamId, this.leagueId});
  @override
  ConsumerState<MyTeamDetailScreen> createState() => _MyTeamDetailScreenState();
}

class _MyTeamDetailScreenState extends ConsumerState<MyTeamDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showActive = true;
  bool _showInjured = true;
  bool _showDead = false;
  bool _isMutating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(userTeamDetailProvider(widget.teamId));

  Future<void> _patch({
    int? rerolls,
    int? fanFactor,
    int? cheerleaders,
    int? assistantCoaches,
    bool? apothecary,
  }) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      final updated = await ref.read(teamRepositoryProvider).patchTeamStaff(
            widget.teamId,
            rerolls: rerolls,
            fanFactor: fanFactor,
            cheerleaders: cheerleaders,
            assistantCoaches: assistantCoaches,
            apothecary: apothecary,
          );
      ref.invalidate(userTeamDetailProvider(widget.teamId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _firePlayer(UserTeamDetail team, UserPlayer player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Despedir jugador', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Despedir a ${player.name}? El coste no se reembolsa.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Despedir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(teamRepositoryProvider).fireUserPlayer(widget.teamId, player.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(userTeamDetailProvider(widget.teamId));
    final isWide = MediaQuery.of(context).size.width >= 800;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err),
        data: (team) {
          final isOwner = widget.leagueId == null || (currentUserId != null && team.userId == currentUserId);
          return Column(children: [
            _buildTopBar(team, isWide, isOwner),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamHeader(team),
                    const SizedBox(height: 16),
                    _buildStatsStrip(team, isWide, isOwner),
                    const SizedBox(height: 20),
                    _buildPlayerSection(team, isWide, isOwner),
                    const SizedBox(height: 20),
                    isWide ? _buildBottomTwoCol(team, isOwner) : _buildBottomStacked(team, isOwner),
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

  // ── Error ──

  Widget _buildError(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error al cargar el equipo',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$err', style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold)),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──

  Widget _buildTopBar(UserTeamDetail team, bool isWide, bool isOwner) {
    final isLeague = widget.leagueId != null;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: AppColors.textSecondary),
                onPressed: () => isLeague
                    ? context.go('/league/${widget.leagueId}')
                    : context.go('/teams'),
                tooltip: isLeague ? 'Volver a la Liga' : 'Volver a Mis Equipos',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        isLeague ? 'Vista de Liga' : 'Mis Equipos',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 12, color: AppColors.textMuted),
                      Text(
                        isLeague ? 'Plantilla' : 'Gestión de Plantilla',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ]),
                    Text(
                      team.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
                        fontSize: isWide ? 18 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isOwner)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('Solo lectura',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    avatar: Icon(PhosphorIcons.eye(PhosphorIconsStyle.regular),
                        size: 14, color: AppColors.textMuted),
                  ),
                ),
              if (_isMutating)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(
                icon: Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold), size: 18),
                onPressed: _refresh,
                color: AppColors.textMuted,
                tooltip: 'Actualizar',
              ),
              if (isOwner) ...[
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () => _showHireDialog(context),
                  icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold), size: 16),
                  label: Text(isWide ? 'Contratar Jugador' : 'Contratar', style: const TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Team header ──

  Widget _buildTeamHeader(UserTeamDetail team) {
    final activeCount = team.players.where((p) => p.status == 'healthy').length;
    final isValid = activeCount >= 11;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/teams/${team.baseRosterId}/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill), size: 28, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${team.name} Roster',
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Gestiona tu plantilla, tesorería, staff y preparativos para el próximo partido.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isValid ? AppColors.success.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isValid ? AppColors.success.withOpacity(0.5) : AppColors.warning.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ESTADO: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: isValid ? AppColors.success : AppColors.warning, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                isValid ? 'Plantilla Válida' : 'Plantilla Inválida',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isValid ? AppColors.success : AppColors.warning),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats strip ──

  Widget _buildStatsStrip(UserTeamDetail team, bool isWide, bool isOwner) {
    final isLeague = widget.leagueId != null;
    final cards = [
      _statCardTeamValue(team),
      _statCardTreasury(team),
      _statCardRerolls(team, isOwner),
      _statCardFanFactor(team, isOwner, isLeague),
      _statCardMedStaff(team, isOwner, isLeague),
    ];
    if (isWide) {
      return Row(
        children: List.generate(cards.length, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
            child: cards[i],
          ),
        )),
      );
    }
    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 160, child: cards[i]),
      ),
    );
  }

  Widget _statCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: child,
    );
  }

  Widget _statCardTeamValue(UserTeamDetail team) {
    return _statCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCardLabel(PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill), 'TEAM VALUE'),
        const SizedBox(height: 6),
        Text('${(team.teamValue / 1000).toStringAsFixed(0)}k',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
          child: Text('+${(team.teamValue / 1000).toStringAsFixed(0)}k', style: TextStyle(fontSize: 10, color: AppColors.success)),
        ),
      ],
    ));
  }

  Widget _statCardTreasury(UserTeamDetail team) {
    return _statCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCardLabel(PhosphorIcons.coins(PhosphorIconsStyle.fill), 'TESORERÍA'),
        const SizedBox(height: 6),
        Text('${(team.treasury / 1000).toStringAsFixed(0)}k',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accent, height: 1)),
        const SizedBox(height: 4),
        Text('Ver Historial', style: TextStyle(fontSize: 11, color: AppColors.primary, decoration: TextDecoration.underline)),
      ],
    ));
  }

  Widget _statCardRerolls(UserTeamDetail team, bool isOwner) {
    final canAdd = isOwner && team.treasury >= team.rerollCost;
    final canRemove = isOwner && team.rerolls > 0;
    return _statCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCardLabel(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill), 'SEGUNDAS OP.'),
        const SizedBox(height: 4),
        Text('${team.rerolls}  (${team.rerollCost ~/ 1000}k/1)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
        const SizedBox(height: 6),
        Row(children: [
          _counterBtn(icon: PhosphorIcons.minus(PhosphorIconsStyle.bold), enabled: canRemove && !_isMutating, onTap: () => _patch(rerolls: team.rerolls - 1)),
          const SizedBox(width: 8),
          _counterBtn(icon: PhosphorIcons.plus(PhosphorIconsStyle.bold), enabled: canAdd && !_isMutating, onTap: () => _patch(rerolls: team.rerolls + 1)),
        ]),
      ],
    ));
  }

  Widget _statCardFanFactor(UserTeamDetail team, bool isOwner, bool isLeague) {
    final canAdd = isOwner && isLeague && team.treasury >= 10000;
    final canRemove = isOwner && isLeague && team.dedicatedFans > 0;
    return _statCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCardLabel(PhosphorIcons.megaphone(PhosphorIconsStyle.fill), 'FACTOR HINCHAS'),
        const SizedBox(height: 4),
        Text('${team.dedicatedFans}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1)),
        const SizedBox(height: 6),
        Row(children: [
          _counterBtn(icon: PhosphorIcons.minus(PhosphorIconsStyle.bold), enabled: canRemove && !_isMutating, onTap: () => _patch(fanFactor: team.dedicatedFans - 1)),
          const SizedBox(width: 8),
          _counterBtn(icon: PhosphorIcons.plus(PhosphorIconsStyle.bold), enabled: canAdd && !_isMutating, onTap: () => _patch(fanFactor: team.dedicatedFans + 1)),
        ]),
      ],
    ));
  }

  Widget _statCardMedStaff(UserTeamDetail team, bool isOwner, bool isLeague) {
    return _statCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCardLabel(PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill), 'STAFF MÉDICO'),
        const SizedBox(height: 8),
        if (!team.apothecaryAllowed)
          Text('No disponible', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
        else if (team.apothecary)
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Apotecario', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
          ])
        else if (isOwner && isLeague) ...[
          Text('Apotecario', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: team.treasury >= 50000 && !_isMutating ? () => _patch(apothecary: true) : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              side: const BorderSide(color: AppColors.accent),
              foregroundColor: AppColors.accent,
            ),
            child: const Text('Contratar  50k', style: TextStyle(fontSize: 11)),
          ),
        ] else
          Text('Sin apotecario', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ));
  }

  Widget _statCardLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _counterBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceLight : AppColors.surfaceLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 12, color: enabled ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  // ── Player section ──

  Widget _buildPlayerSection(UserTeamDetail team, bool isWide, bool isOwner) {
    final filtered = _filterPlayers(team.players);
    final totalActive = team.players.where((p) => !p.isDead).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular), size: 16, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _filterPill('Activos', _showActive, (v) => setState(() => _showActive = v)),
                const SizedBox(width: 6),
                _filterPill('Lesionados', _showInjured, (v) => setState(() => _showInjured = v)),
                const SizedBox(width: 6),
                _filterPill('Muertos', _showDead, (v) => setState(() => _showDead = v)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                  child: Text('Jugadores: $totalActive/16',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.bold), size: 14),
                  label: const Text('Exportar Roster', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Table header
        _buildTableHeader(isWide),
        const Divider(height: 1),
        // Rows
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(children: [
                Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.light), size: 40, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text('Sin jugadores que mostrar', style: TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          )
        else
          ...filtered.map((p) => _buildPlayerRow(p, team, isWide, isOwner)),
        if (team.players.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('1 - ${filtered.length} de ${team.players.length} jugadores',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
          ),
      ],
    );
  }

  Widget _filterPill(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      labelStyle: TextStyle(fontSize: 11, color: selected ? AppColors.textPrimary : AppColors.textMuted),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.25),
      checkmarkColor: AppColors.primary,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  List<UserPlayer> _filterPlayers(List<UserPlayer> all) {
    return all.where((p) {
      if (p.isDead && !_showDead) return false;
      if (!p.isDead && p.status != 'healthy' && !_showInjured) return false;
      if (!p.isDead && p.status == 'healthy' && !_showActive) return false;
      if (_searchQuery.isNotEmpty) {
        if (!p.name.toLowerCase().contains(_searchQuery) &&
            !p.positionLabel.toLowerCase().contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildTableHeader(bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 36, child: _th('#')),
          SizedBox(width: 150, child: _th('NOMBRE')),
          if (isWide) Expanded(flex: 2, child: _th('POSICIÓN')),
          Expanded(flex: 3, child: _th('ATRIBUTOS (MA/ST/AG/PA/AV)')),
          if (isWide) Expanded(flex: 3, child: _th('HABILIDADES')),
          SizedBox(width: 44, child: Center(child: _th('SPP'))),
          SizedBox(width: 80, child: Center(child: _th('ESTADO'))),
          if (isWide) SizedBox(width: 60, child: Center(child: _th('COSTE'))),
          SizedBox(width: 40, child: _th('')),
        ],
      ),
    );
  }

  Widget _th(String t) => Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8));

  Widget _buildPlayerRow(UserPlayer player, UserTeamDetail team, bool isWide, bool isOwner) {
    final isDead = player.isDead;
    final canLevelUp = _canLevelUp(player);
    return InkWell(
      onTap: () {
        final tid = widget.teamId;
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
          bottom: BorderSide(color: AppColors.surfaceLight),
          left: BorderSide(
            color: isDead
                ? AppColors.dead.withOpacity(0.5)
                : player.status != 'healthy'
                    ? AppColors.warning.withOpacity(0.5)
                    : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // # badge
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(5)),
                child: Center(child: Text('#${player.number}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              ),
            ),
          ),
          // Avatar + name
          SizedBox(
            width: 150,
            child: Row(
              children: [
                _buildPlayerAvatar(player),
                const SizedBox(width: 8),
                Expanded(
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
              ],
            ),
          ),
          // Position
          if (isWide)
            Expanded(
              flex: 2,
              child: Text(player.positionLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          // Stats
          Expanded(
            flex: 3,
            child: Wrap(spacing: 4, runSpacing: 4, children: [
              _statChip('${player.stats.ma}'),
              _statChip('${player.stats.st}'),
              _statChip(player.stats.ag),
              if (player.stats.pa != null) _statChip(player.stats.pa!),
              _statChip(player.stats.av),
            ]),
          ),
          // Skills
          if (isWide)
            Expanded(
              flex: 3,
              child: Wrap(spacing: 4, runSpacing: 4, children: player.perks.take(4).map(_skillBadge).toList()),
            ),
          // SPP
          SizedBox(
            width: 44,
            child: Center(
              child: Text('${player.spp}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: canLevelUp ? AppColors.success : AppColors.textPrimary,
                  )),
            ),
          ),
          // Status
          SizedBox(
            width: 80,
            child: Center(child: canLevelUp && !isDead ? _levelUpBadge() : _statusBadge(player)),
          ),
          // Cost
          if (isWide)
            SizedBox(
              width: 60,
              child: Center(
                child: Text('${player.currentValue ~/ 1000}k',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ),
            ),
          // Actions
          SizedBox(
            width: 40,
            child: Center(
              child: isOwner
                  ? IconButton(
                      icon: Icon(PhosphorIcons.userMinus(PhosphorIconsStyle.bold), size: 16),
                      color: AppColors.textMuted,
                      tooltip: 'Despedir',
                      onPressed: () => _firePlayer(team, player),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPlayerAvatar(UserPlayer player) {
    return Stack(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Center(
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
        ),
      ),
      if (player.isDead)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
            child: Icon(PhosphorIcons.skull(PhosphorIconsStyle.fill), size: 10, color: AppColors.dead),
          ),
        )
      else if (player.status != 'healthy')
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
            child: Icon(PhosphorIcons.firstAid(PhosphorIconsStyle.fill), size: 10, color: AppColors.warning),
          ),
        ),
    ]);
  }

  Widget _statChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _skillBadge(UserPlayerPerk perk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Text(perk.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    );
  }

  Widget _statusBadge(UserPlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: player.statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(player.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: player.statusColor)),
    );
  }

  Widget _levelUpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(PhosphorIcons.arrowFatUp(PhosphorIconsStyle.fill), size: 10, color: AppColors.warning),
        const SizedBox(width: 3),
        Text('SUBIR NIVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning)),
      ]),
    );
  }

  bool _canLevelUp(UserPlayer p) {
    const thresholds = [6, 16, 31, 51, 76, 176];
    return thresholds.contains(p.spp);
  }

  // ── Bottom sections ──

  Widget _buildBottomTwoCol(UserTeamDetail team, bool isOwner) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTreasuryHistory()),
          const SizedBox(width: 16),
          Expanded(child: _buildStaffGestion(team, isOwner)),
        ],
      ),
    );
  }

  Widget _buildBottomStacked(UserTeamDetail team, bool isOwner) {
    return Column(children: [
      _buildTreasuryHistory(),
      const SizedBox(height: 16),
      _buildStaffGestion(team, isOwner),
    ]);
  }

  Widget _buildTreasuryHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill), size: 14, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('REGISTRO DE TESORERÍA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 12),
          _historyItem('Creación del equipo', 'Fondos iniciales', 1000000, true),
          const Divider(height: 1),
          _historyItem('Contratación de plantilla', 'Jugadores base', -700000, false),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(PhosphorIcons.arrowDown(PhosphorIconsStyle.bold), size: 12),
                label: const Text('Ajuste Manual de Fondos', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(String title, String subtitle, int amount, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            isPositive ? '+${(amount / 1000).toStringAsFixed(0)}k' : '${(amount / 1000).toStringAsFixed(0)}k',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isPositive ? AppColors.success : AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffGestion(UserTeamDetail team, bool isOwner) {
    final activeCount = team.players.where((p) => p.status == 'healthy').length;
    final isValidRoster = activeCount >= 11;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill), size: 14, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('STAFF Y GESTIÓN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 12),
          _staffRow(
            label: 'ENTRENADORES AYUDANTES',
            count: team.assistantCoaches,
            cost: 10000,
            canHire: isOwner && team.treasury >= 10000,
            canFire: isOwner && team.assistantCoaches > 0,
            onHire: () => _patch(assistantCoaches: team.assistantCoaches + 1),
            onFire: () => _patch(assistantCoaches: team.assistantCoaches - 1),
          ),
          const SizedBox(height: 10),
          _staffRow(
            label: 'ANIMADORAS',
            count: team.cheerleaders,
            cost: 10000,
            canHire: isOwner && team.treasury >= 10000,
            canFire: isOwner && team.cheerleaders > 0,
            onHire: () => _patch(cheerleaders: team.cheerleaders + 1),
            onFire: () => _patch(cheerleaders: team.cheerleaders - 1),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isValidRoster
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                size: 16,
                color: isValidRoster ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado del Roster',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      isValidRoster
                          ? 'Actualmente tienes $activeCount jugadores activos. El equipo está listo para jugar.'
                          : 'Actualmente tienes $activeCount jugadores activos. Necesitas mínimo 11 para el próximo partido.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staffRow({
    required String label,
    required int count,
    required int cost,
    required bool canHire,
    required bool canFire,
    required VoidCallback onHire,
    required VoidCallback onFire,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
          const Spacer(),
          Text('$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: count > 0 ? AppColors.textPrimary : AppColors.textMuted)),
        ]),
        Text('Coste: ${cost ~/ 1000}k. Modificador a Eventos.',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(children: [
          _staffActionBtn(label: 'Despedir', enabled: canFire && !_isMutating, color: AppColors.error, onTap: onFire),
          const SizedBox(width: 8),
          _staffActionBtn(label: 'Contratar', enabled: canHire && !_isMutating, color: AppColors.accent, onTap: onHire),
        ]),
      ],
    );
  }

  Widget _staffActionBtn({
    required String label,
    required bool enabled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : AppColors.textMuted,
        side: BorderSide(color: enabled ? color.withOpacity(0.6) : AppColors.surfaceLight),
        minimumSize: const Size(80, 30),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showHireDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Contratar jugador')),
    );
  }
}

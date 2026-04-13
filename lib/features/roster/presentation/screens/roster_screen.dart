import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/team.dart';
import '../widgets/player_row.dart';
import '../widgets/staff_section.dart';

class RosterScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String teamId;

  const RosterScreen({
    super.key,
    required this.leagueId,
    required this.teamId,
  });

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  bool _showActives = true;
  bool _showInjured = true;
  bool _showDead = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final teamAsync = ref.watch(teamProvider(widget.teamId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;

    return Scaffold(
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.warning(PhosphorIconsStyle.bold),
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error cargando el equipo',
                  style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('$error',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        data: (team) {
          final isOwner =
              currentUserId != null && team.ownerId == currentUserId;
          return _buildContent(context, team, isWide, isOwner);
        },
      ),
      floatingActionButton: teamAsync.valueOrNull != null &&
              currentUserId != null &&
              teamAsync.valueOrNull!.ownerId == currentUserId
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPlayerDialog(context),
              label: Text(tr(lang, 'team.sign')),
              icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold)),
            )
          : null,
    );
  }

  Widget _buildContent(
      BuildContext context, Team team, bool isWide, bool isOwner) {
    return CustomScrollView(
      slivers: [
        _buildHeader(team, isWide, isOwner),
        SliverToBoxAdapter(child: _buildTreasuryBar(team, isOwner)),
        SliverToBoxAdapter(child: _buildFilters()),
        _buildPlayerList(team),
        SliverToBoxAdapter(child: _buildStaffSection(team, isOwner)),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildHeader(Team team, bool isWide, bool isOwner) {
    final lang = ref.watch(localeProvider);
    return SliverAppBar(
      expandedHeight: isWide ? 180 : 140,
      pinned: true,
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
        onPressed: () => context.go('/league/${widget.leagueId}'),
      ),
      actions: [
        if (isOwner) ...[
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold)),
            onPressed: () {},
            tooltip: tr(lang, 'team.editPlayer'),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.bold)),
            onPressed: () {},
            tooltip: 'Configuración',
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Chip(
              label: Text(tr(lang, 'team.readOnly'),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              avatar: Icon(PhosphorIcons.eye(PhosphorIconsStyle.regular),
                  size: 14, color: AppColors.textMuted),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Team emblem
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'teams/${_teamAssetPath(team.baseTeamId)}/logo.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          PhosphorIcons.shield(PhosphorIconsStyle.bold),
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatChip('TV', '${team.teamValue ~/ 1000}k'),
                            const SizedBox(width: 8),
                            _buildStatChip(tr(lang, 'roster.title'),
                                '${team.characters.where((c) => c.status == PlayerStatus.healthy).length}'),
                            const SizedBox(width: 8),
                            _buildStatChip(tr(lang, 'teamCreator.rerolls'),
                                '${team.rerolls}'),
                          ],
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

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryBar(Team team, bool isOwner) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill),
              color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TESORERÍA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${team.treasury ~/ 1000}k',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isOwner) ...[
            _buildQuickBuyButton(
                'Re-roll', team.rerollCost, () => _buyReroll(team)),
            const SizedBox(width: 8),
            _buildQuickBuyButton('Apotecario', team.apothecary ? null : 50000,
                team.apothecary ? null : () => _buyApothecary(team)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickBuyButton(
      String label, int? cost, VoidCallback? onPressed) {
    final enabled = cost != null && onPressed != null;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.accent : AppColors.textMuted,
        side: BorderSide(
          color: enabled ? AppColors.accent : AppColors.surfaceLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (cost != null)
            Text(
              '${cost ~/ 1000}k',
              style: TextStyle(
                fontSize: 10,
                color: enabled
                    ? AppColors.textMuted
                    : AppColors.textMuted.withOpacity(0.5),
              ),
            )
          else
            Text(
              '✓',
              style: TextStyle(fontSize: 10, color: AppColors.success),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'PLANTILLA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _buildFilterChip(
              'Activos', _showActives, (v) => setState(() => _showActives = v)),
          const SizedBox(width: 8),
          _buildFilterChip('Lesionados', _showInjured,
              (v) => setState(() => _showInjured = v)),
          const SizedBox(width: 8),
          _buildFilterChip(
              'Muertos', _showDead, (v) => setState(() => _showDead = v)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      labelStyle: TextStyle(
        fontSize: 11,
        color: selected ? AppColors.textPrimary : AppColors.textMuted,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.3),
      checkmarkColor: AppColors.primary,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPlayerList(Team team) {
    final filteredPlayers = team.characters.where((c) {
      if (c.status == PlayerStatus.dead) return _showDead;
      if (c.status == PlayerStatus.injured) return _showInjured;
      return _showActives;
    }).toList();

    if (filteredPlayers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.light),
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No hay jugadores que mostrar',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final player = filteredPlayers[index];
            return PlayerRow(
              character: player,
              onTap: () => context.go(
                  '/league/${widget.leagueId}/team/${widget.teamId}/player/${player.id}'),
            );
          },
          childCount: filteredPlayers.length,
        ),
      ),
    );
  }

  Widget _buildStaffSection(Team team, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StaffSection(
        rerolls: team.rerolls,
        rerollCost: team.rerollCost,
        hasApothecary: team.apothecary,
        assistantCoaches: team.assistantCoaches,
        cheerleaders: team.cheerleaders,
        onBuyReroll: () => _buyReroll(team),
        onBuyApothecary: () => _buyApothecary(team),
        onBuyAssistant: () => _buyAssistant(team),
        onBuyCheerleader: () => _buyCheerleader(team),
        treasury: team.treasury,
        readOnly: !isOwner,
      ),
    );
  }

  String _teamAssetPath(String raceId) {
    return raceId.toLowerCase().replaceAll(' ', '_');
  }

  void _showAddPlayerDialog(BuildContext context) {
    // TODO: Implement player recruitment dialog
  }

  void _buyReroll(Team team) {
    // TODO: Implement buy reroll
  }

  void _buyApothecary(Team team) {
    // TODO: Implement buy apothecary
  }

  void _buyAssistant(Team team) {
    // TODO: Implement buy assistant
  }

  void _buyCheerleader(Team team) {
    // TODO: Implement buy cheerleader
  }
}

// Provider for team data
final teamProvider = FutureProvider.family<Team, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeam(teamId);
});

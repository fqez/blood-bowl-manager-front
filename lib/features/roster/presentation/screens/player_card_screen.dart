import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/team.dart';
import '../screens/roster_screen.dart';
import '../widgets/skill_badge.dart';
import '../widgets/stat_hex.dart';

class PlayerCardScreen extends ConsumerWidget {
  final String leagueId;
  final String teamId;
  final String playerId;

  const PlayerCardScreen({
    super.key,
    required this.leagueId,
    required this.teamId,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error', style: TextStyle(color: AppColors.error)),
        ),
        data: (team) {
          final player = team.characters.firstWhere(
            (c) => c.id == playerId,
            orElse: () => throw Exception('Jugador no encontrado'),
          );
          return _buildContent(context, team, player, isWide);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Team team, Character player, bool isWide) {
    return CustomScrollView(
      slivers: [
        _buildHeader(context, player),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainInfo(player)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSidebar(player)),
                    ],
                  )
                : Column(
                    children: [
                      _buildMainInfo(player),
                      const SizedBox(height: 16),
                      _buildSidebar(player),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Character player) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
        onPressed: () => context.go('/league/$leagueId/team/$teamId'),
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold)),
          onPressed: () {},
          tooltip: 'Editar jugador',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            // Player portrait area
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Center(
                          child: Text(
                            player.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Player info
            Positioned(
              left: 16,
              bottom: 16,
              right: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${player.number}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    player.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    player.position,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(Character player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats hexagon
        _buildStatsSection(player),
        const SizedBox(height: 24),
        // Skills
        _buildSkillsSection(player),
        const SizedBox(height: 24),
        // History
        _buildHistorySection(player),
      ],
    );
  }

  Widget _buildStatsSection(Character player) {
    final stats = player.stats;

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
          Text(
            'CARACTERÍSTICAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatHex(
                label: 'MOV',
                value: stats.ma,
                modifier: 0,
              ),
              StatHex(
                label: 'FUE',
                value: stats.st,
                modifier: 0,
              ),
              StatHex(
                label: 'AGI',
                value: stats.ag,
                modifier: 0,
              ),
              StatHex(
                label: 'PAS',
                value: stats.pa,
                modifier: 0,
              ),
              StatHex(
                label: 'ARM',
                value: stats.av,
                modifier: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(Character player) {
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
          Row(
            children: [
              Text(
                'HABILIDADES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${player.skills.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (player.skills.isEmpty)
            Text(
              'Sin habilidades adicionales',
              style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: player.skills.map((skill) => SkillBadge(skill: skill)).toList(),
            ),
        ],
      ),
    );
  }

  // Note: _buildInjuriesSection removed - Character model doesn't track injury history

  Widget _buildHistorySection(Character player) {
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
          Text(
            'HISTORIAL DE PARTIDOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHistoryStat(
                icon: PhosphorIcons.footballHelmet(PhosphorIconsStyle.fill),
                label: 'Nivel',
                value: '${player.level}',
              ),
              _buildHistoryStat(
                icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                label: 'SPP',
                value: '${player.spp}',
                color: AppColors.accent,
              ),
              _buildHistoryStat(
                icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
                label: 'Valor',
                value: '${player.cost ~/ 1000}k',
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStat({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? AppColors.textMuted, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Character player) {
    return Column(
      children: [
        _buildSppCard(player),
        const SizedBox(height: 16),
        _buildValueCard(player),
      ],
    );
  }

  Widget _buildSppCard(Character player) {
    final currentSpp = player.spp;
    final nextLevelSpp = _getNextLevelSpp(player.level);
    final progress = nextLevelSpp > 0 ? currentSpp / nextLevelSpp : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'NIVEL ${player.level}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$currentSpp',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'SPP',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nextLevelSpp > 0)
            Text(
              '${nextLevelSpp - currentSpp} SPP para nivel ${player.level + 1}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Text(
              'Nivel máximo alcanzado',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValueCard(Character player) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Text(
            'VALOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${player.value ~/ 1000}k',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), size: 16),
              label: const Text('Despedir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getNextLevelSpp(int level) {
    switch (level) {
      case 1:
        return 6;
      case 2:
        return 16;
      case 3:
        return 31;
      case 4:
        return 51;
      case 5:
        return 76;
      case 6:
        return 176;
      default:
        return 0;
    }
  }
}

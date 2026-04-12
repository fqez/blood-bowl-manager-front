import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../../league/domain/models/league.dart';
import '../widgets/stat_card.dart';
import '../widgets/league_card.dart';
import '../widgets/notification_card.dart';

// Providers
final myLeaguesProvider = FutureProvider<List<League>>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getMyLeagues();
});

final invitationsProvider = FutureProvider<List<LeagueInvitation>>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getInvitations();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myLeaguesProvider);
          ref.invalidate(invitationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          child: isWideScreen
              ? _buildWideLayout(context, ref)
              : _buildNarrowLayout(context, ref),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Text(
            'DASHBOARD',
            style: TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Resumen de actividad y ligas activas',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/create-team'),
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
          label: const Text('Crear Equipo'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showJoinLeagueDialog(context),
          icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.bold), size: 18),
          label: const Text('Unirse a Liga'),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(PhosphorIcons.bell(PhosphorIconsStyle.regular)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(ref),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildLeaguesSection(context, ref),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildNotificationsSection(ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(ref),
        const SizedBox(height: 24),
        _buildLeaguesSection(context, ref),
        const SizedBox(height: 24),
        _buildNotificationsSection(ref),
      ],
    );
  }

  Widget _buildStatsRow(WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return leaguesAsync.when(
      loading: () => _buildStatsRowSkeleton(),
      error: (_, __) => _buildStatsRowSkeleton(),
      data: (leagues) {
        // Calculate aggregate stats
        int totalMatches = 0;
        int totalWins = 0;
        int totalSpp = 0;
        int totalCasualties = 0;

        for (final league in leagues) {
          for (final standing in league.standings) {
            totalMatches += standing.gamesPlayed;
            totalWins += standing.wins;
            totalSpp += standing.touchdownsFor * 3; // Simplified SPP calculation
            totalCasualties += standing.casualtiesFor;
          }
        }

        final winRate = totalMatches > 0
            ? (totalWins / totalMatches * 100).toStringAsFixed(0)
            : '--';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isNarrow ? (constraints.maxWidth - 16) / 2 : 180,
                  child: StatCard(
                    icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
                    label: 'PARTIDOS JUGADOS',
                    value: totalMatches.toString(),
                    subtitle: '+3 esta temporada',
                    subtitleColor: AppColors.success,
                  ),
                ),
                SizedBox(
                  width: isNarrow ? (constraints.maxWidth - 16) / 2 : 180,
                  child: StatCard(
                    icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                    label: 'WIN RATE',
                    value: '$winRate%',
                    subtitle: '+2% vs anterior',
                    subtitleColor: AppColors.success,
                  ),
                ),
                SizedBox(
                  width: isNarrow ? (constraints.maxWidth - 16) / 2 : 180,
                  child: StatCard(
                    icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                    label: 'TOTAL SPP',
                    value: totalSpp.toString(),
                    subtitle: 'En todos los equipos activos',
                  ),
                ),
                SizedBox(
                  width: isNarrow ? (constraints.maxWidth - 16) / 2 : 180,
                  child: StatCard(
                    icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
                    label: 'BAJAS CAUSADAS',
                    value: totalCasualties.toString(),
                    subtitle: 'Sangre para Nuffle',
                    subtitleColor: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRowSkeleton() {
    return Row(
      children: List.generate(4, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }

  Widget _buildLeaguesSection(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'LIGAS ACTIVAS',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill)),
                  onPressed: () {},
                  iconSize: 20,
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.list(PhosphorIconsStyle.regular)),
                  onPressed: () {},
                  iconSize: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        leaguesAsync.when(
          loading: () => _buildLeaguesLoading(),
          error: (error, _) => _buildLeaguesError(error.toString()),
          data: (leagues) => leagues.isEmpty
              ? _buildEmptyLeagues()
              : _buildLeaguesGrid(context, leagues),
        ),
      ],
    );
  }

  Widget _buildLeaguesLoading() {
    return Row(
      children: List.generate(2, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index == 0 ? 16 : 0),
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }

  Widget _buildLeaguesError(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Error: $error',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildEmptyLeagues() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.trophy(PhosphorIconsStyle.light),
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No estás en ninguna liga',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un equipo y únete a una liga para empezar a jugar',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguesGrid(BuildContext context, List<League> leagues) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            return LeagueCard(
              league: leagues[index],
              onTap: () => context.go('/league/${leagues[index].id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsSection(WidgetRef ref) {
    final invitationsAsync = ref.watch(invitationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.bell(PhosphorIconsStyle.fill),
                 color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'AVISOS',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '3 Nuevos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sample notifications
        NotificationCard(
          type: NotificationType.levelUp,
          title: 'Registra subida de nivel (SPP) para \'Grog el Mutilador\'.',
          actionText: 'Asignar ahora',
          onTap: () {},
          time: 'Hace 2h',
        ),
        const SizedBox(height: 8),
        NotificationCard(
          type: NotificationType.matchResult,
          title: 'El rival ha validado el resultado: Orkboyz 2 - 1 Elfos Oscuros.',
          actionText: 'Ver acta',
          onTap: () {},
          time: 'Ayer',
        ),
        const SizedBox(height: 8),
        NotificationCard(
          type: NotificationType.injury,
          title: 'El jugador \'Grom\' (Orkboyz) sufre lesión persistente (-1 Movimiento).',
          time: 'Ayer',
        ),
        const SizedBox(height: 8),
        NotificationCard(
          type: NotificationType.levelUp,
          title: 'Snikch (Skaven Blight) alcanza el Nivel 3. Habilidad elegida: Esquivar.',
          time: 'Ayer',
        ),

        // Invitations
        invitationsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (invitations) => Column(
            children: invitations.map((inv) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NotificationCard(
                type: NotificationType.invitation,
                title: 'Has sido invitado a \'${inv.leagueName}\'.',
                actionText: 'Aceptar',
                secondaryActionText: 'Rechazar',
                onTap: () => _acceptInvitation(ref, inv.id),
                onSecondaryTap: () => _declineInvitation(ref, inv.id),
                time: 'Hace 3 días',
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showJoinLeagueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a Liga'),
        content: const Text('Introduce el código de invitación de la liga.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(WidgetRef ref, String invitationId) async {
    try {
      await ref.read(leagueRepositoryProvider).acceptInvitation(invitationId);
      ref.invalidate(invitationsProvider);
      ref.invalidate(myLeaguesProvider);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _declineInvitation(WidgetRef ref, String invitationId) async {
    try {
      await ref.read(leagueRepositoryProvider).declineInvitation(invitationId);
      ref.invalidate(invitationsProvider);
    } catch (e) {
      // Handle error
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../../../team_creator/presentation/screens/team_creator_screen.dart';

// ignore_for_file: deprecated_member_use

/// Provider that fetches the user's saved tactics.
final myTacticsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getMyTactics();
});

class MyTacticsScreen extends ConsumerWidget {
  const MyTacticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final tacticsAsync = ref.watch(myTacticsProvider);
    final rostersAsync = ref.watch(baseRostersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(lang),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, lang),
                  const SizedBox(height: 20),
                  tacticsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        children: [
                          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                              size: 40, color: AppColors.error),
                          const SizedBox(height: 8),
                          Text('Error: $e',
                              style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(myTacticsProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    data: (tactics) {
                      if (tactics.isEmpty) {
                        return _buildEmptyState(context, lang);
                      }

                      // Build a map of roster names for display
                      final rosterMap = <String, BaseTeam>{};
                      rostersAsync.whenData((teams) {
                        for (final t in teams) {
                          rosterMap[t.id] = t;
                        }
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tactics.length} TÁCTICAS GUARDADAS',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...tactics.map((t) => _buildTacticCard(
                              context, ref, t, rosterMap, lang)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill),
                color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Text(
              'TÁCTICAS',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const Text('  >  ',
                style: TextStyle(fontSize: 11, color: Colors.white38)),
            Text(
              tr(lang, 'myTactics.title'),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill),
                        color: AppColors.accent, size: 26),
                    const SizedBox(width: 12),
                    Text(
                      tr(lang, 'myTactics.title'),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr(lang, 'myTactics.subtitle'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/tactics'),
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
            label: Text(
              'NUEVA',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(PhosphorIcons.crosshair(PhosphorIconsStyle.regular),
                size: 60, color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              tr(lang, 'myTactics.noTactics'),
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              tr(lang, 'myTactics.createFirst'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/tactics'),
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
              label: Text(
                'CREAR TÁCTICA',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticCard(
      BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> tactic,
      Map<String, BaseTeam> rosterMap,
      String lang) {
    final id = tactic['id'] as String;
    final name = tactic['name'] as String? ?? 'Sin nombre';
    final mode = tactic['mode'] as String? ?? 'attack';
    final rosterId = tactic['base_roster_id'] as String? ?? '';
    final playerCount = tactic['player_count'] as int? ?? 0;
    final goodAgainstCount = tactic['good_against_count'] as int? ?? 0;
    final roster = rosterMap[rosterId];
    final isAttack = mode == 'attack';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/tactics?id=$id'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              children: [
                // Team logo
                SizedBox(
                  width: 44,
                  height: 44,
                  child: roster != null
                      ? Image.asset(
                          'assets/teams/${roster.id}/logo.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              PhosphorIcons.shield(PhosphorIconsStyle.fill),
                              size: 28,
                              color: AppColors.textMuted),
                        )
                      : Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                          size: 28, color: AppColors.textMuted),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            roster?.name ?? rosterId,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$playerCount jugadores',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (goodAgainstCount > 0) ...[
                            const SizedBox(width: 8),
                            Icon(PhosphorIcons.sword(PhosphorIconsStyle.fill),
                                size: 11, color: AppColors.success),
                            const SizedBox(width: 2),
                            Text(
                              '$goodAgainstCount',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.success),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Mode badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        (isAttack ? AppColors.error : const Color(0xFF2196F3))
                            .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAttack
                          ? AppColors.error.withOpacity(0.4)
                          : const Color(0xFF2196F3).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAttack
                            ? PhosphorIcons.sword(PhosphorIconsStyle.fill)
                            : PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
                        size: 12,
                        color: isAttack
                            ? AppColors.error
                            : const Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAttack ? 'ATAQUE' : 'DEFENSA',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isAttack
                              ? AppColors.error
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Delete button
                IconButton(
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                      size: 18, color: AppColors.error.withOpacity(0.6)),
                  onPressed: () => _confirmDelete(context, ref, id, name, lang),
                  tooltip: tr(lang, 'myTactics.delete'),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id,
      String name, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'myTactics.delete'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Eliminar "$name"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(teamRepositoryProvider);
                await repo.deleteTactic(id);
                ref.invalidate(myTacticsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(trf(lang, 'common.error', {'e': '$e'})),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(tr(lang, 'common.delete'),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

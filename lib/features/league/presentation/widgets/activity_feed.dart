import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';

class ActivityFeed extends ConsumerWidget {
  final String leagueId;

  const ActivityFeed({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    // Sample activity data
    final activities = [
      _ActivityItem(
        type: _ActivityType.matchRegistered,
        title: 'Athel Loren 2 - 1 Khazad-dûm validado por el comisario.',
        time: 'Hace 2h',
      ),
      _ActivityItem(
        type: _ActivityType.injury,
        title:
            'El jugador \'Grom\' (Orkboyz) sufre lesión persistente (-1 Movimiento).',
        time: 'Ayer',
      ),
      _ActivityItem(
        type: _ActivityType.levelUp,
        title:
            'Snikch (Skaven Blight) alcanza el Nivel 3. Habilidad elegida: Esquivar.',
        time: 'Ayer',
      ),
    ];

    return Column(
      children:
          activities.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  Widget _buildActivityItem(_ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor(activity.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(activity.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(activity.type),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(activity.type),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      activity.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(_ActivityType type) {
    switch (type) {
      case _ActivityType.matchRegistered:
        return AppColors.success;
      case _ActivityType.injury:
        return AppColors.warning;
      case _ActivityType.levelUp:
        return AppColors.accent;
    }
  }

  String _getTypeLabel(_ActivityType type) {
    switch (type) {
      case _ActivityType.matchRegistered:
        return 'PARTIDO REGISTRADO';
      case _ActivityType.injury:
        return 'BAJA GRAVE';
      case _ActivityType.levelUp:
        return 'SUBIDA DE NIVEL';
    }
  }
}

enum _ActivityType {
  matchRegistered,
  injury,
  levelUp,
}

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String time;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.time,
  });
}

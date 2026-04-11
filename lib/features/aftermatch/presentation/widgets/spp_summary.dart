import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../domain/models/aftermatch.dart';

class SppSummary extends StatelessWidget {
  final List<TouchdownRecord> touchdowns;
  final List<InjuryRecord> injuries;
  final List<BonusSppRecord> bonusSpp;
  final Team? homeTeam;
  final Team? awayTeam;
  final ValueChanged<BonusSppRecord> onBonusSppAdded;
  final ValueChanged<int> onBonusSppRemoved;

  const SppSummary({
    super.key,
    required this.touchdowns,
    required this.injuries,
    required this.bonusSpp,
    required this.homeTeam,
    required this.awayTeam,
    required this.onBonusSppAdded,
    required this.onBonusSppRemoved,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate SPP by player
    final sppByPlayer = <String, _PlayerSpp>{};

    // TDs (4 SPP each)
    for (final td in touchdowns) {
      sppByPlayer.putIfAbsent(td.playerId, () => _PlayerSpp(name: td.playerName));
      sppByPlayer[td.playerId]!.touchdowns++;
    }

    // Casualties (2 SPP each) - Note: InjuryRecord doesn't track who caused the injury
    // This would need backend support to track casualty SPP

    // Bonus SPP
    for (final spp in bonusSpp) {
      sppByPlayer.putIfAbsent(spp.playerId, () => _PlayerSpp(name: spp.playerName));
      sppByPlayer[spp.playerId]!.bonus += spp.amount;
      sppByPlayer[spp.playerId]!.bonusReasons.add(spp.reason);
    }

    final sortedPlayers = sppByPlayer.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return Column(
      children: [
        // Player SPP list
        if (sortedPlayers.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: sortedPlayers.map((entry) => _buildPlayerSppRow(
                entry.key,
                entry.value,
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Add bonus SPP
        Text(
          'AÑADIR SPP BONUS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBonusButton(
                context,
                icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                label: 'MVP',
                amount: 4,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBonusButton(
                context,
                icon: PhosphorIcons.football(PhosphorIconsStyle.fill),
                label: 'Pase',
                amount: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBonusButton(
                context,
                icon: PhosphorIcons.handFist(PhosphorIconsStyle.fill),
                label: 'Intercepción',
                amount: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bonus SPP list
        if (bonusSpp.isNotEmpty)
          ...bonusSpp.asMap().entries.map((entry) => _buildBonusSppItem(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildPlayerSppRow(String playerId, _PlayerSpp spp) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          // Player avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                spp.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spp.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (spp.touchdowns > 0)
                      _buildSppChip('${spp.touchdowns} TD', AppColors.success),
                    if (spp.casualties > 0)
                      _buildSppChip('${spp.casualties} CAS', AppColors.error),
                    if (spp.bonus > 0)
                      _buildSppChip('+${spp.bonus}', AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
          // Total SPP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${spp.total}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSppChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBonusButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int amount,
  }) {
    return OutlinedButton(
      onPressed: () => _showBonusSppDialog(context, label, amount),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        side: BorderSide(color: AppColors.accent),
        foregroundColor: AppColors.accent,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '+$amount SPP',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusSppItem(int index, BonusSppRecord spp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
              color: AppColors.accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: spp.playerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' • ${spp.reason} (+${spp.amount} SPP)',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
            onPressed: () => onBonusSppRemoved(index),
            color: AppColors.textMuted,
            iconSize: 16,
          ),
        ],
      ),
    );
  }

  void _showBonusSppDialog(BuildContext context, String reason, int amount) {
    final allPlayers = [
      ...(homeTeam?.characters.where((c) => c.status == PlayerStatus.healthy).toList() ?? []),
      ...(awayTeam?.characters.where((c) => c.status == PlayerStatus.healthy).toList() ?? []),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asignar $reason',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '+$amount SPP',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allPlayers.length,
                itemBuilder: (context, index) {
                  final player = allPlayers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        '#${player.number}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      player.position,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onBonusSppAdded(BonusSppRecord(
                        playerId: player.id,
                        playerName: player.name,
                        amount: amount,
                        reason: reason,
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSpp {
  final String name;
  int touchdowns = 0;
  int casualties = 0;
  int bonus = 0;
  List<String> bonusReasons = [];

  _PlayerSpp({required this.name});

  int get total => (touchdowns * 4) + (casualties * 2) + bonus;
}

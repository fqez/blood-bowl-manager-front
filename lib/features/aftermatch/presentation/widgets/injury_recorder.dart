import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../domain/models/aftermatch.dart';

class InjuryRecorder extends StatelessWidget {
  final Team? homeTeam;
  final Team? awayTeam;
  final List<InjuryRecord> injuries;
  final ValueChanged<InjuryRecord> onInjuryAdded;
  final ValueChanged<int> onInjuryRemoved;

  const InjuryRecorder({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.injuries,
    required this.onInjuryAdded,
    required this.onInjuryRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Recorded injuries
        if (injuries.isNotEmpty) ...[
          ...injuries.asMap().entries.map((entry) =>
            _buildInjuryItem(entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        // Add injury buttons
        Row(
          children: [
            Expanded(
              child: _buildAddButton(
                context,
                team: homeTeam,
                isHome: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAddButton(
                context,
                team: awayTeam,
                isHome: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Info card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.info(PhosphorIconsStyle.fill),
                  color: AppColors.info, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solo registra lesiones que afecten al jugador (BH, SI, RSI, muerte). Las bajas normales se cuentan automáticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInjuryItem(int index, InjuryRecord injury) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getInjuryColor(injury.type),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getInjuryColor(injury.type).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getInjuryIcon(injury.type),
              color: _getInjuryColor(injury.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      injury.playerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getInjuryColor(injury.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getInjuryLabel(injury.type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getInjuryColor(injury.type),
                        ),
                      ),
                    ),
                  ],
                ),
                if (injury.details != null)
                  Text(
                    injury.details!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold)),
            onPressed: () => onInjuryRemoved(index),
            color: AppColors.error,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context, {
    required Team? team,
    required bool isHome,
  }) {
    return OutlinedButton(
      onPressed: () => _showInjuryDialog(context, team, isHome),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: AppColors.warning),
        foregroundColor: AppColors.warning,
      ),
      child: Column(
        children: [
          Icon(PhosphorIcons.firstAid(PhosphorIconsStyle.bold), size: 24),
          const SizedBox(height: 8),
          Text('Lesión ${team?.name ?? (isHome ? "Local" : "Visitante")}'),
        ],
      ),
    );
  }

  void _showInjuryDialog(BuildContext context, Team? team, bool isHome) {
    if (team == null) return;

    final players = team.characters.where((c) => c.status == PlayerStatus.healthy).toList();
    Character? selectedPlayer;
    InjuryType selectedType = InjuryType.badlyHurt;
    String? description;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar Lesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Player selector
              DropdownButtonFormField<Character>(
                decoration: InputDecoration(
                  labelText: 'Jugador lesionado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: AppColors.surface,
                items: players.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text('#${p.number} ${p.name}'),
                )).toList(),
                onChanged: (v) => setState(() => selectedPlayer = v),
              ),
              const SizedBox(height: 16),
              // Injury type
              Text(
                'Tipo de lesión',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: InjuryType.values.map((type) => ChoiceChip(
                  label: Text(_getInjuryLabel(type)),
                  selected: selectedType == type,
                  onSelected: (v) => setState(() => selectedType = type),
                  selectedColor: _getInjuryColor(type).withOpacity(0.3),
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: selectedType == type
                        ? _getInjuryColor(type)
                        : AppColors.textMuted,
                    fontSize: 12,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'ej: -1 Fuerza',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (v) => description = v,
              ),
              const SizedBox(height: 24),
              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPlayer != null
                      ? () {
                          Navigator.pop(context);
                          onInjuryAdded(InjuryRecord(
                            playerId: selectedPlayer!.id,
                            playerName: selectedPlayer!.name,
                            type: selectedType,
                            details: description,
                          ));
                        }
                      : null,
                  child: const Text('Registrar lesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getInjuryColor(InjuryType type) {
    switch (type) {
      case InjuryType.badlyHurt:
        return AppColors.warning;
      case InjuryType.missNextGame:
        return AppColors.warning;
      case InjuryType.nigglingInjury:
        return AppColors.error;
      case InjuryType.statDecrease:
        return AppColors.error;
      case InjuryType.dead:
        return AppColors.textMuted;
    }
  }

  IconData _getInjuryIcon(InjuryType type) {
    switch (type) {
      case InjuryType.badlyHurt:
        return PhosphorIcons.bandaids(PhosphorIconsStyle.fill);
      case InjuryType.missNextGame:
        return PhosphorIcons.bandaids(PhosphorIconsStyle.fill);
      case InjuryType.nigglingInjury:
        return PhosphorIcons.heartBreak(PhosphorIconsStyle.fill);
      case InjuryType.statDecrease:
        return PhosphorIcons.arrowDown(PhosphorIconsStyle.fill);
      case InjuryType.dead:
        return PhosphorIcons.skull(PhosphorIconsStyle.fill);
    }
  }

  String _getInjuryLabel(InjuryType type) {
    switch (type) {
      case InjuryType.badlyHurt:
        return 'BH';
      case InjuryType.missNextGame:
        return 'MNG';
      case InjuryType.nigglingInjury:
        return 'NI';
      case InjuryType.statDecrease:
        return 'SD';
      case InjuryType.dead:
        return 'Muerto';
    }
  }
}

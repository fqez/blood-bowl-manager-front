import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../roster/domain/models/team.dart';
import 'race_card.dart';

class TeamCreatorRaceStep extends StatelessWidget {
  const TeamCreatorRaceStep({
    super.key,
    required this.isWide,
    required this.lang,
    required this.racesAsync,
    required this.selectedRace,
    required this.onRetry,
    required this.onSelectRace,
    required this.retryLabel,
  });

  final bool isWide;
  final String lang;
  final AsyncValue<List<BaseTeam>> racesAsync;
  final BaseTeam? selectedRace;
  final VoidCallback onRetry;
  final ValueChanged<BaseTeam> onSelectRace;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return racesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar equipos',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
      data: (races) => _TeamCreatorRaceStepContent(
        isWide: isWide,
        lang: lang,
        races: races,
        selectedRace: selectedRace,
        onSelectRace: onSelectRace,
      ),
    );
  }
}

class _TeamCreatorRaceStepContent extends StatefulWidget {
  const _TeamCreatorRaceStepContent({
    required this.isWide,
    required this.lang,
    required this.races,
    required this.selectedRace,
    required this.onSelectRace,
  });

  final bool isWide;
  final String lang;
  final List<BaseTeam> races;
  final BaseTeam? selectedRace;
  final ValueChanged<BaseTeam> onSelectRace;

  @override
  State<_TeamCreatorRaceStepContent> createState() =>
      _TeamCreatorRaceStepContentState();
}

class _TeamCreatorRaceStepContentState
    extends State<_TeamCreatorRaceStepContent> {
  int? _selectedTier;

  @override
  Widget build(BuildContext context) {
    final filteredRaces = _selectedTier == null
        ? widget.races
        : widget.races.where((race) => race.tier == _selectedTier).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECCIONA UNA RAZA',
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TierFilterPill(
              label: widget.lang == 'en' ? 'ALL' : 'TODOS',
              isSelected: _selectedTier == null,
              onTap: () => setState(() => _selectedTier = null),
            ),
            for (final tier in [1, 2, 3, 4])
              _TierFilterPill(
                label: 'TIER $tier',
                tier: tier,
                isSelected: _selectedTier == tier,
                onTap: () => setState(() => _selectedTier = tier),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.isWide ? 4 : 2,
            childAspectRatio: widget.isWide ? 1.1 : 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredRaces.length,
          itemBuilder: (context, index) {
            final race = filteredRaces[index];
            return RaceCard(
              race: race,
              isSelected: widget.selectedRace?.id == race.id,
              onTap: () => widget.onSelectRace(race),
            );
          },
        ),
      ],
    );
  }
}

class _TierFilterPill extends StatelessWidget {
  const _TierFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tier,
  });

  final String label;
  final int? tier;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (tier) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.accent;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

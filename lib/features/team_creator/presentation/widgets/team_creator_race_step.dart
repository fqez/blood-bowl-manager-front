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
    required this.teamName,
    required this.onRetry,
    required this.onSelectRace,
    required this.onTeamNameChanged,
    required this.teamNameLabel,
    required this.teamNameHint,
    required this.retryLabel,
  });

  final bool isWide;
  final String lang;
  final AsyncValue<List<BaseTeam>> racesAsync;
  final BaseTeam? selectedRace;
  final String teamName;
  final VoidCallback onRetry;
  final ValueChanged<BaseTeam> onSelectRace;
  final ValueChanged<String> onTeamNameChanged;
  final String teamNameLabel;
  final String teamNameHint;
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
        teamName: teamName,
        onSelectRace: onSelectRace,
        onTeamNameChanged: onTeamNameChanged,
        teamNameLabel: teamNameLabel,
        teamNameHint: teamNameHint,
      ),
    );
  }
}

class _TeamCreatorRaceStepContent extends StatelessWidget {
  const _TeamCreatorRaceStepContent({
    required this.isWide,
    required this.lang,
    required this.races,
    required this.selectedRace,
    required this.teamName,
    required this.onSelectRace,
    required this.onTeamNameChanged,
    required this.teamNameLabel,
    required this.teamNameHint,
  });

  final bool isWide;
  final String lang;
  final List<BaseTeam> races;
  final BaseTeam? selectedRace;
  final String teamName;
  final ValueChanged<BaseTeam> onSelectRace;
  final ValueChanged<String> onTeamNameChanged;
  final String teamNameLabel;
  final String teamNameHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedRace != null) ...[
          Container(
            height: isWide ? 200 : 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/teams/${selectedRace!.id}/wallpaper.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: Icon(
                          PhosphorIcons.image(PhosphorIconsStyle.light),
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/teams/${selectedRace!.id}/logo.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                color: AppColors.textMuted,
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
                                selectedRace!.name,
                                style: context.textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  _TeamTierBadge(tier: selectedRace!.tier ?? 2),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RR ${selectedRace!.rerollCost ~/ 1000}k',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        TextField(
          decoration: InputDecoration(
            labelText: teamNameLabel,
            hintText: teamNameHint,
            prefixIcon: Icon(PhosphorIcons.flag(PhosphorIconsStyle.bold)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: onTeamNameChanged,
        ),
        const SizedBox(height: 24),
        Text(
          'SELECCIONA UNA RAZA',
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: races.length,
          itemBuilder: (context, index) {
            final race = races[index];
            return RaceCard(
              race: race,
              isSelected: selectedRace?.id == race.id,
              onTap: () => onSelectRace(race),
            );
          },
        ),
      ],
    );
  }
}

class _TeamTierBadge extends StatelessWidget {
  const _TeamTierBadge({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    final colors = {
      1: AppColors.success,
      2: AppColors.accent,
      3: AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[tier] ?? AppColors.textMuted).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Tier $tier',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colors[tier] ?? AppColors.textMuted,
        ),
      ),
    );
  }
}

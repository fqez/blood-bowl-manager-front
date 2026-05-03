import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';

class ScoreInput extends ConsumerWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final ValueChanged<int> onHomeScoreChanged;
  final ValueChanged<int> onAwayScoreChanged;

  const ScoreInput({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.onHomeScoreChanged,
    required this.onAwayScoreChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TeamScoreInput(
              teamName: homeTeamName,
              score: homeScore,
              onScoreChanged: onHomeScoreChanged,
              isHome: true,
              lang: lang,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _TeamScoreInput(
              teamName: awayTeamName,
              score: awayScore,
              onScoreChanged: onAwayScoreChanged,
              isHome: false,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreInput extends StatelessWidget {
  final String teamName;
  final int score;
  final ValueChanged<int> onScoreChanged;
  final bool isHome;
  final String lang;

  const _TeamScoreInput({
    required this.teamName,
    required this.score,
    required this.onScoreChanged,
    required this.isHome,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Column(
      children: [
        // Team icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              teamName.substring(0, 1).toUpperCase(),
              style: textTheme.displayMedium?.copyWith(
                fontSize: 28,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          teamName,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          isHome ? tr(lang, 'aftermatch.home') : tr(lang, 'aftermatch.away'),
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        // Score controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
              onPressed: score > 0 ? () => onScoreChanged(score - 1) : null,
            ),
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            _buildButton(
              icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
              onPressed: () => onScoreChanged(score + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onPressed != null
                ? AppColors.textPrimary
                : AppColors.textMuted.withOpacity(0.5),
            size: 20,
          ),
        ),
      ),
    );
  }
}

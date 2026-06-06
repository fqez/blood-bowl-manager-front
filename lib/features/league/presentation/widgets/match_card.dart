import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class MatchCard extends ConsumerWidget {
  final Match match;
  final bool expanded;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.expanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  match.isPending ? AppColors.primary : AppColors.surfaceLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatus(lang),
              const SizedBox(height: 12),
              _buildTeams(),
              if (match.isPending || match.isInProgress) ...[
                const SizedBox(height: 16),
                _buildActionButton(lang),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getStatusLabel(lang),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (match.playedAt != null)
          Text(
            _formatDate(match.playedAt!),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildTeams() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTeams = constraints.maxWidth < (expanded ? 620 : 520);

        if (stackTeams) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTeamText(
                      match.home,
                      alignEnd: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildTeamIcon(match.home.baseRosterId, match.home.teamName),
                ],
              ),
              const SizedBox(height: 10),
              _buildScore(),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTeamIcon(match.away.baseRosterId, match.away.teamName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTeamText(
                      match.away,
                      alignEnd: false,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: _buildTeamText(
                      match.home,
                      alignEnd: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildTeamIcon(match.home.baseRosterId, match.home.teamName),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildScore(),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTeamIcon(match.away.baseRosterId, match.away.teamName),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _buildTeamText(
                      match.away,
                      alignEnd: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamText(
    MatchTeamInfo team, {
    required bool alignEnd,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          team.teamName,
          style: TextStyle(
            fontSize: expanded ? 18 : 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (team.username.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            team.username,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTeamIcon(String baseRosterId, String teamName) {
    final fallbackLabel = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';
    final assetPath =
        baseRosterId.isNotEmpty ? 'assets/teams/$baseRosterId/logo.webp' : null;

    return SizedBox(
      width: expanded ? 104 : 92,
      height: expanded ? 104 : 92,
      child: assetPath == null
          ? _buildTeamFallback(fallbackLabel)
          : Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildTeamFallback(fallbackLabel),
            ),
    );
  }

  Widget _buildTeamFallback(String label) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildScore() {
    final showScore = match.isPlayed || match.isInProgress;

    return showScore
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${match.scoreHome}',
                style: TextStyle(
                  fontSize: expanded ? 28 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: expanded ? 28 : 26,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                '${match.scoreAway}',
                style: TextStyle(
                  fontSize: expanded ? 28 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          )
        : Text(
            '-',
            style: TextStyle(
              fontSize: expanded ? 28 : 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          );
  }

  Widget _buildActionButton(String lang) {
    return SizedBox(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: expanded ? 180 : 156),
          child: ElevatedButton(
            onPressed: onTap,
            style: (match.isInProgress
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      )
                    : ElevatedButton.styleFrom())
                .copyWith(
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            child: Text(match.isInProgress
                ? tr(lang, 'match.continueMatch')
                : tr(lang, 'match.startMatch')),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (match.status) {
      case 'scheduled':
      case 'pending':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel(String lang) {
    switch (match.status) {
      case 'scheduled':
      case 'pending':
        return tr(lang, 'match.pending');
      case 'in_progress':
        return tr(lang, 'match.inProgress');
      case 'completed':
        return tr(lang, 'match.completed');
      default:
        return match.status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return 'Hace ${DateTime.now().difference(date).inDays} días';
  }
}

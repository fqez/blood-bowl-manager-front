import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/league.dart';

class MatchCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              color: match.isPending ? AppColors.primary : AppColors.surfaceLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatus(),
              const SizedBox(height: 12),
              _buildTeams(),
              if (match.isPending) ...[
                const SizedBox(height: 16),
                _buildActionButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getStatusLabel(),
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
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildTeams() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildTeamIcon(match.home.teamName),
              const SizedBox(height: 8),
              Text(
                match.home.teamName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildScore(),
        Expanded(
          child: Column(
            children: [
              _buildTeamIcon(match.away.teamName),
              const SizedBox(height: 8),
              Text(
                match.away.teamName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamIcon(String teamName) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          teamName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isPlayed) ...[
            IconButton(
              icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold)),
              onPressed: null,
              iconSize: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
          ],
          Text(
            match.isPlayed ? '${match.scoreHome}' : '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            match.isPlayed ? '${match.scoreAway}' : '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (match.isPlayed) ...[
            IconButton(
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
              onPressed: null,
              iconSize: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: const Text('Registrar Post-Partido'),
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

  String _getStatusLabel() {
    switch (match.status) {
      case 'scheduled':
        return 'POR JUGAR';
      case 'pending':
        return 'PENDIENTE';
      case 'in_progress':
        return 'EN PROGRESO';
      case 'completed':
        return 'COMPLETADO';
      default:
        return match.status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return 'Hace ${DateTime.now().difference(date).inDays} días';
  }
}

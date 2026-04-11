import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

enum NotificationType {
  levelUp,
  matchResult,
  injury,
  invitation,
}

class NotificationCard extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String? actionText;
  final String? secondaryActionText;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final String? time;

  const NotificationCard({
    super.key,
    required this.type,
    required this.title,
    this.actionText,
    this.secondaryActionText,
    this.onTap,
    this.onSecondaryTap,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeIndicator(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getTypeLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (time != null)
                Text(
                  time!,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (actionText != null || secondaryActionText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (actionText != null)
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionText!,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (secondaryActionText != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onSecondaryTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.textMuted,
                    ),
                    child: Text(
                      secondaryActionText!,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeIndicator() {
    return Container(
      width: 4,
      height: 16,
      decoration: BoxDecoration(
        color: _getTypeColor(),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getTypeColor() {
    switch (type) {
      case NotificationType.levelUp:
        return AppColors.accent;
      case NotificationType.matchResult:
        return AppColors.success;
      case NotificationType.injury:
        return AppColors.warning;
      case NotificationType.invitation:
        return AppColors.info;
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case NotificationType.levelUp:
        return 'SUBIDA PENDIENTE';
      case NotificationType.matchResult:
        return 'CONFIRMACIÓN DE PARTIDO';
      case NotificationType.injury:
        return 'BAJA GRAVE';
      case NotificationType.invitation:
        return 'INVITACIÓN A LIGA';
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case NotificationType.levelUp:
        return PhosphorIcons.arrowUp(PhosphorIconsStyle.fill);
      case NotificationType.matchResult:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      case NotificationType.injury:
        return PhosphorIcons.bandaids(PhosphorIconsStyle.fill);
      case NotificationType.invitation:
        return PhosphorIcons.envelope(PhosphorIconsStyle.fill);
    }
  }
}

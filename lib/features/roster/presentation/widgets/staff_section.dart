import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class StaffSection extends StatelessWidget {
  final int rerolls;
  final int rerollCost;
  final bool hasApothecary;
  final int assistantCoaches;
  final int cheerleaders;
  final VoidCallback onBuyReroll;
  final VoidCallback onBuyApothecary;
  final VoidCallback onBuyAssistant;
  final VoidCallback onBuyCheerleader;
  final int treasury;
  final bool readOnly;

  const StaffSection({
    super.key,
    required this.rerolls,
    required this.rerollCost,
    required this.hasApothecary,
    required this.assistantCoaches,
    required this.cheerleaders,
    required this.onBuyReroll,
    required this.onBuyApothecary,
    required this.onBuyAssistant,
    required this.onBuyCheerleader,
    required this.treasury,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL & EQUIPO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStaffCard(
              icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
              label: 'Re-rolls',
              count: rerolls,
              cost: rerollCost,
              canBuy: !readOnly && treasury >= rerollCost,
              onBuy: readOnly ? null : onBuyReroll,
            ),
            _buildStaffCard(
              icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
              label: 'Apotecario',
              count: hasApothecary ? 1 : 0,
              cost: 50000,
              canBuy: !readOnly && !hasApothecary && treasury >= 50000,
              maxCount: 1,
              onBuy: (readOnly || hasApothecary) ? null : onBuyApothecary,
            ),
            _buildStaffCard(
              icon: PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill),
              label: 'Asistentes',
              count: assistantCoaches,
              cost: 10000,
              canBuy: !readOnly && treasury >= 10000,
              onBuy: readOnly ? null : onBuyAssistant,
            ),
            _buildStaffCard(
              icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
              label: 'Animadoras',
              count: cheerleaders,
              cost: 10000,
              canBuy: !readOnly && treasury >= 10000,
              onBuy: readOnly ? null : onBuyCheerleader,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffCard({
    required IconData icon,
    required String label,
    required int count,
    required int cost,
    required bool canBuy,
    int? maxCount,
    VoidCallback? onBuy,
  }) {
    final isMaxed = maxCount != null && count >= maxCount;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? AppColors.accent : AppColors.textMuted,
                ),
              ),
              if (maxCount != null) ...[
                Text(
                  '/$maxCount',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (!isMaxed && onBuy != null)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton(
                onPressed: canBuy ? onBuy : null,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: canBuy ? AppColors.accent : AppColors.surfaceLight,
                  ),
                  foregroundColor: canBuy ? AppColors.accent : AppColors.textMuted,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${cost ~/ 1000}k',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else if (isMaxed)
            Container(
              height: 32,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Completo',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

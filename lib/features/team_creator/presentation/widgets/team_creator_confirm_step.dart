import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';

class TeamCreatorConfirmStep extends StatelessWidget {
  const TeamCreatorConfirmStep({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.raceName,
    required this.rosterCount,
    required this.rerolls,
    required this.apothecary,
    required this.dedicatedFans,
    required this.spent,
    required this.remaining,
    required this.isValidRoster,
    this.favouredOfLabel,
  });

  final String? teamId;
  final String teamName;
  final String raceName;
  final int rosterCount;
  final int rerolls;
  final bool apothecary;
  final int dedicatedFans;
  final int spent;
  final int remaining;
  final bool isValidRoster;
  final String? favouredOfLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedTeamName = teamName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            return Column(
              children: [
                SizedBox(
                  height: compact ? 210 : 280,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: compact ? 10 : 14,
                        child: Container(
                          width: compact ? 210 : 310,
                          height: compact ? 22 : 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.38),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/teams/$teamId/wallpaper.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          PhosphorIcons.image(PhosphorIconsStyle.light),
                          size: compact ? 72 : 96,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _ConfirmTeamName(text: resolvedTeamName),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/teams/$teamId/logo.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            PhosphorIcons.shield(PhosphorIconsStyle.fill),
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        raceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MoneyItem(
                icon: PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
                label: 'VALOR DEL EQUIPO',
                value: formatBudget(spent),
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneyItem(
                icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
                label: 'TESORERÍA',
                value: formatBudget(remaining),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryItem(
              icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
              label: 'Jugadores',
              value: '$rosterCount',
              color: AppColors.primary,
            ),
            _SummaryItem(
              icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
              label: 'Re-rolls',
              value: '$rerolls',
              color: AppColors.accent,
            ),
            _SummaryItem(
              icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
              label: 'Hinchas',
              value: '$dedicatedFans',
              color: AppColors.warning,
            ),
            _SummaryItem(
              icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
              label: 'Apotecario',
              value: apothecary ? 'Sí' : 'No',
              color: apothecary ? AppColors.success : AppColors.textMuted,
            ),
            if (favouredOfLabel != null)
              _SummaryItem(
                icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                label: 'Favorito',
                value: favouredOfLabel!,
                color: AppColors.primary,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceLight),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface.withOpacity(0.9),
                AppColors.card.withOpacity(0.72),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                isValidRoster
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                color: isValidRoster ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isValidRoster
                      ? 'Listo para crear la plantilla.'
                      : 'El equipo necesita al menos 11 jugadores para poder jugar.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isValidRoster ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmTeamName extends StatelessWidget {
  const _ConfirmTeamName({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final fontSize = (maxWidth / 10).clamp(46.0, 82.0);
        final fillStyle = TextStyle(
          fontFamily: 'RugbySquadOutline',
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
          height: 0.9,
          foreground: Paint()
            ..shader = const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFDB927), Color(0xFF552583)],
              stops: [0.1, 0.72],
            ).createShader(Rect.fromLTWH(0, 0, maxWidth, fontSize * 2)),
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.82),
              blurRadius: 9,
              offset: const Offset(0, 2),
            ),
          ],
        );
        final strokeStyle = fillStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (fontSize * 0.045).clamp(2.2, 4.0)
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.black.withOpacity(0.95),
          shadows: null,
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: strokeStyle,
            ),
            Text(
              text.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: fillStyle,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyItem extends StatelessWidget {
  const _MoneyItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: color,
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

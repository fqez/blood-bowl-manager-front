import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';

class TeamHeroHeader extends StatelessWidget {
  const TeamHeroHeader({
    super.key,
    required this.rosterId,
    required this.rosterName,
    required this.teamName,
    required this.rerollCost,
    this.tier,
    this.trailing,
    this.height = 320,
    this.teamNameFontFamily = 'Teko',
    this.teamNameColor = const Color.fromARGB(255, 255, 0, 0),
    this.teamNameFontWeight = FontWeight.w600,
    this.teamNameGradient,
    this.teamNameFontSize,
    this.teamNameCompactFontSize,
  });

  final String rosterId;
  final String rosterName;
  final String teamName;
  final int rerollCost;
  final int? tier;
  final Widget? trailing;
  final double height;
  final String teamNameFontFamily;
  final Color teamNameColor;
  final FontWeight teamNameFontWeight;
  final Gradient? teamNameGradient;
  final double? teamNameFontSize;
  final double? teamNameCompactFontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final horizontalPadding = compact ? 16.0 : 24.0;
        final displayName = teamName.trim().isNotEmpty ? teamName : rosterName;

        return Container(
          height: compact ? 260 : height,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(color: AppColors.background),
              Positioned(
                right: compact ? -90 : -20,
                top: compact ? 0 : -30,
                bottom: compact ? 10 : -20,
                child: Image.asset(
                  'assets/teams/$rosterId/wallpaper.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    colors: [
                      AppColors.background,
                      AppColors.background.withOpacity(0.6),
                      AppColors.background.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.background],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: horizontalPadding,
                child: _TeamIdentityCard(
                  rosterId: rosterId,
                  rosterName: rosterName,
                  tier: tier ?? 2,
                  rerollCost: rerollCost,
                ),
              ),
              if (trailing != null)
                Positioned(
                  top: 20,
                  right: horizontalPadding,
                  child: trailing!,
                ),
              Positioned(
                left: horizontalPadding,
                right: compact ? horizontalPadding : 200,
                bottom: 24,
                child: _TeamNameText(
                  text: displayName.toUpperCase(),
                  fontFamily: teamNameFontFamily,
                  color: teamNameColor,
                  fontSize: compact
                      ? (teamNameCompactFontSize ?? 42)
                      : (teamNameFontSize ?? 52),
                  fontWeight: teamNameFontWeight,
                  gradient: teamNameGradient,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamNameText extends StatelessWidget {
  const _TeamNameText({
    required this.text,
    required this.fontFamily,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
    this.gradient,
  });

  final String text;
  final String fontFamily;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final responsiveFontSize = _resolveFontSize(context, maxWidth);
        final textHeight = responsiveFontSize * 2.15;

        final fillStyle = TextStyle(
          fontFamily: fontFamily,
          fontSize: responsiveFontSize,
          fontWeight: fontWeight,
          color: gradient == null ? color : null,
          foreground: gradient == null
              ? null
              : (Paint()
                ..shader = gradient!.createShader(
                  Rect.fromLTWH(0, 0, maxWidth, textHeight),
                )),
          letterSpacing: 2,
          height: 0.95,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

        if (gradient == null) {
          return Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: fillStyle,
          );
        }

        final strokeStyle = fillStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (responsiveFontSize * 0.045).clamp(2.4, 4.5)
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.black.withOpacity(0.95),
          shadows: null,
        );

        return Stack(
          children: [
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: strokeStyle,
            ),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: fillStyle,
            ),
          ],
        );
      },
    );
  }

  double _resolveFontSize(BuildContext context, double maxWidth) {
    final minFontSize = (fontSize * 0.58).clamp(34.0, fontSize);
    var low = minFontSize;
    var high = fontSize;

    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (_fits(context, maxWidth, mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return low;
  }

  bool _fits(BuildContext context, double maxWidth, double testFontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: testFontSize,
          fontWeight: fontWeight,
          letterSpacing: 2,
          height: 0.95,
        ),
      ),
      maxLines: 2,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);

    return !painter.didExceedMaxLines;
  }
}

class _TeamIdentityCard extends StatelessWidget {
  const _TeamIdentityCard({
    required this.rosterId,
    required this.rosterName,
    required this.tier,
    required this.rerollCost,
  });

  final String rosterId;
  final String rosterName;
  final int tier;
  final int rerollCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/teams/$rosterId/logo.webp',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  PhosphorIcons.shield(PhosphorIconsStyle.fill),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rosterName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _TierBadge(tier: tier),
                  const SizedBox(width: 8),
                  Text(
                    'RR ${formatBudget(rerollCost)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    final colors = {
      1: AppColors.success,
      2: AppColors.accent,
      3: AppColors.warning,
    };
    final color = colors[tier] ?? AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Tier $tier',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

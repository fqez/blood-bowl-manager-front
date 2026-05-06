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
  });

  final String rosterId;
  final String rosterName;
  final String teamName;
  final int rerollCost;
  final int? tier;
  final Widget? trailing;
  final double height;

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
                child: Text(
                  displayName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Teko',
                    fontSize: compact ? 42 : 52,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

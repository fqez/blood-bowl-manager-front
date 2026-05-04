import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class WikiPageTopBar extends StatelessWidget {
  const WikiPageTopBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 14 : 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              PhosphorIcons.book(PhosphorIconsStyle.fill),
              color: AppColors.accent,
              size: isCompact ? 24 : 30,
            ),
            const SizedBox(width: 10),
            Text(
              'WIKI',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: isCompact ? 22 : 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(width: isCompact ? 12 : 14),
            if (!isCompact) ...[
              const Text(
                '>',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: isCompact ? 18 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WikiPageHeroHeader extends StatelessWidget {
  const WikiPageHeroHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.gradientColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color gradientColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final useCompact = isCompact || compact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(useCompact ? 16 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            gradientColor.withOpacity(0.32),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(
          useCompact ? 16 : AppDimensions.radiusXl,
        ),
        border: Border.all(color: gradientColor.withOpacity(0.34)),
      ),
      child: useCompact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.1,
                          height: 1,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 42),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2.6,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }
}

class WikiContentScale extends StatelessWidget {
  const WikiContentScale({
    super.key,
    required this.child,
    this.scale = 1.1,
  });

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}

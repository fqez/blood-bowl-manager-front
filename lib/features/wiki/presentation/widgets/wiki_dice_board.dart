import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

typedef WikiDiceBoardDescriptionBuilder = Widget Function(
  BuildContext context,
  WikiDiceBoardEntry entry,
  double fontSize,
);

class WikiDiceBoardEntry {
  final String roll;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? iconAssetPath;
  final Color color;
  final String description;

  const WikiDiceBoardEntry({
    required this.roll,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAssetPath,
    required this.color,
    required this.description,
  }) : assert(icon != null || iconAssetPath != null);
}

class WikiDiceBoard extends StatelessWidget {
  const WikiDiceBoard({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.diceAssetPath,
    required this.entries,
    this.descriptionBuilder,
    this.compactBreakpoint = 860,
    this.compactRowHeight = 108,
    this.desktopRowHeight = 96,
    this.compactDiceSize = 208,
    this.desktopDiceSize = 216,
    this.desktopDiceColumnWidth = 244,
    this.rowSpacing = 12,
    this.showRollCircle = true,
    this.inlineRollBadgeWhenHidden = true,
    this.compactRowIconScale = 0.42,
    this.desktopRowIconScale = 0.44,
    this.rollTextScale = 0.34,
  });

  final IconData headerIcon;
  final String title;
  final String subtitle;
  final String diceAssetPath;
  final List<WikiDiceBoardEntry> entries;
  final WikiDiceBoardDescriptionBuilder? descriptionBuilder;
  final double compactBreakpoint;
  final double compactRowHeight;
  final double desktopRowHeight;
  final double compactDiceSize;
  final double desktopDiceSize;
  final double desktopDiceColumnWidth;
  final double rowSpacing;
  final bool showRollCircle;
  final bool inlineRollBadgeWhenHidden;
  final double compactRowIconScale;
  final double desktopRowIconScale;
  final double rollTextScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: AppTypography.wikiSectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < compactBreakpoint;
              final rowHeight = compact ? compactRowHeight : desktopRowHeight;
              final desktopBoardHeight = entries.length * rowHeight +
                  (entries.length - 1) * rowSpacing;

              if (compact) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Center(
                        child: _buildDiceImage(compactDiceSize),
                      ),
                    ),
                    ...entries.map(
                      (entry) => _buildBoardRow(
                        context,
                        entry,
                        rowHeight: rowHeight,
                        compact: true,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: desktopDiceColumnWidth,
                    height: desktopBoardHeight,
                    child: Center(
                      child: _buildDiceImage(desktopDiceSize),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        ...entries.map(
                          (entry) => _buildBoardRow(
                            context,
                            entry,
                            rowHeight: rowHeight,
                            compact: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoardRow(
    BuildContext context,
    WikiDiceBoardEntry entry, {
    required double rowHeight,
    required bool compact,
  }) {
    final circleSize = rowHeight;
    final titleFontSize = compact ? 18.0 : 20.0;
    final subtitleFontSize = compact ? 11.0 : 12.0;
    final descriptionFontSize = compact ? 11.5 : 12.5;
    final iconSize =
        rowHeight * (compact ? compactRowIconScale : desktopRowIconScale);

    return Padding(
      padding: EdgeInsets.only(bottom: rowSpacing),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showRollCircle) ...[
              _buildRollCircle(entry, size: circleSize),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: entry.color.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      entry.color.withOpacity(0.12),
                      AppColors.surface,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 10 : 11,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: compact ? 12 : 14),
                        child: entry.iconAssetPath != null
                            ? Image.asset(
                                entry.iconAssetPath!,
                                width: iconSize,
                                height: iconSize,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              )
                            : Icon(
                                entry.icon,
                                color: entry.color,
                                size: iconSize,
                              ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (!showRollCircle &&
                                    inlineRollBadgeWhenHidden)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entry.color.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: entry.color.withOpacity(0.32),
                                      ),
                                    ),
                                    child: Text(
                                      entry.roll,
                                      style: TextStyle(
                                        fontFamily:
                                            AppTypography.displayFontFamily,
                                        fontSize: subtitleFontSize + 1,
                                        fontWeight: FontWeight.w900,
                                        color: entry.color,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                Text(
                                  entry.title,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFontFamily,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: entry.color,
                                    letterSpacing: 0.8,
                                    height: 1,
                                  ),
                                ),
                                if ((entry.subtitle ?? '').isNotEmpty)
                                  Text(
                                    entry.subtitle!,
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                      height: 1,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: descriptionBuilder != null
                                    ? descriptionBuilder!(
                                        context,
                                        entry,
                                        descriptionFontSize,
                                      )
                                    : Text(
                                        entry.description,
                                        maxLines: compact ? 3 : 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: descriptionFontSize,
                                          color: AppColors.textSecondary,
                                          height: 1.32,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiceImage(double size) {
    return Image.asset(
      diceAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }

  Widget _buildRollCircle(WikiDiceBoardEntry entry, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: entry.color.withOpacity(0.14),
        border: Border.all(color: entry.color.withOpacity(0.45), width: 2),
        boxShadow: [
          BoxShadow(
            color: entry.color.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          entry.roll,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.displayFontFamily,
            fontSize: size * rollTextScale,
            fontWeight: FontWeight.w900,
            color: entry.color,
            height: 0.95,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

typedef WikiTimelineDescriptionBuilder = Widget Function(
  BuildContext context,
  WikiTimelineEntry entry,
  double fontSize,
);

class WikiTimelineEntry {
  final String marker;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String description;

  const WikiTimelineEntry({
    required this.marker,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class WikiTimelineSection extends StatelessWidget {
  const WikiTimelineSection({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.entries,
    this.descriptionBuilder,
    this.railWidth = 64,
    this.circleSize = 38,
    this.lineWidth = 6,
    this.itemSpacing = 14,
    this.showMarkerLabel = false,
    this.railColor,
    this.circleLineGap = 6,
  });

  final IconData headerIcon;
  final String title;
  final String subtitle;
  final List<WikiTimelineEntry> entries;
  final WikiTimelineDescriptionBuilder? descriptionBuilder;
  final double railWidth;
  final double circleSize;
  final double lineWidth;
  final double itemSpacing;
  final bool showMarkerLabel;
  final Color? railColor;
  final double circleLineGap;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              _buildEntry(
                context,
                entries[i],
                isFirst: i == 0,
                isLast: i == entries.length - 1,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntry(
    BuildContext context,
    WikiTimelineEntry entry, {
    required bool isFirst,
    required bool isLast,
  }) {
    final titleFontSize = 18.0;
    final subtitleFontSize = 11.0;
    final descriptionFontSize = 12.0;
    final effectiveRailColor = railColor ?? entry.color;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: railWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: isFirst
                            ? const SizedBox.shrink()
                            : _buildLineFill(effectiveRailColor),
                      ),
                      if (!isFirst) SizedBox(height: circleLineGap),
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.color,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: entry.color.withOpacity(0.26),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: showMarkerLabel
                            ? Center(
                                child: Text(
                                  entry.marker,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (!isLast) SizedBox(height: circleLineGap),
                      Expanded(
                        child: isLast
                            ? const SizedBox.shrink()
                            : _buildLineFill(effectiveRailColor),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        entry.color.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: entry.color.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(entry.icon, color: entry.color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  entry.title,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFontFamily,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: entry.color,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if ((entry.subtitle ?? '').isNotEmpty)
                                  Text(
                                    entry.subtitle!,
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      descriptionBuilder != null
                          ? descriptionBuilder!(
                              context, entry, descriptionFontSize)
                          : Text(
                              entry.description,
                              style: TextStyle(
                                fontSize: descriptionFontSize,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          SizedBox(
            height: itemSpacing,
            child: Row(
              children: [
                SizedBox(
                  width: railWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildLineFill(effectiveRailColor),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLineFill(Color color) {
    return FractionallySizedBox(
      widthFactor: lineWidth / railWidth,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

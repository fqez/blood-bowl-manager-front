import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'wiki_page_chrome.dart';

class WikiPageLayout extends StatelessWidget {
  const WikiPageLayout({
    super.key,
    required this.title,
    required this.heroIcon,
    required this.subtitle,
    required this.accentColor,
    required this.gradientColor,
    required this.child,
    this.contentScale = 1.1,
    this.contentPadding = const EdgeInsets.all(24),
    this.headerSpacing = 28,
  });

  final String title;
  final IconData heroIcon;
  final String subtitle;
  final Color accentColor;
  final Color gradientColor;
  final Widget child;
  final double contentScale;
  final EdgeInsetsGeometry contentPadding;
  final double headerSpacing;

  static BorderRadius get cardRadius =>
      BorderRadius.circular(AppDimensions.radiusMd);

  static BorderRadius get panelRadius =>
      BorderRadius.circular(AppDimensions.radiusSm);

  static BorderRadius get heroRadius =>
      BorderRadius.circular(AppDimensions.radiusXl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WikiPageTopBar(title: title),
          Expanded(
            child: SingleChildScrollView(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WikiPageHeroHeader(
                    icon: heroIcon,
                    title: title,
                    subtitle: subtitle,
                    accentColor: accentColor,
                    gradientColor: gradientColor,
                  ),
                  SizedBox(height: headerSpacing),
                  WikiContentScale(
                    scale: contentScale,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

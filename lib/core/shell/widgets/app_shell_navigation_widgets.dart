import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';
import '../../l10n/translations.dart';
import '../../../features/auth/data/providers/auth_provider.dart';

class AppShellNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? route;

  const AppShellNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.route,
  });
}

class AppShellSideNav extends ConsumerWidget {
  const AppShellSideNav({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onNavigate,
  });

  final List<AppShellNavItem> navItems;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? 220 : 64,
      color: AppColors.surface,
      child: Column(
        children: [
          AppShellHeader(
            expanded: expanded,
            onExpand: () => onExpandedChanged(true),
            onCollapse: () => onExpandedChanged(false),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _AppShellNavTile(
                  index: AppShellNavIndexes.myLeagues,
                  item: navItems[AppShellNavIndexes.myLeagues],
                  selectedIndex: selectedIndex,
                  expanded: expanded,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.myTeams,
                  item: navItems[AppShellNavIndexes.myTeams],
                  selectedIndex: selectedIndex,
                  expanded: expanded,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.createTeam,
                  item: navItems[AppShellNavIndexes.createTeam],
                  selectedIndex: selectedIndex,
                  expanded: expanded,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.myTactics,
                  item: navItems[AppShellNavIndexes.myTactics],
                  selectedIndex: selectedIndex,
                  expanded: expanded,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.quickMatch,
                  item: navItems[AppShellNavIndexes.quickMatch],
                  selectedIndex: selectedIndex,
                  expanded: expanded,
                  onNavigate: onNavigate,
                ),
                const Divider(height: 32),
                if (expanded)
                  _AppShellSectionLabel(label: tr(lang, 'nav.wiki')),
                ..._buildTiles([
                  AppShellNavIndexes.wikiSkills,
                  AppShellNavIndexes.wikiWeather,
                  AppShellNavIndexes.wikiStars,
                  AppShellNavIndexes.wikiInjuries,
                  AppShellNavIndexes.wikiBlocking,
                  AppShellNavIndexes.wikiPassing,
                  AppShellNavIndexes.wikiAchievements,
                  AppShellNavIndexes.tactics,
                ]),
                const Divider(height: 32),
                if (expanded)
                  _AppShellSectionLabel(label: tr(lang, 'nav.activeLeague')),
                ..._buildTiles([
                  AppShellNavIndexes.leagueView,
                  AppShellNavIndexes.roster,
                  AppShellNavIndexes.player,
                  AppShellNavIndexes.postMatch,
                  AppShellNavIndexes.liveMatch,
                ]),
              ],
            ),
          ),
          AppShellUserSection(expanded: expanded),
        ],
      ),
    );
  }

  List<Widget> _buildTiles(List<int> indexes) {
    return indexes
        .map(
          (index) => _AppShellNavTile(
            index: index,
            item: navItems[index],
            selectedIndex: selectedIndex,
            expanded: expanded,
            onNavigate: onNavigate,
          ),
        )
        .toList();
  }
}

class AppShellBottomNav extends ConsumerWidget {
  const AppShellBottomNav({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final List<AppShellNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomItems = [
      navItems[AppShellNavIndexes.myLeagues],
      navItems[AppShellNavIndexes.myTeams],
      navItems[AppShellNavIndexes.leagueView],
      navItems[AppShellNavIndexes.liveMatch],
    ];
    final bottomIndices = [
      AppShellNavIndexes.myLeagues,
      AppShellNavIndexes.myTeams,
      AppShellNavIndexes.leagueView,
      AppShellNavIndexes.liveMatch,
    ];
    final clampedIndex = bottomIndices.contains(selectedIndex)
        ? bottomIndices.indexOf(selectedIndex)
        : 0;
    final lang = ref.watch(localeProvider);

    return BottomNavigationBar(
      currentIndex: clampedIndex,
      onTap: (index) {
        final route = bottomItems[index].route;
        if (route != null) onNavigate(route);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
          label: tr(lang, 'nav.home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill)),
          label: tr(lang, 'nav.league'),
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.shield(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill)),
          label: tr(lang, 'nav.myTeams'),
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
          label: tr(lang, 'nav.create'),
        ),
      ],
    );
  }
}

class AppShellDrawer extends ConsumerWidget {
  const AppShellDrawer({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final List<AppShellNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          const AppShellHeader(expanded: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _AppShellNavTile(
                  index: AppShellNavIndexes.myLeagues,
                  item: navItems[AppShellNavIndexes.myLeagues],
                  selectedIndex: selectedIndex,
                  expanded: true,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.myTeams,
                  item: navItems[AppShellNavIndexes.myTeams],
                  selectedIndex: selectedIndex,
                  expanded: true,
                  onNavigate: onNavigate,
                ),
                _AppShellNavTile(
                  index: AppShellNavIndexes.createTeam,
                  item: navItems[AppShellNavIndexes.createTeam],
                  selectedIndex: selectedIndex,
                  expanded: true,
                  onNavigate: onNavigate,
                ),
                const Divider(height: 32),
                _AppShellSectionLabel(label: tr(lang, 'nav.wiki')),
                ..._buildTiles([
                  AppShellNavIndexes.wikiSkills,
                  AppShellNavIndexes.wikiWeather,
                  AppShellNavIndexes.wikiStars,
                  AppShellNavIndexes.wikiInjuries,
                  AppShellNavIndexes.wikiBlocking,
                  AppShellNavIndexes.wikiPassing,
                  AppShellNavIndexes.wikiAchievements,
                ]),
                const Divider(height: 32),
                _AppShellSectionLabel(label: tr(lang, 'nav.activeLeague')),
                ..._buildTiles([
                  AppShellNavIndexes.leagueView,
                  AppShellNavIndexes.roster,
                  AppShellNavIndexes.player,
                  AppShellNavIndexes.postMatch,
                  AppShellNavIndexes.liveMatch,
                ]),
              ],
            ),
          ),
          const AppShellUserSection(expanded: true),
        ],
      ),
    );
  }

  List<Widget> _buildTiles(List<int> indexes) {
    return indexes
        .map(
          (index) => _AppShellNavTile(
            index: index,
            item: navItems[index],
            selectedIndex: selectedIndex,
            expanded: true,
            onNavigate: onNavigate,
          ),
        )
        .toList();
  }
}

class AppShellHeader extends ConsumerWidget {
  const AppShellHeader({
    super.key,
    required this.expanded,
    this.onExpand,
    this.onCollapse,
  });

  final bool expanded;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final logo = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.sports_football,
        color: AppColors.textPrimary,
      ),
    );

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            logo,
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onExpand,
              color: AppColors.textMuted,
              iconSize: 18,
              tooltip: tr(lang, 'nav.expand'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLOOD BOWL',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                    height: 1,
                  ),
                ),
                Text(
                  'LEAGUE MANAGER',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          if (onCollapse != null)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onCollapse,
              color: AppColors.textMuted,
              iconSize: 18,
              tooltip: tr(lang, 'nav.collapse'),
            ),
        ],
      ),
    );
  }
}

class AppShellUserSection extends ConsumerWidget {
  const AppShellUserSection({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull?.user;
    final initial = user?.username.substring(0, 1).toUpperCase() ?? 'U';

    if (!expanded) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceLight)),
        ),
        child: Center(
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'Coach',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'TV: --',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const _AppShellLangToggle(),
          IconButton(
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
            onPressed: () {},
            iconSize: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _AppShellNavTile extends StatelessWidget {
  const _AppShellNavTile({
    required this.index,
    required this.item,
    required this.selectedIndex,
    required this.expanded,
    required this.onNavigate,
  });

  final int index;
  final AppShellNavItem item;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isDisabled = item.route == null;
    final iconColor = isDisabled
        ? AppColors.textMuted.withOpacity(0.35)
        : isSelected
            ? AppColors.primary
            : AppColors.textSecondary;

    return Tooltip(
      message: expanded ? '' : item.label,
      preferBelow: false,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: expanded ? 8 : 4,
          vertical: 2,
        ),
        child: Material(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isDisabled ? null : () => onNavigate(item.route!),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12 : 0,
                vertical: 10,
              ),
              child: expanded
                  ? Row(
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 20,
                          color: iconColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: iconColor,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShellSectionLabel extends StatelessWidget {
  const _AppShellSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.displayFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _AppShellLangToggle extends ConsumerWidget {
  const _AppShellLangToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);

    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).state = lang == 'es' ? 'en' : 'es';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          lang.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

abstract final class AppShellNavIndexes {
  static const int myLeagues = 0;
  static const int myTeams = 1;
  static const int leagueView = 2;
  static const int roster = 3;
  static const int player = 4;
  static const int postMatch = 5;
  static const int liveMatch = 6;
  static const int createTeam = 7;
  static const int wikiSkills = 8;
  static const int wikiWeather = 9;
  static const int wikiStars = 10;
  static const int wikiInjuries = 11;
  static const int wikiBlocking = 12;
  static const int wikiPassing = 13;
  static const int wikiAchievements = 14;
  static const int tactics = 15;
  static const int myTactics = 16;
  static const int quickMatch = 17;
}

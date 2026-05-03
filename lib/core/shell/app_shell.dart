import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../../features/live_match/data/active_match_provider.dart';
import 'widgets/app_shell_navigation_widgets.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarExpanded = true;

  List<AppShellNavItem> _buildNavItems(String location, String lang) {
    final leagueMatch = RegExp(r'/league/([^/]+)').firstMatch(location);
    final teamMatch = RegExp(r'/team/([^/]+)').firstMatch(location);
    final playerMatch = RegExp(r'/player/([^/]+)').firstMatch(location);
    final matchMatch = RegExp(r'/match/([^/]+)').firstMatch(location);

    final leagueId = leagueMatch?.group(1);
    final teamId = teamMatch?.group(1);
    final playerId = playerMatch?.group(1);
    final matchId = matchMatch?.group(1);

    // Use persisted active match context when URL doesn't contain match info
    final activeMatch = ref.watch(activeMatchProvider);
    final liveLeagueId = leagueId ?? activeMatch?.leagueId;
    final liveMatchId = matchId ?? activeMatch?.matchId;

    return [
      AppShellNavItem(
        icon: PhosphorIcons.house(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myLeagues'),
        route: '/leagues',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.shield(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myTeams'),
        route: '/teams',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.leagueView'),
        route: leagueId != null ? '/league/$leagueId' : null,
      ),
      AppShellNavItem(
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.roster'),
        route: (leagueId != null && teamId != null)
            ? '/league/$leagueId/team/$teamId'
            : null,
      ),
      AppShellNavItem(
        icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.player'),
        route: (leagueId != null && teamId != null && playerId != null)
            ? '/league/$leagueId/team/$teamId/player/$playerId'
            : null,
      ),
      AppShellNavItem(
        icon: PhosphorIcons.football(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.postMatch'),
        route: (leagueId != null && matchId != null)
            ? '/league/$leagueId/match/$matchId/aftermatch'
            : null,
      ),
      AppShellNavItem(
        icon: PhosphorIcons.playCircle(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.liveMatch'),
        route: (liveLeagueId != null && liveMatchId != null)
            ? '/league/$liveLeagueId/match/$liveMatchId/live'
            : null,
      ),
      AppShellNavItem(
        icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.createTeam'),
        route: '/create-team',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.book(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiSkills'),
        route: '/wiki/skills',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiWeather'),
        route: '/wiki/weather',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.star(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.star(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiStars'),
        route: '/wiki/star-players',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.heartBreak(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.heartBreak(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiInjuries'),
        route: '/wiki/injuries',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.handFist(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.handFist(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiBlocking'),
        route: '/wiki/blocking',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.football(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiPassing'),
        route: '/wiki/passing',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiAchievements'),
        route: '/wiki/achievements',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.crosshair(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.crosshair(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.tactics'),
        route: '/tactics',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.folder(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.folder(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myTactics'),
        route: '/my-tactics',
      ),
      AppShellNavItem(
        icon: PhosphorIcons.sword(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.sword(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.quickMatch'),
        route: '/quick-match',
      ),
    ];
  }

  int _resolveSelectedIndex(String location) {
    if (location.startsWith('/quick-match'))
      return AppShellNavIndexes.quickMatch;
    if (location.startsWith('/my-tactics')) return AppShellNavIndexes.myTactics;
    if (location.startsWith('/tactics')) return AppShellNavIndexes.tactics;
    if (location.startsWith('/wiki/achievements')) {
      return AppShellNavIndexes.wikiAchievements;
    }
    if (location.startsWith('/wiki/passing'))
      return AppShellNavIndexes.wikiPassing;
    if (location.startsWith('/wiki/blocking'))
      return AppShellNavIndexes.wikiBlocking;
    if (location.startsWith('/wiki/injuries'))
      return AppShellNavIndexes.wikiInjuries;
    if (location.startsWith('/wiki/star-players'))
      return AppShellNavIndexes.wikiStars;
    if (location.startsWith('/wiki/weather'))
      return AppShellNavIndexes.wikiWeather;
    if (location.startsWith('/wiki')) return AppShellNavIndexes.wikiSkills;
    if (location.startsWith('/leagues')) return AppShellNavIndexes.myLeagues;
    if (location.startsWith('/dashboard')) return AppShellNavIndexes.myLeagues;
    if (location.startsWith('/teams')) return AppShellNavIndexes.myTeams;
    if (location.contains('/player/')) return AppShellNavIndexes.player;
    if (location.contains('/live')) return AppShellNavIndexes.liveMatch;
    if (location.contains('/aftermatch')) return AppShellNavIndexes.postMatch;
    if (location.contains('/team/')) return AppShellNavIndexes.roster;
    if (location.contains('/league/')) return AppShellNavIndexes.leagueView;
    if (location.startsWith('/create-team'))
      return AppShellNavIndexes.createTeam;
    return AppShellNavIndexes.myLeagues;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    final location = GoRouterState.of(context).uri.toString();
    final lang = ref.watch(localeProvider);
    final navItems = _buildNavItems(location, lang);
    final selectedIndex = _resolveSelectedIndex(location);

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            AppShellSideNav(
              navItems: navItems,
              selectedIndex: selectedIndex,
              expanded: _sidebarExpanded,
              onExpandedChanged: (expanded) {
                setState(() => _sidebarExpanded = expanded);
              },
              onNavigate: context.go,
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : AppShellBottomNav(
              navItems: navItems,
              selectedIndex: selectedIndex,
              onNavigate: context.go,
            ),
      drawer: isWideScreen
          ? null
          : AppShellDrawer(
              navItems: navItems,
              selectedIndex: selectedIndex,
              onNavigate: context.go,
            ),
    );
  }
}

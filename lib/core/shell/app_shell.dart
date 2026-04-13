import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/live_match/data/active_match_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarExpanded = true;

  List<_NavItem> _buildNavItems(String location, String lang) {
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
      _NavItem(
        icon: PhosphorIcons.house(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myLeagues'),
        route: '/leagues',
      ),
      _NavItem(
        icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.shield(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myTeams'),
        route: '/teams',
      ),
      _NavItem(
        icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.leagueView'),
        route: leagueId != null ? '/league/$leagueId' : null,
      ),
      _NavItem(
        icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.roster'),
        route: (leagueId != null && teamId != null)
            ? '/league/$leagueId/team/$teamId'
            : null,
      ),
      _NavItem(
        icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.player'),
        route: (leagueId != null && teamId != null && playerId != null)
            ? '/league/$leagueId/team/$teamId/player/$playerId'
            : null,
      ),
      _NavItem(
        icon: PhosphorIcons.football(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.football(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.postMatch'),
        route: (leagueId != null && matchId != null)
            ? '/league/$leagueId/match/$matchId/aftermatch'
            : null,
      ),
      _NavItem(
        icon: PhosphorIcons.playCircle(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.liveMatch'),
        route: (liveLeagueId != null && liveMatchId != null)
            ? '/league/$liveLeagueId/match/$liveMatchId/live'
            : null,
      ),
      _NavItem(
        icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.createTeam'),
        route: '/create-team',
      ),
      _NavItem(
        icon: PhosphorIcons.book(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.book(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiSkills'),
        route: '/wiki/skills',
      ),
      _NavItem(
        icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiWeather'),
        route: '/wiki/weather',
      ),
      _NavItem(
        icon: PhosphorIcons.star(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.star(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.wikiStars'),
        route: '/wiki/star-players',
      ),
      _NavItem(
        icon: PhosphorIcons.crosshair(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.crosshair(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.tactics'),
        route: '/tactics',
      ),
      _NavItem(
        icon: PhosphorIcons.folder(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.folder(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.myTactics'),
        route: '/my-tactics',
      ),
      _NavItem(
        icon: PhosphorIcons.sword(PhosphorIconsStyle.regular),
        selectedIcon: PhosphorIcons.sword(PhosphorIconsStyle.fill),
        label: tr(lang, 'nav.quickMatch'),
        route: '/quick-match',
      ),
    ];
  }
  // indices: 0=Mis Ligas, 1=Mis Equipos, 2=Vista de Liga, 3=Plantilla, 4=Jugador, 5=Post-Partido, 6=Live Match, 7=Crear Equipo, 8=Wiki Skills, 9=Wiki Clima, 10=Wiki Estrellas, 11=Tácticas, 12=Mis Tácticas, 13=Partido Rápido

  int _resolveSelectedIndex(String location) {
    if (location.startsWith('/quick-match')) return 13;
    if (location.startsWith('/my-tactics')) return 12;
    if (location.startsWith('/tactics')) return 11;
    if (location.startsWith('/wiki/star-players')) return 10;
    if (location.startsWith('/wiki/weather')) return 9;
    if (location.startsWith('/wiki')) return 8;
    if (location.startsWith('/leagues')) return 0;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/teams')) return 1;
    if (location.contains('/player/')) return 4;
    if (location.contains('/live')) return 6;
    if (location.contains('/aftermatch')) return 5;
    if (location.contains('/team/')) return 3;
    if (location.contains('/league/')) return 2;
    if (location.startsWith('/create-team')) return 7;
    return 0;
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
          if (isWideScreen) _buildSideNav(navItems, selectedIndex),
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
      bottomNavigationBar:
          isWideScreen ? null : _buildBottomNav(navItems, selectedIndex),
      drawer: isWideScreen ? null : _buildDrawer(navItems, selectedIndex),
    );
  }

  Widget _buildSideNav(List<_NavItem> navItems, int selectedIndex) {
    final lang = ref.watch(localeProvider);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 220 : 64,
      color: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(_sidebarExpanded),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, navItems[0], selectedIndex),
                _buildNavItem(1, navItems[1], selectedIndex),
                _buildNavItem(7, navItems[7], selectedIndex),
                _buildNavItem(12, navItems[12], selectedIndex),
                _buildNavItem(13, navItems[13], selectedIndex),
                const Divider(height: 32),
                if (_sidebarExpanded) _buildSectionLabel(tr(lang, 'nav.wiki')),
                _buildNavItem(8, navItems[8], selectedIndex),
                _buildNavItem(9, navItems[9], selectedIndex),
                _buildNavItem(10, navItems[10], selectedIndex),
                _buildNavItem(11, navItems[11], selectedIndex),
                const Divider(height: 32),
                if (_sidebarExpanded)
                  _buildSectionLabel(tr(lang, 'nav.activeLeague')),
                _buildNavItem(2, navItems[2], selectedIndex),
                _buildNavItem(3, navItems[3], selectedIndex),
                _buildNavItem(4, navItems[4], selectedIndex),
                _buildNavItem(5, navItems[5], selectedIndex),
                _buildNavItem(6, navItems[6], selectedIndex),
              ],
            ),
          ),
          _buildUserSection(_sidebarExpanded),
        ],
      ),
    );
  }

  Widget _buildHeader(bool expanded) {
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
              onPressed: () => setState(() => _sidebarExpanded = true),
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
                    fontFamily: AppTextStyles.displayFont,
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _sidebarExpanded = false),
            color: AppColors.textMuted,
            iconSize: 18,
            tooltip: tr(lang, 'nav.collapse'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final isDisabled = item.route == null;

    final iconColor = isDisabled
        ? AppColors.textMuted.withOpacity(0.35)
        : isSelected
            ? AppColors.primary
            : AppColors.textSecondary;

    return Tooltip(
      message: _sidebarExpanded ? '' : item.label,
      preferBelow: false,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: _sidebarExpanded ? 8 : 4,
          vertical: 2,
        ),
        child: Material(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isDisabled ? null : () => context.go(item.route!),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _sidebarExpanded ? 12 : 0,
                vertical: 10,
              ),
              child: _sidebarExpanded
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.displayFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildUserSection(bool expanded) {
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
              style: TextStyle(
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
              style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'TV: --',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildLangToggle(),
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

  Widget _buildLangToggle() {
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(List<_NavItem> navItems, int selectedIndex) {
    // Map bottom tabs: 0→Dashboard, 1→Mis Equipos, 2→Liga, 3→Crear
    final bottomItems = [navItems[0], navItems[1], navItems[2], navItems[6]];
    final bottomIndices = [0, 1, 2, 6];
    final clampedIndex = bottomIndices.contains(selectedIndex)
        ? bottomIndices.indexOf(selectedIndex)
        : 0;

    final lang = ref.watch(localeProvider);
    return BottomNavigationBar(
      currentIndex: clampedIndex,
      onTap: (i) {
        final item = bottomItems[i];
        if (item.route != null) context.go(item.route!);
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

  Widget _buildDrawer(List<_NavItem> navItems, int selectedIndex) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, navItems[0], selectedIndex),
                _buildNavItem(1, navItems[1], selectedIndex),
                _buildNavItem(7, navItems[7], selectedIndex),
                const Divider(height: 32),
                _buildSectionLabel(tr(ref.watch(localeProvider), 'nav.wiki')),
                _buildNavItem(8, navItems[8], selectedIndex),
                _buildNavItem(9, navItems[9], selectedIndex),
                const Divider(height: 32),
                _buildSectionLabel(
                    tr(ref.watch(localeProvider), 'nav.activeLeague')),
                _buildNavItem(2, navItems[2], selectedIndex),
                _buildNavItem(3, navItems[3], selectedIndex),
                _buildNavItem(4, navItems[4], selectedIndex),
                _buildNavItem(5, navItems[5], selectedIndex),
                _buildNavItem(6, navItems[6], selectedIndex),
              ],
            ),
          ),
          _buildUserSection(true),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? route;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.route,
  });
}

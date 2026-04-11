import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/providers/auth_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: PhosphorIcons.house(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
      label: 'Mis Ligas',
      route: '/dashboard',
    ),
    _NavItem(
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      label: 'Vista de Liga',
      route: null, // Dynamic based on selected league
    ),
    _NavItem(
      icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
      label: 'Plantilla',
      route: null, // Dynamic based on selected team
    ),
    _NavItem(
      icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
      label: 'Jugador',
      route: null, // Dynamic based on selected player
    ),
    _NavItem(
      icon: PhosphorIcons.football(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.football(PhosphorIconsStyle.fill),
      label: 'Post-Partido',
      route: null, // Dynamic based on selected match
    ),
    _NavItem(
      icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.regular),
      selectedIcon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
      label: 'Crear Equipo',
      route: '/create-team',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen) _buildSideNav(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : _buildBottomNav(),
      drawer: isWideScreen ? null : _buildDrawer(),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, _navItems[0]),
                _buildNavItem(5, _navItems[5]),
                const Divider(height: 32),
                _buildSectionLabel('LIGA ACTIVA'),
                _buildNavItem(1, _navItems[1]),
                _buildNavItem(2, _navItems[2]),
                _buildNavItem(3, _navItems[3]),
                _buildNavItem(4, _navItems[4]),
              ],
            ),
          ),
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLOOD BOWL',
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'LEAGUE MANAGER',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (item.route != null) {
              setState(() => _selectedIndex = index);
              context.go(item.route!);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull?.user;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              user?.username.substring(0, 1).toUpperCase() ?? 'U',
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
          IconButton(
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
            onPressed: () {
              // TODO: Navigate to settings
            },
            iconSize: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex.clamp(0, 3),
      onTap: (index) {
        final routes = ['/dashboard', null, null, '/create-team'];
        if (routes[index] != null) {
          setState(() => _selectedIndex = index);
          context.go(routes[index]!);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill)),
          label: 'Liga',
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)),
          label: 'Equipo',
        ),
        BottomNavigationBarItem(
          icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.regular)),
          activeIcon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
          label: 'Crear',
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, _navItems[0]),
                _buildNavItem(5, _navItems[5]),
                const Divider(height: 32),
                _buildSectionLabel('LIGA ACTIVA'),
                _buildNavItem(1, _navItems[1]),
                _buildNavItem(2, _navItems[2]),
                _buildNavItem(3, _navItems[3]),
                _buildNavItem(4, _navItems[4]),
              ],
            ),
          ),
          _buildUserSection(),
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

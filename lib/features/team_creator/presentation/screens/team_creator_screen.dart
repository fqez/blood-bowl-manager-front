import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../widgets/race_card.dart';
import '../widgets/position_card.dart';
import '../widgets/budget_bar.dart';

// Provider para obtener los base rosters del backend
final baseRostersProvider = FutureProvider<List<BaseTeam>>((ref) async {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getBaseTeams();
});

// Provider para obtener el detalle de un roster específico
final baseRosterDetailProvider = FutureProvider.family<BaseTeam, String>((ref, rosterId) async {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getBaseTeamDetail(rosterId);
});

class TeamCreatorScreen extends ConsumerStatefulWidget {
  final String? leagueId;

  const TeamCreatorScreen({super.key, this.leagueId});

  @override
  ConsumerState<TeamCreatorScreen> createState() => _TeamCreatorScreenState();
}

class _TeamCreatorScreenState extends ConsumerState<TeamCreatorScreen> {
  int _currentStep = 0;

  // Team data
  String _teamName = '';
  BaseTeam? _selectedRace;
  final List<_RecruitedPlayer> _roster = [];
  int _rerolls = 0;
  bool _apothecary = false;
  int _assistantCoaches = 0;
  int _cheerleaders = 0;
  bool _loadingRaceDetail = false;

  static const int _startingBudget = 1000000;

  int get _spent {
    int total = 0;
    for (final player in _roster) {
      total += player.position.cost;
    }
    total += _rerolls * (_selectedRace?.rerollCost ?? 50000);
    if (_apothecary) total += 50000;
    total += _assistantCoaches * 10000;
    total += _cheerleaders * 10000;
    return total;
  }

  int get _remaining => _startingBudget - _spent;

  int get _rosterCount => _roster.length;

  bool get _isValidRoster {
    // At least 11 players
    if (_rosterCount < 11) return false;
    // At least 3 rerolls recommended (soft check)
    return true;
  }

  /// Selecciona una raza y carga su detalle completo desde el backend
  Future<void> _selectRace(BaseTeam raceSummary) async {
    // Si ya está seleccionada y tenemos el detalle, no hacer nada
    if (_selectedRace?.id == raceSummary.id && _selectedRace!.positions.isNotEmpty) {
      return;
    }

    // Mostrar la selección inmediatamente con datos básicos
    setState(() {
      _selectedRace = raceSummary;
      _loadingRaceDetail = true;
      // Limpiar roster si cambiamos de raza
      _roster.clear();
      _rerolls = 0;
    });

    try {
      // Cargar el detalle completo (con posiciones)
      final repository = ref.read(teamRepositoryProvider);
      final detail = await repository.getBaseTeamDetail(raceSummary.id);

      if (mounted) {
        setState(() {
          _selectedRace = detail;
          _loadingRaceDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRaceDetail = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles del equipo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Crear Equipo'),
              leading: IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                onPressed: () => _showExitDialog(context),
              ),
            ),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar con pasos
        Container(
          width: 260,
          color: AppColors.surface,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                      onPressed: () => _showExitDialog(context),
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Crear Equipo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Steps verticales
              Expanded(child: _buildVerticalSteps()),
              // Budget bar en sidebar
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BudgetBar(spent: _spent, total: _startingBudget),
                ),
            ],
          ),
        ),
        // Contenido principal - usa todo el espacio
        Expanded(
          child: Column(
            children: [
              // Header con título del paso actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getStepTitle(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildDesktopNavigationButtons(),
                  ],
                ),
              ),
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildCurrentStep(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Selecciona una raza';
      case 1:
        return 'Ficha jugadores';
      case 2:
        return 'Personal y equipo';
      case 3:
        return 'Confirmar equipo';
      default:
        return '';
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProgressSteps(),
        if (_currentStep > 0)
          BudgetBar(spent: _spent, total: _startingBudget),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: _buildCurrentStep(false),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildVerticalSteps() {
    final steps = [
      {'title': 'Raza', 'subtitle': 'Selecciona tu equipo'},
      {'title': 'Roster', 'subtitle': 'Ficha jugadores'},
      {'title': 'Personal', 'subtitle': 'Re-rolls y staff'},
      {'title': 'Confirmar', 'subtitle': 'Revisa y crea'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        final step = steps[index];

        return InkWell(
          onTap: isCompleted ? () => setState(() => _currentStep = index) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.1) : null,
              border: Border(
                left: BorderSide(
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.success
                          : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.success
                            : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            PhosphorIcons.check(PhosphorIconsStyle.bold),
                            size: 18,
                            color: AppColors.textPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isActive || isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        step['subtitle']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopNavigationButtons() {
    final canProceed = _canProceed();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), size: 16),
            label: const Text('Anterior'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton.icon(
          onPressed: canProceed
              ? () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _createTeam();
                  }
                }
              : null,
          icon: Icon(
            _currentStep < 3
                ? PhosphorIcons.arrowRight(PhosphorIconsStyle.bold)
                : PhosphorIcons.check(PhosphorIconsStyle.bold),
            size: 16,
          ),
          label: Text(_currentStep < 3 ? 'Siguiente' : 'Crear Equipo'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    final steps = ['Raza', 'Roster', 'Personal', 'Confirmar'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < _currentStep
                    ? AppColors.primary
                    : AppColors.surfaceLight,
              ),
            );
          } else {
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == _currentStep;
            final isCompleted = stepIndex < _currentStep;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.success
                            : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                            size: 16, color: AppColors.textPrimary)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isActive ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  Widget _buildCurrentStep(bool isWide) {
    switch (_currentStep) {
      case 0:
        return _buildRaceStep(isWide);
      case 1:
        return _buildRosterStep(isWide);
      case 2:
        return _buildStaffStep(isWide);
      case 3:
        return _buildConfirmStep(isWide);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRaceStep(bool isWide) {
    final racesAsync = ref.watch(baseRostersProvider);

    return racesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar equipos',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(baseRostersProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (races) => _buildRaceStepContent(isWide, races),
    );
  }

  Widget _buildRaceStepContent(bool isWide, List<BaseTeam> races) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wallpaper del equipo seleccionado
        if (_selectedRace != null) ...[
          Container(
            height: isWide ? 200 : 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'teams/${_selectedRace!.id}/wallpaper.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: Icon(
                          PhosphorIcons.image(PhosphorIconsStyle.light),
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Team name overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'teams/${_selectedRace!.id}/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRace!.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildTierBadge(_selectedRace!.tier ?? 2),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RR ${_selectedRace!.rerollCost ~/ 1000}k',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Team name input
        TextField(
          decoration: InputDecoration(
            labelText: 'Nombre del equipo',
            hintText: 'ej: Los Leones de Altdorf',
            prefixIcon: Icon(PhosphorIcons.flag(PhosphorIconsStyle.bold)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (v) => setState(() => _teamName = v),
        ),
        const SizedBox(height: 24),
        Text(
          'SELECCIONA UNA RAZA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 6 : 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: races.length,
          itemBuilder: (context, index) {
            final race = races[index];
            return RaceCard(
              race: race,
              isSelected: _selectedRace?.id == race.id,
              onTap: () => _selectRace(race),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTierBadge(int tier) {
    final colors = {
      1: AppColors.success,
      2: AppColors.accent,
      3: AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[tier] ?? AppColors.textMuted).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Tier $tier',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colors[tier] ?? AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildRosterStep(bool isWide) {
    // Si estamos cargando el detalle de la raza, mostrar indicador
    if (_loadingRaceDetail) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando posiciones...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Usar las posiciones del equipo seleccionado desde el backend
    final positions = _selectedRace?.positions ?? <BasePosition>[];

    // Wallpaper del equipo - composición con imagen emergente
    Widget buildTeamWallpaper() {
      if (_selectedRace == null) return const SizedBox.shrink();
      return Container(
        height: 280,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Imagen del equipo posicionada a la derecha, emergiendo
            Positioned(
              right: -40,
              top: -20,
              bottom: -40,
              child: Image.asset(
                'assets/teams/${_selectedRace!.id}/wallpaper.png',
                height: 340,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Contenido a la izquierda
            Positioned(
              left: 0,
              top: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de info del equipo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/teams/${_selectedRace!.id}/logo.png',
                            width: 48,
                            height: 48,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRace!.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Tier ${_selectedRace!.tier ?? 2}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'RR ${(_selectedRace!.rerollCost / 1000).toInt()}k',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nombre del equipo grande (editable en el futuro)
                  Text(
                    _teamName.isNotEmpty ? _teamName.toUpperCase() : _selectedRace!.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 4,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Widget para la lista de posiciones disponibles
    Widget buildPositionsList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FICHAJES DISPONIBLES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...positions.map((pos) {
            final hired = _roster.where((r) => r.position.id == pos.id).length;
            final canHire = hired < pos.maxQuantity &&
                _remaining >= pos.cost &&
                _rosterCount < 16;

            return PositionCard(
              position: pos,
              hiredCount: hired,
              canHire: canHire,
              affordable: _remaining >= pos.cost,
              onHire: canHire ? () => _hirePlayer(pos) : null,
            );
          }),
        ],
      );
    }

    // Widget para el roster actual
    Widget buildRosterPanel() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contador de roster
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _rosterCount >= 11 ? AppColors.success : AppColors.warning,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _rosterCount >= 11
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: _rosterCount >= 11 ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Text(
                  '$_rosterCount / 16',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'jugadores',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'TU ROSTER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_roster.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.users(PhosphorIconsStyle.light),
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin jugadores',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Haz clic en + para fichar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_roster
                .asMap()
                .entries
                .map((entry) => _buildRecruitedPlayer(entry.key, entry.value))),
        ],
      );
    }

    // Layout de dos columnas para desktop (sin Expanded, ya está en ScrollView)
    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTeamWallpaper(),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: Posiciones disponibles
                Expanded(
                  flex: 3,
                  child: buildPositionsList(),
                ),
                const SizedBox(width: 32),
                // Columna derecha: Roster fichado
                Expanded(
                  flex: 2,
                  child: buildRosterPanel(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Layout móvil (columna única)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildTeamWallpaper(),
        // Current roster summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _rosterCount >= 11 ? AppColors.success : AppColors.warning,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _rosterCount >= 11
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                color: _rosterCount >= 11 ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Text(
                '$_rosterCount / 16 jugadores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_rosterCount < 11) ...[
                const SizedBox(width: 8),
                Text(
                  '(mínimo 11)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        buildPositionsList(),
        // Recruited players at bottom on mobile
        if (_roster.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'JUGADORES FICHADOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...(_roster
              .asMap()
              .entries
              .map((entry) => _buildRecruitedPlayer(entry.key, entry.value))),
        ],
      ],
    );
  }

  Widget _buildRecruitedPlayer(int index, _RecruitedPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.position.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${player.position.cost ~/ 1000}k',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold)),
            onPressed: () => setState(() => _roster.removeAt(index)),
            color: AppColors.error,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStep(bool isWide) {
    final rerollCost = _selectedRace?.rerollCost ?? 50000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL Y EQUIPO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Re-rolls
        _buildStaffItem(
          icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
          label: 'Re-rolls',
          description: '${rerollCost ~/ 1000}k cada uno',
          count: _rerolls,
          maxCount: 8,
          cost: rerollCost,
          onIncrement: _remaining >= rerollCost
              ? () => setState(() => _rerolls++)
              : null,
          onDecrement: _rerolls > 0 ? () => setState(() => _rerolls--) : null,
        ),
        // Apothecary
        _buildStaffToggle(
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
          label: 'Apotecario',
          description: '50k',
          enabled: _apothecary,
          cost: 50000,
          canToggle: !_apothecary ? _remaining >= 50000 : true,
          onToggle: (v) => setState(() => _apothecary = v),
        ),
        // Assistant coaches
        _buildStaffItem(
          icon: PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill),
          label: 'Asistentes',
          description: '10k cada uno',
          count: _assistantCoaches,
          maxCount: 6,
          cost: 10000,
          onIncrement: _remaining >= 10000
              ? () => setState(() => _assistantCoaches++)
              : null,
          onDecrement: _assistantCoaches > 0
              ? () => setState(() => _assistantCoaches--)
              : null,
        ),
        // Cheerleaders
        _buildStaffItem(
          icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
          label: 'Animadoras',
          description: '10k cada una',
          count: _cheerleaders,
          maxCount: 12,
          cost: 10000,
          onIncrement: _remaining >= 10000
              ? () => setState(() => _cheerleaders++)
              : null,
          onDecrement:
              _cheerleaders > 0 ? () => setState(() => _cheerleaders--) : null,
        ),
        const SizedBox(height: 24),
        // Recommendations
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                  color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Se recomienda empezar con al menos 3 re-rolls y un apotecario para equipos que lo permitan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffItem({
    required IconData icon,
    required String label,
    required String description,
    required int count,
    required int maxCount,
    required int cost,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold)),
                onPressed: onDecrement,
                color: onDecrement != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                onPressed: count < maxCount ? onIncrement : null,
                color: onIncrement != null && count < maxCount
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffToggle({
    required IconData icon,
    required String label,
    required String description,
    required bool enabled,
    required int cost,
    required bool canToggle,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppColors.success : AppColors.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: canToggle ? onToggle : null,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team summary card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // Team emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'teams/${_selectedRace?.id}/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      PhosphorIcons.shield(PhosphorIconsStyle.fill),
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _teamName.isEmpty ? 'Sin nombre' : _teamName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                _selectedRace?.name ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('Jugadores', '$_rosterCount'),
                  _buildSummaryItem('Re-rolls', '$_rerolls'),
                  _buildSummaryItem('Apotecario', _apothecary ? 'Sí' : 'No'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'VALOR DEL EQUIPO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_spent ~/ 1000}k',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'TESORERÍA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_remaining ~/ 1000}k',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Warnings
        if (!_isValidRoster)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El equipo necesita al menos 11 jugadores para poder jugar.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Anterior'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: canProceed
                  ? () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _createTeam();
                      }
                    }
                  : null,
              child: Text(_currentStep < 3 ? 'Siguiente' : 'Crear Equipo'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _teamName.isNotEmpty && _selectedRace != null;
      case 1:
        return _rosterCount >= 11;
      case 2:
        return true;
      case 3:
        return _isValidRoster;
      default:
        return false;
    }
  }

  void _hirePlayer(BasePosition position) {
    setState(() {
      _roster.add(_RecruitedPlayer(position: position));
    });
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Abandonar creación?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Se perderán todos los datos del equipo.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _createTeam() {
    // TODO: Submit team to API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Equipo "$_teamName" creado correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/dashboard');
  }
}

class _RecruitedPlayer {
  final BasePosition position;

  _RecruitedPlayer({required this.position});
}

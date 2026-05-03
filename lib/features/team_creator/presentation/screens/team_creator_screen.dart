import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../widgets/budget_bar.dart';
import '../widgets/team_creator_confirm_step.dart';
import '../widgets/team_creator_race_step.dart';
import '../widgets/team_creator_roster_step.dart';

final baseRostersProvider = FutureProvider<List<BaseTeam>>((ref) async {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getBaseTeams();
});

final baseRosterDetailProvider =
    FutureProvider.family<BaseTeam, String>((ref, rosterId) async {
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
  late final TextEditingController _teamNameController;

  String _teamName = '';
  BaseTeam? _selectedRace;
  final List<_RecruitedPlayer> _roster = [];
  int _rerolls = 0;
  bool _apothecary = false;
  int _assistantCoaches = 0;
  int _cheerleaders = 0;
  bool _loadingRaceDetail = false;
  bool _isCreating = false;

  static const int _startingBudget = 1000000;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: _teamName);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

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
    if (_rosterCount < 11) return false;
    return true;
  }

  Future<void> _selectRace(BaseTeam raceSummary) async {
    if (_selectedRace?.id == raceSummary.id &&
        _selectedRace!.positions.isNotEmpty) {
      return;
    }

    setState(() {
      _selectedRace = raceSummary;
      _loadingRaceDetail = true;
      _roster.clear();
      _rerolls = 0;
    });

    try {
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
    final lang = ref.watch(localeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide
          ? null
          : AppBar(
              title: Text(tr(lang, 'teamCreator.title')),
              leading: IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                onPressed: () => _showExitDialog(context),
              ),
            ),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final textTheme = context.textTheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                onPressed: () => _showExitDialog(context),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _getStepTitle(),
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (_currentStep == 1 && _selectedRace != null) ...[
                const SizedBox(width: 12),
                Icon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _teamName.isNotEmpty ? _teamName : 'Nuevo Equipo',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const Spacer(),
              if (_currentStep > 0)
                SizedBox(
                  width: 220,
                  child: BudgetBar(spent: _spent, total: _startingBudget),
                ),
              const SizedBox(width: 24),
              _buildDesktopNavigationButtons(),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: _currentStep == 1 ? 0 : 32,
              right: _currentStep == 1 ? 0 : 32,
              top: _currentStep == 1 ? 0 : 32,
              bottom: 32,
            ),
            child: _buildCurrentStep(true),
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    final lang = ref.watch(localeProvider);
    switch (_currentStep) {
      case 0:
        return tr(lang, 'teamCreator.step1');
      case 1:
        return tr(lang, 'teamCreator.step2');
      case 2:
        return tr(lang, 'teamCreator.title');
      default:
        return '';
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProgressSteps(),
        if (_currentStep > 0) BudgetBar(spent: _spent, total: _startingBudget),
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

  Widget _buildDesktopNavigationButtons() {
    final canProceed = _canProceed() && !_isCreating;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                size: 16),
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
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _createTeam();
                  }
                }
              : null,
          icon: Icon(
            _currentStep < 2
                ? PhosphorIcons.arrowRight(PhosphorIconsStyle.bold)
                : PhosphorIcons.check(PhosphorIconsStyle.bold),
            size: 16,
          ),
          label: _isCreating && _currentStep == 2
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_currentStep < 2
                  ? 'Siguiente'
                  : tr(ref.watch(localeProvider), 'teamCreator.create')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    final steps = ['Raza', 'Roster', 'Confirmar'];

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
        return TeamCreatorRaceStep(
          isWide: isWide,
          lang: ref.watch(localeProvider),
          racesAsync: ref.watch(baseRostersProvider),
          selectedRace: _selectedRace,
          teamName: _teamName,
          onRetry: () => ref.invalidate(baseRostersProvider),
          onSelectRace: _selectRace,
          onTeamNameChanged: (value) => setState(() => _teamName = value),
          teamNameLabel: tr(ref.watch(localeProvider), 'teamCreator.teamName'),
          teamNameHint:
              tr(ref.watch(localeProvider), 'teamCreator.teamNameHint'),
          retryLabel: tr(ref.watch(localeProvider), 'common.retry'),
        );
      case 1:
        return _buildRosterStep(isWide);
      case 2:
        return TeamCreatorConfirmStep(
          teamId: _selectedRace?.id,
          teamName: _teamName,
          raceName: _selectedRace?.name ?? '',
          rosterCount: _rosterCount,
          rerolls: _rerolls,
          apothecary: _apothecary,
          spent: _spent,
          remaining: _remaining,
          isValidRoster: _isValidRoster,
        );
      default:
        return const SizedBox.shrink();
    }
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
    final race = _selectedRace;
    final positions = race?.positions ?? <BasePosition>[];
    final rerollCost = race?.rerollCost ?? 50000;

    // ── Cabecera banner ──────────────────────────────────────────────────────
    Widget buildHeader() {
      if (race == null) return const SizedBox.shrink();

      return Container(
        height: 320,
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(color: AppColors.background),
            Positioned(
              right: -20,
              top: -30,
              bottom: -20,
              child: Image.asset(
                'assets/teams/${race.id}/wallpaper.png',
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
                    colors: [
                      Colors.transparent,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 24,
              child: Container(
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
                        'assets/teams/${race.id}/logo.webp',
                        width: 36,
                        height: 36,
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
                          race.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _buildTierBadge(race.tier ?? 2),
                            const SizedBox(width: 8),
                            Text(
                              'RR ${rerollCost ~/ 1000}k',
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
              ),
            ),
            Positioned(
              left: 24,
              right: 200,
              bottom: 24,
              child: Text(
                (_teamName.isNotEmpty ? _teamName : race.name).toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Teko',
                  fontSize: 52,
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
    }

    // ── Tabla de reclutamiento ────────────────────────────────────────────────
    Widget buildRecruitmentTable(bool wide) {
      final lang = ref.watch(localeProvider);
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de tabla
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'RECLUTAMIENTO DE JUGADORES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_rosterCount >= 11
                              ? AppColors.success
                              : AppColors.warning)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _rosterCount >= 11
                            ? AppColors.success
                            : AppColors.warning,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      trf(lang, 'roster.playerCount', {'n': '$_rosterCount'}),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _rosterCount >= 11
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cabecera de columnas (solo en wide)
            if (wide)
              Container(
                color: AppColors.surfaceLight.withOpacity(0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    _tableHeader('POSICIÓN', flex: 4),
                    _tableHeader('MA', flex: 1, center: true),
                    _tableHeader('ST', flex: 1, center: true),
                    _tableHeader('AG', flex: 1, center: true),
                    _tableHeader('PA', flex: 1, center: true),
                    _tableHeader('AV', flex: 1, center: true),
                    _tableHeader('HABILIDADES', flex: 5),
                    _tableHeader('COSTE', flex: 2, center: true),
                    _tableHeader('LÍMITE / CANTIDAD', flex: 4, center: true),
                  ],
                ),
              ),
            // Filas de posiciones
            if (positions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No hay posiciones disponibles',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...positions.map((pos) =>
                  wide ? _buildPositionRow(pos) : _buildPositionCard(pos)),
          ],
        ),
      );
    }

    // ── Panel izquierdo: identidad del equipo ─────────────────────────────────
    Widget buildIdentityPanel() {
      final lang = ref.watch(localeProvider);
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Presupuesto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _remaining < 0 ? AppColors.error : AppColors.surfaceLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.coinVertical(PhosphorIconsStyle.fill),
                    size: 16,
                    color: _remaining < 0 ? AppColors.error : AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRESUPUESTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_remaining ~/ 1000}k restantes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remaining < 0
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_spent ~/ 1000}k / ${_startingBudget ~/ 1000}k',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'IDENTIDAD DEL EQUIPO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(lang, 'teamCreator.teamName'),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _teamNameController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: tr(lang, 'teamCreator.teamNameHint'),
                hintStyle: TextStyle(color: AppColors.textMuted),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
              onChanged: (v) => setState(() => _teamName = v),
            ),
            const SizedBox(height: 16),
            // Reglas especiales
            if (race != null && race.specialRules.isNotEmpty) ...[
              Text(
                'REGLAS ESPECIALES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: race.specialRules
                    .map((rule) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Text(
                            rule,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    }

    // ── Jugadores estrella disponibles ──────────────────────────────────────
    Widget buildStarPlayersSection() {
      final raceId = _selectedRace?.id;
      if (raceId == null) return const SizedBox.shrink();

      final asyncStar = ref.watch(starPlayersForTeamProvider(raceId));

      return asyncStar.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (stars) {
          if (stars.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'JUGADORES ESTRELLA DISPONIBLES',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${stars.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contratable como Inducement durante los partidos.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                // Horizontal scroll of mini star cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stars.map((sp) {
                      final id = sp['id'] as String? ?? '';
                      final name = sp['name'] as String? ?? '';
                      final cost = sp['cost'] as int? ?? 0;
                      final types =
                          (sp['player_types'] as List?)?.cast<String>() ?? [];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Image
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent.withOpacity(0.2)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.asset(
                                  'assets/images/star_players/$id.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                                    size: 20,
                                    color: AppColors.accent.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${cost ~/ 1000}K',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                            if (types.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                types.join(', '),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 8, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // ── Panel de staff ────────────────────────────────────────────────────────
    Widget buildStaffPanel(bool wide) {
      Widget rerollsTile() => Expanded(
            child: _buildStaffTile(
              icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
              label: 'REROLLS',
              subtitle: '${rerollCost ~/ 1000}k c/u',
              count: _rerolls,
              onDec: _rerolls > 0 ? () => setState(() => _rerolls--) : null,
              onInc: _remaining >= rerollCost
                  ? () => setState(() => _rerolls++)
                  : null,
            ),
          );
      Widget apoTile() => Expanded(
            child: _buildApothecaryTile(
              allowed: race?.apothecaryAllowed ?? true,
              enabled: _apothecary,
              canToggle: !_apothecary ? _remaining >= 50000 : true,
              onToggle: (v) => setState(() => _apothecary = v),
            ),
          );
      Widget cheerTile() => Expanded(
            child: _buildStaffTile(
              icon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
              label: 'ANIMADORAS',
              subtitle: '10k c/u',
              count: _cheerleaders,
              onDec: _cheerleaders > 0
                  ? () => setState(() => _cheerleaders--)
                  : null,
              onInc: _remaining >= 10000
                  ? () => setState(() => _cheerleaders++)
                  : null,
            ),
          );
      Widget assistTile() => Expanded(
            child: _buildStaffTile(
              icon: PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.fill),
              label: 'ASISTENTES',
              subtitle: '10k c/u',
              count: _assistantCoaches,
              onDec: _assistantCoaches > 0
                  ? () => setState(() => _assistantCoaches--)
                  : null,
              onInc: _remaining >= 10000
                  ? () => setState(() => _assistantCoaches++)
                  : null,
            ),
          );

      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EQUIPO TÉCNICO Y MEJORAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (wide)
              Row(children: [
                rerollsTile(),
                const SizedBox(width: 12),
                apoTile(),
                const SizedBox(width: 12),
                cheerTile(),
                const SizedBox(width: 12),
                assistTile(),
              ])
            else ...[
              Row(children: [
                rerollsTile(),
                const SizedBox(width: 12),
                apoTile()
              ]),
              const SizedBox(height: 12),
              Row(children: [
                cheerTile(),
                const SizedBox(width: 12),
                assistTile()
              ]),
            ],
          ],
        ),
      );
    }

    // ── Estado del roster ─────────────────────────────────────────────────────
    Widget buildRosterStatus() {
      final isValid = _rosterCount >= 11 && _remaining >= 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isValid
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isValid ? AppColors.success : AppColors.warning,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isValid
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: isValid ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValid ? 'Roster Válido' : 'Roster Incompleto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              isValid ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        isValid
                            ? 'Cumples con el mínimo de 11 jugadores y no superas el presupuesto.'
                            : 'Necesitas al menos 11 jugadores (tienes $_rosterCount).',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isValid) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep++),
              icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  size: 16),
              label: const Text('Continuar a Confirmar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      );
    }

    // ── Layout completo ───────────────────────────────────────────────────────
    return TeamCreatorRosterStep(
      isWide: isWide,
      loadingRaceDetail: _loadingRaceDetail,
      header: buildHeader(),
      identityPanel: buildIdentityPanel(),
      recruitmentTable: buildRecruitmentTable(isWide),
      starPlayersSection: buildStarPlayersSection(),
      staffPanel: buildStaffPanel(isWide),
      rosterStatus: buildRosterStatus(),
    );
  }

  Widget _tableHeader(String text, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPositionRow(BasePosition pos) {
    final hired = _roster.where((r) => r.position.id == pos.id).length;
    final canHire =
        hired < pos.maxQuantity && _remaining >= pos.cost && _rosterCount < 16;
    final isMaxed = hired >= pos.maxQuantity;

    String _statCell(int val) => '$val';

    final perkNames = pos.startingPerks.map((p) => p.name).join(', ');

    return Container(
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMaxed
                  ? AppColors.textMuted.withOpacity(0.3)
                  : canHire
                      ? AppColors.success
                      : AppColors.warning,
            ),
          ),
          // Nombre posición
          Expanded(
            flex: 4,
            child: Text(
              pos.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMaxed ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          // Stats
          _statBadge(_statCell(pos.stats.ma), highlight: !isMaxed),
          _statBadge(_statCell(pos.stats.st), highlight: !isMaxed),
          _statBadge('${pos.stats.ag}+', highlight: !isMaxed),
          _statBadge(pos.stats.pa == 0 ? '-' : '${pos.stats.pa}+',
              highlight: !isMaxed),
          _statBadge('${pos.stats.av}+', highlight: !isMaxed),
          // Habilidades
          Expanded(
            flex: 5,
            child: Text(
              perkNames,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Coste
          Expanded(
            flex: 2,
            child: Text(
              '${pos.cost ~/ 1000}k',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          // Controles cantidad
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleButton(
                  icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                  onTap: hired > 0
                      ? () {
                          final idx = _roster
                              .lastIndexWhere((r) => r.position.id == pos.id);
                          if (idx >= 0) setState(() => _roster.removeAt(idx));
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '$hired',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        hired > 0 ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                _circleButton(
                  icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  onTap: canHire ? () => _hirePlayer(pos) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${pos.maxQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(BasePosition pos) {
    final hired = _roster.where((r) => r.position.id == pos.id).length;
    final canHire =
        hired < pos.maxQuantity && _remaining >= pos.cost && _rosterCount < 16;
    final isMaxed = hired >= pos.maxQuantity;
    final perkNames = pos.startingPerks.map((p) => p.name).join(', ');

    return Container(
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMaxed
                  ? AppColors.textMuted.withOpacity(0.3)
                  : canHire
                      ? AppColors.success
                      : AppColors.warning,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isMaxed ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: [
                    _miniStat('${pos.stats.ma}'),
                    _miniStat('${pos.stats.st}'),
                    _miniStat('${pos.stats.ag}+'),
                    _miniStat(pos.stats.pa == 0 ? '-' : '${pos.stats.pa}+'),
                    _miniStat('${pos.stats.av}+'),
                  ],
                ),
                if (perkNames.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    perkNames,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pos.cost ~/ 1000}k',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _circleButton(
                    icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                    onTap: hired > 0
                        ? () {
                            final idx = _roster
                                .lastIndexWhere((r) => r.position.id == pos.id);
                            if (idx >= 0) setState(() => _roster.removeAt(idx));
                          }
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$hired',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hired > 0
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  _circleButton(
                    icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                    onTap: canHire ? () => _hirePlayer(pos) : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/${pos.maxQuantity}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        val,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _statBadge(String val, {bool highlight = true}) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Container(
          width: 32,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.surfaceLight.withOpacity(0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withOpacity(0.3),
          border: Border.all(
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textMuted.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildStaffTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required int count,
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          Text(subtitle,
              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                  icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                  onTap: onDec),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$count',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        count > 0 ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              _circleButton(
                  icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  onTap: onInc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApothecaryTile({
    required bool allowed,
    required bool enabled,
    required bool canToggle,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppColors.success.withOpacity(0.5)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
            color: allowed ? AppColors.accent : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            'BOTICARIO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            allowed ? '50k (Max 1)' : 'No disponible',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Switch(
            value: enabled && allowed,
            onChanged: allowed && canToggle ? onToggle : null,
            activeColor: AppColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final lang = ref.watch(localeProvider);
    final canProceed = _canProceed() && !_isCreating;

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
                onPressed:
                    _isCreating ? null : () => setState(() => _currentStep--),
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
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _createTeam();
                      }
                    }
                  : null,
              child: _isCreating && _currentStep == 2
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentStep < 2
                      ? 'Siguiente'
                      : tr(lang, 'teamCreator.create')),
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
    final lang = ref.watch(localeProvider);
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
            child: Text(tr(lang, 'common.cancel')),
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

  Future<void> _createTeam() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      // 1. Crear equipo vacío
      final teamId = await repository.createUserTeam(
        name: _teamName,
        baseRosterId: _selectedRace!.id,
      );

      // 2. Fichar cada jugador
      for (int i = 0; i < _roster.length; i++) {
        final pos = _roster[i].position;
        await repository.hirePlayer(
          teamId,
          baseType: pos.id,
          name: pos.name,
          number: i + 1,
        );
      }

      // 3. Guardar staff y re-rolls
      if (_rerolls > 0 ||
          _cheerleaders > 0 ||
          _assistantCoaches > 0 ||
          _apothecary) {
        await repository.patchTeamStaff(
          teamId,
          rerolls: _rerolls,
          cheerleaders: _cheerleaders,
          assistantCoaches: _assistantCoaches,
          apothecary: _apothecary,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipo "$_teamName" creado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear el equipo: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

class _RecruitedPlayer {
  final BasePosition position;

  _RecruitedPlayer({required this.position});
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../domain/models/aftermatch.dart';
import '../widgets/score_input.dart';
import '../widgets/touchdown_recorder.dart';
import '../widgets/injury_recorder.dart';
import '../widgets/spp_summary.dart';

class AftermatchScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String matchId;

  const AftermatchScreen({
    super.key,
    required this.leagueId,
    required this.matchId,
  });

  @override
  ConsumerState<AftermatchScreen> createState() => _AftermatchScreenState();
}

class _AftermatchScreenState extends ConsumerState<AftermatchScreen> {
  int _currentStep = 0;

  // Match data
  int _homeScore = 0;
  int _awayScore = 0;
  final List<TouchdownRecord> _touchdowns = [];
  final List<InjuryRecord> _injuries = [];
  final List<BonusSppRecord> _bonusSpp = [];

  // Mock data for teams (would come from API)
  Team? _homeTeam;
  Team? _awayTeam;

  final _steps = [
    'Resultado',
    'Touchdowns',
    'Lesiones',
    'Resumen SPP',
    'Confirmar',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post-Partido'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 16,
                vertical: 24,
              ),
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.primary : AppColors.surfaceLight,
              ),
            );
          } else {
            // Step indicator
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == _currentStep;
            final isCompleted = stepIndex < _currentStep;

            return Container(
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
            );
          }
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildScoreStep();
      case 1:
        return _buildTouchdownsStep();
      case 2:
        return _buildInjuriesStep();
      case 3:
        return _buildSppSummaryStep();
      case 4:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScoreStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          title: 'Resultado Final',
          subtitle: 'Introduce el marcador del partido',
        ),
        const SizedBox(height: 32),
        ScoreInput(
          homeTeamName: _homeTeam?.name ?? 'Equipo Local',
          awayTeamName: _awayTeam?.name ?? 'Equipo Visitante',
          homeScore: _homeScore,
          awayScore: _awayScore,
          onHomeScoreChanged: (v) => setState(() => _homeScore = v),
          onAwayScoreChanged: (v) => setState(() => _awayScore = v),
        ),
      ],
    );
  }

  Widget _buildTouchdownsStep() {
    final totalTD = _homeScore + _awayScore;
    final recordedTD = _touchdowns.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: PhosphorIcons.target(PhosphorIconsStyle.fill),
          title: 'Registro de Touchdowns',
          subtitle: 'Asigna cada touchdown a su anotador',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: recordedTD == totalTD
                ? AppColors.success.withOpacity(0.2)
                : AppColors.warning.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                recordedTD == totalTD
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                color: recordedTD == totalTD
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Text(
                '$recordedTD / $totalTD touchdowns registrados',
                style: TextStyle(
                  color: recordedTD == totalTD
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TouchdownRecorder(
          homeTeam: _homeTeam,
          awayTeam: _awayTeam,
          homeGoal: _homeScore,
          awayGoal: _awayScore,
          touchdowns: _touchdowns,
          onTouchdownAdded: (td) => setState(() => _touchdowns.add(td)),
          onTouchdownRemoved: (index) =>
              setState(() => _touchdowns.removeAt(index)),
        ),
      ],
    );
  }

  Widget _buildInjuriesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
          title: 'Registro de Lesiones',
          subtitle: 'Registra bajas graves, lesiones y muertes',
        ),
        const SizedBox(height: 24),
        InjuryRecorder(
          homeTeam: _homeTeam,
          awayTeam: _awayTeam,
          injuries: _injuries,
          onInjuryAdded: (injury) => setState(() => _injuries.add(injury)),
          onInjuryRemoved: (index) => setState(() => _injuries.removeAt(index)),
        ),
      ],
    );
  }

  Widget _buildSppSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
          title: 'Resumen de SPP',
          subtitle: 'Revisa y añade SPP de bonus (MVP, pases, etc.)',
        ),
        const SizedBox(height: 24),
        SppSummary(
          touchdowns: _touchdowns,
          injuries: _injuries,
          bonusSpp: _bonusSpp,
          homeTeam: _homeTeam,
          awayTeam: _awayTeam,
          onBonusSppAdded: (spp) => setState(() => _bonusSpp.add(spp)),
          onBonusSppRemoved: (index) =>
              setState(() => _bonusSpp.removeAt(index)),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          title: 'Confirmar Acta',
          subtitle: 'Revisa los datos antes de enviar',
        ),
        const SizedBox(height: 24),
        _buildConfirmCard(),
      ],
    );
  }

  Widget _buildConfirmCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      _homeTeam?.name ?? 'Local',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_homeScore',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _awayTeam?.name ?? 'Visitante',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_awayScore',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Summary stats
          Row(
            children: [
              _buildSummaryStat(
                icon: PhosphorIcons.target(PhosphorIconsStyle.fill),
                label: 'Touchdowns',
                value: '${_touchdowns.length}',
                color: AppColors.success,
              ),
              _buildSummaryStat(
                icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
                label: 'Lesiones',
                value: '${_injuries.length}',
                color: AppColors.warning,
              ),
              _buildSummaryStat(
                icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                label: 'SPP Bonus',
                value: '${_bonusSpp.fold(0, (sum, s) => sum + s.amount)}',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Una vez enviada, el acta deberá ser validada por el comisario.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
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
              onPressed: _currentStep < _steps.length - 1
                  ? () => setState(() => _currentStep++)
                  : _submitMatch,
              child: Text(_currentStep < _steps.length - 1
                  ? 'Siguiente'
                  : 'Enviar Acta'),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Salir del registro?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Se perderán los datos introducidos.',
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
              context.go('/league/${widget.leagueId}');
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

  void _submitMatch() {
    // TODO: Submit match data to API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Acta enviada correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/league/${widget.leagueId}');
  }
}

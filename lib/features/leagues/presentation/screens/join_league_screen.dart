import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league_summary.dart';

class JoinLeagueScreen extends ConsumerStatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  ConsumerState<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends ConsumerState<JoinLeagueScreen> {
  final _codeController = TextEditingController();

  LeagueByCodePreview? _preview;
  List<UserTeamSummary>? _userTeams;
  String? _selectedTeamId;

  bool _searching = false;
  bool _joining = false;
  String? _searchError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _code => _codeController.text.trim().toUpperCase();

  // ── Step 1: look up league by code ──

  Future<void> _searchLeague() async {
    if (_code.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _preview = null;
      _selectedTeamId = null;
    });
    try {
      final repo = ref.read(leagueRepositoryProvider);
      final preview = await repo.getLeagueByCode(_code);
      final teams = await ref.read(teamRepositoryProvider).getUserTeams();
      setState(() {
        _preview = preview;
        _userTeams = teams;
        if (teams.isNotEmpty) _selectedTeamId = teams.first.id;
      });
    } catch (e) {
      setState(() => _searchError = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ── Step 2: join ──

  Future<void> _joinLeague() async {
    if (_preview == null || _selectedTeamId == null) return;
    setState(() => _joining = true);
    try {
      await ref.read(leagueRepositoryProvider).joinLeagueWithCode(
            _preview!.id,
            _selectedTeamId!,
            _code,
          );
      if (mounted) context.go('/league/${_preview!.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('not found') || msg.contains('404')) {
      return 'Código incorrecto — no se encontró ninguna liga';
    }
    if (msg.contains('invite') || msg.contains('código')) {
      return 'Código de invitación incorrecto';
    }
    if (msg.contains('user already has')) {
      return 'Ya tienes un equipo inscrito en esta liga';
    }
    if (msg.contains('already')) {
      return 'Ya formas parte de esta liga con ese equipo';
    }
    if (msg.contains('full') || msg.contains('max')) {
      return 'La liga ya está llena';
    }
    return 'Error: $e';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 80 : 16, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCodeStep(),
                      if (_preview != null) ...[
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildPreviewCard(),
                        const SizedBox(height: 24),
                        _buildTeamStep(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/leagues'),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    color: AppColors.textSecondary),
              ),
              Text(
                'UNIRSE A UNA LIGA',
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 1 — CÓDIGO DE INVITACIÓN',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        Text(
          'Introduce el código que te ha compartido el organizador de la liga:',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    fontFamily: 'monospace'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(8),
                  _UpperCaseFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'XXXXXXXX',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      letterSpacing: 5,
                      fontFamily: 'monospace'),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
                onSubmitted: (_) => _searchLeague(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _searching ? null : _searchLeague,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
              label: const Text('Buscar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                minimumSize: const Size(0, 52),
              ),
            ),
          ],
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_searchError!,
                    style: TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewCard() {
    final p = _preview!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(p.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(p.status),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(p.status)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(p.formatLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            if (p.isFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('LLENA',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error)),
              ),
          ]),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          Text('Organizada por ${p.ownerUsername}',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(children: [
            _statChip(PhosphorIcons.usersThree(PhosphorIconsStyle.bold),
                '${p.teamCount}/${p.maxTeams}', 'Equipos'),
            const SizedBox(width: 12),
            _statChip(PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                'T${p.season}', 'Temporada'),
          ]),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    ]);
  }

  Widget _buildTeamStep() {
    if (_userTeams == null) return const SizedBox.shrink();
    final canJoin = _preview!.isDraft && !_preview!.isFull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 2 — ELIGE TU EQUIPO',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1),
        ),
        const SizedBox(height: 14),
        if (!canJoin) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _preview!.isFull
                      ? 'Esta liga ya está llena y no acepta más equipos.'
                      : 'Esta liga no está abierta a nuevas inscripciones.',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ]),
          ),
        ] else if (_userTeams!.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No tienes equipos creados.',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => context.go('/create-team'),
                        child: Text('Crear un equipo →',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                decoration: TextDecoration.underline)),
                      ),
                    ]),
              ),
            ]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTeamId,
                isExpanded: true,
                dropdownColor: AppColors.card,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: _userTeams!
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Row(children: [
                            Icon(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                size: 18, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(t.raceLabel,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted)),
                                  ]),
                            ),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeamId = v),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _joining || _selectedTeamId == null ? null : _joinLeague,
              icon: _joining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(PhosphorIcons.door(PhosphorIconsStyle.bold)),
              label: Text(_joining ? 'Uniéndose...' : 'Unirse a la Liga',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(0, 52),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Divider(color: AppColors.surfaceLight)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
            size: 18, color: AppColors.textMuted),
      ),
      Expanded(child: Divider(color: AppColors.surfaceLight)),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft':
        return AppColors.warning;
      case 'active':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft':
        return 'Inscripción';
      case 'active':
        return 'Activa';
      case 'completed':
        return 'Finalizada';
      default:
        return s;
    }
  }
}

// ── Helper: uppercase text formatter ──

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league.dart';

class LeagueBackofficeScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueBackofficeScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueBackofficeScreen> createState() =>
      _LeagueBackofficeScreenState();
}

class _LeagueBackofficeScreenState
    extends ConsumerState<LeagueBackofficeScreen> {
  final _leagueNameController = TextEditingController();
  final _leagueDescriptionController = TextEditingController();
  final _leagueMaxTeamsController = TextEditingController();

  final Map<String, _TeamEditorState> _teamEditors = {};
  final Set<String> _savingTeamIds = <String>{};
  final Set<String> _selectedCommissionerUsernames = <String>{};

  League? _league;
  Map<String, UserTeamDetail> _teamsById = {};
  bool _loading = true;
  bool _savingLeague = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBackoffice());
  }

  @override
  void dispose() {
    _leagueNameController.dispose();
    _leagueDescriptionController.dispose();
    _leagueMaxTeamsController.dispose();
    for (final editor in _teamEditors.values) {
      editor.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBackoffice({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final leagueRepo = ref.read(leagueRepositoryProvider);
      final teamRepo = ref.read(teamRepositoryProvider);

      final league = await leagueRepo.getLeague(widget.leagueId);
      final teams = await Future.wait(
        league.teams.map(
          (entry) => teamRepo.getUserTeamDetail(
            entry.teamId,
            leagueId: widget.leagueId,
          ),
        ),
      );

      if (!mounted) return;

      _leagueNameController.text = league.name;
      _leagueDescriptionController.text = league.description ?? '';
      _leagueMaxTeamsController.text = '${league.maxTeams}';
      _selectedCommissionerUsernames
        ..clear()
        ..addAll(
          league.commissionerUsernames.where(
            (username) => username != league.ownerUsername,
          ),
        );

      final nextTeams = {for (final team in teams) team.id: team};
      final removedIds =
          _teamEditors.keys.where((id) => !nextTeams.containsKey(id));
      for (final id in removedIds.toList()) {
        _teamEditors.remove(id)?.dispose();
      }
      for (final team in teams) {
        final editor = _teamEditors[team.id];
        if (editor == null) {
          _teamEditors[team.id] = _TeamEditorState.fromTeam(team);
        } else {
          editor.apply(team);
        }
      }

      setState(() {
        _league = league;
        _teamsById = nextTeams;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _saveLeague() async {
    final league = _league;
    if (league == null) return;

    final name = _leagueNameController.text.trim();
    final maxTeams = int.tryParse(_leagueMaxTeamsController.text.trim());
    final commissionerUsernames = _selectedCommissionerUsernames.toList()
      ..sort();

    if (name.isEmpty) {
      _showSnack('Ponle un nombre a la liga.', isError: true);
      return;
    }
    if (maxTeams == null || maxTeams < 2) {
      _showSnack('El maximo de equipos debe ser al menos 2.', isError: true);
      return;
    }

    setState(() => _savingLeague = true);
    try {
      await ref.read(leagueRepositoryProvider).updateLeagueSettings(
            league.id,
            name: name,
            description: _leagueDescriptionController.text.trim(),
            maxTeams: maxTeams,
            commissionerUsernames: commissionerUsernames,
          );
      await _loadBackoffice(showLoader: false);
      if (!mounted) return;
      _showSnack('Backoffice de liga actualizado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('$error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingLeague = false);
      }
    }
  }

  Future<void> _saveTeam(UserTeamDetail team) async {
    final editor = _teamEditors[team.id];
    if (editor == null) return;

    final treasury = int.tryParse(editor.treasuryController.text.trim());
    final rerolls = int.tryParse(editor.rerollsController.text.trim());
    final fanFactor = int.tryParse(editor.fanFactorController.text.trim());
    final dedicatedFans =
        int.tryParse(editor.dedicatedFansController.text.trim());
    final cheerleaders =
        int.tryParse(editor.cheerleadersController.text.trim());
    final assistantCoaches =
        int.tryParse(editor.assistantCoachesController.text.trim());

    if ([
      treasury,
      rerolls,
      fanFactor,
      dedicatedFans,
      cheerleaders,
      assistantCoaches
    ].contains(null)) {
      _showSnack('Revisa los campos numericos de ${team.name}.', isError: true);
      return;
    }

    setState(() => _savingTeamIds.add(team.id));
    try {
      final updated = await ref.read(teamRepositoryProvider).patchTeamStaff(
            team.id,
            name: editor.nameController.text.trim(),
            treasury: treasury,
            rerolls: rerolls,
            fanFactor: fanFactor,
            dedicatedFans: dedicatedFans,
            cheerleaders: cheerleaders,
            assistantCoaches: assistantCoaches,
            apothecary: editor.apothecary,
            leagueId: widget.leagueId,
            commissionerEdit: true,
          );

      if (!mounted) return;

      editor.apply(updated);
      setState(() {
        _teamsById = {
          ..._teamsById,
          updated.id: updated,
        };
      });
      _showSnack('${updated.name} actualizado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('$error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingTeamIds.remove(team.id));
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final league = _league;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Backoffice de liga'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _BackofficeErrorState(
                  message: _error!,
                  onRetry: _loadBackoffice,
                )
              : league == null
                  ? _BackofficeErrorState(
                      message: 'No se pudo cargar la liga.',
                      onRetry: _loadBackoffice,
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadBackoffice(showLoader: false),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1220),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHero(league),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final stacked = constraints.maxWidth < 920;
                                    if (stacked) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLeagueSettingsCard(league),
                                          const SizedBox(height: 16),
                                          _buildTeamSummaryCard(league),
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child:
                                              _buildLeagueSettingsCard(league),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: _buildTeamSummaryCard(league),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Equipos inscritos',
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFontFamily,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Edicion directa, sin ventanas intermedias. Cada tarjeta guarda sus cambios por separado.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...league.teams.map(_buildTeamCard),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHero(League league) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroTextWidth =
            constraints.maxWidth < 560 ? constraints.maxWidth : 520.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.95),
                AppColors.primaryDark,
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: heroTextWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Panel de comisario',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      league.name,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 42,
                        height: 0.95,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ajusta los parametros clave de la liga y corrige los equipos participantes desde un unico panel visual.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comisarios: ${league.commissionerUsernames.isEmpty ? league.ownerUsername : league.commissionerUsernames.join(', ')}',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _BackofficeStatCard(
                    icon: PhosphorIcons.flagPennant(PhosphorIconsStyle.fill),
                    label: 'Estado',
                    value: _statusLabel(league.status),
                  ),
                  _BackofficeStatCard(
                    icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                    label: 'Temporada',
                    value: '${league.season}',
                  ),
                  _BackofficeStatCard(
                    icon: PhosphorIcons.sword(PhosphorIconsStyle.fill),
                    label: 'Jornada',
                    value: '${league.currentRound ?? 1}',
                  ),
                  _BackofficeStatCard(
                    icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    label: 'Equipos',
                    value: '${league.teams.length}/${league.maxTeams}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeagueSettingsCard(League league) {
    return _BackofficePanel(
      title: 'Datos base de la liga',
      subtitle: 'Lo esencial arriba y editable al momento.',
      icon: PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _leagueNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration(
              'Nombre de liga',
              icon: PhosphorIcons.trophy(PhosphorIconsStyle.bold),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _leagueDescriptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: _inputDecoration(
              'Descripcion',
              icon: PhosphorIcons.notePencil(PhosphorIconsStyle.bold),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _leagueMaxTeamsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                'Maximo de equipos',
                icon: PhosphorIcons.users(PhosphorIconsStyle.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildCommissionerSelector(league),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _savingLeague ? null : _saveLeague,
            icon: _savingLeague
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            label: Text(_savingLeague ? 'Guardando...' : 'Guardar liga'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSummaryCard(League league) {
    final totalTreasury = _teamsById.values.fold<int>(
      0,
      (sum, team) => sum + team.treasury,
    );
    final averageTv = _teamsById.isEmpty
        ? 0
        : _teamsById.values.fold<int>(0, (sum, team) => sum + team.teamValue) ~/
            _teamsById.length;

    return _BackofficePanel(
      title: 'Radar rapido',
      subtitle: 'Lectura inmediata de la competicion.',
      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
      child: Column(
        children: [
          _summaryRow('Equipos cargados', '${league.teams.length}'),
          _summaryRow('Partidos registrados', '${league.matches.length}'),
          _summaryRow('Tesoreria total', _formatGold(totalTreasury)),
          _summaryRow('TV media', _formatGold(averageTv)),
          _summaryRow('Codigo de invitacion', league.inviteCode ?? '-'),
        ],
      ),
    );
  }

  Widget _buildCommissionerSelector(League league) {
    final members = _leagueMembers(league);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: Icon(
            PhosphorIcons.usersThree(PhosphorIconsStyle.bold),
            size: 18,
            color: AppColors.accent,
          ),
          title: const Text(
            'Comisarios',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _selectedCommissionerUsernames.isEmpty
                ? 'Selecciona miembros de la liga'
                : _selectedCommissionerUsernames.join(', '),
            style: const TextStyle(color: AppColors.textMuted),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BackofficeTag(
                      icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
                      label: 'Propietario fijo: ${league.ownerUsername}',
                    ),
                    ..._selectedCommissionerUsernames.map(
                      (username) => _BackofficeTag(
                        icon: PhosphorIcons.checkCircle(
                          PhosphorIconsStyle.fill,
                        ),
                        label: username,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...members.map(
              (member) => CheckboxListTile(
                dense: true,
                value: member.username == league.ownerUsername
                    ? true
                    : _selectedCommissionerUsernames.contains(member.username),
                onChanged: member.username == league.ownerUsername
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedCommissionerUsernames.add(member.username);
                          } else {
                            _selectedCommissionerUsernames
                                .remove(member.username);
                          }
                        });
                      },
                activeColor: AppColors.accent,
                title: Text(
                  member.username,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  member.teamName == null
                      ? 'Propietario de la liga'
                      : 'Equipo: ${member.teamName}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                secondary: Icon(
                  member.username == league.ownerUsername
                      ? PhosphorIcons.crown(PhosphorIconsStyle.fill)
                      : PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                  color: member.username == league.ownerUsername
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_LeagueMemberOption> _leagueMembers(League league) {
    final byUsername = <String, _LeagueMemberOption>{
      league.ownerUsername: _LeagueMemberOption(
        username: league.ownerUsername,
        teamName: null,
      ),
    };

    for (final team in league.teams) {
      byUsername.putIfAbsent(
        team.username,
        () => _LeagueMemberOption(
          username: team.username,
          teamName: team.teamName,
        ),
      );
    }

    final members = byUsername.values.toList()
      ..sort((left, right) {
        if (left.username == league.ownerUsername) return -1;
        if (right.username == league.ownerUsername) return 1;
        return left.username
            .toLowerCase()
            .compareTo(right.username.toLowerCase());
      });
    return members;
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(LeagueTeam leagueTeam) {
    final team = _teamsById[leagueTeam.teamId];
    if (team == null) return const SizedBox.shrink();

    final editor = _teamEditors[team.id]!;
    final saving = _savingTeamIds.contains(team.id);
    final headerWidth = MediaQuery.of(context).size.width < 520 ? 280.0 : 420.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: headerWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BackofficeTag(
                            icon: PhosphorIcons.shield(PhosphorIconsStyle.fill),
                            label: team.raceLabel,
                          ),
                          _BackofficeTag(
                            icon: PhosphorIcons.userCircle(
                                PhosphorIconsStyle.fill),
                            label: leagueTeam.username,
                          ),
                          _BackofficeTag(
                            icon: PhosphorIcons.usersThree(
                                PhosphorIconsStyle.fill),
                            label: '${team.players.length} jugadores',
                          ),
                          _BackofficeTag(
                            icon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
                            label: 'TV ${_formatGold(team.teamValue)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : () => _saveTeam(team),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(PhosphorIcons.checkFat(PhosphorIconsStyle.bold)),
                  label: Text(saving ? 'Guardando...' : 'Guardar equipo'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _numberField(editor.nameController,
                    label: 'Nombre', width: 260, isText: true),
                _numberField(editor.treasuryController,
                    label: 'Tesoreria', width: 180),
                _numberField(editor.rerollsController,
                    label: 'Rerolls', width: 150),
                _numberField(editor.fanFactorController,
                    label: 'Factor de hinchas', width: 170),
                _numberField(editor.dedicatedFansController,
                    label: 'Hinchas dedicados', width: 170),
                _numberField(editor.cheerleadersController,
                    label: 'Animadoras', width: 150),
                _numberField(editor.assistantCoachesController,
                    label: 'Asistentes', width: 150),
                SizedBox(
                  width: 220,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: editor.apothecary,
                      onChanged: editor.apothecaryAllowed
                          ? (value) => setState(() => editor.apothecary = value)
                          : null,
                      activeColor: AppColors.success,
                      title: const Text(
                        'Apotecario',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        editor.apothecaryAllowed
                            ? 'Activar o desactivar'
                            : 'No permitido para esta raza',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Coste de reroll base: ${_formatGold(team.rerollCost)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller, {
    required String label,
    required double width,
    bool isText = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: isText ? TextInputType.text : TextInputType.number,
        inputFormatters:
            isText ? null : [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon:
          icon == null ? null : Icon(icon, size: 18, color: AppColors.accent),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.surfaceLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.surfaceLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }

  String _statusLabel(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.draft:
        return 'Draft';
      case LeagueStatus.active:
        return 'Activa';
      case LeagueStatus.paused:
        return 'Pausada';
      case LeagueStatus.finished:
      case LeagueStatus.completed:
        return 'Completada';
      case LeagueStatus.cancelled:
        return 'Cancelada';
    }
  }

  String _formatGold(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      buffer.write(digits[index]);
      final remaining = digits.length - index - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    final prefix = value < 0 ? '-' : '';
    return '$prefix${buffer.toString()} gp';
  }
}

class _BackofficePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _BackofficePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _BackofficeStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BackofficeStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentLight, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BackofficeTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BackofficeTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BackofficeErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function({bool showLoader}) onRetry;

  const _BackofficeErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              size: 42,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamEditorState {
  final TextEditingController nameController;
  final TextEditingController treasuryController;
  final TextEditingController rerollsController;
  final TextEditingController fanFactorController;
  final TextEditingController dedicatedFansController;
  final TextEditingController cheerleadersController;
  final TextEditingController assistantCoachesController;
  final bool apothecaryAllowed;
  bool apothecary;

  _TeamEditorState._({
    required this.nameController,
    required this.treasuryController,
    required this.rerollsController,
    required this.fanFactorController,
    required this.dedicatedFansController,
    required this.cheerleadersController,
    required this.assistantCoachesController,
    required this.apothecaryAllowed,
    required this.apothecary,
  });

  factory _TeamEditorState.fromTeam(UserTeamDetail team) {
    return _TeamEditorState._(
      nameController: TextEditingController(text: team.name),
      treasuryController: TextEditingController(text: '${team.treasury}'),
      rerollsController: TextEditingController(text: '${team.rerolls}'),
      fanFactorController: TextEditingController(text: '${team.fanFactor}'),
      dedicatedFansController:
          TextEditingController(text: '${team.dedicatedFans}'),
      cheerleadersController:
          TextEditingController(text: '${team.cheerleaders}'),
      assistantCoachesController:
          TextEditingController(text: '${team.assistantCoaches}'),
      apothecaryAllowed: team.apothecaryAllowed,
      apothecary: team.apothecary,
    );
  }

  void apply(UserTeamDetail team) {
    nameController.text = team.name;
    treasuryController.text = '${team.treasury}';
    rerollsController.text = '${team.rerolls}';
    fanFactorController.text = '${team.fanFactor}';
    dedicatedFansController.text = '${team.dedicatedFans}';
    cheerleadersController.text = '${team.cheerleaders}';
    assistantCoachesController.text = '${team.assistantCoaches}';
    apothecary = team.apothecary;
  }

  void dispose() {
    nameController.dispose();
    treasuryController.dispose();
    rerollsController.dispose();
    fanFactorController.dispose();
    dedicatedFansController.dispose();
    cheerleadersController.dispose();
    assistantCoachesController.dispose();
  }
}

class _LeagueMemberOption {
  final String username;
  final String? teamName;

  const _LeagueMemberOption({
    required this.username,
    required this.teamName,
  });
}

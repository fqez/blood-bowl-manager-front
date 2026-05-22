import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roster/domain/models/team.dart';
import '../../../shared/data/repositories.dart';
import '../../../team_creator/presentation/screens/team_creator_screen.dart';

// ignore_for_file: deprecated_member_use

/// Provider that fetches the user's saved tactics.
final myTacticsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getMyTactics();
});

class MyTacticsScreen extends ConsumerStatefulWidget {
  const MyTacticsScreen({super.key});

  @override
  ConsumerState<MyTacticsScreen> createState() => _MyTacticsScreenState();
}

class _MyTacticsScreenState extends ConsumerState<MyTacticsScreen> {
  String? _selectedRosterId;

  Map<String, dynamic> _exportableTactic(Map<String, dynamic> tactic) {
    return {
      'name': tactic['name'] ?? 'Tactica importada',
      'base_roster_id': tactic['base_roster_id'],
      'mode': tactic['mode'] ?? 'attack',
      'placements': tactic['placements'] ?? const [],
      'good_against': tactic['good_against'] ?? const [],
      'notes': tactic['notes'] ?? '',
    };
  }

  Future<void> _exportTactics(
    List<Map<String, dynamic>> tactics,
    String lang,
  ) async {
    if (tactics.isEmpty) return;
    try {
      final repo = ref.read(teamRepositoryProvider);
      final details = await Future.wait(tactics.map((tactic) async {
        final id = tactic['id'] as String?;
        return id == null ? tactic : await repo.getTactic(id);
      }));
      final payload = {
        'bbm_tactics_export': 1,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'tactics': details.map(_exportableTactic).toList(),
      };
      const encoder = JsonEncoder.withIndent('  ');
      await Clipboard.setData(ClipboardData(text: encoder.convert(payload)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${details.length} táctica(s) copiadas como JSON'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trf(lang, 'common.error', {'e': '$e'})),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showImportDialog(String lang) async {
    final controller = TextEditingController();
    final jsonText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Importar tácticas',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 14,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              hintText: 'Pega aquí el JSON exportado',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (jsonText == null || jsonText.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(jsonText);
      final tactics = _readImportedTactics(decoded);
      if (tactics.isEmpty) throw const FormatException('JSON sin tácticas');
      final repo = ref.read(teamRepositoryProvider);
      for (final tactic in tactics) {
        await repo.createTactic(tactic);
      }
      ref.invalidate(myTacticsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tactics.length} táctica(s) importadas'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trf(lang, 'common.error', {'e': '$e'})),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _readImportedTactics(Object? decoded) {
    final rawTactics = decoded is Map<String, dynamic>
        ? decoded['tactics'] ?? decoded
        : decoded;
    final list = rawTactics is List ? rawTactics : [rawTactics];
    return list
        .whereType<Map>()
        .map((raw) => _normalizeImportedTactic(raw.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _normalizeImportedTactic(Map<String, dynamic> raw) {
    final rosterId = raw['base_roster_id'];
    if (rosterId is! String || rosterId.isEmpty) {
      throw const FormatException('Falta base_roster_id');
    }
    final placements = (raw['placements'] as List? ?? const [])
        .whereType<Map>()
        .map((placement) {
      final data = placement.cast<String, dynamic>();
      final row = data['row'];
      final col = data['col'];
      final positionId = data['position_id'];
      if (row is! int || col is! int || positionId is! String) {
        throw const FormatException('Placement inválido');
      }
      return {'row': row, 'col': col, 'position_id': positionId};
    }).toList();
    return {
      'name': (raw['name'] as String?)?.trim().isNotEmpty == true
          ? (raw['name'] as String).trim()
          : 'Táctica importada',
      'base_roster_id': rosterId,
      'mode': raw['mode'] == 'defense' ? 'defense' : 'attack',
      'placements': placements,
      'good_against': (raw['good_against'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      'notes': raw['notes'] as String? ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final tacticsAsync = ref.watch(myTacticsProvider);
    final rostersAsync = ref.watch(baseRostersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context, lang),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, lang),
                  const SizedBox(height: 20),
                  tacticsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        children: [
                          Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                              size: 40, color: AppColors.error),
                          const SizedBox(height: 8),
                          Text('Error: $e',
                              style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(myTacticsProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    data: (tactics) {
                      if (tactics.isEmpty) {
                        return _buildEmptyState(context, lang);
                      }

                      final rosterMap = {
                        for (final team
                            in rostersAsync.valueOrNull ?? const <BaseTeam>[])
                          team.id: team,
                      };
                      final filteredTactics = _selectedRosterId == null
                          ? tactics
                          : tactics
                              .where((tactic) =>
                                  tactic['base_roster_id'] == _selectedRosterId)
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${filteredTactics.length} TÁCTICAS GUARDADAS',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showImportDialog(lang),
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: const Text('Importar'),
                              ),
                              OutlinedButton.icon(
                                onPressed: filteredTactics.isEmpty
                                    ? null
                                    : () => _exportTactics(
                                          filteredTactics,
                                          lang,
                                        ),
                                icon: const Icon(Icons.file_download, size: 16),
                                label: const Text('Exportar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTeamFilter(tactics, rosterMap, lang),
                          const SizedBox(height: 18),
                          _buildGroupedTactics(
                              context, ref, filteredTactics, rosterMap, lang),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilter(List<Map<String, dynamic>> tactics,
      Map<String, BaseTeam> rosterMap, String lang) {
    final rosterIds = tactics
        .map((tactic) => tactic['base_roster_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) =>
          _rosterName(a, rosterMap).compareTo(_rosterName(b, rosterMap)));

    if (rosterIds.length <= 1) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: _selectedRosterId == null,
          onSelected: (_) => setState(() => _selectedRosterId = null),
          selectedColor: AppColors.primary.withOpacity(0.25),
          backgroundColor: AppColors.card,
          labelStyle: TextStyle(
            color: _selectedRosterId == null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: _selectedRosterId == null
                ? AppColors.primary
                : AppColors.surfaceLight,
          ),
        ),
        ...rosterIds.map((rosterId) {
          final selected = _selectedRosterId == rosterId;
          return ChoiceChip(
            avatar: _buildRosterLogo(rosterId, size: 20),
            label: Text(_rosterName(rosterId, rosterMap)),
            selected: selected,
            onSelected: (_) => setState(() => _selectedRosterId = rosterId),
            selectedColor: AppColors.primary.withOpacity(0.25),
            backgroundColor: AppColors.card,
            labelStyle: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.surfaceLight,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGroupedTactics(
      BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> tactics,
      Map<String, BaseTeam> rosterMap,
      String lang) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final tactic in tactics) {
      final rosterId = tactic['base_roster_id'] as String? ?? '';
      grouped.putIfAbsent(rosterId, () => []).add(tactic);
    }

    final rosterIds = grouped.keys.toList()
      ..sort((a, b) =>
          _rosterName(a, rosterMap).compareTo(_rosterName(b, rosterMap)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rosterIds.length; index++) ...[
          _buildTeamSectionHeader(
              rosterIds[index], grouped[rosterIds[index]]!.length, rosterMap),
          const SizedBox(height: 10),
          _buildTacticsGrid(
              context, ref, grouped[rosterIds[index]]!, rosterMap, lang),
          if (index != rosterIds.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTeamSectionHeader(
      String rosterId, int count, Map<String, BaseTeam> rosterMap) {
    return Row(
      children: [
        _buildRosterLogo(rosterId, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _rosterName(rosterId, rosterMap).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _rosterName(String rosterId, Map<String, BaseTeam> rosterMap) {
    if (rosterId.isEmpty) return 'Sin equipo';
    return rosterMap[rosterId]?.name ?? rosterId;
  }

  Widget _buildRosterLogo(String rosterId, {double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: rosterId.isNotEmpty
          ? Image.asset(
              'assets/teams/$rosterId/logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                PhosphorIcons.shield(PhosphorIconsStyle.fill),
                size: size * 0.65,
                color: AppColors.textMuted,
              ),
            )
          : Icon(
              PhosphorIcons.shield(PhosphorIconsStyle.fill),
              size: size * 0.65,
              color: AppColors.textMuted,
            ),
    );
  }

  Widget _buildTopBar(BuildContext context, String lang) {
    final isCompact = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill),
                color: AppColors.accent, size: 22),
            Text(
              'TÁCTICAS',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            if (!isCompact)
              const Text('  >  ',
                  style: TextStyle(fontSize: 11, color: Colors.white38)),
            Text(
              tr(lang, 'myTactics.title'),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    final isCompact = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill),
                        color: AppColors.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(lang, 'myTactics.title'),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tr(lang, 'myTactics.subtitle'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showImportDialog(lang),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('IMPORTAR'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/tactics'),
                      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 16),
                      label: Text(
                        'NUEVA',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill),
                              color: AppColors.accent, size: 26),
                          const SizedBox(width: 12),
                          Text(
                            tr(lang, 'myTactics.title'),
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(lang, 'myTactics.subtitle'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _showImportDialog(lang),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('IMPORTAR'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/tactics'),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 16),
                  label: Text(
                    'NUEVA',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(PhosphorIcons.crosshair(PhosphorIconsStyle.regular),
                size: 60, color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              tr(lang, 'myTactics.noTactics'),
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              tr(lang, 'myTactics.createFirst'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/tactics'),
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
              label: Text(
                'CREAR TÁCTICA',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showImportDialog(lang),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('IMPORTAR JSON'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticsGrid(
      BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> tactics,
      Map<String, BaseTeam> rosterMap,
      String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
                ? 2
                : 1;
        final spacing = columns == 1 ? 10.0 : 12.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tactics
              .map((tactic) => SizedBox(
                    width: cardWidth,
                    child:
                        _buildTacticCard(context, ref, tactic, rosterMap, lang),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTacticCard(
      BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> tactic,
      Map<String, BaseTeam> rosterMap,
      String lang) {
    final id = tactic['id'] as String;
    final name = tactic['name'] as String? ?? 'Sin nombre';
    final mode = tactic['mode'] as String? ?? 'attack';
    final rosterId = tactic['base_roster_id'] as String? ?? '';
    final playerCount = tactic['player_count'] as int? ?? 0;
    final goodAgainstCount = tactic['good_against_count'] as int? ?? 0;
    final roster = rosterMap[rosterId];
    final isAttack = mode == 'attack';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/tactics?id=$id'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 178),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRosterLogo(rosterId),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roster?.name ?? rosterId,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.file_download, size: 18),
                        color: AppColors.accent.withOpacity(0.8),
                        onPressed: () => _exportTactics([tactic], lang),
                        tooltip: 'Exportar',
                        splashRadius: 18,
                      ),
                      IconButton(
                        icon: Icon(
                            PhosphorIcons.trash(PhosphorIconsStyle.regular),
                            size: 18,
                            color: AppColors.error.withOpacity(0.6)),
                        onPressed: () =>
                            _confirmDelete(context, ref, id, name, lang),
                        tooltip: tr(lang, 'myTactics.delete'),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildModeBadge(isAttack, lang),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildMetricChip(
                    PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    '$playerCount jugadores',
                    AppColors.textSecondary,
                  ),
                  if (goodAgainstCount > 0)
                    _buildMetricChip(
                      PhosphorIcons.sword(PhosphorIconsStyle.fill),
                      '$goodAgainstCount',
                      AppColors.success,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildModeBadge(bool isAttack, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isAttack ? AppColors.error : const Color(0xFF2196F3))
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAttack
              ? AppColors.error.withOpacity(0.4)
              : const Color(0xFF2196F3).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAttack
                ? PhosphorIcons.sword(PhosphorIconsStyle.fill)
                : PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
            size: 12,
            color: isAttack ? AppColors.error : const Color(0xFF2196F3),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tr(lang, isAttack ? 'tactics.attack' : 'tactics.defense')
                  .toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isAttack ? AppColors.error : const Color(0xFF2196F3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id,
      String name, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(lang, 'myTactics.delete'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Eliminar "$name"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(lang, 'common.cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(teamRepositoryProvider);
                await repo.deleteTactic(id);
                ref.invalidate(myTacticsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(trf(lang, 'common.error', {'e': '$e'})),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(tr(lang, 'common.delete'),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

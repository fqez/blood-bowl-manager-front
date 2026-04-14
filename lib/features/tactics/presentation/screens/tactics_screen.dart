import 'package:flutter/material.dart';
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

/// Half-field: 15 columns wide × 14 rows deep.
/// Row 0 = opponent LoS, Row 1 = your LoS, Rows 2–13 = your half + end zone.
const int _pitchCols = 15;
const int _pitchRows = 14;

/// Line of scrimmage = row 1 (your side). Row 0 is opponent's side.
const int _losRow = 1;

/// Wide zones: cols 0-3 (left) and cols 11-14 (right).
const int _wideZoneLeft = 3; // cols 0..3
const int _wideZoneRight = 11; // cols 11..14

/// Grid alignment — exact pixel coordinates from the 1024×1024 pitch image.
const double _imgSize = 1024;
const double _gridOriginX = 20;
const double _gridOriginY = 107;
const double _cellPx = 65.6;

/// Generic opponent position types (placed only on row 0).
const String _oppLineman = 'opp_lineman';
const String _oppBlitzer = 'opp_blitzer';
const String _oppBigGuy = 'opp_big_guy';

class TacticsScreen extends ConsumerStatefulWidget {
  /// When non-null, load an existing tactic for editing.
  final String? tacticId;

  const TacticsScreen({super.key, this.tacticId});

  @override
  ConsumerState<TacticsScreen> createState() => _TacticsScreenState();
}

class _TacticsScreenState extends ConsumerState<TacticsScreen> {
  BaseTeam? _selectedTeam;
  String? _selectedPositionId;

  /// attack or defense
  String _mode = 'attack';

  // Grid state: key = "row_col", value = position id
  final Map<String, String> _grid = {};

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _goodAgainst = {};

  bool _saving = false;
  bool _loading = false;
  String? _existingTacticId;
  bool _placingOpponent = false;
  String _selectedOpponentId = _oppLineman;

  @override
  void initState() {
    super.initState();
    if (widget.tacticId != null) {
      _existingTacticId = widget.tacticId;
      _loadExistingTactic(widget.tacticId!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Load existing tactic ──────────────────────────────────────────────────

  Future<void> _loadExistingTactic(String tacticId) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(teamRepositoryProvider);
      final data = await repo.getTactic(tacticId);

      final rosterId = data['base_roster_id'] as String;
      final detail = await repo.getBaseTeamDetail(rosterId);

      final placements = (data['placements'] as List?) ?? [];
      final gridMap = <String, String>{};
      for (final p in placements) {
        final row = p['row'] as int;
        final col = p['col'] as int;
        gridMap['${row}_$col'] = p['position_id'] as String;
      }

      setState(() {
        _selectedTeam = detail;
        _selectedPositionId =
            detail.positions.isNotEmpty ? detail.positions.first.id : null;
        _nameController.text = data['name'] as String? ?? '';
        _mode = data['mode'] as String? ?? 'attack';
        _notesController.text = data['notes'] as String? ?? '';
        _goodAgainst
          ..clear()
          ..addAll(((data['good_against'] as List?) ?? []).cast<String>());
        _grid
          ..clear()
          ..addAll(gridMap);
      });
    } catch (e) {
      if (mounted) {
        final lang = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.error', {'e': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Save / Update tactic ──────────────────────────────────────────────────

  Future<void> _saveTactic() async {
    if (_selectedTeam == null) return;
    final lang = ref.read(localeProvider);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(lang, 'tactics.tacticName')),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(teamRepositoryProvider);
      final placements = _grid.entries.map((e) {
        final parts = e.key.split('_');
        return {
          'row': int.parse(parts[0]),
          'col': int.parse(parts[1]),
          'position_id': e.value,
        };
      }).toList();

      final body = {
        'name': name,
        'base_roster_id': _selectedTeam!.id,
        'mode': _mode,
        'placements': placements,
        'good_against': _goodAgainst.toList(),
        'notes': _notesController.text,
      };

      if (_existingTacticId != null) {
        await repo.updateTactic(_existingTacticId!, body);
      } else {
        final created = await repo.createTactic(body);
        _existingTacticId = created['id'] as String?;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(lang, 'common.save')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.error', {'e': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Select team (loads detail endpoint with positions) ─────────────────────

  Future<void> _selectTeam(String teamId) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(teamRepositoryProvider);
      final detail = await repo.getBaseTeamDetail(teamId);
      setState(() {
        _selectedTeam = detail;
        _selectedPositionId =
            detail.positions.isNotEmpty ? detail.positions.first.id : null;
        _grid.clear();
      });
    } catch (e) {
      if (mounted) {
        final lang = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.error', {'e': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _countPlaced(String positionId) =>
      _grid.values.where((v) => v == positionId).length;

  int get _totalPlaced =>
      _grid.values.where((v) => !v.startsWith('opp_')).length;

  /// Players on the LoS (row 1 — own team only)
  int get _losCount => _grid.entries
      .where((e) => _parseRow(e.key) == _losRow && !e.value.startsWith('opp_'))
      .length;

  int _parseRow(String key) => int.parse(key.split('_')[0]);
  int _parseCol(String key) => int.parse(key.split('_')[1]);
  String _cellKey(int row, int col) => '${row}_$col';

  /// Per-wide-zone counts (own team only)
  int get _leftWideCount => _grid.entries
      .where((e) =>
          _parseCol(e.key) <= _wideZoneLeft && !e.value.startsWith('opp_'))
      .length;
  int get _rightWideCount => _grid.entries
      .where((e) =>
          _parseCol(e.key) >= _wideZoneRight && !e.value.startsWith('opp_'))
      .length;

  List<String> get _validationErrors {
    final errors = <String>[];
    if (_totalPlaced > 11) errors.add('Máximo 11 jugadores en el campo');
    if (_totalPlaced >= 3 && _losCount < 3) {
      errors.add('Mínimo 3 jugadores en la Línea de Scrimmage');
    }
    if (_leftWideCount > 2) errors.add('Máx. 2 jugadores en banda izquierda');
    if (_rightWideCount > 2) errors.add('Máx. 2 jugadores en banda derecha');
    return errors;
  }

  void _onCellTap(int row, int col) {
    final key = _cellKey(row, col);
    setState(() {
      if (_grid.containsKey(key)) {
        _grid.remove(key);
      } else if (_placingOpponent) {
        if (row == 0) {
          _grid[key] = _selectedOpponentId;
        }
      } else if (_selectedPositionId != null && _totalPlaced < 11) {
        if (row >= _losRow) {
          final pos = _selectedTeam?.positions
              .where((p) => p.id == _selectedPositionId)
              .firstOrNull;
          if (pos != null && _countPlaced(pos.id) < pos.maxQuantity) {
            _grid[key] = pos.id;
          }
        }
      }
    });
  }

  // Distinct palette – each position in a roster gets a unique colour.
  static const _positionPalette = <Color>[
    Color(0xFF795548), // brown
    Color(0xFF00BCD4), // cyan
    Color(0xFFE91E63), // pink
    Color(0xFFE53935), // red
    Color(0xFF4CAF50), // green
    Color(0xFF2196F3), // blue
    Color(0xFFFF9800), // orange
    Color(0xFF9C27B0), // purple
    Color(0xFFFF5722), // deep orange
    Color(0xFF009688), // teal
    Color(0xFF3F51B5), // indigo
    Color(0xFFCDDC39), // lime
  ];

  Color _positionColor(String positionId) {
    if (positionId == _oppLineman) return const Color(0xFF5C6BC0);
    if (positionId == _oppBlitzer) return const Color(0xFFB71C1C);
    if (positionId == _oppBigGuy) return const Color(0xFF4A148C);

    final positions = _selectedTeam?.positions ?? [];
    final index = positions.indexWhere((p) => p.id == positionId);
    if (index < 0) return AppColors.textMuted;
    return _positionPalette[index % _positionPalette.length];
  }

  String _positionAbbrev(String positionId) {
    if (positionId == _oppLineman) return 'LN';
    if (positionId == _oppBlitzer) return 'BZ';
    if (positionId == _oppBigGuy) return 'BG';

    final pos =
        _selectedTeam?.positions.where((p) => p.id == positionId).firstOrNull;
    if (pos == null) return '?';
    final words = pos.name.split(RegExp(r'[\s/]+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return pos.name.substring(0, pos.name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final rostersAsync = ref.watch(baseRostersProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopBar(lang),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(lang),
                        const SizedBox(height: 20),
                        _buildTeamSelector(rostersAsync, lang),
                        const SizedBox(height: 20),
                        if (_selectedTeam != null) ...[
                          // Name + mode + save bar
                          _buildTacticBar(lang),
                          const SizedBox(height: 16),
                          // Position selector always on top
                          _buildPositionSelector(lang),
                          const SizedBox(height: 16),
                          // Opponent placement selector
                          _buildOpponentSelector(lang),
                          const SizedBox(height: 16),
                          // Validation + stats bar
                          _buildStatsBar(lang),
                          const SizedBox(height: 16),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildPitchSection()),
                                const SizedBox(width: 20),
                                Expanded(
                                    flex: 2,
                                    child: _buildSidePanel(rostersAsync)),
                              ],
                            )
                          else ...[
                            _buildPitchSection(),
                            const SizedBox(height: 20),
                            _buildSidePanel(rostersAsync),
                          ],
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopBar(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(PhosphorIcons.crosshair(PhosphorIconsStyle.fill),
                color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Text(
              'TÁCTICAS',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const Text('  >  ',
                style: TextStyle(fontSize: 11, color: Colors.white38)),
            Text(
              'FORMACIÓN DE KICKOFF',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.go('/my-tactics'),
              icon:
                  Icon(PhosphorIcons.folder(PhosphorIconsStyle.fill), size: 18),
              label: Text(
                tr(lang, 'myTactics.title'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.crosshair(PhosphorIconsStyle.fill),
                  color: AppColors.accent, size: 26),
              const SizedBox(width: 12),
              Text(
                tr(lang, 'tactics.title'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
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
            tr(lang, 'tactics.subtitle'),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // -- Team Selector ----------------------------------------------------------

  Widget _buildTeamSelector(
      AsyncValue<List<BaseTeam>> rostersAsync, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(lang, 'tactics.selectTeam'),
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 10),
          rostersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (teams) {
              final sorted = List<BaseTeam>.from(teams)
                ..sort((a, b) => a.name.compareTo(b.name));
              return DropdownButtonFormField<String>(
                value: _selectedTeam?.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                dropdownColor: AppColors.surface,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                hint: const Text('Elige un equipo...',
                    style: TextStyle(color: AppColors.textMuted)),
                items: sorted
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/teams/${t.id}/logo.webp',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                      PhosphorIcons.shield(
                                          PhosphorIconsStyle.fill),
                                      size: 18,
                                      color: AppColors.textMuted),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(t.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  _selectTeam(id);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // -- Stats bar ---------------------------------------------------------------

  Widget _buildTacticBar(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: tr(lang, 'tactics.tacticName'),
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              prefixIcon: Icon(PhosphorIcons.tag(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.accent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          // Mode selector + save button
          Row(
            children: [
              _modeChip('attack', tr(lang, 'tactics.attack'),
                  PhosphorIcons.sword(PhosphorIconsStyle.fill),
                  color: AppColors.error),
              const SizedBox(width: 8),
              _modeChip('defense', tr(lang, 'tactics.defense'),
                  PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
                  color: const Color(0xFF2196F3)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveTactic,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill),
                        size: 20),
                label: Text(
                  _existingTacticId != null
                      ? tr(lang, 'tactics.save')
                      : tr(lang, 'tactics.save'),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String mode, String label, IconData icon,
      {required Color color}) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.surfaceLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? color : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _pitchStat(
                  trf(lang, 'tactics.ownPlayers', {'n': '$_totalPlaced'}), ''),
              const SizedBox(width: 12),
              _pitchStat(
                  trf(lang, 'tactics.losCount', {'n': '$_losCount'}), ''),
              const SizedBox(width: 12),
              _pitchStat('Banda izq.', '$_leftWideCount/2'),
              const SizedBox(width: 12),
              _pitchStat('Banda der.', '$_rightWideCount/2'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _grid.clear()),
                icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                    size: 14),
                label: Text(tr(lang, 'tactics.clear'),
                    style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.error.withOpacity(0.7)),
              ),
            ],
          ),
          if (_validationErrors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: _validationErrors
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Icon(
                                  PhosphorIcons.warning(
                                      PhosphorIconsStyle.fill),
                                  size: 13,
                                  color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.warning))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // -- Pitch Section (image + overlay grid) -----------------------------------

  Widget _buildPitchSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The image is square (1024×1024).
          final imageWidth = constraints.maxWidth;
          final scale = imageWidth / _imgSize;
          final imageHeight = imageWidth; // 1:1 aspect ratio

          // Exact grid positioning from pixel coordinates
          final gridLeft = _gridOriginX * scale;
          final gridTop = _gridOriginY * scale;
          final cellW = _cellPx * scale;
          final cellH = _cellPx * scale;
          final gridW = _pitchCols * cellW;
          final gridH = _pitchRows * cellH;

          return SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background pitch image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/plantilla_pitch.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2E7D32),
                      child: const Center(
                        child: Text(
                          'Imagen del campo no disponible',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                // Interactive grid overlay — exact pixel alignment
                Positioned(
                  left: gridLeft,
                  top: gridTop,
                  width: gridW,
                  height: gridH,
                  child: _buildGridOverlay(cellW, cellH),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridOverlay(double cellW, double cellH) {
    return Column(
      children: List.generate(_pitchRows, (row) {
        return SizedBox(
          height: cellH,
          child: Row(
            children: List.generate(_pitchCols, (col) {
              return SizedBox(
                width: cellW,
                height: cellH,
                child: _buildOverlayCell(row, col, cellW, cellH),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildOverlayCell(int row, int col, double cellW, double cellH) {
    final key = _cellKey(row, col);
    final occupant = _grid[key];
    final isLoS = row == _losRow;
    final isOpponentRow = row == 0;
    final isOpp = occupant != null && occupant.startsWith('opp_');
    final minSide = cellW < cellH ? cellW : cellH;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isLoS
                ? Colors.white.withOpacity(0.12)
                : isOpponentRow
                    ? Colors.red.withOpacity(0.10)
                    : Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
          color: isLoS && occupant == null
              ? AppColors.primary.withOpacity(0.06)
              : isOpponentRow && occupant == null
                  ? Colors.red.withOpacity(0.04)
                  : Colors.transparent,
        ),
        child: occupant != null
            ? Center(
                child: Container(
                  width: minSide * (isOpp ? 0.72 : 0.82),
                  height: minSide * (isOpp ? 0.72 : 0.82),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.9,
                      colors: isOpp
                          ? [
                              Color.lerp(_positionColor(occupant), Colors.white,
                                  0.15)!,
                              _positionColor(occupant).withOpacity(0.8),
                              Color.lerp(
                                  _positionColor(occupant), Colors.black, 0.4)!,
                            ]
                          : [
                              Color.lerp(
                                  _positionColor(occupant), Colors.white, 0.3)!,
                              _positionColor(occupant),
                              Color.lerp(_positionColor(occupant), Colors.black,
                                  0.25)!,
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: isOpp ? const Color(0xFFFF5252) : Colors.white,
                      width: isOpp ? 1.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isOpp ? 0.4 : 0.6),
                        blurRadius: isOpp ? 3 : 5,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: _positionColor(occupant)
                            .withOpacity(isOpp ? 0.3 : 0.5),
                        blurRadius: isOpp ? 4 : 8,
                        spreadRadius: isOpp ? 0 : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _positionAbbrev(occupant),
                      style: TextStyle(
                        fontSize: minSide * (isOpp ? 0.25 : 0.3),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Colors.black87,
                              blurRadius: 3,
                              offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _pitchStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // -- Side panel (legend + rules + notes + good against) ---------------------

  Widget _buildSidePanel(AsyncValue<List<BaseTeam>> rostersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPositionLegend(),
        const SizedBox(height: 16),
        _buildRulesCard(),
        const SizedBox(height: 16),
        _buildNotesCard(),
        const SizedBox(height: 16),
        _buildGoodAgainstCard(rostersAsync),
      ],
    );
  }

  Widget _buildPositionSelector(String lang) {
    final positions = _selectedTeam?.positions ?? [];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !_placingOpponent
              ? AppColors.accent.withOpacity(0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(tr(lang, 'tactics.yourPositions'),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: !_placingOpponent
                        ? AppColors.accent
                        : AppColors.textMuted,
                    letterSpacing: 0.8,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'tactics.selectPosition'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: positions.map((pos) {
              final isSelected =
                  !_placingOpponent && _selectedPositionId == pos.id;
              final placed = _countPlaced(pos.id);
              final color = _positionColor(pos.id);
              return GestureDetector(
                onTap: () => setState(() {
                  _placingOpponent = false;
                  _selectedPositionId = pos.id;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? color.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.surfaceLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            _positionAbbrev(pos.id),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pos.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$placed / ${pos.maxQuantity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: placed >= pos.maxQuantity
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSelector(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _placingOpponent
              ? const Color(0xFFFF5252).withOpacity(0.5)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  size: 20, color: const Color(0xFFFF5252)),
              const SizedBox(width: 10),
              Text(tr(lang, 'tactics.opponent'),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _placingOpponent
                        ? const Color(0xFFFF5252)
                        : AppColors.textMuted,
                    letterSpacing: 0.8,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _placingOpponent = !_placingOpponent;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _placingOpponent
                        ? const Color(0xFFFF5252).withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _placingOpponent
                          ? const Color(0xFFFF5252)
                          : AppColors.surfaceLight,
                      width: _placingOpponent ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _placingOpponent ? 'COLOCANDO RIVAL' : 'ACTIVAR',
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _placingOpponent
                          ? const Color(0xFFFF5252)
                          : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'tactics.opponentDesc'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _oppChip(_oppLineman, tr(lang, 'tactics.oppLineman'), 'LN'),
              _oppChip(_oppBlitzer, tr(lang, 'tactics.oppBlitzer'), 'BZ'),
              _oppChip(_oppBigGuy, tr(lang, 'tactics.oppBigGuy'), 'BG'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oppChip(String id, String name, String abbr) {
    final selected = _placingOpponent && _selectedOpponentId == id;
    final color = _positionColor(id);
    return GestureDetector(
      onTap: () => setState(() {
        _placingOpponent = true;
        _selectedOpponentId = id;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.surfaceLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
              ),
              child: Center(
                child: Text(
                  abbr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionLegend() {
    final positions = _selectedTeam?.positions ?? [];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEYENDA DE POSICIONES',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 10),
          ...positions.map((pos) {
            final color = _positionColor(pos.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        _positionAbbrev(pos.id),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(pos.name,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Text('${_countPlaced(pos.id)}/${pos.maxQuantity}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _countPlaced(pos.id) >= pos.maxQuantity
                            ? AppColors.error
                            : AppColors.textMuted,
                      )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REGLAS DE SETUP',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          _ruleRow('Máximo 11 jugadores en el campo'),
          _ruleRow('Mínimo 3 en la Línea de Scrimmage'),
          _ruleRow('Máximo 2 jugadores por Wide Zone (banda)'),
          _ruleRow('Todos en tu mitad del campo'),
        ],
      ),
    );
  }

  Widget _ruleRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: 12, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('NOTAS',
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 5,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            decoration: InputDecoration(
              hintText:
                  'Apunta tu plan táctico, matchups clave, jugadas especiales...',
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // -- Good Against -----------------------------------------------------------

  Widget _buildGoodAgainstCard(AsyncValue<List<BaseTeam>> rostersAsync) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.sword(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Text('BUENO CONTRA',
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona los equipos contra los que esta formación funciona bien.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          rostersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (teams) {
              final sorted = List<BaseTeam>.from(teams)
                ..sort((a, b) => a.name.compareTo(b.name));
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sorted.map((team) {
                  final selected = _goodAgainst.contains(team.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _goodAgainst.remove(team.id);
                        } else {
                          _goodAgainst.add(team.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.success
                              : AppColors.surfaceLight,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(
                              'assets/teams/${team.id}/logo.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                  PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            team.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            Icon(
                                PhosphorIcons.checkCircle(
                                    PhosphorIconsStyle.fill),
                                size: 14,
                                color: AppColors.success),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

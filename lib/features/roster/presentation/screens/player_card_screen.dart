import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/perk_assets.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../league/domain/models/league.dart';
import '../../../my_teams/domain/models/user_team.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/utils/player_position_labels.dart';
import '../../domain/models/team.dart';
import '../screens/roster_screen.dart';
import '../utils/player_image_picker.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';

// ignore_for_file: deprecated_member_use

final _playerBaseRosterProvider =
    FutureProvider.family<BaseTeam, String>((ref, rosterId) async {
  return ref.watch(teamRepositoryProvider).getBaseTeamDetail(rosterId);
});

final _leagueContextProvider =
    FutureProvider.autoDispose.family<League, String>((ref, leagueId) async {
  return ref.watch(leagueRepositoryProvider).getLeague(leagueId);
});

final _playerUserTeamDetailProvider = FutureProvider.autoDispose
    .family<UserTeamDetail, String>((ref, teamId) async {
  if (teamId.startsWith('league|')) {
    final payload = teamId.substring(7);
    final splitAt = payload.indexOf('|');
    if (splitAt <= 0 || splitAt >= payload.length - 1) {
      throw StateError('Invalid league player detail key: $teamId');
    }
    final leagueId = payload.substring(0, splitAt);
    final actualTeamId = payload.substring(splitAt + 1);
    return ref
        .watch(teamRepositoryProvider)
        .getUserTeamDetail(actualTeamId, leagueId: leagueId);
  }
  return ref.watch(teamRepositoryProvider).getUserTeamDetail(teamId);
});

class _SkillAdvancementChoice {
  final Map<String, dynamic>? perk;
  final String advancementType;
  final String? characteristic;
  final int? characteristicRoll;
  final String? resultLabel;

  const _SkillAdvancementChoice({
    this.perk,
    required this.advancementType,
    this.characteristic,
    this.characteristicRoll,
    this.resultLabel,
  });
}

class _SkillCategoryAccess {
  final String symbol;
  final String family;
  final String label;
  final String? access;

  const _SkillCategoryAccess({
    required this.symbol,
    required this.family,
    required this.label,
    required this.access,
  });

  bool get enabled => access != null;
  String get advancementType =>
      access == 'PRIMARY' ? 'choose_primary_skill' : 'choose_secondary_skill';
}

class _RandomSkillRollOption {
  final Map<String, dynamic>? perk;
  final String englishName;
  final String displayName;
  final List<String> rollLabels;
  final bool isOwned;

  _RandomSkillRollOption({
    required this.perk,
    required this.englishName,
    required this.displayName,
    required this.rollLabels,
    required this.isOwned,
  });

  String get perkId => perkIdFromJson(perk);
}

class PlayerCardScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String teamId;
  final String playerId;

  const PlayerCardScreen({
    super.key,
    required this.leagueId,
    required this.teamId,
    required this.playerId,
  });

  @override
  ConsumerState<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends ConsumerState<PlayerCardScreen> {
  String get leagueId => widget.leagueId;
  String get teamId => widget.teamId;
  String get playerId => widget.playerId;
  String get _teamDetailKey =>
      leagueId.isEmpty ? teamId : 'league|$leagueId|$teamId';
  bool _isMutating = false;

  void _refresh() {
    ref.invalidate(teamProvider(teamId));
    ref.invalidate(_playerUserTeamDetailProvider(_teamDetailKey));
  }

  Future<void> _showEditPlayerDialog(
    BuildContext context,
    Character player,
    String lang, {
    String? image,
  }) async {
    final nameController = TextEditingController(text: player.name);
    final numberController =
        TextEditingController(text: player.number.toString());
    var draftImage = image?.trim() ?? '';
    final imageUrlController = TextEditingController(
      text: _isEmbeddedPlayerImage(draftImage) ? '' : draftImage,
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '#${player.number}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tr(lang, 'player.editPlayer'),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 18)),
              ),
            ],
          ),
          content: SizedBox(
            width: min(460.0, MediaQuery.of(ctx).size.width - 48),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: tr(lang, 'player.name'),
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(
                            PhosphorIcons.user(PhosphorIconsStyle.regular),
                            size: 18,
                            color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? tr(lang, 'player.nameEmpty')
                          : null,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: numberController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr(lang, 'player.number'),
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(
                            PhosphorIcons.tShirt(PhosphorIconsStyle.regular),
                            size: 18,
                            color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return tr(lang, 'player.numberRequired');
                        }
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 99) {
                          return tr(lang, 'player.numberRange');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _playerImageEditor(
                      lang: lang,
                      image: draftImage,
                      urlController: imageUrlController,
                      onUrlChanged: (value) => setDialogState(() {
                        draftImage = value.trim();
                      }),
                      onPick: () async {
                        final dataUri = await _pickPlayerImageDataUri(lang);
                        if (dataUri == null || !ctx.mounted) return;
                        setDialogState(() {
                          draftImage = dataUri;
                          imageUrlController.clear();
                        });
                      },
                      onRemove: draftImage.isEmpty
                          ? null
                          : () => setDialogState(() {
                                draftImage = '';
                                imageUrlController.clear();
                              }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(lang, 'common.cancel'),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(tr(lang, 'common.save')),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    if (confirmed != true) return;

    final newName = nameController.text.trim();
    final newNumber = int.tryParse(numberController.text.trim());
    final newImage = draftImage.trim();
    final currentImage = image?.trim() ?? '';

    final nameChanged = newName != player.name;
    final numberChanged = newNumber != null && newNumber != player.number;
    final imageChanged = newImage != currentImage;

    if (!nameChanged && !numberChanged && !imageChanged) return;

    try {
      await ref.read(teamRepositoryProvider).updatePlayer(
            teamId,
            player.id,
            name: nameChanged ? newName : null,
            number: numberChanged ? newNumber : null,
            image: imageChanged ? newImage : null,
            leagueId: leagueId.isEmpty ? null : leagueId,
          );
      if (!context.mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trf(lang, 'player.updated',
              {'name': newName, 'number': '${newNumber ?? player.number}'})),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.error', {'e': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String?> _pickPlayerImageDataUri(String lang) async {
    try {
      return await pickPlayerImageDataUri();
    } catch (error, stackTrace) {
      debugPrint('Could not pick player image: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(lang, 'player.imagePickError')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  bool _isEmbeddedPlayerImage(String source) =>
      source.startsWith('data:image/');

  Uint8List? _bytesFromDataUri(String source) {
    final commaIndex = source.indexOf(',');
    if (commaIndex < 0 || !source.substring(0, commaIndex).contains('base64')) {
      return null;
    }
    try {
      return base64Decode(source.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _playerImageEditor({
    required String lang,
    required String image,
    required TextEditingController urlController,
    required ValueChanged<String> onUrlChanged,
    required Future<void> Function() onPick,
    required VoidCallback? onRemove,
  }) {
    final hasImage = image.trim().isNotEmpty;
    final isUploaded = _isEmbeddedPlayerImage(image);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 142,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    _playerPortraitImage(image),
                    if (isUploaded)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.66),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tr(lang, 'player.uploadedImage'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Icon(
                    PhosphorIcons.image(PhosphorIconsStyle.regular),
                    color: AppColors.textMuted,
                    size: 34,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(PhosphorIcons.uploadSimple(PhosphorIconsStyle.bold),
                  size: 16),
              label: Text(tr(lang, 'player.pickImage')),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon:
                  Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), size: 16),
              label: Text(tr(lang, 'player.removeImage')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: urlController,
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: tr(lang, 'player.image'),
            hintText: tr(lang, 'player.imageHint'),
            helperText: tr(lang, 'player.imageHelp'),
            labelStyle: const TextStyle(color: AppColors.textMuted),
            hintStyle: const TextStyle(color: AppColors.textMuted),
            helperStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(PhosphorIcons.link(PhosphorIconsStyle.regular),
                size: 18, color: AppColors.textMuted),
          ),
          maxLength: 2000,
          onChanged: onUrlChanged,
        ),
      ],
    );
  }

  // -- Add Skill Dialog ------------------------------------------------------

  Future<void> _showAddSkillDialog(BuildContext context, Character player,
      String lang, BaseTeam? baseRoster) async {
    final perks = ref.read(allPerksProvider).valueOrNull;
    if (perks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(lang, 'player.loadingSkills')),
            backgroundColor: AppColors.info),
      );
      return;
    }

    final accessRows = _skillCategoryAccess(baseRoster, player);
    final primaryRows =
        accessRows.where((row) => row.access == 'PRIMARY').toList();
    final secondaryRows =
        accessRows.where((row) => row.access == 'SECONDARY').toList();
    if (primaryRows.isEmpty && secondaryRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No skill access found for this player'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    final families = <String, List<Map<String, dynamic>>>{};
    for (final perk in perks) {
      final symbol = _perkFamilySymbol(perk);
      if (symbol != null) families.putIfAbsent(symbol, () => []).add(perk);
    }

    final ownedIds = player.skills.map((skill) => _skillKey(skill.id)).toSet();
    String selectedMode = primaryRows.isNotEmpty
        ? 'choose_primary_skill'
        : secondaryRows.isNotEmpty
            ? 'choose_secondary_skill'
            : 'characteristic_improvement';
    String? selectedSymbol = primaryRows.isNotEmpty
        ? primaryRows.first.symbol
        : secondaryRows.isNotEmpty
            ? secondaryRows.first.symbol
            : null;
    String searchQuery = '';
    Map<String, dynamic>? selectedPerk;
    int? selectedCharacteristicRoll;
    String? selectedCharacteristic;
    int? randomRollOneFirstDie;
    int? randomRollOneSecondDie;
    int? randomRollTwoFirstDie;
    int? randomRollTwoSecondDie;

    final selectedChoice = await showDialog<_SkillAdvancementChoice>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final rules = ref.read(advancementRulesProvider).valueOrNull;
          final randomPrimaryCost =
              _advancementCost(player, 'random_primary_skill');
          final choosePrimaryCost =
              _advancementCost(player, 'choose_primary_skill');
          final chooseSecondaryCost =
              _advancementCost(player, 'choose_secondary_skill');
          final characteristicCost =
              _advancementCost(player, 'characteristic_improvement');
          final modeCost = _advancementCost(player, selectedMode);
          final selectedModeHasAccess = switch (selectedMode) {
            'random_primary_skill' => primaryRows.isNotEmpty,
            'choose_primary_skill' => primaryRows.isNotEmpty,
            'choose_secondary_skill' => secondaryRows.isNotEmpty,
            'characteristic_improvement' => true,
            _ => false,
          };
          final selectedModeBrowsable = selectedModeHasAccess && modeCost > 0;
          final selectedModeAffordable =
              selectedModeBrowsable && player.spp >= modeCost;
          final requiredAccess = selectedMode == 'choose_secondary_skill'
              ? 'SECONDARY'
              : 'PRIMARY';
          final selectableRows =
              accessRows.where((row) => row.access == requiredAccess).toList();
          final selectedAccess = selectableRows.isEmpty
              ? null
              : selectableRows.firstWhere(
                  (row) => row.symbol == selectedSymbol,
                  orElse: () => selectableRows.first,
                );
          final randomRollOptions =
              selectedMode == 'random_primary_skill' && selectedAccess != null
                  ? _buildRandomSkillRollOptions(
                      perks: perks,
                      lang: lang,
                      categorySymbol: selectedAccess.symbol,
                      ownedIds: ownedIds,
                      rollOneFirstDie: randomRollOneFirstDie,
                      rollOneSecondDie: randomRollOneSecondDie,
                      rollTwoFirstDie: randomRollTwoFirstDie,
                      rollTwoSecondDie: randomRollTwoSecondDie,
                    )
                  : const <_RandomSkillRollOption>[];
          final familyPerks = selectedAccess == null
              ? <Map<String, dynamic>>[]
              : families[selectedAccess.symbol] ?? [];
          final query = searchQuery.toLowerCase();
          final filtered = query.isEmpty
              ? familyPerks
              : familyPerks.where((perk) {
                  final nameEs = ((perk['name'] as Map?)?['es'] ?? '')
                      .toString()
                      .toLowerCase();
                  final nameEn = ((perk['name'] as Map?)?['en'] ?? '')
                      .toString()
                      .toLowerCase();
                  return nameEs.contains(query) || nameEn.contains(query);
                }).toList();
          final screenSize = MediaQuery.of(ctx).size;
          final dialogWidth = min(1080.0, screenSize.width - 48);
          final dialogHeight = min(760.0, max(520.0, screenSize.height - 72));

          return Dialog(
            backgroundColor: Colors.transparent,
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        border: Border(
                          bottom: BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('ADQUIRIR MEJORA',
                                    style: TextStyle(
                                      color: AppColors.accentLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    )),
                                const SizedBox(height: 3),
                                Text(player.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily:
                                          AppTypography.displayFontFamily,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    )),
                              ],
                            ),
                          ),
                          _sppPill(
                            '${player.spp} ${tr(lang, 'player.availableSpp')}',
                            true,
                            prominent: true,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 330,
                            child: Container(
                              color:
                                  AppColors.background.withValues(alpha: 0.55),
                              padding: const EdgeInsets.all(14),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _dialogSectionLabel('TIPO DE MEJORA'),
                                  const SizedBox(height: 10),
                                  _advancementModeCard(
                                    title: 'Primaria al azar',
                                    subtitle:
                                        '${rules?.randomSkillDice ?? '2D6'} · ${primaryRows.length} categorias primarias',
                                    icon: PhosphorIcons.diceFive(
                                        PhosphorIconsStyle.fill),
                                    cost: randomPrimaryCost,
                                    enabled: primaryRows.isNotEmpty &&
                                        randomPrimaryCost > 0,
                                    selected:
                                        selectedMode == 'random_primary_skill',
                                    color: AppColors.warning,
                                    onTap: () => setDialogState(() {
                                      selectedMode = 'random_primary_skill';
                                      selectedSymbol = primaryRows.isNotEmpty
                                          ? primaryRows.first.symbol
                                          : null;
                                      searchQuery = '';
                                      selectedPerk = null;
                                      selectedCharacteristicRoll = null;
                                      selectedCharacteristic = null;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  _advancementModeCard(
                                    title: 'Elegir primaria',
                                    subtitle:
                                        '${primaryRows.length} categorias disponibles',
                                    icon: PhosphorIcons.crosshair(
                                        PhosphorIconsStyle.fill),
                                    cost: choosePrimaryCost,
                                    enabled: primaryRows.isNotEmpty &&
                                        choosePrimaryCost > 0,
                                    selected:
                                        selectedMode == 'choose_primary_skill',
                                    color: AppColors.success,
                                    onTap: () => setDialogState(() {
                                      selectedMode = 'choose_primary_skill';
                                      selectedSymbol = primaryRows.isNotEmpty
                                          ? primaryRows.first.symbol
                                          : null;
                                      searchQuery = '';
                                      selectedPerk = null;
                                      selectedCharacteristicRoll = null;
                                      selectedCharacteristic = null;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  _advancementModeCard(
                                    title: 'Elegir secundaria',
                                    subtitle:
                                        '${secondaryRows.length} categorias disponibles',
                                    icon: PhosphorIcons.starFour(
                                        PhosphorIconsStyle.fill),
                                    cost: chooseSecondaryCost,
                                    enabled: secondaryRows.isNotEmpty &&
                                        chooseSecondaryCost > 0,
                                    selected: selectedMode ==
                                        'choose_secondary_skill',
                                    color: AppColors.accent,
                                    onTap: () => setDialogState(() {
                                      selectedMode = 'choose_secondary_skill';
                                      selectedSymbol = secondaryRows.isNotEmpty
                                          ? secondaryRows.first.symbol
                                          : null;
                                      searchQuery = '';
                                      selectedPerk = null;
                                      selectedCharacteristicRoll = null;
                                      selectedCharacteristic = null;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  _advancementModeCard(
                                    title: 'Mejora de atributo',
                                    subtitle: 'Tirada D8 y atributo permitido',
                                    icon: PhosphorIcons.chartLineUp(
                                        PhosphorIconsStyle.fill),
                                    cost: characteristicCost,
                                    enabled: characteristicCost > 0,
                                    selected: selectedMode ==
                                        'characteristic_improvement',
                                    color: AppColors.primaryLight,
                                    onTap: () => setDialogState(() {
                                      selectedMode =
                                          'characteristic_improvement';
                                      searchQuery = '';
                                      selectedPerk = null;
                                    }),
                                  ),
                                  const SizedBox(height: 18),
                                  _dialogSectionLabel('CATEGORIAS'),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final row in accessRows)
                                        _skillCategoryChip(
                                          row: row,
                                          selected: row.symbol ==
                                                  selectedSymbol &&
                                              selectedMode !=
                                                  'characteristic_improvement',
                                          onTap: selectedModeBrowsable &&
                                                  row.access ==
                                                      requiredAccess &&
                                                  selectedMode !=
                                                      'characteristic_improvement'
                                              ? () => setDialogState(() {
                                                    selectedSymbol = row.symbol;
                                                    searchQuery = '';
                                                    selectedPerk = null;
                                                  })
                                              : null,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 14, 18, 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background
                                        .withValues(alpha: 0.5),
                                    border: const Border(
                                      bottom: BorderSide(
                                          color: AppColors.surfaceLight),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _advancementModeTitle(selectedMode),
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.displayFontFamily,
                                            color: AppColors.textPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      _sppPill('$modeCost SPP',
                                          selectedModeAffordable),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: selectedMode ==
                                          'characteristic_improvement'
                                      ? _characteristicImprovementPanel(
                                          rules: rules,
                                          player: player,
                                          lang: lang,
                                          selectedRoll:
                                              selectedCharacteristicRoll,
                                          selectedCharacteristic:
                                              selectedCharacteristic,
                                          enabled: selectedModeBrowsable,
                                          onRollSelected: (roll) =>
                                              setDialogState(() {
                                            selectedCharacteristicRoll = roll;
                                            selectedCharacteristic = null;
                                            selectedPerk = null;
                                          }),
                                          onCharacteristicSelected:
                                              (characteristic) =>
                                                  setDialogState(() {
                                            selectedCharacteristic =
                                                characteristic;
                                          }),
                                          onApply: selectedModeAffordable &&
                                                  selectedCharacteristicRoll !=
                                                      null &&
                                                  selectedCharacteristic != null
                                              ? () => Navigator.pop(
                                                    ctx,
                                                    _SkillAdvancementChoice(
                                                      advancementType:
                                                          'characteristic_improvement',
                                                      characteristic:
                                                          selectedCharacteristic,
                                                      characteristicRoll:
                                                          selectedCharacteristicRoll,
                                                      resultLabel:
                                                          selectedCharacteristic,
                                                    ),
                                                  )
                                              : null,
                                        )
                                      : selectedMode == 'random_primary_skill'
                                          ? _randomPrimaryPanel(
                                              cost: randomPrimaryCost,
                                              enabled: selectedModeBrowsable,
                                              affordable:
                                                  selectedModeAffordable,
                                              selectedAccess: selectedAccess,
                                              canChooseCategory:
                                                  primaryRows.length > 1,
                                              rollOneFirstDie:
                                                  randomRollOneFirstDie,
                                              rollOneSecondDie:
                                                  randomRollOneSecondDie,
                                              rollTwoFirstDie:
                                                  randomRollTwoFirstDie,
                                              rollTwoSecondDie:
                                                  randomRollTwoSecondDie,
                                              options: randomRollOptions,
                                              selectedPerk: selectedPerk,
                                              onRollOneFirstDieChanged:
                                                  (value) => setDialogState(() {
                                                randomRollOneFirstDie = value;
                                                selectedPerk = null;
                                              }),
                                              onRollOneSecondDieChanged:
                                                  (value) => setDialogState(() {
                                                randomRollOneSecondDie = value;
                                                selectedPerk = null;
                                              }),
                                              onRollTwoFirstDieChanged:
                                                  (value) => setDialogState(() {
                                                randomRollTwoFirstDie = value;
                                                selectedPerk = null;
                                              }),
                                              onRollTwoSecondDieChanged:
                                                  (value) => setDialogState(() {
                                                randomRollTwoSecondDie = value;
                                                selectedPerk = null;
                                              }),
                                              onSelectOption: (option) =>
                                                  setDialogState(() {
                                                selectedPerk = option.perk;
                                              }),
                                              onApply: selectedModeAffordable &&
                                                      selectedPerk != null
                                                  ? () {
                                                      final perk =
                                                          selectedPerk!;
                                                      final nameMap =
                                                          perk['name']
                                                                  as Map? ??
                                                              {};
                                                      final name = nameMap['es']
                                                              as String? ??
                                                          nameMap['en']
                                                              as String? ??
                                                          '';
                                                      Navigator.pop(
                                                        ctx,
                                                        _SkillAdvancementChoice(
                                                          perk: perk,
                                                          advancementType:
                                                              'random_primary_skill',
                                                          resultLabel: name,
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                            )
                                          : Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          16, 14, 16, 10),
                                                  child: TextField(
                                                    enabled:
                                                        selectedModeBrowsable,
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary),
                                                    decoration: InputDecoration(
                                                      hintText: tr(lang,
                                                          'player.searchSkill'),
                                                      hintStyle:
                                                          const TextStyle(
                                                              color: AppColors
                                                                  .textMuted),
                                                      filled: true,
                                                      fillColor:
                                                          AppColors.background,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                      prefixIcon: Icon(
                                                          PhosphorIcons
                                                              .magnifyingGlass(
                                                                  PhosphorIconsStyle
                                                                      .regular),
                                                          color: AppColors
                                                              .textMuted,
                                                          size: 18),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              vertical: 12),
                                                    ),
                                                    onChanged: (value) =>
                                                        setDialogState(() =>
                                                            searchQuery =
                                                                value.trim()),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          16, 0, 16, 12),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      tr(lang,
                                                          'player.tapSkillForDetails'),
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.textMuted,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: !selectedModeBrowsable
                                                      ? _disabledAdvancementState(
                                                          player.spp,
                                                          modeCost,
                                                          selectedModeHasAccess,
                                                        )
                                                      : filtered.isEmpty
                                                          ? Center(
                                                              child: Text(
                                                                  tr(lang,
                                                                      'player.noResults'),
                                                                  style: const TextStyle(
                                                                      color: AppColors
                                                                          .textMuted)))
                                                          : GridView.builder(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      16,
                                                                      0,
                                                                      16,
                                                                      16),
                                                              gridDelegate:
                                                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                                                maxCrossAxisExtent:
                                                                    260,
                                                                mainAxisExtent:
                                                                    74,
                                                                crossAxisSpacing:
                                                                    12,
                                                                mainAxisSpacing:
                                                                    12,
                                                              ),
                                                              itemCount:
                                                                  filtered
                                                                      .length,
                                                              itemBuilder:
                                                                  (ctx, index) {
                                                                final perk =
                                                                    filtered[
                                                                        index];
                                                                final perkId =
                                                                    perkIdFromJson(
                                                                        perk);
                                                                final nameMap =
                                                                    perk['name']
                                                                            as Map? ??
                                                                        {};
                                                                final name = nameMap[
                                                                            'es']
                                                                        as String? ??
                                                                    nameMap['en']
                                                                        as String? ??
                                                                    '';
                                                                final isOwned =
                                                                    ownedIds.contains(
                                                                        _skillKey(
                                                                            perkId));
                                                                final isSelected = selectedPerk !=
                                                                        null &&
                                                                    _skillKey(perkIdFromJson(
                                                                            selectedPerk!)) ==
                                                                        _skillKey(
                                                                            perkId);

                                                                return _skillChoiceTile(
                                                                  perkId:
                                                                      perkId,
                                                                  name: name,
                                                                  color: _familyColor(
                                                                      selectedAccess
                                                                              ?.family ??
                                                                          ''),
                                                                  isOwned:
                                                                      isOwned,
                                                                  selected:
                                                                      isSelected,
                                                                  onTap: () =>
                                                                      showSkillPopup(
                                                                    ctx,
                                                                    ref,
                                                                    skillName:
                                                                        name,
                                                                  ),
                                                                  onSelect: isOwned ||
                                                                          !selectedModeAffordable
                                                                      ? null
                                                                      : () =>
                                                                          setDialogState(
                                                                              () {
                                                                            selectedPerk =
                                                                                perk;
                                                                          }),
                                                                );
                                                              },
                                                            ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          16, 0, 16, 16),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed:
                                                          selectedModeAffordable &&
                                                                  selectedPerk !=
                                                                      null
                                                              ? () {
                                                                  final perk =
                                                                      selectedPerk!;
                                                                  final nameMap =
                                                                      perk['name']
                                                                              as Map? ??
                                                                          {};
                                                                  final name = nameMap[
                                                                              'es']
                                                                          as String? ??
                                                                      nameMap['en']
                                                                          as String? ??
                                                                      '';
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    _SkillAdvancementChoice(
                                                                      perk:
                                                                          perk,
                                                                      advancementType:
                                                                          selectedMode,
                                                                      resultLabel:
                                                                          name,
                                                                    ),
                                                                  );
                                                                }
                                                              : null,
                                                      icon: Icon(PhosphorIcons
                                                          .checkCircle(
                                                              PhosphorIconsStyle
                                                                  .fill)),
                                                      label: Text(tr(lang,
                                                              'player.confirmAdvancement')
                                                          .toUpperCase()),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.warning,
                                                        foregroundColor:
                                                            AppColors
                                                                .background,
                                                        disabledBackgroundColor:
                                                            AppColors
                                                                .surfaceLight,
                                                        disabledForegroundColor:
                                                            AppColors.textMuted,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 18,
                                                                vertical: 14),
                                                      ),
                                                    ),
                                                  ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (!context.mounted || selectedChoice == null) return;

    final confirmed = await _showAdvancementConfirmationDialog(
      context,
      player: player,
      choice: selectedChoice,
      lang: lang,
    );
    if (!context.mounted || confirmed != true) return;

    final chosenPerk = selectedChoice.perk;
    final perkId = chosenPerk == null ? null : perkIdFromJson(chosenPerk);
    final resultName = selectedChoice.resultLabel ?? '';

    try {
      setState(() => _isMutating = true);
      await ref.read(teamRepositoryProvider).applyPlayerAdvancement(
            teamId,
            playerId,
            advancementType: selectedChoice.advancementType,
            perkId: perkId,
            characteristic: selectedChoice.characteristic,
            characteristicRoll: selectedChoice.characteristicRoll,
            leagueId: leagueId.isEmpty ? null : leagueId,
          );
      if (!context.mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                selectedChoice.advancementType == 'characteristic_improvement'
                    ? '${selectedChoice.characteristic} mejorado'
                    : trf(lang, 'common.perkAdded', {'name': resultName})),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.error', {'e': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<bool?> _showAdvancementConfirmationDialog(
    BuildContext context, {
    required Character player,
    required _SkillAdvancementChoice choice,
    required String lang,
  }) {
    final cost = _advancementCost(player, choice.advancementType);
    final remainingSpp = player.spp - cost;
    final summary = choice.advancementType == 'characteristic_improvement'
        ? '+${choice.characteristic ?? ''}'
        : (choice.resultLabel ?? '');

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          tr(lang, 'player.confirmAdvancementTitle'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: min(420.0, MediaQuery.of(ctx).size.width - 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(lang, 'player.confirmAdvancementPrompt'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _confirmationRow(
                tr(lang, 'player.advancementTypeLabel'),
                _advancementModeTitle(choice.advancementType),
              ),
              _confirmationRow(
                tr(lang, 'player.selectedImprovement'),
                summary,
              ),
              _confirmationRow(
                tr(lang, 'player.sppCost'),
                '$cost SPP',
              ),
              _confirmationRow(
                tr(lang, 'player.remainingSpp'),
                '$remainingSpp SPP',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.background,
            ),
            child: Text(tr(lang, 'player.confirmAdvancement')),
          ),
        ],
      ),
    );
  }

  Widget _confirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ));
  }

  Widget _sppPill(String label, bool available, {bool prominent = false}) {
    final color = available ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 14 : 11,
        vertical: prominent ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: prominent ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(prominent ? 10 : 6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: prominent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prominent) ...[
            Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                size: 16, color: color),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: TextStyle(
                color: color,
                fontSize: prominent ? 15 : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: prominent ? 0.3 : 0,
              )),
        ],
      ),
    );
  }

  String _advancementModeTitle(String mode) {
    return switch (mode) {
      'random_primary_skill' => 'Primaria al azar',
      'choose_primary_skill' => 'Elegir habilidad primaria',
      'choose_secondary_skill' => 'Elegir habilidad secundaria',
      'characteristic_improvement' => 'Mejora de atributo',
      _ => 'Mejora',
    };
  }

  Widget _advancementModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int cost,
    required bool enabled,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final borderColor = selected ? color : AppColors.surfaceLight;
    return Opacity(
      opacity: enabled ? 1 : 0.46,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _sppPill('$cost SPP', enabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disabledAdvancementState(int playerSpp, int cost, bool hasAccess) {
    final message = hasAccess
        ? 'Faltan ${cost - playerSpp} SPP para esta mejora.'
        : 'Esta mejora no aplica a este jugador.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.lock(PhosphorIconsStyle.fill),
              size: 34, color: AppColors.textMuted.withValues(alpha: 0.55)),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _randomPrimaryPanel({
    required int cost,
    required bool enabled,
    required bool affordable,
    required _SkillCategoryAccess? selectedAccess,
    required bool canChooseCategory,
    required int? rollOneFirstDie,
    required int? rollOneSecondDie,
    required int? rollTwoFirstDie,
    required int? rollTwoSecondDie,
    required List<_RandomSkillRollOption> options,
    required Map<String, dynamic>? selectedPerk,
    required ValueChanged<int?> onRollOneFirstDieChanged,
    required ValueChanged<int?> onRollOneSecondDieChanged,
    required ValueChanged<int?> onRollTwoFirstDieChanged,
    required ValueChanged<int?> onRollTwoSecondDieChanged,
    required ValueChanged<_RandomSkillRollOption> onSelectOption,
    required VoidCallback? onApply,
  }) {
    final selectedPerkKey =
        selectedPerk == null ? null : _skillKey(perkIdFromJson(selectedPerk));

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.diceFive(PhosphorIconsStyle.fill),
                    color: AppColors.warning, size: 38),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HABILIDAD PRIMARIA AL AZAR',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 6),
                      const Text(
                        'Introduce dos tiradas manuales de 2D6 y elige uno de los resultados.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _sppPill(
                            selectedAccess == null
                                ? 'Sin categoria'
                                : 'Categoria: ${selectedAccess.label}',
                            selectedAccess != null,
                          ),
                          _sppPill('$cost SPP', affordable),
                          if (canChooseCategory)
                            const Text(
                              'Si tiene varias primarias, elige la categoria a la izquierda.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
          const SizedBox(height: 18),
          if (!enabled)
            Expanded(
              child: _disabledAdvancementState(0, cost, selectedAccess != null),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _randomDiceInputCard(
                    title: 'Tirada 1',
                    firstDie: rollOneFirstDie,
                    secondDie: rollOneSecondDie,
                    onFirstDieChanged: onRollOneFirstDieChanged,
                    onSecondDieChanged: onRollOneSecondDieChanged,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _randomDiceInputCard(
                    title: 'Tirada 2',
                    firstDie: rollTwoFirstDie,
                    secondDie: rollTwoSecondDie,
                    onFirstDieChanged: onRollTwoFirstDieChanged,
                    onSecondDieChanged: onRollTwoSecondDieChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: options.isEmpty
                  ? const Center(
                      child: Text(
                        'Introduce las dos tiradas para ver las habilidades resultantes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESULTADOS',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: GridView.builder(
                            itemCount: options.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              mainAxisExtent: 100,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final option = options[index];
                              final isSelected = selectedPerkKey != null &&
                                  selectedPerkKey == _skillKey(option.perkId);

                              return _skillChoiceTile(
                                perkId: option.perkId,
                                name: option.displayName,
                                caption:
                                    'Tirada: ${option.rollLabels.join(' · ')}',
                                color:
                                    _familyColor(selectedAccess?.family ?? ''),
                                isOwned: option.isOwned,
                                selected: isSelected,
                                onTap: () => showSkillPopup(
                                  context,
                                  ref,
                                  skillName: option.englishName,
                                  family: selectedAccess?.family,
                                ),
                                onSelect: option.isOwned || !affordable
                                    ? null
                                    : () => onSelectOption(option),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onApply,
                icon: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)),
                label: const Text('CONFIRMAR MEJORA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.surfaceLight,
                  disabledForegroundColor: AppColors.textMuted,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _randomDiceInputCard({
    required String title,
    required int? firstDie,
    required int? secondDie,
    required ValueChanged<int?> onFirstDieChanged,
    required ValueChanged<int?> onSecondDieChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _randomDieDropdown(
                  label: '1er D6',
                  value: firstDie,
                  onChanged: onFirstDieChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _randomDieDropdown(
                  label: '2do D6',
                  value: secondDie,
                  onChanged: onSecondDieChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _randomDieDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      items: List.generate(
        6,
        (index) => DropdownMenuItem<int>(
          value: index + 1,
          child: Text('${index + 1}'),
        ),
      ),
      onChanged: onChanged,
    );
  }

  List<_RandomSkillRollOption> _buildRandomSkillRollOptions({
    required List<Map<String, dynamic>> perks,
    required String lang,
    required String categorySymbol,
    required Set<String> ownedIds,
    required int? rollOneFirstDie,
    required int? rollOneSecondDie,
    required int? rollTwoFirstDie,
    required int? rollTwoSecondDie,
  }) {
    final options = <String, _RandomSkillRollOption>{};

    void addRoll(int? firstDie, int? secondDie) {
      if (firstDie == null || secondDie == null) return;

      final englishName =
          _randomPrimarySkillName(categorySymbol, firstDie, secondDie);
      if (englishName == null) return;

      final perk = findPerkDefinition(perks, englishName);
      final perkId = perkIdFromJson(perk);
      final key = perkId.isNotEmpty ? _skillKey(perkId) : englishName;
      final rollLabel = '$firstDie+$secondDie';
      final existing = options[key];
      if (existing != null) {
        existing.rollLabels.add(rollLabel);
        return;
      }

      options[key] = _RandomSkillRollOption(
        perk: perk,
        englishName: englishName,
        displayName: localizedPerkName(perks, englishName, lang),
        rollLabels: [rollLabel],
        isOwned: perkId.isNotEmpty && ownedIds.contains(_skillKey(perkId)),
      );
    }

    addRoll(rollOneFirstDie, rollOneSecondDie);
    addRoll(rollTwoFirstDie, rollTwoSecondDie);

    return options.values.toList();
  }

  String? _randomPrimarySkillName(
      String categorySymbol, int firstDie, int secondDie) {
    if (firstDie < 1 || firstDie > 6 || secondDie < 1 || secondDie > 6) {
      return null;
    }

    const table = <String, List<List<String>>>{
      'A': [
        [
          'Catch',
          'Diving Catch',
          'Diving Tackle',
          'Dodge',
          'Defensive',
          'Hit and Run'
        ],
        [
          'Jump Up',
          'Leap',
          'Safe Pair of Hands',
          'Sidestep',
          'Sprint',
          'Sure Feet'
        ],
      ],
      'D': [
        [
          'Dirty Player',
          'Eye Gouge',
          'Fumblerooski',
          'Lethal Flight',
          'Lone Fouler',
          'Pile Driver'
        ],
        [
          'Put the Boot In',
          'Quick Foul',
          'Saboteur',
          'Shadowing',
          'Sneaky Git',
          'Violent Innovator'
        ],
      ],
      'G': [
        ['Block', 'Dauntless', 'Fend', 'Frenzy', 'Kick', 'Pro'],
        [
          'Steady Footing',
          'Strip Ball',
          'Sure Hands',
          'Tackle',
          'Taunt',
          'Wrestle'
        ],
      ],
      'M': [
        [
          'Big Hand',
          'Claws',
          'Disturbing Presence',
          'Extra Arms',
          'Foul Appearance',
          'Horns'
        ],
        [
          'Iron Hard Skin',
          'Monstrous Mouth',
          'Prehensile Tail',
          'Tentacles',
          'Two Heads',
          'Very Long Legs'
        ],
      ],
      'P': [
        [
          'Accurate',
          'Cannoneer',
          'Cloud Burster',
          'Dump-Off',
          'Give and Go',
          'Hail Mary Pass'
        ],
        [
          'Leader',
          'Nerves of Steel',
          'On the Ball',
          'Pass',
          'Punt',
          'Safe Pass'
        ],
      ],
      'S': [
        ['Arm Bar', 'Brawler', 'Break Tackle', 'Bullseye', 'Grab', 'Guard'],
        [
          'Juggernaut',
          'Mighty Blow',
          'Multiple Block',
          'Stand Firm',
          'Strong Arm',
          'Thick Skull'
        ],
      ],
    };

    final rows = table[categorySymbol.toUpperCase()];
    if (rows == null) return null;

    final halfIndex = firstDie <= 3 ? 0 : 1;
    return rows[halfIndex][secondDie - 1];
  }

  Widget _characteristicImprovementPanel({
    required AdvancementRules? rules,
    required Character player,
    required String lang,
    required int? selectedRoll,
    required String? selectedCharacteristic,
    required bool enabled,
    required ValueChanged<int> onRollSelected,
    required ValueChanged<String> onCharacteristicSelected,
    required VoidCallback? onApply,
  }) {
    final entries = rules?.characteristicTable ?? [];
    CharacteristicImprovementResult? selectedEntry;
    if (selectedRoll != null) {
      for (final entry in entries) {
        if (selectedRoll >= entry.minRoll && selectedRoll <= entry.maxRoll) {
          selectedEntry = entry;
          break;
        }
      }
    }
    const stats = ['MA', 'ST', 'AG', 'PA', 'AV'];

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resultado D8',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (index) {
              final roll = index + 1;
              final selected = roll == selectedRoll;
              return ChoiceChip(
                label: Text('$roll'),
                selected: selected,
                onSelected: enabled ? (_) => onRollSelected(roll) : null,
                selectedColor: AppColors.primary.withValues(alpha: 0.35),
                backgroundColor: AppColors.card,
                disabledColor: AppColors.surfaceLight,
                labelStyle: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w900,
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Text('Atributo permitido',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats.map((stat) {
              final statAllowedByRoll = selectedEntry?.allows(stat) == true &&
                  (stat != 'PA' || player.stats.pa > 0);
              return _characteristicChip(
                stat: stat,
                selected: stat == selectedCharacteristic,
                enabled: enabled && statAllowedByRoll,
                onTap: () => onCharacteristicSelected(stat),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Text(
              selectedEntry == null
                  ? 'Selecciona la tirada D8 para ver que atributos aplica.'
                  : selectedEntry.description[lang] ??
                      selectedEntry.description['en'] ??
                      '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: Icon(PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill)),
              label: const Text('APLICAR ATRIBUTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surfaceLight,
                disabledForegroundColor: AppColors.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _characteristicChip({
    required String stat,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text('+$stat',
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              )),
        ),
      ),
    );
  }

  Widget _skillCategoryChip({
    required _SkillCategoryAccess row,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final enabled = row.enabled && onTap != null;
    final color = _familyColor(row.family);
    final accessText = row.access ?? 'NO';

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 147,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? color : AppColors.surfaceLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: enabled ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(row.symbol,
                    style: TextStyle(
                      color: enabled ? color : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(height: 2),
                    Text(accessText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skillChoiceTile({
    required String perkId,
    required String name,
    String? caption,
    required Color color,
    required bool isOwned,
    required bool selected,
    required VoidCallback? onTap,
    required VoidCallback? onSelect,
  }) {
    return Opacity(
      opacity: isOwned ? 0.42 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isOwned
                  ? AppColors.success.withValues(alpha: 0.6)
                  : selected
                      ? AppColors.warning
                      : color,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: onSelect == null ? null : (_) => onSelect(),
                  activeColor: AppColors.warning,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return AppColors.textMuted;
                    }
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.warning;
                    }
                    return AppColors.textSecondary;
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Container(
                width: 58,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  border: Border(
                      right: BorderSide(color: color.withValues(alpha: 0.45))),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    perkAssetPath(perkId),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                      size: 24,
                      color: color,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          )),
                      if (caption != null && caption.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isOwned)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      color: AppColors.success,
                      size: 18),
                )
              else if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _familyColor(String family) {
    switch (family.toLowerCase()) {
      case 'g':
      case 'general':
        return AppColors.skillGeneral;
      case 'a':
      case 'agility':
        return AppColors.skillAgility;
      case 's':
      case 'strength':
        return AppColors.skillStrength;
      case 'p':
      case 'passing':
        return AppColors.skillPassing;
      case 'm':
      case 'mutation':
        return AppColors.skillMutation;
      case 'extraordinary':
      case 't':
      case 'trait':
        return AppColors.skillExtraordinary;
      case 'd':
      case 'devious':
        return const Color(0xFFFF6F00);
      default:
        return AppColors.textMuted;
    }
  }

  // -- SPP helpers -----------------------------------------------------------

  int _nextSpp(int level) {
    const map = {1: 3, 2: 4, 3: 6, 4: 8, 5: 10, 6: 15};
    return map[level] ?? 0;
  }

  bool _canLevelUp(Character player) {
    final next = _nextSpp(player.level);
    return next > 0 && player.spp >= next;
  }

  int _advancementCost(Character player, String advancementType) {
    final row = ref
        .read(advancementRulesProvider)
        .valueOrNull
        ?.rowForAdvancement(player.level - 1);
    if (row != null) {
      switch (advancementType) {
        case 'choose_primary_skill':
          return row.choosePrimarySkill;
        case 'choose_secondary_skill':
          return row.chooseSecondarySkill;
        case 'characteristic_improvement':
          return row.characteristicImprovement;
        default:
          return row.randomPrimarySkill;
      }
    }

    const chosenPrimary = {1: 6, 2: 8, 3: 12, 4: 16, 5: 20, 6: 30};
    const chosenSecondary = {1: 12, 2: 14, 3: 18, 4: 22, 5: 26, 6: 40};
    const characteristic = {1: 18, 2: 20, 3: 24, 4: 28, 5: 32, 6: 50};
    return switch (advancementType) {
      'choose_primary_skill' => chosenPrimary[player.level] ?? 0,
      'choose_secondary_skill' => chosenSecondary[player.level] ?? 0,
      'characteristic_improvement' => characteristic[player.level] ?? 0,
      _ => _nextSpp(player.level),
    };
  }

  bool _canBuySkillAdvancement(Character player, BaseTeam? roster) {
    final accessRows = _skillCategoryAccess(roster, player);
    final hasPrimary = accessRows.any((row) => row.access == 'PRIMARY');
    final hasSecondary = accessRows.any((row) => row.access == 'SECONDARY');
    final randomPrimaryCost = _advancementCost(player, 'random_primary_skill');
    final chosenPrimaryCost = _advancementCost(player, 'choose_primary_skill');
    final chosenSecondaryCost =
        _advancementCost(player, 'choose_secondary_skill');
    final characteristicCost =
        _advancementCost(player, 'characteristic_improvement');
    final canBuyRandomPrimary =
        hasPrimary && randomPrimaryCost > 0 && player.spp >= randomPrimaryCost;
    final canBuyChosenPrimary =
        hasPrimary && chosenPrimaryCost > 0 && player.spp >= chosenPrimaryCost;
    final canBuyChosenSecondary = hasSecondary &&
        chosenSecondaryCost > 0 &&
        player.spp >= chosenSecondaryCost;
    final canBuyCharacteristic =
        characteristicCost > 0 && player.spp >= characteristicCost;

    return canBuyRandomPrimary ||
        canBuyChosenPrimary ||
        canBuyChosenSecondary ||
        canBuyCharacteristic;
  }

  BasePosition? _basePositionFor(BaseTeam? roster, Character player) {
    if (roster == null) return null;

    for (final candidate in roster.positions) {
      final candidateKeys = <String>{
        _positionKey(candidate.id),
        _positionKey(candidate.name),
        if (candidate.position != null) _positionKey(candidate.position!),
      }..remove('');
      final playerKeys = <String>{
        _positionKey(player.positionId),
        _positionKey(player.position),
      }..remove('');

      if (candidateKeys.intersection(playerKeys).isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  List<_SkillCategoryAccess> _skillCategoryAccess(
      BaseTeam? roster, Character player) {
    final position = _basePositionFor(roster, player);
    final primary = (position?.normalSkills.isNotEmpty ?? false)
        ? position!.normalSkills
        : player.normalSkills;
    final secondary = (position?.doubleSkills.isNotEmpty ?? false)
        ? position!.doubleSkills
        : player.doubleSkills;
    final primarySymbols =
        primary.map(_accessSymbol).whereType<String>().toSet();
    final secondarySymbols =
        secondary.map(_accessSymbol).whereType<String>().toSet();

    const categories = [
      _SkillCategoryAccess(
          symbol: 'G', family: 'general', label: 'General', access: null),
      _SkillCategoryAccess(
          symbol: 'S', family: 'strength', label: 'Fuerza', access: null),
      _SkillCategoryAccess(
          symbol: 'A', family: 'agility', label: 'Agilidad', access: null),
      _SkillCategoryAccess(
          symbol: 'P', family: 'passing', label: 'Pase', access: null),
      _SkillCategoryAccess(
          symbol: 'M', family: 'mutation', label: 'Mutación', access: null),
      _SkillCategoryAccess(
          symbol: 'D', family: 'devious', label: 'Triquiñuela', access: null),
    ];

    return categories.map((row) {
      final access = primarySymbols.contains(row.symbol)
          ? 'PRIMARY'
          : secondarySymbols.contains(row.symbol)
              ? 'SECONDARY'
              : null;
      return _SkillCategoryAccess(
        symbol: row.symbol,
        family: row.family,
        label: row.label,
        access: access,
      );
    }).toList();
  }

  String? _accessSymbol(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'g':
      case 'general':
        return 'G';
      case 's':
      case 'strength':
      case 'fuerza':
        return 'S';
      case 'a':
      case 'agility':
      case 'agilidad':
        return 'A';
      case 'p':
      case 'passing':
      case 'pase':
        return 'P';
      case 'm':
      case 'mutation':
      case 'mutacion':
      case 'mutación':
        return 'M';
      case 'd':
      case 'devious':
      case 'trickery':
      case 'triquinuela':
      case 'triquiñuela':
        return 'D';
      default:
        return null;
    }
  }

  String? _perkFamilySymbol(Map<String, dynamic> perk) {
    final kind = (perk['kind'] as String? ?? '').toLowerCase().trim();
    if (kind == 'trait') return null;

    final raw = perk['family'] ?? perk['category'];
    if (raw is! String) return null;
    return _accessSymbol(raw);
  }

  Set<String>? _startingSkillKeys(BaseTeam? roster, Character player) {
    final position = _basePositionFor(roster, player);
    if (position == null) return null;

    final keys = <String>{};
    for (final perk in position.startingPerks) {
      keys.add(_skillKey(perk.id));
      keys.add(_skillKey(perk.name));
    }
    keys.remove('');
    return keys;
  }

  String _positionKey(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  String _skillKey(String value) {
    final normalized = value
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[_\s]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]+'), '');
    return normalized.startsWith('perk-')
        ? normalized.substring('perk-'.length)
        : normalized;
  }

  bool? _isAcquiredSkill(Skill skill, Set<String>? startingSkillKeys) {
    if (startingSkillKeys == null) return null;
    return !startingSkillKeys.contains(_skillKey(skill.id)) &&
        !startingSkillKeys.contains(_skillKey(skill.name));
  }

  UserPlayer? _userPlayerFromDetail(UserTeamDetail? team, String playerId) {
    if (team == null) return null;
    for (final player in team.players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final teamAsync = ref.watch(teamProvider(teamId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    final isWide = MediaQuery.of(context).size.width >= 900;

    // Pre-load perks for the add skill dialog
    ref.watch(allPerksProvider);
    ref.watch(advancementRulesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
            child: Text(trf(lang, 'common.error', {'e': '$err'}),
                style: const TextStyle(color: AppColors.error))),
        data: (team) {
          final league = leagueId.isEmpty
              ? null
              : ref.watch(_leagueContextProvider(leagueId)).valueOrNull;
          final isOwner = currentUserId != null &&
              (team.ownerId == currentUserId || league?.isCommissioner == true);
          final baseRoster =
              ref.watch(_playerBaseRosterProvider(team.baseTeamId)).valueOrNull;
          final userTeamDetailAsync =
              ref.watch(_playerUserTeamDetailProvider(_teamDetailKey));
          final userPlayer =
              _userPlayerFromDetail(userTeamDetailAsync.valueOrNull, playerId);
          final player = team.characters.firstWhere(
            (c) => c.id == playerId,
            orElse: () => throw Exception(tr(lang, 'player.notFound')),
          );
          final startingSkillKeys = _startingSkillKeys(baseRoster, player);
          return Column(children: [
            _buildTopBar(context, team, player, lang),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context, team, player, isOwner, lang,
                          baseRoster, userPlayer),
                      const SizedBox(height: 24),
                      if (isWide)
                        _buildWideLayout(
                            context,
                            team,
                            player,
                            isOwner,
                            lang,
                            startingSkillKeys,
                            baseRoster,
                            userPlayer,
                            userTeamDetailAsync.isLoading)
                      else
                        _buildNarrowLayout(
                            context,
                            team,
                            player,
                            isOwner,
                            lang,
                            startingSkillKeys,
                            baseRoster,
                            userPlayer,
                            userTeamDetailAsync.isLoading),
                    ],
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  // -- Top Bar ---------------------------------------------------------------

  Widget _buildTopBar(
      BuildContext context, Team team, Character player, String lang) {
    final isLeague = leagueId.isNotEmpty;
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
            // Back button + Breadcrumb
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
              onPressed: () => isLeague
                  ? context.go('/league/$leagueId/team/$teamId')
                  : context.go('/teams/$teamId'),
              tooltip: tr(lang, 'player.back'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
            // Breadcrumb
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: team.baseTeamName.toUpperCase(),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                    const TextSpan(
                      text: '  >  ROSTER  >  ',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    TextSpan(
                      text: '${player.name.toUpperCase()} - PLAYER DETAILS',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Action icons
            IconButton(
              icon: Icon(PhosphorIcons.bell(PhosphorIconsStyle.regular),
                  color: Colors.white54, size: 20),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular),
                  color: Colors.white54, size: 20),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            // Save button
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(lang, 'player.saved')))),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('SAVE',
                  style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  // -- Hero Section with Portrait --------------------------------------------

  Widget _buildHeroSection(BuildContext context, Team team, Character player,
      bool isOwner, String lang, BaseTeam? baseRoster, UserPlayer? userPlayer) {
    final positionLabel = _localizedCharacterPosition(player, baseRoster, lang);
    final playerImage = userPlayer?.image?.trim();
    final hasPlayerImage = playerImage != null && playerImage.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.58),
            AppColors.error.withValues(alpha: 0.24),
            AppColors.surface,
          ],
          stops: const [0, 0.42, 1],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big jersey number
          GestureDetector(
            onTap: isOwner
                ? () => _showEditPlayerDialog(context, player, lang,
                    image: playerImage)
                : null,
            child: Container(
              width: 150,
              height: 174,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withValues(alpha: 0.72),
                    AppColors.primary.withValues(alpha: 0.42),
                    AppColors.accent.withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.55), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasPlayerImage)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _playerPortraitImage(playerImage),
                      ),
                    )
                  else ...[
                    // Faded big number background
                    Positioned(
                      top: -10,
                      child: Text(
                        '${player.number}',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 152,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                      ),
                    ),
                    // Main number
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('#',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              height: 1,
                            )),
                        Text('${player.number}',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              fontSize: 90,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 0.85,
                              letterSpacing: -2,
                              shadows: [
                                Shadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ],
                  if (hasPlayerImage)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.64),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text('#${player.number}',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              color: AppColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            )),
                      ),
                    ),
                  // Edit overlay
                  if (isOwner)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                            PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                            size: 14,
                            color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 28),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & position badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusBadge(player),
                    _positionBadge(positionLabel),
                    if (_canLevelUp(player)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                PhosphorIcons.arrowFatLinesUp(
                                    PhosphorIconsStyle.fill),
                                size: 12,
                                color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(tr(lang, 'team.levelUp'),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Player name - BIG
                Row(
                  children: [
                    _headerJerseyNumber(player.number),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        player.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 62,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.0,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _showEditPlayerDialog(
                            context, player, lang,
                            image: playerImage),
                        icon: Icon(
                            PhosphorIcons.pencilSimple(
                                PhosphorIconsStyle.regular),
                            size: 20,
                            color: AppColors.textMuted),
                        tooltip: tr(lang, 'player.editName'),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                // Info chips
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _heroInfoChip(PhosphorIcons.shield(PhosphorIconsStyle.fill),
                        tr(lang, 'player.team'), team.name, AppColors.info),
                    _heroInfoChip(
                        PhosphorIcons.coinVertical(PhosphorIconsStyle.fill),
                        tr(lang, 'player.value'),
                        '${_formatNumber(player.value)} GP',
                        AppColors.accent),
                    _heroInfoChip(PhosphorIcons.star(PhosphorIconsStyle.fill),
                        'SPP', '${player.spp}', AppColors.info),
                    _heroInfoChip(
                        PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
                        tr(lang, 'player.level'),
                        '${player.level}',
                        AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerJerseyNumber(int number) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.58)),
      ),
      child: Text(
        '#$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypography.displayFontFamily,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: AppColors.accent,
          height: 0.92,
        ),
      ),
    );
  }

  Widget _playerPortraitImage(String source) {
    if (_isEmbeddedPlayerImage(source)) {
      final bytes = _bytesFromDataUri(source);
      if (bytes == null) return _playerPortraitFallback();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _playerPortraitFallback(),
      );
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _playerPortraitFallback(),
      );
    }

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _playerPortraitFallback(),
    );
  }

  Widget _playerPortraitFallback() {
    return Container(
      color: AppColors.surface.withValues(alpha: 0.72),
      child: Center(
        child: Icon(
          PhosphorIcons.image(PhosphorIconsStyle.regular),
          color: AppColors.textMuted,
          size: 34,
        ),
      ),
    );
  }

  Widget _heroInfoChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1)),
            Text(value,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
          ],
        ),
      ],
    );
  }

  // -- Layouts ---------------------------------------------------------------

  Widget _buildWideLayout(
      BuildContext context,
      Team team,
      Character player,
      bool isOwner,
      String lang,
      Set<String>? startingSkillKeys,
      BaseTeam? baseRoster,
      UserPlayer? userPlayer,
      bool injuriesLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildAttributesAndSkillsCard(context, player, isOwner, lang,
                  startingSkillKeys, baseRoster),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildLevelTrackerCard(
                  context, player, isOwner, lang, baseRoster),
              const SizedBox(height: 20),
              _buildInjuryTimelineCard(
                  player, userPlayer, injuriesLoading, lang),
              const SizedBox(height: 20),
              _buildPerformanceRecordsCard(player, lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context,
      Team team,
      Character player,
      bool isOwner,
      String lang,
      Set<String>? startingSkillKeys,
      BaseTeam? baseRoster,
      UserPlayer? userPlayer,
      bool injuriesLoading) {
    return Column(
      children: [
        _buildLevelTrackerCard(context, player, isOwner, lang, baseRoster),
        const SizedBox(height: 20),
        _buildAttributesAndSkillsCard(
            context, player, isOwner, lang, startingSkillKeys, baseRoster),
        const SizedBox(height: 20),
        _buildInjuryTimelineCard(player, userPlayer, injuriesLoading, lang),
        const SizedBox(height: 20),
        _buildPerformanceRecordsCard(player, lang),
        const SizedBox(height: 40),
      ],
    );
  }

  // -- Attributes & Skills Card ---------------------------------------------

  Widget _buildAttributesAndSkillsCard(
      BuildContext context,
      Character player,
      bool isOwner,
      String lang,
      Set<String>? startingSkillKeys,
      BaseTeam? baseRoster) {
    final s = player.stats;
    final baseStats = _basePositionFor(baseRoster, player)?.stats;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(tr(lang, 'player.coreAttributes')),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final tileWidth = compact
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 48) / 5;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statColumn(
                    'MA', '${s.ma}', _statValueColor('MA', s.ma, baseStats?.ma),
                    width: tileWidth),
                _statColumn(
                    'ST', '${s.st}', _statValueColor('ST', s.st, baseStats?.st),
                    width: tileWidth),
                _statColumn('AG', '${s.ag}+',
                    _statValueColor('AG', s.ag, baseStats?.ag),
                    width: tileWidth),
                _statColumn('PA', s.pa > 0 ? '${s.pa}+' : '-',
                    _statValueColor('PA', s.pa, baseStats?.pa),
                    width: tileWidth),
                _statColumn('AV', '${s.av}+',
                    _statValueColor('AV', s.av, baseStats?.av),
                    width: tileWidth),
              ],
            );
          }),
          const SizedBox(height: 22),
          Divider(
              color: AppColors.surfaceLight.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 18),
          _buildSkillsPanel(context, player, isOwner, lang, startingSkillKeys),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color,
      {required double width}) {
    return SizedBox(
      width: width,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statValueColor(String stat, int current, int? base) {
    if (base == null || current == base) return AppColors.textPrimary;
    final improved = switch (stat) {
      'AG' || 'PA' => current > 0 && current < base,
      _ => current > base,
    };
    return improved ? AppColors.success : AppColors.error;
  }

  // -- Skills Panel ----------------------------------------------------------

  Widget _buildSkillsPanel(BuildContext context, Character player, bool isOwner,
      String lang, Set<String>? startingSkillKeys) {
    final allPerks = ref.watch(allPerksProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle(tr(lang, 'player.skills')),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        if (player.skills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                Icon(PhosphorIcons.lightning(PhosphorIconsStyle.regular),
                    size: 32,
                    color: AppColors.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(tr(lang, 'player.noSkills'),
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 16,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    )),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? tr(lang, 'player.addSkillHint')
                      : tr(lang, 'player.noSkillsYet'),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted.withValues(alpha: 0.4)),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: player.skills.map((s) {
              final displayName = localizedPerkName(allPerks, s.name, lang);
              final isAcquired = _isAcquiredSkill(s, startingSkillKeys) == true;
              final color = _skillColor(s.family, isAcquired: isAcquired);
              return GestureDetector(
                onTap: () => showSkillPopup(context, ref,
                    skillName: s.name,
                    family: s.family,
                    description: s.description),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: displayName,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 190),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: color.withValues(alpha: 0.58)),
                      ),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _skillColor(String? family, {required bool isAcquired}) {
    if (isAcquired) return AppColors.accent;
    switch ((family ?? '').toLowerCase()) {
      case 'strength':
      case 's':
        return AppColors.error;
      case 'agility':
      case 'a':
        return AppColors.success;
      case 'passing':
      case 'p':
        return AppColors.info;
      case 'mutation':
      case 'm':
        return AppColors.primaryLight;
      default:
        return AppColors.primary;
    }
  }

  // -- Level Tracker Card ----------------------------------------------------

  Widget _buildLevelTrackerCard(BuildContext context, Character player,
      bool isOwner, String lang, BaseTeam? baseRoster) {
    final next = _nextSpp(player.level);
    final isMax = next == 0;
    final progress = isMax ? 1.0 : (player.spp / next).clamp(0.0, 1.0);
    final canLevel = _canLevelUp(player);
    final canBuySkill = isOwner && _canBuySkillAdvancement(player, baseRoster);
    final canOpenSkillPlanner = isOwner && baseRoster != null;
    final remaining = isMax ? 0 : next - player.spp;

    return _card(
      borderColor: canLevel ? AppColors.warning.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(tr(lang, 'player.levelTracker')),
              const Spacer(),
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: canOpenSkillPlanner && !_isMutating
                      ? () =>
                          _showAddSkillDialog(context, player, lang, baseRoster)
                      : null,
                  icon: Icon(
                      PhosphorIcons.arrowFatLinesUp(PhosphorIconsStyle.fill),
                      size: 15),
                  label: Text(tr(lang, 'player.addSkill'),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuySkill
                        ? AppColors.warning.withValues(alpha: 0.18)
                        : AppColors.surfaceLight,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    foregroundColor:
                        canBuySkill ? AppColors.warning : AppColors.textPrimary,
                    disabledForegroundColor: AppColors.textMuted,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: canBuySkill
                            ? AppColors.warning.withValues(alpha: 0.45)
                            : AppColors.textMuted.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                )
              else
                Icon(PhosphorIcons.arrowFatLinesUp(PhosphorIconsStyle.fill),
                    size: 20, color: AppColors.accent.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _levelBadge(
                      '${tr(lang, 'player.level')} ${player.level}', true),
                  const Spacer(),
                  Text(
                    '${player.spp} / ${isMax ? 'MAX' : next} SPP',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seriousProgressBar(
                value: progress,
                color: canLevel ? AppColors.warning : AppColors.accent,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    isMax
                        ? tr(lang, 'player.nextLevel')
                        : '${tr(lang, 'player.toNextLevel')}: $remaining SPP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (!isMax)
                    Text(
                      '${tr(lang, 'player.nextLevel')}: ${player.level + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seriousProgressBar({required double value, required Color color}) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _levelBadge(String text, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrent
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isCurrent ? AppColors.accent : AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // -- Performance Records Card ----------------------------------------------

  Widget _buildPerformanceRecordsCard(Character player, String lang) {
    final career = player.career;
    final dashboardStats = [
      _GraphValue(
          tr(lang, 'aftermatch.touchdowns'), career.touchdowns.toDouble(), 5),
      _GraphValue(
          tr(lang, 'aftermatch.completions'), career.completions.toDouble(), 8),
      _GraphValue(
          tr(lang, 'aftermatch.casualties'), career.casualties.toDouble(), 5),
      _GraphValue(tr(lang, 'aftermatch.interceptions'),
          career.interceptions.toDouble(), 4),
      _GraphValue(tr(lang, 'aftermatch.kos'), career.kos.toDouble(), 6),
      _GraphValue(tr(lang, 'aftermatch.mvp'), career.mvpAwards.toDouble(), 3),
    ];

    return _card(
      borderColor: AppColors.accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(tr(lang, 'player.performanceDashboard')),
          const SizedBox(height: 18),
          _statGraph(dashboardStats),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final metricWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: dashboardStats
                    .map((item) => _dashboardMetric(
                          label: item.label,
                          value: item.displayValue,
                          progress: _graphRatio(item),
                          width: metricWidth,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashboardMetric({
    required String label,
    required String value,
    required double progress,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6)),
                ),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1)),
              ],
            ),
            const SizedBox(height: 10),
            _miniBar(progress),
          ],
        ),
      ),
    );
  }

  // -- Injury Timeline Card --------------------------------------------------

  Widget _buildInjuryTimelineCard(
      Character player, UserPlayer? userPlayer, bool loading, String lang) {
    final history = [...?userPlayer?.injuryHistory]..sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    final legacyNote = player.injuryDetails?.trim();
    final hasLegacyNote = legacyNote != null && legacyNote.isNotEmpty;

    return _card(
      borderColor: AppColors.warning.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(lang == 'es'
              ? 'Historial de lesiones y mejoras'
              : 'Injuries and advancements'),
          const SizedBox(height: 18),
          if (loading && userPlayer == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(AppColors.warning),
              ),
            )
          else if (history.isEmpty && !hasLegacyNote && !player.missNextGame)
            _emptyTimelineState(lang)
          else ...[
            if (history.isNotEmpty)
              ...history.asMap().entries.map(
                    (entry) => _injuryTimelineItem(
                      entry.value,
                      isLast: entry.key == history.length - 1 &&
                          !hasLegacyNote &&
                          !player.missNextGame,
                      lang: lang,
                    ),
                  ),
            if (hasLegacyNote || player.missNextGame)
              _legacyInjuryTimelineItem(player, legacyNote, lang),
          ],
        ],
      ),
    );
  }

  Widget _emptyTimelineState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(
        lang == 'es'
            ? 'Sin lesiones ni mejoras registradas'
            : 'No injuries or advancements recorded',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _injuryTimelineItem(UserPlayerInjuryRecord record,
      {required bool isLast, required String lang}) {
    final color = _injuryRecordColor(record);
    final details = _injuryRecordDetails(record, lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.18),
                      border: Border.all(color: color.withValues(alpha: 0.55)),
                    ),
                    child:
                        Icon(_injuryRecordIcon(record), size: 12, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 6),
                        color: AppColors.surfaceLight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _injuryRecordTitle(record),
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimelineDate(record.createdAt, lang),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        details,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legacyInjuryTimelineItem(
      Character player, String? legacyNote, String lang) {
    final statusLabel = player.missNextGame
        ? (lang == 'es' ? 'Se pierde el proximo partido' : 'Misses next game')
        : (lang == 'es' ? 'Lesion registrada' : 'Recorded injury');
    final note = legacyNote ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withValues(alpha: 0.18),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.55)),
                ),
                child: Icon(PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
                    size: 12, color: AppColors.warning),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabel,
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w900)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(note,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.3)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _injuryRecordTitle(UserPlayerInjuryRecord record) {
    if (record.label.trim().isNotEmpty) return record.label;
    return record.type
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _injuryRecordDetails(UserPlayerInjuryRecord record, String lang) {
    final details = <String>[];
    if (record.roll != null) {
      details
          .add(lang == 'es' ? 'Tirada ${record.roll}' : 'Roll ${record.roll}');
    }
    if ((record.stat ?? '').isNotEmpty) {
      final stat = record.stat!.toUpperCase();
      final reduction = record.reduction;
      details.add(
          reduction == null || reduction.isEmpty ? stat : '$stat $reduction');
    }
    if ((record.notes ?? '').trim().isNotEmpty) {
      details.add(record.notes!.trim());
    }
    return details.join(' · ');
  }

  String _formatTimelineDate(DateTime? date, String lang) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    if (lang == 'es') return '$day/$month/${date.year}';
    return '$month/$day/${date.year}';
  }

  Color _injuryRecordColor(UserPlayerInjuryRecord record) {
    switch (record.type) {
      case 'dead':
        return AppColors.dead;
      case 'lasting_injury':
        return AppColors.error;
      case 'advancement':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  IconData _injuryRecordIcon(UserPlayerInjuryRecord record) {
    switch (record.type) {
      case 'dead':
        return PhosphorIcons.skull(PhosphorIconsStyle.fill);
      case 'sent_off':
        return PhosphorIcons.warning(PhosphorIconsStyle.fill);
      case 'advancement':
        return PhosphorIcons.arrowFatLinesUp(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.firstAid(PhosphorIconsStyle.fill);
    }
  }

  Widget _statGraph(List<_GraphValue> values) {
    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((item) {
          final ratio = (item.value / item.max).clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.displayValue,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _miniBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 7,
        backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.7),
        valueColor:
            AlwaysStoppedAnimation(AppColors.accent.withValues(alpha: 0.75)),
      ),
    );
  }

  double _graphRatio(_GraphValue item) =>
      item.max <= 0 ? 0 : (item.value / item.max).clamp(0.0, 1.0);

  // -- Shared Helpers --------------------------------------------------------

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.displayFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _statusBadge(Character player) {
    Color color;
    String label;
    switch (player.status) {
      case PlayerStatus.healthy:
        color = AppColors.success;
        label = 'ACTIVE STATUS';
        break;
      case PlayerStatus.injured:
        color = AppColors.warning;
        label = 'INJURED';
        break;
      case PlayerStatus.mng:
        color = AppColors.warning;
        label = 'MISS NEXT GAME';
        break;
      case PlayerStatus.dead:
        color = AppColors.dead;
        label = 'DEAD';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _positionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
      ),
      child: Text(
        position.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.info,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _localizedCharacterPosition(
      Character player, BaseTeam? roster, String lang) {
    final position = _basePositionFor(roster, player);
    final raw = position?.position ?? position?.name ?? player.position;
    return localizedPositionText(raw, lang);
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},000';
    }
    return number.toString();
  }
}

class _GraphValue {
  _GraphValue(this.label, this.value, this.max, {String? displayValue})
      : displayValue = displayValue ?? _defaultDisplay(value);

  final String label;
  final double value;
  final double max;
  final String displayValue;

  static String _defaultDisplay(double value) => value.toStringAsFixed(0);
}

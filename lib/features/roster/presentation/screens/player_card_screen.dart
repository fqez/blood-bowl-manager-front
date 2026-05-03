import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/team.dart';
import '../screens/roster_screen.dart';
import '../widgets/skill_badge.dart';
import '../../../shared/presentation/widgets/skill_popup.dart';

// ignore_for_file: deprecated_member_use

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

  void _refresh() => ref.invalidate(teamProvider(teamId));

  Future<void> _showEditPlayerDialog(
      BuildContext context, Character player, String lang) async {
    final nameController = TextEditingController(text: player.name);
    final numberController =
        TextEditingController(text: player.number.toString());
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '#${player.number}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr(lang, 'player.editPlayer'),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: tr(lang, 'player.name'),
                  labelStyle: TextStyle(color: AppColors.textMuted),
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
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr(lang, 'player.number'),
                  labelStyle: TextStyle(color: AppColors.textMuted),
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
                  if (v == null || v.trim().isEmpty)
                    return tr(lang, 'player.numberRequired');
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 99)
                    return tr(lang, 'player.numberRange');
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'common.cancel'),
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(tr(lang, 'common.save')),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (confirmed != true) return;

    final newName = nameController.text.trim();
    final newNumber = int.tryParse(numberController.text.trim());

    final nameChanged = newName != player.name;
    final numberChanged = newNumber != null && newNumber != player.number;

    if (!nameChanged && !numberChanged) return;

    try {
      await ref.read(teamRepositoryProvider).updatePlayer(
            teamId,
            player.id,
            name: nameChanged ? newName : null,
            number: numberChanged ? newNumber : null,
          );
      if (!mounted) return;
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(lang, 'player.updated',
                {'name': newName, 'number': '${newNumber ?? player.number}'})),
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
    }
  }

  // -- Add Skill Dialog ------------------------------------------------------

  Future<void> _showAddSkillDialog(
      BuildContext context, Character player, String lang) async {
    final perksAsync = ref.read(allPerksProvider);
    final perks = perksAsync.valueOrNull;
    if (perks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(lang, 'player.loadingSkills')),
            backgroundColor: AppColors.info),
      );
      return;
    }

    final families = <String, List<Map<String, dynamic>>>{};
    for (final perk in perks) {
      final family = perk['family'] as String? ?? 'General';
      families.putIfAbsent(family, () => []).add(perk);
    }
    final ownedIds = player.skills.map((s) => s.id).toSet();
    String selectedFamily = families.keys.first;
    String? searchQuery;

    final selectedPerk = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final familyPerks = families[selectedFamily] ?? [];
            final filtered = searchQuery != null && searchQuery!.isNotEmpty
                ? familyPerks.where((p) {
                    final nameEs = ((p['name'] as Map?)?['es'] ?? '')
                        .toString()
                        .toLowerCase();
                    final nameEn = ((p['name'] as Map?)?['en'] ?? '')
                        .toString()
                        .toLowerCase();
                    return nameEs.contains(searchQuery!.toLowerCase()) ||
                        nameEn.contains(searchQuery!.toLowerCase());
                  }).toList()
                : familyPerks;

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 700, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.surface
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                              color: AppColors.accent, size: 24),
                          const SizedBox(width: 12),
                          Text(tr(lang, 'player.addSkill'),
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1,
                              )),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon:
                                const Icon(Icons.close, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: tr(lang, 'player.searchSkill'),
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                              PhosphorIcons.magnifyingGlass(
                                  PhosphorIconsStyle.regular),
                              color: AppColors.textMuted,
                              size: 18),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) => setDialogState(() => searchQuery = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: families.keys.map((family) {
                            final isActive = family == selectedFamily;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(family.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    )),
                                selected: isActive,
                                onSelected: (_) => setDialogState(
                                    () => selectedFamily = family),
                                backgroundColor: AppColors.background,
                                selectedColor: _familyColor(family),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isActive
                                      ? _familyColor(family)
                                      : AppColors.surfaceLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(tr(lang, 'player.noResults'),
                                  style: TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final perk = filtered[i];
                                final perkId = perk['_id'] as String? ?? '';
                                final nameMap = perk['name'] as Map? ?? {};
                                final nameEs = nameMap['es'] as String? ??
                                    nameMap['en'] as String? ??
                                    '';
                                final nameEn = nameMap['en'] as String? ?? '';
                                final descMap =
                                    perk['description'] as Map? ?? {};
                                final descEs = descMap['es'] as String? ??
                                    descMap['en'] as String? ??
                                    '';
                                final isOwned = ownedIds.contains(perkId);

                                return Opacity(
                                  opacity: isOwned ? 0.4 : 1.0,
                                  child: Card(
                                    color: AppColors.card,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isOwned
                                            ? AppColors.success.withOpacity(0.5)
                                            : AppColors.surfaceLight,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: isOwned
                                          ? null
                                          : () => Navigator.pop(ctx, perk),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color:
                                                    _familyColor(selectedFamily)
                                                        .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  'assets/images/perks/upscaled/perk-${perkId.replaceAll('_', '-')}.png',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(
                                                    PhosphorIcons.lightning(
                                                        PhosphorIconsStyle
                                                            .fill),
                                                    size: 22,
                                                    color: _familyColor(
                                                        selectedFamily),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                            nameEs
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppTypography
                                                                      .displayFontFamily,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            )),
                                                      ),
                                                      if (isOwned)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColors
                                                                .success
                                                                .withOpacity(
                                                                    0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Text(
                                                              tr(lang,
                                                                  'player.acquired'),
                                                              style: TextStyle(
                                                                  fontSize: 9,
                                                                  color: AppColors
                                                                      .success,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                    ],
                                                  ),
                                                  Text(nameEn,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textMuted)),
                                                  const SizedBox(height: 4),
                                                  Text(descEs,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;

    if (selectedPerk == null) return;

    final perkId = selectedPerk['_id'] as String;
    final nameMap = selectedPerk['name'] as Map;
    final perkName = nameMap['es'] as String? ?? nameMap['en'] as String? ?? '';
    final family = selectedPerk['family'] as String?;

    try {
      await ref.read(teamRepositoryProvider).addPerkToPlayer(
            teamId,
            playerId,
            perkId: perkId,
            perkName: perkName,
            category: family,
          );
      if (!mounted) return;
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(trf(lang, 'common.perkAdded', {'name': perkName})),
              backgroundColor: AppColors.success),
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
    }
  }

  Color _familyColor(String family) {
    switch (family.toLowerCase()) {
      case 'general':
        return AppColors.skillGeneral;
      case 'agility':
        return AppColors.skillAgility;
      case 'strength':
        return AppColors.skillStrength;
      case 'passing':
        return AppColors.skillPassing;
      case 'mutation':
        return AppColors.skillMutation;
      case 'extraordinary':
      case 'trait':
        return AppColors.skillExtraordinary;
      case 'devious':
        return const Color(0xFFFF6F00);
      default:
        return AppColors.textMuted;
    }
  }

  // -- SPP helpers -----------------------------------------------------------

  int _nextSpp(int level) {
    const map = {1: 6, 2: 16, 3: 31, 4: 51, 5: 76, 6: 176};
    return map[level] ?? 0;
  }

  bool _canLevelUp(Character player) {
    final next = _nextSpp(player.level);
    return next > 0 && player.spp >= next;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
            child: Text(trf(lang, 'common.error', {'e': '$err'}),
                style: TextStyle(color: AppColors.error))),
        data: (team) {
          final isOwner =
              currentUserId != null && team.ownerId == currentUserId;
          final player = team.characters.firstWhere(
            (c) => c.id == playerId,
            orElse: () => throw Exception(tr(lang, 'player.notFound')),
          );
          return Column(children: [
            _buildTopBar(context, team, player, lang),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context, team, player, isOwner, lang),
                      const SizedBox(height: 24),
                      if (isWide)
                        _buildWideLayout(context, team, player, isOwner, lang)
                      else
                        _buildNarrowLayout(
                            context, team, player, isOwner, lang),
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
      bool isOwner, String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.surface.withOpacity(0.9),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big jersey number
          GestureDetector(
            onTap: isOwner
                ? () => _showEditPlayerDialog(context, player, lang)
                : null,
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.6),
                    AppColors.primary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Faded big number background
                  Positioned(
                    top: -10,
                    child: Text(
                      '${player.number}',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 140,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.08),
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
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 0.85,
                            letterSpacing: -2,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withOpacity(0.8),
                                blurRadius: 20,
                              ),
                            ],
                          )),
                    ],
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
                Row(
                  children: [
                    _statusBadge(player),
                    const SizedBox(width: 8),
                    _positionBadge(player.position),
                    if (_canLevelUp(player)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.5)),
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
                            const Text('LEVEL UP!',
                                style: TextStyle(
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
                    Flexible(
                      child: Text(
                        player.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.0,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () =>
                            _showEditPlayerDialog(context, player, lang),
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
                        'EQUIPO', team.name, AppColors.textSecondary),
                    _heroInfoChip(
                        PhosphorIcons.coinVertical(PhosphorIconsStyle.fill),
                        'VALOR',
                        '${_formatNumber(player.value)} GP',
                        AppColors.accent),
                    _heroInfoChip(PhosphorIcons.star(PhosphorIconsStyle.fill),
                        'SPP', '${player.spp}', AppColors.info),
                    _heroInfoChip(
                        PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
                        'NIVEL',
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

  Widget _heroInfoChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
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

  Widget _buildWideLayout(BuildContext context, Team team, Character player,
      bool isOwner, String lang) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildCoreAttributesCard(context, player, isOwner),
              const SizedBox(height: 20),
              _buildAbilitiesCard(context, player, isOwner, lang),
              const SizedBox(height: 20),
              _buildCareerChronicleCard(player, lang),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildLevelTrackerCard(player),
              const SizedBox(height: 20),
              _buildPerformanceRecordsCard(player),
              const SizedBox(height: 20),
              _buildActionButtons(context, isOwner, lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Team team, Character player,
      bool isOwner, String lang) {
    return Column(
      children: [
        _buildLevelTrackerCard(player),
        const SizedBox(height: 20),
        _buildCoreAttributesCard(context, player, isOwner),
        const SizedBox(height: 20),
        _buildAbilitiesCard(context, player, isOwner, lang),
        const SizedBox(height: 20),
        _buildPerformanceRecordsCard(player),
        const SizedBox(height: 20),
        _buildCareerChronicleCard(player, lang),
        const SizedBox(height: 20),
        _buildActionButtons(context, isOwner, lang),
        const SizedBox(height: 40),
      ],
    );
  }

  // -- Core Attributes Card --------------------------------------------------

  Widget _buildCoreAttributesCard(
      BuildContext context, Character player, bool isOwner) {
    final s = player.stats;
    final canEdit = isOwner && _canLevelUp(player);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('CORE ATTRIBUTES'),
              const Spacer(),
              if (canEdit)
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Proximamente: Manual Modification'))),
                  icon: Icon(PhosphorIcons.sliders(PhosphorIconsStyle.fill),
                      size: 14, color: AppColors.textMuted),
                  label: const Text('MANUAL MODIFICATION',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn('MOV', '${s.ma}', canEdit, context),
              _statColumn('FUE', '${s.st}', canEdit, context),
              _statColumn('AGI', '${s.ag}+', canEdit, context),
              _statColumn('PAS', s.pa > 0 ? '${s.pa}+' : '-',
                  canEdit && s.pa > 0, context),
              _statColumn('ARM', '${s.av}+', canEdit, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(
      String label, String value, bool canEdit, BuildContext context) {
    return Column(
      children: [
        // Plus button
        if (canEdit)
          _statButton(
              '+',
              () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Proximamente: $label +1')))),
        if (!canEdit) const SizedBox(height: 28),
        const SizedBox(height: 4),
        // Value
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Minus button
        if (canEdit)
          _statButton(
              '-',
              () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Proximamente: $label -1')))),
        if (!canEdit) const SizedBox(height: 28),
      ],
    );
  }

  Widget _statButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // -- Abilities & Traits Card -----------------------------------------------

  Widget _buildAbilitiesCard(
      BuildContext context, Character player, bool isOwner, String lang) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('ABILITIES & TRAITS'),
              const Spacer(),
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: () => _showAddSkillDialog(context, player, lang),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 14),
                  label: Text('ADD SKILL',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info.withOpacity(0.15),
                    foregroundColor: AppColors.info,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: AppColors.info.withOpacity(0.3)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (player.skills.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  Icon(PhosphorIcons.lightning(PhosphorIconsStyle.regular),
                      size: 32, color: AppColors.textMuted.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text(tr(lang, 'player.noSkills'),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 16,
                        color: AppColors.textMuted.withOpacity(0.5),
                      )),
                  const SizedBox(height: 4),
                  Text(
                    isOwner
                        ? tr(lang, 'player.addSkillHint')
                        : tr(lang, 'player.noSkillsYet'),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: player.skills
                  .map((s) => GestureDetector(
                        onTap: () => showSkillPopup(context, ref,
                            skillName: s.name,
                            family: s.family,
                            description: s.description),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: SkillBadge(skill: s),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // -- Level Tracker Card ----------------------------------------------------

  Widget _buildLevelTrackerCard(Character player) {
    final next = _nextSpp(player.level);
    final isMax = next == 0;
    final progress = isMax ? 1.0 : (player.spp / next).clamp(0.0, 1.0);
    final canLevel = _canLevelUp(player);
    final remaining = isMax ? 0 : next - player.spp;

    return _card(
      borderColor: canLevel ? AppColors.warning.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('LEVEL TRACKER'),
              const Spacer(),
              // Decorative arrow up
              Icon(PhosphorIcons.arrowFatLinesUp(PhosphorIconsStyle.fill),
                  size: 20, color: AppColors.accent.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 20),
          // Level progress indicator
          Row(
            children: [
              _levelBadge('NIVEL ${player.level}', true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(
                              canLevel ? AppColors.warning : AppColors.accent),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMax) _levelBadge('NIVEL ${player.level + 1}', false),
            ],
          ),
          const SizedBox(height: 24),
          // SPP Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STAR PLAYER POINTS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${player.spp.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: canLevel
                              ? AppColors.warning
                              : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' / ${next.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TO NEXT LEVEL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMax
                        ? 'MAX'
                        : '${remaining.toString().padLeft(2, '0')} SPP',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
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

  Widget _levelBadge(String text, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.accent.withOpacity(0.15)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrent
              ? AppColors.accent.withOpacity(0.4)
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

  Widget _buildPerformanceRecordsCard(Character player) {
    // Placeholder stats - these would come from backend in real implementation
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PERFORMANCE RECORDS'),
          const SizedBox(height: 16),
          _performanceRow('Matches Played', '00'),
          _performanceRow('Touchdowns', '00', valueColor: AppColors.info),
          _performanceRow('Casualties Caused', '00',
              valueColor: AppColors.error),
          _performanceRow('MVP Awards', '00', valueColor: AppColors.accent),
        ],
      ),
    );
  }

  Widget _performanceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // -- Career Chronicle Card -------------------------------------------------

  Widget _buildCareerChronicleCard(Character player, String lang) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CAREER CHRONICLE'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest Match
              Expanded(
                child: _chronicleColumn(
                  'LATEST MATCH',
                  AppColors.primary,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(lang, 'player.noMatches'),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(lang, 'player.noMatchesDesc'),
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              _vertDivider(),
              // Achievement
              Expanded(
                child: _chronicleColumn(
                  'ACHIEVEMENT',
                  AppColors.accent,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(lang, 'player.noAchievements'),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(lang, 'player.noAchievementsDesc'),
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              _vertDivider(),
              // Notes
              Expanded(
                child: _chronicleColumn(
                  'NOTES',
                  AppColors.info,
                  Text(
                    tr(lang, 'player.noNotes'),
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chronicleColumn(String title, Color color, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _vertDivider() => Container(
        height: 80,
        width: 1,
        color: AppColors.surfaceLight,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );

  // -- Action Buttons --------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, bool isOwner, String lang) {
    if (!isOwner) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr(lang, 'player.changesSaved')))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              tr(lang, 'player.saveChanges'),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.surfaceLight),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              tr(lang, 'player.dismiss'),
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Shared Helpers --------------------------------------------------------

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? AppColors.surfaceLight),
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
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
        color: AppColors.info.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.info.withOpacity(0.5)),
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},000';
    }
    return number.toString();
  }
}

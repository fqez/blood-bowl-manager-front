import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../domain/models/team.dart';
import '../screens/roster_screen.dart';
import '../widgets/skill_badge.dart';

class PlayerCardScreen extends ConsumerWidget {
  final String leagueId;
  final String teamId;
  final String playerId;

  const PlayerCardScreen({
    super.key,
    required this.leagueId,
    required this.teamId,
    required this.playerId,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        data: (team) {
          final isOwner = currentUserId != null && team.ownerId == currentUserId;
          final player = team.characters.firstWhere(
            (c) => c.id == playerId,
            orElse: () => throw Exception('Jugador no encontrado'),
          );
          return Column(children: [
            _buildTopBar(context, team, player),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context, team, player, isOwner),
                      const SizedBox(height: 24),
                      if (isWide)
                        _buildWideLayout(context, team, player, isOwner)
                      else
                        _buildNarrowLayout(context, team, player, isOwner),
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

  Widget _buildTopBar(BuildContext context, Team team, Character player) {
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
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
              onPressed: () => isLeague
                  ? context.go('/league/$leagueId/team/$teamId')
                  : context.go('/teams/$teamId'),
              tooltip: 'Volver',
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
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                    const TextSpan(
                      text: '  >  ROSTER  >  ',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    TextSpan(
                      text: '${player.name.toUpperCase()} - PLAYER DETAILS',
                      style: TextStyle(
                        fontFamily: AppTextStyles.displayFont,
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
                  const SnackBar(content: Text('Guardado'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('SAVE',
                  style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  // -- Hero Section with Portrait --------------------------------------------

  Widget _buildHeroSection(
      BuildContext context, Team team, Character player, bool isOwner) {
    return Container(
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portrait with number badge
          Stack(
            children: [
              Container(
                width: 140,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.user(PhosphorIconsStyle.fill),
                    size: 60,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                ),
              ),
              // Number badge
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${player.number}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              // Edit icon
              if (isOwner)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                        size: 14, color: Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badges
                Row(
                  children: [
                    _statusBadge(player),
                    const SizedBox(width: 8),
                    _positionBadge(player.position),
                  ],
                ),
                const SizedBox(height: 12),
                // Player name
                Text(
                  player.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.0,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Team and Value row
                Row(
                  children: [
                    _infoLabel('TEAM', team.name, AppColors.textSecondary),
                    const SizedBox(width: 32),
                    _infoLabel('VALUE', '${_formatNumber(player.value)} GP', AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLabel(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.displayFont,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // -- Layouts ---------------------------------------------------------------

  Widget _buildWideLayout(
      BuildContext context, Team team, Character player, bool isOwner) {
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
              _buildAbilitiesCard(context, player, isOwner),
              const SizedBox(height: 20),
              _buildCareerChronicleCard(player),
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
              _buildActionButtons(context, isOwner),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context, Team team, Character player, bool isOwner) {
    return Column(
      children: [
        _buildLevelTrackerCard(player),
        const SizedBox(height: 20),
        _buildCoreAttributesCard(context, player, isOwner),
        const SizedBox(height: 20),
        _buildAbilitiesCard(context, player, isOwner),
        const SizedBox(height: 20),
        _buildPerformanceRecordsCard(player),
        const SizedBox(height: 20),
        _buildCareerChronicleCard(player),
        const SizedBox(height: 20),
        _buildActionButtons(context, isOwner),
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
                      const SnackBar(content: Text('Proximamente: Manual Modification'))),
                  icon: Icon(PhosphorIcons.sliders(PhosphorIconsStyle.fill),
                      size: 14, color: AppColors.textMuted),
                  label: const Text('MANUAL MODIFICATION',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
              _statColumn('PAS', s.pa > 0 ? '${s.pa}+' : '-', canEdit && s.pa > 0, context),
              _statColumn('ARM', '${s.av}+', canEdit, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, bool canEdit, BuildContext context) {
    return Column(
      children: [
        // Plus button
        if (canEdit)
          _statButton('+', () => ScaffoldMessenger.of(context).showSnackBar(
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
                  fontFamily: AppTextStyles.displayFont,
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
          _statButton('-', () => ScaffoldMessenger.of(context).showSnackBar(
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
              fontFamily: AppTextStyles.displayFont,
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

  Widget _buildAbilitiesCard(BuildContext context, Character player, bool isOwner) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('ABILITIES & TRAITS'),
              const Spacer(),
              if (isOwner)
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proximamente: Add Skill'))),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 12, color: AppColors.info),
                  label: const Text('ADD SKILL',
                      style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: AppColors.info.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (player.skills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _emptySkillSlot(),
                  const SizedBox(width: 12),
                  _emptySkillSlot(),
                  const SizedBox(width: 12),
                  _lockedSkillSlot(),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...player.skills.map((s) => _skillItem(s)),
                if (player.skills.length < 3) _lockedSkillSlot(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _skillItem(Skill skill) {
    final isStandard = skill.family?.toLowerCase() != 'trait';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isStandard ? 'STANDARD' : 'TRAIT',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isStandard ? AppColors.info : AppColors.warning,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            skill.name,
            style: TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySkillSlot() {
    return Container(
      width: 100,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceLight, style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.regular),
            size: 18, color: AppColors.textMuted.withOpacity(0.3)),
      ),
    );
  }

  Widget _lockedSkillSlot() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Center(
        child: Icon(PhosphorIcons.lock(PhosphorIconsStyle.fill),
            size: 18, color: AppColors.textMuted.withOpacity(0.4)),
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
                          fontFamily: AppTextStyles.displayFont,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: canLevel ? AppColors.warning : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' / ${next.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.displayFont,
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
                    isMax ? 'MAX' : '${remaining.toString().padLeft(2, '0')} SPP',
                    style: TextStyle(
                      fontFamily: AppTextStyles.displayFont,
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
        color: isCurrent ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrent ? AppColors.accent.withOpacity(0.4) : AppColors.surfaceLight,
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
          _performanceRow('Casualties Caused', '00', valueColor: AppColors.error),
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
              fontFamily: AppTextStyles.displayFont,
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

  Widget _buildCareerChronicleCard(Character player) {
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
                        'No hay partidos',
                        style: TextStyle(
                          fontFamily: AppTextStyles.displayFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'El jugador aun no ha disputado ningun partido.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                        'Sin logros',
                        style: TextStyle(
                          fontFamily: AppTextStyles.displayFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aun no ha conseguido logros destacados.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                  const Text(
                    '"Sin notas del entrenador."',
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

  Widget _buildActionButtons(BuildContext context, bool isOwner) {
    if (!isOwner) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cambios guardados'))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'GUARDAR CAMBIOS',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'DESPEDIR',
              style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
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
        fontFamily: AppTextStyles.displayFont,
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
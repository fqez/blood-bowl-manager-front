import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../league/domain/models/league.dart';
import '../../../my_teams/domain/models/user_team.dart';

const matchEventInjuryTypes = [
  'Badly Hurt',
  'Serious Injury',
  'RIP',
  'Miss Next Game',
  'Niggling Injury',
  '-AV',
  '-MA',
  '-AG',
  '-PA',
  '-ST',
];

class MatchEventDraft {
  final String type;
  final String team;
  final String? playerId;
  final String? playerName;
  final String? victimId;
  final String? victimName;
  final String? injury;
  final String? injuryCategory;
  final String? injuryNote;
  final int? lastingInjuryRoll;
  final bool sentOff;
  final bool accidentalCasualty;
  final String? detail;
  final int half;
  final int turn;

  const MatchEventDraft({
    required this.type,
    required this.team,
    this.playerId,
    this.playerName,
    this.victimId,
    this.victimName,
    this.injury,
    this.injuryCategory,
    this.injuryNote,
    this.lastingInjuryRoll,
    this.sentOff = false,
    this.accidentalCasualty = false,
    this.detail,
    required this.half,
    required this.turn,
  });
}

typedef MatchEventSubmit = FutureOr<bool> Function(MatchEventDraft draft);

Future<void> showMatchEventDialog({
  required BuildContext context,
  required Match match,
  required String lang,
  required String eventType,
  required List<UserPlayer> homePlayers,
  required List<UserPlayer> awayPlayers,
  required MatchEventSubmit onAdd,
  String initialTeam = 'home',
  bool allowTeamSelection = true,
}) async {
  String selectedTeam = initialTeam;
  UserPlayer? selectedPlayer;
  UserPlayer? selectedVictim;
  String playerNameText = '';
  String victimNameText = '';
  String? selectedInjury;
  String casualtyCategory = 'badly_hurt';
  int lastingInjuryRoll = 1;
  String detail = '';
  bool superbThrow = false;
  bool landedStanding = false;
  bool foulSentOff = false;
  bool accidentalCasualty = false;
  bool submitting = false;

  final isThrowTeammate = eventType == 'throw_teammate';
  final isCasualty = eventType == 'casualty';
  final isFoul = eventType == 'foul';

  final needsVictim = [
        'casualty',
        'ko',
        'rip',
        'badly_hurt',
        'serious_injury',
        'stun',
      ].contains(eventType) ||
      isThrowTeammate;
  final needsInjury =
      ['rip', 'badly_hurt', 'serious_injury'].contains(eventType);

  List<UserPlayer> getPlayers(String team) =>
      team == 'home' ? homePlayers : awayPlayers;
  List<UserPlayer> getOpponents(String team) =>
      team == 'home' ? awayPlayers : homePlayers;
  List<UserPlayer> getVictimCandidates(String team) => isThrowTeammate
      ? getPlayers(team).where((p) => p.id != selectedPlayer?.id).toList()
      : isCasualty && accidentalCasualty
          ? getPlayers(team)
          : getOpponents(team);

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final players = getPlayers(selectedTeam);
        final hasRoster = players.isNotEmpty;
        final evColor = matchEventColor(eventType);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 620),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: evColor.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: evColor.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        evColor.withValues(alpha: 0.2),
                        AppColors.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              evColor.withValues(alpha: 0.3),
                              evColor.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: evColor.withValues(alpha: 0.4)),
                        ),
                        child: Icon(matchEventIcon(eventType),
                            color: evColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventType.toUpperCase(),
                              style: TextStyle(
                                color: evColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tr(lang, 'liveMatch.add')} ${eventType.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                            color: AppColors.textMuted, size: 20),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (allowTeamSelection)
                          Row(
                            children: [
                              Expanded(
                                child: _teamChip(
                                  label: match.home.teamName,
                                  selected: selectedTeam == 'home',
                                  onTap: () => setS(() {
                                    selectedTeam = 'home';
                                    selectedPlayer = null;
                                    selectedVictim = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _teamChip(
                                  label: match.away.teamName,
                                  selected: selectedTeam == 'away',
                                  onTap: () => setS(() {
                                    selectedTeam = 'away';
                                    selectedPlayer = null;
                                    selectedVictim = null;
                                  }),
                                ),
                              ),
                            ],
                          )
                        else
                          _teamChip(
                            label: selectedTeam == 'home'
                                ? match.home.teamName
                                : match.away.teamName,
                            selected: true,
                            onTap: () {},
                          ),
                        const SizedBox(height: 16),
                        if (hasRoster)
                          DropdownButtonFormField<UserPlayer>(
                            key: ValueKey('player-$selectedTeam'),
                            value: selectedPlayer,
                            dropdownColor: AppColors.card,
                            isExpanded: true,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _inputDeco(isThrowTeammate
                                ? 'Jugador que lanza'
                                : accidentalCasualty
                                    ? (lang == 'es'
                                        ? 'Sin jugador causante'
                                        : 'No causing player')
                                    : tr(lang, 'liveMatch.selectPlayer')),
                            items: players
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        '#${p.number} — ${p.name}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: accidentalCasualty
                                ? null
                                : (v) => setS(() {
                                      selectedPlayer = v;
                                      if (selectedVictim?.id == v?.id) {
                                        selectedVictim = null;
                                      }
                                    }),
                          )
                        else
                          TextField(
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _inputDeco(isThrowTeammate
                                ? 'Jugador que lanza'
                                : tr(lang, 'liveMatch.playerName')),
                            onChanged: (v) => playerNameText = v,
                          ),
                        if (needsVictim) ...[
                          const SizedBox(height: 12),
                          if (getVictimCandidates(selectedTeam).isNotEmpty)
                            DropdownButtonFormField<UserPlayer>(
                              key: ValueKey(
                                'victim-$selectedTeam-${selectedPlayer?.id ?? ''}',
                              ),
                              value: selectedVictim,
                              dropdownColor: AppColors.card,
                              isExpanded: true,
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDeco(isThrowTeammate
                                  ? 'Jugador lanzado'
                                  : accidentalCasualty
                                      ? (lang == 'es'
                                          ? 'Jugador lesionado'
                                          : 'Injured player')
                                      : tr(lang, 'liveMatch.selectVictim')),
                              items: getVictimCandidates(selectedTeam)
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          '#${p.number} — ${p.name}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setS(() => selectedVictim = v),
                            )
                          else
                            TextField(
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDeco(isThrowTeammate
                                  ? 'Jugador lanzado'
                                  : tr(lang, 'liveMatch.victimName')),
                              onChanged: (v) => victimNameText = v,
                            ),
                        ],
                        if (isThrowTeammate) ...[
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: superbThrow,
                            dense: true,
                            activeColor: AppColors.accent,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Lanzamiento soberbio (+1 SPP al lanzador si cae de pie)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onChanged: (v) =>
                                setS(() => superbThrow = v ?? false),
                          ),
                          CheckboxListTile(
                            value: landedStanding,
                            dense: true,
                            activeColor: AppColors.success,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'El jugador lanzado cae de pie (+1 SPP)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onChanged: (v) =>
                                setS(() => landedStanding = v ?? false),
                          ),
                        ],
                        if (isCasualty) ...[
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: accidentalCasualty,
                            dense: true,
                            activeColor: AppColors.warning,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              lang == 'es'
                                  ? 'Caida/accidente (sin SPP)'
                                  : 'Fall/accident (no SPP)',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onChanged: submitting
                                ? null
                                : (value) => setS(() {
                                      accidentalCasualty = value ?? false;
                                      selectedPlayer = null;
                                      selectedVictim = null;
                                    }),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: casualtyCategory,
                            dropdownColor: AppColors.card,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _inputDeco(
                                lang == 'es' ? 'Resultado' : 'Result'),
                            items: _casualtyConditionOptions(lang)
                                .map((option) => DropdownMenuItem<String>(
                                      value: option.value,
                                      child: Row(
                                        children: [
                                          Icon(option.icon,
                                              size: 16, color: option.color),
                                          const SizedBox(width: 8),
                                          Text(
                                            option.label,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: submitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setS(() => casualtyCategory = value);
                                    }
                                  },
                          ),
                          if (casualtyCategory == 'lasting_injury') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: lastingInjuryRoll,
                              dropdownColor: AppColors.card,
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDeco('D6'),
                              items: List.generate(6, (index) => index + 1)
                                  .map((roll) => DropdownMenuItem<int>(
                                        value: roll,
                                        child: Text(_lastingInjuryRollLabel(
                                            roll, lang)),
                                      ))
                                  .toList(),
                              onChanged: submitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setS(() => lastingInjuryRoll = value);
                                      }
                                    },
                            ),
                          ],
                        ],
                        if (isFoul) ...[
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: foulSentOff,
                            dense: true,
                            activeColor: AppColors.warning,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              lang == 'es'
                                  ? 'Jugador expulsado'
                                  : 'Player sent off',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onChanged: submitting
                                ? null
                                : (value) =>
                                    setS(() => foulSentOff = value ?? false),
                          ),
                        ],
                        if (needsInjury) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedInjury,
                            dropdownColor: AppColors.card,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration:
                                _inputDeco(tr(lang, 'liveMatch.injuryType')),
                            items: matchEventInjuryTypes
                                .map((i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(i),
                                    ))
                                .toList(),
                            onChanged: (v) => setS(() => selectedInjury = v),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: _inputDeco(tr(lang, 'liveMatch.detail')),
                          onChanged: (v) => detail = v,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          tr(lang, 'common.cancel'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(matchEventIcon(eventType), size: 18),
                        onPressed: submitting
                            ? null
                            : () async {
                                setS(() => submitting = true);
                                final cleanDetail = detail.trim();
                                final eventDetail = isThrowTeammate
                                    ? 'Soberbio: ${superbThrow ? 'sí' : 'no'} · Cae de pie: ${landedStanding ? 'sí' : 'no'}${cleanDetail.isEmpty ? '' : ' · $cleanDetail'}'
                                    : accidentalCasualty
                                        ? 'accidental=true${cleanDetail.isEmpty ? '' : ' · $cleanDetail'}'
                                        : cleanDetail;
                                final injuryCategory = isCasualty &&
                                        casualtyCategory != 'badly_hurt'
                                    ? casualtyCategory
                                    : null;
                                final shouldClose = await onAdd(MatchEventDraft(
                                  type: eventType,
                                  team: selectedTeam,
                                  playerId: accidentalCasualty
                                      ? null
                                      : selectedPlayer?.id,
                                  playerName: accidentalCasualty
                                      ? null
                                      : selectedPlayer != null
                                          ? '#${selectedPlayer!.number} ${selectedPlayer!.name}'
                                          : (playerNameText.isEmpty
                                              ? null
                                              : playerNameText),
                                  victimId: selectedVictim?.id,
                                  victimName: selectedVictim != null
                                      ? '#${selectedVictim!.number} ${selectedVictim!.name}'
                                      : (victimNameText.isEmpty
                                          ? null
                                          : victimNameText),
                                  injury: isCasualty
                                      ? _casualtyInjuryLabel(
                                          casualtyCategory,
                                          lastingInjuryRoll,
                                          lang,
                                        )
                                      : selectedInjury,
                                  injuryCategory: injuryCategory,
                                  injuryNote:
                                      cleanDetail.isEmpty ? null : cleanDetail,
                                  lastingInjuryRoll:
                                      casualtyCategory == 'lasting_injury'
                                          ? lastingInjuryRoll
                                          : null,
                                  sentOff: isFoul && foulSentOff,
                                  accidentalCasualty: accidentalCasualty,
                                  detail:
                                      eventDetail.isEmpty ? null : eventDetail,
                                  half: match.currentHalf,
                                  turn: match.currentTurn,
                                ));
                                if (!ctx.mounted) return;
                                if (shouldClose) {
                                  Navigator.pop(ctx);
                                } else {
                                  setS(() => submitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: evColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: evColor.withValues(alpha: 0.5),
                        ),
                        label: Text(tr(lang, 'liveMatch.add')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Color matchEventColor(String type) {
  switch (type) {
    case 'touchdown':
      return AppColors.accent;
    case 'casualty':
    case 'rip':
    case 'serious_injury':
      return AppColors.error;
    case 'ko':
    case 'stun':
    case 'badly_hurt':
      return AppColors.warning;
    case 'completion':
    case 'interception':
    case 'throw_teammate':
      return AppColors.info;
    case 'foul':
      return AppColors.primaryLight;
    case 'score_change':
      return AppColors.accent;
    case 'half_change':
    case 'turn_change':
      return AppColors.info;
    case 'weather_change':
    case 'kickoff_change':
      return AppColors.warning;
    case 'reroll_change':
      return const Color(0xFF9C27B0);
    default:
      return AppColors.textMuted;
  }
}

IconData matchEventIcon(String type) {
  switch (type) {
    case 'touchdown':
      return PhosphorIcons.trophy(PhosphorIconsStyle.fill);
    case 'casualty':
    case 'rip':
    case 'serious_injury':
      return PhosphorIcons.skull(PhosphorIconsStyle.fill);
    case 'ko':
    case 'stun':
    case 'badly_hurt':
      return PhosphorIcons.lightningSlash(PhosphorIconsStyle.fill);
    case 'completion':
      return PhosphorIcons.arrowBendUpRight(PhosphorIconsStyle.fill);
    case 'throw_teammate':
      return PhosphorIcons.userSwitch(PhosphorIconsStyle.fill);
    case 'interception':
      return PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill);
    case 'foul':
      return PhosphorIcons.prohibit(PhosphorIconsStyle.fill);
    case 'score_change':
      return PhosphorIcons.plusMinus(PhosphorIconsStyle.fill);
    case 'half_change':
      return PhosphorIcons.timer(PhosphorIconsStyle.fill);
    case 'turn_change':
      return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
    case 'weather_change':
      return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
    case 'kickoff_change':
      return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
    case 'reroll_change':
      return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
    default:
      return PhosphorIcons.note(PhosphorIconsStyle.fill);
  }
}

InputDecoration _inputDeco(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.surfaceLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );

Widget _teamChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Material(
    color: selected
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

class _MatchConditionOption {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _MatchConditionOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

List<_MatchConditionOption> _casualtyConditionOptions(String lang) => [
      _MatchConditionOption(
        value: 'badly_hurt',
        label: lang == 'es' ? 'Sin secuelas' : 'No long-term effect',
        color: AppColors.warning,
        icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
      ),
      _MatchConditionOption(
        value: 'miss_next_game',
        label: lang == 'es' ? 'Se pierde el próximo' : 'Miss next game',
        color: AppColors.warning,
        icon: PhosphorIcons.calendarX(PhosphorIconsStyle.fill),
      ),
      _MatchConditionOption(
        value: 'lasting_injury',
        label: lang == 'es' ? 'Lesión permanente' : 'Lasting injury',
        color: AppColors.error,
        icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
      ),
      _MatchConditionOption(
        value: 'dead',
        label: lang == 'es' ? 'Muerto' : 'Dead',
        color: AppColors.dead,
        icon: PhosphorIcons.skull(PhosphorIconsStyle.fill),
      ),
    ];

String _casualtyInjuryLabel(String category, int roll, String lang) {
  switch (category) {
    case 'miss_next_game':
      return lang == 'es' ? 'Se pierde el próximo' : 'Miss next game';
    case 'lasting_injury':
      return _lastingInjuryRollLabel(roll, lang);
    case 'dead':
      return lang == 'es' ? 'Muerto' : 'Dead';
    default:
      return lang == 'es' ? 'Sin secuelas' : 'No long-term effect';
  }
}

String _lastingInjuryRollLabel(int roll, String lang) {
  switch (roll) {
    case 1:
    case 2:
      return lang == 'es'
          ? '$roll - Cabeza fracturada (-1 AV)'
          : '$roll - Head injury (-1 AV)';
    case 3:
      return lang == 'es'
          ? '3 - Rodilla aplastada (-1 MA)'
          : '3 - Smashed knee (-1 MA)';
    case 4:
      return lang == 'es' ? '4 - Brazo roto (-1 PA)' : '4 - Broken arm (-1 PA)';
    case 5:
      return lang == 'es'
          ? '5 - Cadera dislocada (-1 AG)'
          : '5 - Dislocated hip (-1 AG)';
    case 6:
      return lang == 'es'
          ? '6 - Rotura de hombro (-1 ST)'
          : '6 - Broken shoulder (-1 ST)';
    default:
      return '$roll';
  }
}

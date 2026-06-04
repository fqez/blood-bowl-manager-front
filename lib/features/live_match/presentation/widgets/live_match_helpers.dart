part of '../screens/live_match_screen.dart';

// ══════════════════════════════════════════════
//  DATA CLASSES
// ══════════════════════════════════════════════

class _CardOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? description;
  final String? rollLabel;
  const _CardOption(this.value, this.label, this.icon, this.color,
      [this.description, this.rollLabel]);
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final String type;
  final String? sppLabel;
  const _QA(this.label, this.icon, this.color, this.type, this.sppLabel);
}

class _PlayerStatusOption {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _PlayerStatusOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _RiotousRookiesRoll {
  final int firstD3;
  final int secondD3;

  const _RiotousRookiesRoll(this.firstD3, this.secondD3);

  int get count => firstD3 + secondD3 + 1;
}

enum _PrepRosterSortColumn {
  selected,
  number,
  name,
  position,
  ma,
  st,
  ag,
  pa,
  av,
  skills,
  spp,
  status,
  cost,
}

// ══════════════════════════════════════════════
//  CONSTANTS
// ══════════════════════════════════════════════

final _goldFmt = NumberFormat('#,###');

const _inducementSyncMarker = 'BBM_INDUCEMENT_SYNC:';
const _selfInflictedMarker = 'BBM_SELF_INFLICTED:1';

String _inducementInstanceUseKey(String ruleId, int index) => '$ruleId#$index';

int? _prayerRollFromDetail(String detail) {
  final match = RegExp(r'D16\s+(\d{1,2})').firstMatch(detail);
  return int.tryParse(match?.group(1) ?? '');
}

PrayerToNuffleResult? _prayerResultForDetail(
  String detail,
  List<PrayerToNuffleResult> results,
) {
  final roll = _prayerRollFromDetail(detail);
  if (roll == null) return null;
  for (final result in results) {
    if (result.roll == roll) return result;
  }
  return null;
}

Map<String, List<String>> _copyInducementDetails(
  Map<String, List<String>> source,
) =>
    source.map((key, value) => MapEntry(key, List<String>.from(value)));

bool _inducementDetailsEqual(
  Map<String, List<String>> a,
  Map<String, List<String>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || !listEquals(entry.value, other)) return false;
  }
  return true;
}

final _weatherData = [
  _CardOption(
      'Sweltering Heat',
      'Sweltering Heat',
      PhosphorIcons.thermometerHot(PhosphorIconsStyle.fill),
      const Color(0xFFFF6B35),
      'At the start of each drive, each team rolls a D6 per player. On a 1, that player is placed in the Reserves box.'),
  _CardOption(
      'Very Sunny',
      'Very Sunny',
      PhosphorIcons.sun(PhosphorIconsStyle.fill),
      AppColors.warning,
      'A glaring sun dazzles players. –1 modifier to all Catch, Intercept and Pass rolls.'),
  _CardOption(
      'Perfect',
      'Perfect',
      PhosphorIcons.sunHorizon(PhosphorIconsStyle.fill),
      AppColors.success,
      'Perfect conditions. No special effects on play.'),
  _CardOption(
      'Pouring Rain',
      'Pouring Rain',
      PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
      AppColors.info,
      'Rain makes the ball slippery. –1 modifier to all Catch, Intercept, Pick Up and Pass rolls.'),
  _CardOption(
      'Blizzard',
      'Blizzard',
      PhosphorIcons.snowflake(PhosphorIconsStyle.fill),
      const Color(0xFF90CAF9),
      'Reduced visibility and treacherous pitch. –1 to Catch, Intercept, Pick Up and Pass rolls. Players may only go for it once per activation.'),
];

final _kickoffData = [
  _CardOption(
      'Get the Ref!',
      'Get the Ref!',
      PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
      AppColors.error,
      'The crowd is enraged! Both coaches may use a single free Bribe during this drive.'),
  _CardOption(
      'Time Out!',
      'Time Out!',
      PhosphorIcons.timer(PhosphorIconsStyle.fill),
      AppColors.warning,
      'A player fakes an injury. Move the turn marker 1 space in favor of the last-scoring team (or the receiving team if no score yet).'),
  _CardOption(
      'Solid Defence',
      'Solid Defence',
      PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
      AppColors.info,
      'The kicking team receives D3+3 additional set-up cards to use during this drive.'),
  _CardOption(
      'High Kick',
      'High Kick',
      PhosphorIcons.arrowUp(PhosphorIconsStyle.fill),
      AppColors.success,
      'One player on the receiving team may be placed on the exact square where the ball lands (if unoccupied).'),
  _CardOption(
      'Cheering Fans',
      'Cheering Fans',
      PhosphorIcons.handsPraying(PhosphorIconsStyle.fill),
      AppColors.accent,
      'Both teams roll a D6 and add their Fan Factor. The team with the higher total gains +1 Fan Factor permanently.'),
  _CardOption(
      'Brilliant Coaching',
      'Brilliant Coaching',
      PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
      AppColors.primaryLight,
      'Both teams roll a D6 and add their number of Assistant Coaches. The team with the higher total gains 1 extra Re-roll for this half.'),
  _CardOption(
      'Changing Weather',
      'Changing Weather',
      PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
      const Color(0xFF90CAF9),
      'Re-roll on the weather table and immediately apply the new result, even if it is the same condition.'),
  _CardOption(
      'Quick Snap!',
      'Quick Snap!',
      PhosphorIcons.lightning(PhosphorIconsStyle.fill),
      AppColors.warning,
      'The receiving team may make a free Move action with one player before the kick-off takes place.'),
  _CardOption(
      'Blitz!',
      'Blitz!',
      PhosphorIcons.sword(PhosphorIconsStyle.fill),
      AppColors.error,
      'The kicking team gets a free Blitz! action with one player before the ball lands.'),
  _CardOption(
      'Throw a Rock',
      'Throw a Rock',
      PhosphorIcons.asterisk(PhosphorIconsStyle.fill),
      AppColors.primaryDark,
      'An enraged fan hurls a rock at a random player on the opposing team. Roll for injury on that player.'),
  _CardOption(
      'Pitch Invasion',
      'Pitch Invasion',
      PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
      AppColors.error,
      'Fans invade the pitch! For each opposing player on the field, roll a D6; on a 5+ that player is placed in the Reserves box.'),
];

List<_CardOption> _weatherOptionsFromRules(DiceRangeRules? rules, String lang) {
  if (rules == null || rules.table.isEmpty) return _weatherData;
  return rules.table
      .map((entry) => _CardOption(
            entry.localizedLabel('en'),
            entry.localizedLabel(lang),
            _weatherIcon(entry.code),
            _weatherColor(entry.code),
            entry.localizedDescription(lang),
            entry.rollLabel,
          ))
      .toList();
}

List<_CardOption> _kickoffOptionsFromRules(DiceRangeRules? rules, String lang) {
  if (rules == null || rules.table.isEmpty) return _kickoffData;
  return rules.table
      .map((entry) => _CardOption(
            entry.localizedLabel('en'),
            entry.localizedLabel(lang),
            _kickoffIcon(entry.code),
            _kickoffColor(entry.code),
            entry.localizedDescription(lang),
            entry.rollLabel,
          ))
      .toList();
}

IconData _weatherIcon(String code) {
  switch (code) {
    case 'sweltering_heat':
      return PhosphorIcons.thermometerHot(PhosphorIconsStyle.fill);
    case 'very_sunny':
      return PhosphorIcons.sun(PhosphorIconsStyle.fill);
    case 'pouring_rain':
      return PhosphorIcons.cloudRain(PhosphorIconsStyle.fill);
    case 'blizzard':
      return PhosphorIcons.snowflake(PhosphorIconsStyle.fill);
    default:
      return PhosphorIcons.sunHorizon(PhosphorIconsStyle.fill);
  }
}

Color _weatherColor(String code) {
  switch (code) {
    case 'sweltering_heat':
      return const Color(0xFFFF6B35);
    case 'very_sunny':
      return AppColors.warning;
    case 'pouring_rain':
      return AppColors.info;
    case 'blizzard':
      return const Color(0xFF90CAF9);
    default:
      return AppColors.success;
  }
}

IconData _kickoffIcon(String code) {
  switch (code) {
    case 'get_the_ref':
      return PhosphorIcons.megaphone(PhosphorIconsStyle.fill);
    case 'time_out':
      return PhosphorIcons.timer(PhosphorIconsStyle.fill);
    case 'solid_defence':
      return PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill);
    case 'high_kick':
      return PhosphorIcons.arrowUp(PhosphorIconsStyle.fill);
    case 'cheering_fans':
      return PhosphorIcons.handsPraying(PhosphorIconsStyle.fill);
    case 'brilliant_coaching':
      return PhosphorIcons.graduationCap(PhosphorIconsStyle.fill);
    case 'changing_weather':
      return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
    case 'quick_snap':
      return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
    case 'charge':
      return PhosphorIcons.sword(PhosphorIconsStyle.fill);
    case 'pitch_invasion':
      return PhosphorIcons.usersThree(PhosphorIconsStyle.fill);
    default:
      return PhosphorIcons.asterisk(PhosphorIconsStyle.fill);
  }
}

Color _kickoffColor(String code) {
  switch (code) {
    case 'get_the_ref':
    case 'charge':
    case 'pitch_invasion':
      return AppColors.error;
    case 'time_out':
    case 'quick_snap':
      return AppColors.warning;
    case 'solid_defence':
      return AppColors.info;
    case 'high_kick':
      return AppColors.success;
    case 'cheering_fans':
      return AppColors.accent;
    case 'brilliant_coaching':
      return AppColors.primaryLight;
    case 'changing_weather':
      return const Color(0xFF90CAF9);
    default:
      return AppColors.primaryDark;
  }
}

// ══════════════════════════════════════════════
//  HELPER EXTENSION
// ══════════════════════════════════════════════

extension _LiveMatchHelpers on _LiveMatchScreenState {
  TextStyle get _displaySmall =>
      Theme.of(context).textTheme.displaySmall ?? const TextStyle();

  String _fmtGold(int amount) => _goldFmt.format(amount);

  String _fmtStat(dynamic val) {
    if (val == null || val == '-') return '-';
    return '$val';
  }

  String _teamLogoPath(String baseRosterId) {
    if (baseRosterId.isEmpty) return 'assets/teams/human/logo.webp';
    return 'assets/teams/$baseRosterId/logo.webp';
  }

  bool _isSystemEvent(String type) => const {
        'score_change',
        'half_change',
        'turn_change',
        'weather_change',
        'kickoff_change',
        'reroll_change',
        'reroll_total_change',
        'inducement_purchase',
        'inducement_change',
      }.contains(type);

  Color _evColor(String type) {
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
      case 'reroll_total_change':
        return const Color(0xFF9C27B0);
      case 'inducement_purchase':
      case 'inducement_change':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _evIcon(String type) {
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
      case 'reroll_total_change':
        return PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.fill);
      case 'inducement_purchase':
      case 'inducement_change':
        return PhosphorIcons.handCoins(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.note(PhosphorIconsStyle.fill);
    }
  }

  String _fmtAuditDateTime(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(local);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _teamLabel(Match match, String team) {
    switch (team) {
      case 'home':
        return 'HOME - ${match.home.teamName}';
      case 'away':
        return 'AWAY - ${match.away.teamName}';
      default:
        return tr(ref.read(localeProvider), 'liveMatch.system');
    }
  }

  String _matchAuditContext(Match match) {
    final half = match.currentHalf > 0 ? match.currentHalf : '-';
    final turn = match.currentTurn > 0 ? match.currentTurn : '-';
    return [
      'Marcador ${match.scoreHome}-${match.scoreAway}',
      'Parte $half',
      'Turno $turn',
      'Activo ${_teamLabel(match, match.currentTeam)}',
      'Reloj ${_fmtDuration(_elapsed)}',
    ].join(' | ');
  }

  String _withMatchAuditContext(Match match, String? detail) {
    final cleanDetail = detail?.trim();
    final audit = 'Audit: ${_matchAuditContext(match)}';
    if (cleanDetail == null || cleanDetail.isEmpty) return audit;
    return '$cleanDetail\n$audit';
  }

  String _withInducementSyncPayload({
    required String summary,
    required String team,
    required String ruleId,
    required int purchased,
    required int used,
  }) {
    return [
      summary,
      '$_inducementSyncMarker${jsonEncode({
            'team': team,
            'ruleId': ruleId,
            'purchased': purchased,
            'used': used,
          })}',
    ].join('\n');
  }

  String _visibleEventDetail(String detail) {
    return detail
        .split('\n')
        .where((line) =>
            !line.startsWith(_inducementSyncMarker) &&
            line.trim() != _selfInflictedMarker)
        .join('\n')
        .trim();
  }

  void _debugSyncTrace(String message) {
    if (kDebugMode) debugPrint('[LiveMatchSync] $message');
  }

  Widget _empty(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );

  Widget _sectionHeader(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _sectionHeaderAccent(String text) => Row(children: [
        Container(width: 3, height: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(text,
            style: _displaySmall.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic)),
      ]);

  Widget _checkRow(String label, bool ok, String lang) => Row(children: [
        Icon(
          ok
              ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.circle(PhosphorIconsStyle.regular),
          color: ok ? AppColors.success : AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          ok ? '$label ✓' : '$label — ${tr(lang, 'liveMatch.pending')}',
          style: TextStyle(
              color: ok ? AppColors.success : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ]);

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surfaceLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
      );

  Widget _teamLogo(String assetPath, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          PhosphorIcons.shield(PhosphorIconsStyle.fill),
          size: size * 0.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _scoreTap(IconData icon, VoidCallback? onTap, {double size = 32}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: size * 0.45,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 12,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  _CardOption? _findOption(List<_CardOption> data, String value) {
    try {
      return data.firstWhere((d) => d.value == value);
    } catch (_) {
      return null;
    }
  }

  TextStyle _hireStatStyle(bool active) => TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      );
}

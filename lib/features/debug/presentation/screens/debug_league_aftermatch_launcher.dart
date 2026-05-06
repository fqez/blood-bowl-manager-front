import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../league/domain/models/league.dart';
import '../../../shared/data/repositories.dart';

class DebugLeagueAftermatchLauncher extends ConsumerStatefulWidget {
  const DebugLeagueAftermatchLauncher({super.key});

  @override
  ConsumerState<DebugLeagueAftermatchLauncher> createState() =>
      _DebugLeagueAftermatchLauncherState();
}

class _DebugLeagueAftermatchLauncherState
    extends ConsumerState<DebugLeagueAftermatchLauncher> {
  static const _debugEmail = 'test@test.com';
  static const _debugPassword = 'Password123!';

  String _messageKey = 'debugAftermatch.preparing';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openAftermatch());
  }

  Future<void> _openAftermatch() async {
    try {
      await _ensureDebugUser();
      final target = await _findOrPrepareLeagueMatch();
      if (!mounted) return;
      context.go(
          '/league/${target.leagueId}/match/${target.matchId}/aftermatch?debugSeed=${target.debugSeed}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _messageKey = 'debugAftermatch.openError';
      });
    }
  }

  Future<void> _ensureDebugUser() async {
    final current = ref.read(authStateProvider).valueOrNull;
    if (current?.user?.email == _debugEmail) return;

    _setMessage('debugAftermatch.login');
    await ref
        .read(authStateProvider.notifier)
        .login(_debugEmail, _debugPassword);

    final next = ref.read(authStateProvider).valueOrNull;
    if (next?.user?.email != _debugEmail) {
      throw Exception(
          tr(ref.read(localeProvider), 'debugAftermatch.loginError'));
    }
  }

  Future<_DebugAftermatchTarget> _findOrPrepareLeagueMatch() async {
    final repo = ref.read(leagueRepositoryProvider);
    _setMessage('debugAftermatch.searchingLeagues');

    final leagues = await repo.getMyLeaguesSummary();
    final orderedLeagues = [
      ...leagues.where((l) => l.isActive),
      ...leagues.where((l) => !l.isActive),
    ];

    for (final league in orderedLeagues) {
      final detail = await repo.getLeague(league.id);
      if (detail.teams.length < 2) continue;

      var matches = await repo.getLeagueMatches(detail.id);
      Match? match;

      if (detail.status == LeagueStatus.draft) {
        _setMessage('debugAftermatch.startingLeague');
        try {
          await repo.startLeague(detail.id);
          matches = await repo.getLeagueMatches(detail.id);
        } catch (_) {
          continue;
        }
      }

      match = _firstOrNull(matches.where((m) => m.isInProgress));
      if (match != null) {
        _setMessage('debugAftermatch.completingMatch');
        await repo.completeMatch(detail.id, match.id);
        return _DebugAftermatchTarget.random(detail.id, match.id);
      }

      match = _firstOrNull(matches.where((m) => m.isPending));
      if (match != null) {
        _setMessage('debugAftermatch.preparingMatch');
        await repo.startMatch(detail.id, match.id);
        _setMessage('debugAftermatch.randomizing');
        await repo.completeMatch(detail.id, match.id);
        return _DebugAftermatchTarget.random(detail.id, match.id);
      }

      match = _firstOrNull(matches.where((m) => m.isPlayed));
      if (match != null) {
        _setMessage('debugAftermatch.randomizing');
        return _DebugAftermatchTarget.random(detail.id, match.id);
      }
    }

    throw Exception(tr(ref.read(localeProvider), 'debugAftermatch.noMatch'));
  }

  T? _firstOrNull<T>(Iterable<T> values) {
    final iterator = values.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }

  void _setMessage(String messageKey) {
    if (!mounted) return;
    setState(() => _messageKey = messageKey);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error == null
                    ? PhosphorIcons.bug(PhosphorIconsStyle.bold)
                    : PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                color: _error == null ? AppColors.primary : AppColors.error,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                tr(lang, _messageKey),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_error == null) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: AppColors.primary),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openAftermatch,
                  icon: Icon(PhosphorIcons.arrowClockwise()),
                  label: Text(tr(lang, 'common.retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugAftermatchTarget {
  const _DebugAftermatchTarget(this.leagueId, this.matchId, this.debugSeed);

  factory _DebugAftermatchTarget.random(String leagueId, String matchId) {
    return _DebugAftermatchTarget(
      leagueId,
      matchId,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  final String leagueId;
  final String matchId;
  final int debugSeed;
}

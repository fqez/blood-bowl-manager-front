import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/league/presentation/screens/league_overview_screen.dart';
import '../../features/my_teams/presentation/screens/my_team_detail_screen.dart';
import '../../features/roster/presentation/screens/player_card_screen.dart';
import '../../features/aftermatch/presentation/screens/aftermatch_screen.dart';
import '../../features/team_creator/presentation/screens/team_creator_screen.dart';
import '../../features/my_teams/presentation/screens/my_teams_screen.dart';
import '../../features/my_teams/presentation/screens/my_team_detail_screen.dart';
import '../../features/leagues/presentation/screens/leagues_screen.dart';
import '../../features/leagues/presentation/screens/create_league_screen.dart';
import '../../features/leagues/presentation/screens/join_league_screen.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/leagues',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/leagues';
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app routes (with shell)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/leagues',
            name: 'leagues',
            builder: (context, state) => const LeaguesScreen(),
          ),
          GoRoute(
            path: '/leagues/create',
            name: 'create-league',
            builder: (context, state) => const CreateLeagueScreen(),
          ),
          GoRoute(
            path: '/leagues/join',
            name: 'join-league',
            builder: (context, state) => const JoinLeagueScreen(),
          ),
          GoRoute(
            path: '/league/:leagueId',
            name: 'league',
            builder: (context, state) {
              final leagueId = state.pathParameters['leagueId']!;
              return LeagueOverviewScreen(leagueId: leagueId);
            },
            routes: [
              GoRoute(
                path: 'team/:teamId',
                name: 'roster',
                builder: (context, state) {
                  final leagueId = state.pathParameters['leagueId']!;
                  final teamId = state.pathParameters['teamId']!;
                  return MyTeamDetailScreen(teamId: teamId, leagueId: leagueId);
                },
                routes: [
                  GoRoute(
                    path: 'player/:playerId',
                    name: 'player',
                    builder: (context, state) {
                      final leagueId = state.pathParameters['leagueId']!;
                      final teamId = state.pathParameters['teamId']!;
                      final playerId = state.pathParameters['playerId']!;
                      return PlayerCardScreen(
                        leagueId: leagueId,
                        teamId: teamId,
                        playerId: playerId,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'match/:matchId/aftermatch',
                name: 'aftermatch',
                builder: (context, state) {
                  final leagueId = state.pathParameters['leagueId']!;
                  final matchId = state.pathParameters['matchId']!;
                  return AftermatchScreen(
                    leagueId: leagueId,
                    matchId: matchId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/create-team',
            name: 'create-team',
            builder: (context, state) {
              final leagueId = state.uri.queryParameters['leagueId'];
              return TeamCreatorScreen(leagueId: leagueId);
            },
          ),
          GoRoute(
            path: '/teams',
            name: 'my-teams',
            builder: (context, state) => const MyTeamsScreen(),
          ),
          GoRoute(
            path: '/teams/:teamId',
            name: 'my-team-detail',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId']!;
              return MyTeamDetailScreen(teamId: teamId);
            },
            routes: [
              GoRoute(
                path: 'player/:playerId',
                name: 'my-team-player',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  final playerId = state.pathParameters['playerId']!;
                  return PlayerCardScreen(
                    leagueId: '',
                    teamId: teamId,
                    playerId: playerId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

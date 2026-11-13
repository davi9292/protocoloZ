import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/faction/faction_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/trades/trades_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/ranking/ranking_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/expeditions/expeditions_screen.dart';
import '../widgets/app_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final game = ref.watch(gameRepositoryProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshNotifier(auth),
    redirect: (context, state) async {
      final path = state.matchedLocation;
      if (path == '/splash') {
        if (!auth.isSignedIn) return '/login';
        final profile = await game.myProfile();
        if (profile == null || profile['faction_id'] == null) return '/faction';
        return '/home';
      }
      if (!auth.isSignedIn) return path == '/login' ? null : '/login';
      final profile = await game.myProfile();
      final needsFaction = profile == null || profile['faction_id'] == null;
      if (needsFaction && path != '/faction') return '/faction';
      if (!needsFaction && (path == '/login' || path == '/faction')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/faction', builder: (_, __) => const FactionScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/map', builder: (_, __) => const MapScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/expeditions', builder: (_, __) => const ExpeditionsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/trades', builder: (_, __) => const TradesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ranking', builder: (_, __) => const RankingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(AuthRepository auth) {
    auth.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shield_moon, size: 64, color: Color(0xFF9DBB73)),
      SizedBox(height: 16),
      Text('PROTOCOLO Z', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 3)),
      SizedBox(height: 8),
      Text('SOBREVIVER É UM TRABALHO EM EQUIPE', style: TextStyle(color: Color(0xFF91A095), fontSize: 10, letterSpacing: 1.2)),
      SizedBox(height: 24), CircularProgressIndicator(),
    ])),
  );
}

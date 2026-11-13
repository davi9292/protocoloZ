import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index, initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.radar), label: 'Central'),
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Missões'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Mochila'),
        NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Trocas'),
        NavigationDestination(icon: Icon(Icons.warning_amber), label: 'Alertas'),
        NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Ranking'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
      ],
    ),
  );
}

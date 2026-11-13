import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/game_providers.dart';
import '../../core/widgets/z_widgets.dart';
import '../../core/theme/app_theme.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(survivorsProvider), factions = ref.watch(factionRankingProvider);
    return Scaffold(appBar: AppBar(title: const Text('RANKING DA RESISTÊNCIA')), body: DefaultTabController(length: 2, child: Column(children: [
      const TabBar(tabs: [Tab(text: 'SOBREVIVENTES'), Tab(text: 'FACÇÕES')]),
      Expanded(child: TabBarView(children: [
        players.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('$e')),
          data: (list) => ListView(padding: const EdgeInsets.all(16), children: list.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ZPanel(child: Row(children: [
            Text('#${p['position']}', style: const TextStyle(color: ZColors.green, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['nickname'], style: const TextStyle(fontWeight: FontWeight.w800)), Text('${p['faction_name']}', style: const TextStyle(color: ZColors.muted, fontSize: 11))])),
            Text('${p['reputation']} REP', style: const TextStyle(color: ZColors.green, fontWeight: FontWeight.w900)),
          ])))).toList())),
        factions.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('$e')),
          data: (list) => ListView(padding: const EdgeInsets.all(16), children: list.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ZPanel(child: Row(children: [
            Text(f['symbol'], style: const TextStyle(fontSize: 24)), const SizedBox(width: 12), Expanded(child: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.w900))), Text('${f['total_reputation']} REP • ${f['members']} membros', style: const TextStyle(color: ZColors.green, fontSize: 11)),
          ])))).toList())),
      ])),
    ])));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/game_providers.dart';
import '../../core/widgets/z_widgets.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider), inv = ref.watch(inventoryProvider);
    final expedition = ref.watch(activeExpeditionProvider), alerts = ref.watch(alertsProvider), trades = ref.watch(tradesProvider);
    return Scaffold(appBar: AppBar(title: const Text('CENTRAL DE SOBREVIVÊNCIA'), actions: [IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.person_outline))]),
      body: RefreshIndicator(onRefresh: () async { ref.invalidate(profileProvider); ref.invalidate(inventoryProvider); ref.invalidate(activeExpeditionProvider); ref.invalidate(alertsProvider); ref.invalidate(tradesProvider); },
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
        profile.when(data: (p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BEM-VINDO, ${p?['nickname'] ?? 'SOBREVIVENTE'}', style: const TextStyle(color: ZColors.muted, letterSpacing: 1.3, fontSize: 11)),
          const SizedBox(height: 8), Text('${p?['factions']?['symbol'] ?? '☣'}  ${p?['factions']?['name'] ?? 'Rede de resistência'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16), ZPanel(child: Row(children: [const Icon(Icons.military_tech, color: ZColors.green, size: 30), const SizedBox(width: 12), const Expanded(child: Text('REPUTAÇÃO', style: TextStyle(color: ZColors.muted, fontWeight: FontWeight.w800))), Text('${p?['reputation'] ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ZColors.green))])),
        ]), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
        const SizedBox(height: 22), const SectionTitle('Suprimentos principais'),
        const SizedBox(height: 10), inv.when(data: (items) => Wrap(spacing: 8, runSpacing: 8, children: items.take(4).map((i) => Chip(label: Text('${i['icon']} ${i['name']} x${i['quantity']}'))).toList()), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
        const SizedBox(height: 22), const SectionTitle('Expedição em andamento'),
        const SizedBox(height: 10), expedition.when(data: (e) => e == null ? ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nenhum sobrevivente em missão.', style: TextStyle(color: ZColors.muted)),
          const SizedBox(height: 12), ElevatedButton(onPressed: () => context.go('/expeditions'), child: const Text('ESCOLHER EXPEDIÇÃO')),
        ])) : ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e['expedition_types']?['name'] ?? 'Expedição', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8), CountdownTimer(endsAt: DateTime.parse(e['ends_at'])),
          const SizedBox(height: 8), const Text('A contagem usa o horário persistido pelo servidor.', style: TextStyle(color: ZColors.muted, fontSize: 11)),
        ])), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
        const SizedBox(height: 22), const SectionTitle('Alertas ativos'),
        const SizedBox(height: 10), alerts.when(data: (a) => a.isEmpty ? const Text('Nenhuma horda reportada.', style: TextStyle(color: ZColors.muted)) : AlertsPreview(a.take(2).toList()), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
        const SizedBox(height: 22), const SectionTitle('Trocas pendentes'),
        const SizedBox(height: 10), trades.when(data: (t) => Text('${t.where((x) => x['status'] == 'pending' && x['recipient_id'] == x['recipient_id']).length} proposta(s) carregada(s).', style: const TextStyle(color: ZColors.muted)), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
        const SizedBox(height: 22), const SectionTitle('Acesso rápido'),
        const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('Mapa'), avatar: const Icon(Icons.map), onPressed: () => context.go('/map')),
          ActionChip(label: const Text('Trocas'), avatar: const Icon(Icons.swap_horiz), onPressed: () => context.go('/trades')),
          ActionChip(label: const Text('Ranking'), avatar: const Icon(Icons.leaderboard), onPressed: () => context.go('/ranking')),
        ]),
      ])));
  }
}
class AlertsPreview extends StatelessWidget {
  const AlertsPreview(this.alerts, {super.key});
  final List<Map<String, dynamic>> alerts;
  @override Widget build(BuildContext context) => Column(children: alerts.map((a) => Padding(padding: const EdgeInsets.only(bottom: 8), child: HordeAlertBanner(description: a['description'], intensity: a['intensity']))).toList());
}

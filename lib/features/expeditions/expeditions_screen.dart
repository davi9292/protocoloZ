import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/providers/game_providers.dart';
import '../../core/widgets/z_widgets.dart';
import '../../core/theme/app_theme.dart';

class ExpeditionsScreen extends ConsumerWidget {
  const ExpeditionsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(expeditionTypesProvider), active = ref.watch(activeExpeditionProvider);
    return Scaffold(appBar: AppBar(title: const Text('EXPEDIÇÕES')), body: ListView(padding: const EdgeInsets.all(16), children: [
      active.when(data: (e) => e == null ? const SizedBox.shrink() : ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MISSÃO ATIVA', style: TextStyle(color: ZColors.green, fontWeight: FontWeight.w900)),
        Text(e['expedition_types']?['name'] ?? 'Expedição', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        CountdownTimer(endsAt: DateTime.parse(e['ends_at'])),
        const SizedBox(height: 10), ElevatedButton(onPressed: DateTime.parse(e['ends_at']).isAfter(DateTime.now().toUtc()) ? null : () async {
          try { final result = await ref.read(gameRepositoryProvider).collectExpedition(e['id']); ref.invalidate(activeExpeditionProvider); ref.invalidate(inventoryProvider); ref.invalidate(profileProvider); if (context.mounted) showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Suprimentos recuperados'), content: Text('Recompensas: ${result['rewards'] ?? result}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); }
          catch (err) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err'))); }
        }, child: const Text('COLETAR RECOMPENSAS')),
      ])), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
      const SizedBox(height: 18), const SectionTitle('Locais disponíveis'),
      const SizedBox(height: 10),
      types.when(data: (list) => Column(children: list.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 6), Text(t['description'], style: const TextStyle(color: ZColors.muted)),
        const SizedBox(height: 8), Text('${(t['duration_seconds'] / 60).round()} min • Risco ${t['risk_level']}/5', style: const TextStyle(color: ZColors.green, fontSize: 12)),
        const SizedBox(height: 10), ElevatedButton(onPressed: active.valueOrNull != null ? null : () async {
          try { await ref.read(gameRepositoryProvider).startExpedition(t['id']); ref.invalidate(activeExpeditionProvider); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expedição iniciada. Boa sorte.'))); }
          catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
        }, child: const Text('INICIAR EXPEDIÇÃO')),
      ])))).toList()), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
    ]));
  }
}

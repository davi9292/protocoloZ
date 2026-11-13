import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/widgets/z_widgets.dart';
import '../../core/theme/app_theme.dart';

class FactionScreen extends ConsumerWidget {
  const FactionScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final factions = ref.watch(gameRepositoryProvider).factions();
    return Scaffold(appBar: AppBar(title: const Text('ESCOLHA SUA FACÇÃO')), body: FutureBuilder(
      future: factions, builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Sua decisão é definitiva. Escolha com sabedoria.', style: TextStyle(color: ZColors.muted)),
          const SizedBox(height: 18),
          ...snapshot.data!.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              try { await ref.read(gameRepositoryProvider).chooseFaction(f['id']); if (context.mounted) context.go('/home'); }
              catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
            },
            child: ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(f['symbol'], style: const TextStyle(fontSize: 30)), const SizedBox(width: 12), Expanded(child: Text(f['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), const Icon(Icons.arrow_forward, color: ZColors.green)]),
              const SizedBox(height: 8), Text(f['description'], style: const TextStyle(color: ZColors.muted)),
              const SizedBox(height: 10), FactionBadge(name: f['name'], symbol: f['symbol'], color: f['color_hex']),
            ])),
          ))),
        ]);
      },
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/game_providers.dart';
import '../../core/widgets/z_widgets.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(inventoryProvider);
    return Scaffold(appBar: AppBar(title: const Text('INVENTÁRIO')), body: data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Falha ao carregar mochila: $e')),
      data: (items) => items.isEmpty ? const Center(child: Text('Sua mochila está vazia. Saia em uma expedição.')) :
        ListView(padding: const EdgeInsets.all(16), children: [
          Text('${items.length} tipos de suprimentos', style: const TextStyle(color: Color(0xFF91A095))),
          const SizedBox(height: 12),
          ...items.map((i) => Padding(padding: const EdgeInsets.only(bottom: 9), child: ItemTile(name: i['name'], icon: i['icon'], category: i['category'], quantity: i['quantity'] as int))),
        ]),
    ));
  }
}

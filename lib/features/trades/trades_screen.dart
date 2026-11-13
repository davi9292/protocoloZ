import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/game_providers.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/widgets/z_widgets.dart';

class TradesScreen extends ConsumerWidget {
  const TradesScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final trades = ref.watch(realtimeTradesProvider);
    return Scaffold(appBar: AppBar(title: const Text('MERCADO DE TROCAS'), actions: [IconButton(onPressed: () => _newTrade(context, ref), icon: const Icon(Icons.add))]),
      body: trades.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty ? const Center(child: Text('Nenhuma proposta de troca por enquanto.')) :
          ListView(padding: const EdgeInsets.all(16), children: list.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
            TradeCard(title: 'Proposta ${t['id'].toString().substring(0, 8)}', status: t['status'], subtitle: 'Expira em ${t['expires_at']}'),
            if (t['status'] == 'pending') Wrap(alignment: WrapAlignment.end, children: [
              TextButton(onPressed: () async {
                try { await ref.read(gameRepositoryProvider).respondTrade(t['id'], t['recipient_id'] == ref.read(gameRepositoryProvider).uid ? 'accept' : 'cancel'); ref.invalidate(tradesProvider); ref.invalidate(inventoryProvider); ref.invalidate(profileProvider); }
                catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }, child: Text(t['recipient_id'] == ref.read(gameRepositoryProvider).uid ? 'ACEITAR' : 'CANCELAR')),
              if (t['recipient_id'] == ref.read(gameRepositoryProvider).uid) TextButton(onPressed: () async {
                try { await ref.read(gameRepositoryProvider).respondTrade(t['id'], 'decline'); ref.invalidate(tradesProvider); }
                catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }, child: const Text('RECUSAR')),
            ]),
          ]) )).toList())),
    );
  }
  Future<void> _newTrade(BuildContext context, WidgetRef ref) async {
    final target = TextEditingController(), offerItem = TextEditingController(), offerQty = TextEditingController(text: '1'), askItem = TextEditingController(), askQty = TextEditingController(text: '1');
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Nova proposta'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: target, decoration: const InputDecoration(labelText: 'ID do jogador destinatário')),
        TextField(controller: offerItem, decoration: const InputDecoration(labelText: 'UUID do item oferecido')),
        TextField(controller: offerQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade oferecida')),
        TextField(controller: askItem, decoration: const InputDecoration(labelText: 'UUID do item solicitado')),
        TextField(controller: askQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade solicitada')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () async {
        try {
          await ref.read(gameRepositoryProvider).db.rpc('create_trade', params: {
            'p_recipient_id': target.text.trim(),
            'p_items': [
              {'item_id': offerItem.text.trim(), 'side': 'offer', 'quantity': int.parse(offerQty.text)},
              {'item_id': askItem.text.trim(), 'side': 'request', 'quantity': int.parse(askQty.text)},
            ],
          });
          ref.invalidate(tradesProvider); if (ctx.mounted) Navigator.pop(ctx);
        } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
      }, child: const Text('ENVIAR PROPOSTA'))],
    ));
  }
}

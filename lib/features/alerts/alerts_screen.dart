import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/game_providers.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/widgets/z_widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(realtimeAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SINAIS DE HORDA'),
        actions: [
          IconButton(
            onPressed: () => _report(context, ref),
            icon: const Icon(Icons.add_alert),
          ),
        ],
      ),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Nenhum sinal ativo na região.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final alert in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      HordeAlertBanner(
                        description: alert['description'],
                        intensity: alert['intensity'],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            try {
                              await ref.read(gameRepositoryProvider).confirmAlert(alert['id']);
                              ref.invalidate(alertsProvider);
                              ref.invalidate(profileProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                          child: const Text('CONFIRMAR AVISTAMENTO'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final lat = TextEditingController(text: '-23.02');
    final lng = TextEditingController(text: '-45.55');
    final desc = TextEditingController();
    String intensity = 'medium';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Reportar horda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição curta'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: intensity,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Baixa')),
                    DropdownMenuItem(value: 'medium', child: Text('Média')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                  ],
                  onChanged: (v) => setD(() => intensity = v ?? 'medium'),
                ),
                TextField(
                  controller: lat,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
                TextField(
                  controller: lng,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(gameRepositoryProvider).createAlert(
                    double.parse(lat.text),
                    double.parse(lng.text),
                    intensity,
                    desc.text,
                  );
                  ref.invalidate(alertsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('ENVIAR ALERTA'),
            ),
          ],
        ),
      ),
    );
  }
}

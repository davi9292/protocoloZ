import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/providers/game_providers.dart';
import '../../core/widgets/z_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider), stats = ref.watch(profileStatsProvider);
    return Scaffold(appBar: AppBar(title: const Text('REGISTRO DO SOBREVIVENTE')), body: ListView(padding: const EdgeInsets.all(18), children: [
      profile.when(data: (p) => ZPanel(child: Column(children: [
        CircleAvatar(radius: 38, backgroundImage: p?['avatar_url'] == null ? null : NetworkImage(p!['avatar_url']), child: p?['avatar_url'] == null ? const Icon(Icons.person, size: 36) : null),
        const SizedBox(height: 12), Text(p?['nickname'] ?? 'Sobrevivente', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        Text(ref.read(authRepositoryProvider).user?.email ?? '', style: const TextStyle(color: Color(0xFF91A095))),
        const SizedBox(height: 10), if (p?['factions'] != null) FactionBadge(name: p!['factions']['name'], symbol: p['factions']['symbol'], color: p['factions']['color_hex']),
        const SizedBox(height: 8), Text('${p?['reputation'] ?? 0} pontos de reputação', style: const TextStyle(color: Color(0xFF9DBB73), fontWeight: FontWeight.w900)),
        OutlinedButton.icon(onPressed: () async {
          final photo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (photo == null) return;
          try {
            final url = await ref.read(gameRepositoryProvider).uploadImage(File(photo.path), 'avatars');
            await ref.read(gameRepositoryProvider).db.from('profiles').update({'avatar_url': url}).eq('id', ref.read(authRepositoryProvider).user!.id);
            ref.invalidate(profileProvider);
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
        }, icon: const Icon(Icons.camera_alt_outlined), label: const Text('ATUALIZAR AVATAR')),
      ])), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
      const SizedBox(height: 16), const SectionTitle('Estatísticas'),
      stats.when(data: (s) => ZPanel(child: Column(children: [
        _stat('Expedições concluídas', s['completed_expeditions']),
        _stat('Trocas realizadas', s['completed_trades']),
        _stat('Abrigos cadastrados', s['shelters_count']),
        _stat('Alertas confirmados', s['alerts_confirmed']),
      ])), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () async { await ref.read(authRepositoryProvider).signOut(); if (context.mounted) context.go('/login'); }, icon: const Icon(Icons.logout), label: const Text('ENCERRAR SESSÃO')),
    ]));
  }
  Widget _stat(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(label)), Text('${value ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900))]));
}

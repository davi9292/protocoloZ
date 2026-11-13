import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/game_providers.dart';
import '../../data/repositories/game_repository.dart';
import '../../core/widgets/z_widgets.dart';
import '../../core/theme/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng selected = const LatLng(-23.02, -45.55);
  final map = MapController();

  Future<void> useGps() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissão negada. Toque no mapa para marcar manualmente.');
      }

      final p = await Geolocator.getCurrentPosition();
      setState(() => selected = LatLng(p.latitude, p.longitude));
      map.move(selected, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> addShelter() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final capacity = TextEditingController(text: '10');
    bool faction = true;
    XFile? photo;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Novo abrigo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextField(
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacidade'),
                ),
                SwitchListTile(
                  value: faction,
                  onChanged: (v) => setD(() => faction = v),
                  title: const Text('Visível apenas à minha facção'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    photo = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 75,
                    );
                    setD(() {});
                  },
                  icon: const Icon(Icons.photo),
                  label: Text(photo == null ? 'Adicionar foto' : 'Foto selecionada'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  String? url;
                  if (photo != null) {
                    url = await ref.read(gameRepositoryProvider).uploadImage(
                      File(photo!.path),
                      'shelters',
                    );
                  }

                  await ref.read(gameRepositoryProvider).createShelter(
                    name: name.text,
                    description: desc.text,
                    capacity: int.parse(capacity.text),
                    lat: selected.latitude,
                    lng: selected.longitude,
                    factionOnly: faction,
                    photoUrl: url,
                  );
                  ref.invalidate(sheltersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelters = ref.watch(sheltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAPA DA RESISTÊNCIA'),
        actions: [
          IconButton(onPressed: useGps, icon: const Icon(Icons.my_location)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: shelters.when(
              data: (list) => FlutterMap(
                mapController: map,
                options: MapOptions(
                  initialCenter: selected,
                  initialZoom: 11,
                  onTap: (_, point) => setState(() => selected = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.com.protocoloz.app',
                  ),
                  MarkerLayer(
                    markers: [
                      ...list.map(
                        (s) => Marker(
                          point: LatLng(
                            (s['latitude'] as num).toDouble(),
                            (s['longitude'] as num).toDouble(),
                          ),
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.home, color: ZColors.green, size: 32),
                        ),
                      ),
                      Marker(
                        point: selected,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.add_location_alt, color: ZColors.red, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          Container(
            height: 190,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Abrigos registrados')),
                    Text('${shelters.valueOrNull?.length ?? 0}'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: shelters.valueOrNull == null
                      ? const SizedBox.shrink()
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final shelter in shelters.value!)
                              SizedBox(
                                width: 260,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ShelterCard(
                                    name: shelter['name'],
                                    description: shelter['description'] ?? '',
                                    capacity: shelter['capacity'],
                                    visibility: shelter['visibility'],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                ElevatedButton(
                  onPressed: addShelter,
                  child: const Text('CADASTRAR ABRIGO NO PONTO SELECIONADO'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

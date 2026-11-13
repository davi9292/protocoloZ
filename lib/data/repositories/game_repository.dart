import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) => GameRepository());

class GameRepository {
  final SupabaseClient db = Supabase.instance.client;
  String get uid => db.auth.currentUser!.id;

  Future<Map<String, dynamic>?> myProfile() async {
    if (db.auth.currentUser == null) return null;
    final row = await db.from('profiles').select('*, factions(*)').eq('id', uid).maybeSingle();
    return row;
  }

  Future<List<Map<String, dynamic>>> factions() async =>
      List<Map<String, dynamic>>.from(await db.from('factions').select().order('name'));

  Future<void> chooseFaction(String factionId) async {
    await db.rpc('choose_faction', params: {'p_faction_id': factionId});
  }

  Future<List<Map<String, dynamic>>> inventory() async =>
      List<Map<String, dynamic>>.from(await db.from('inventory_view').select().order('category'));

  Future<List<Map<String, dynamic>>> expeditionTypes() async =>
      List<Map<String, dynamic>>.from(await db.from('expedition_types').select().order('duration_seconds'));

  Future<Map<String, dynamic>?> activeExpedition() async =>
      await db.from('expeditions').select('*, expedition_types(*)')
        .eq('user_id', uid).eq('status', 'active').maybeSingle();

  Future<void> startExpedition(String typeId) async {
    await db.rpc('start_expedition', params: {'p_type_id': typeId});
  }

  Future<Map<String, dynamic>> collectExpedition(String expeditionId) async =>
      Map<String, dynamic>.from(await db.rpc('collect_expedition', params: {'p_expedition_id': expeditionId}));

  Future<List<Map<String, dynamic>>> shelters() async =>
      List<Map<String, dynamic>>.from(await db.from('shelters').select('*, profiles(nickname), factions(name, color_hex, symbol)').order('created_at', ascending: false));

  Future<void> createShelter({
    required String name, required String description, required int capacity,
    required double lat, required double lng, required bool factionOnly, String? photoUrl,
  }) async {
    await db.from('shelters').insert({
      'owner_id': uid, 'name': name, 'description': description, 'capacity': capacity,
      'latitude': lat, 'longitude': lng, 'visibility': factionOnly ? 'faction' : 'public',
      'photo_url': photoUrl,
    });
  }

  Future<void> deleteShelter(String id) async {
    await db.from('shelters').delete().eq('id', id);
  }

  Future<String> uploadImage(File file, String folder) async {
    final ext = file.path.split('.').last;
    final path = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await db.storage.from('player-media').upload(path, file);
    return db.storage.from('player-media').getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> alerts() async =>
      List<Map<String, dynamic>>.from(await db.from('horde_alerts').select('*, profiles(nickname)').gt('expires_at', DateTime.now().toUtc().toIso8601String()).order('created_at', ascending: false));

  Future<void> createAlert(double lat, double lng, String intensity, String description) async {
    await db.from('horde_alerts').insert({
      'author_id': uid, 'latitude': lat, 'longitude': lng,
      'intensity': intensity, 'description': description,
    });
  }

  Future<void> respondTrade(String id, String action) async {
    await db.rpc('respond_trade', params: {'p_trade_id': id, 'p_action': action});
  }

  Future<void> confirmAlert(String id) async {
    await db.rpc('confirm_horde_alert', params: {'p_alert_id': id});
  }

  Future<List<Map<String, dynamic>>> trades() async =>
      List<Map<String, dynamic>>.from(await db.from('trades').select('*, trade_items(*, items(name, icon))')
        .or('author_id.eq.$uid,recipient_id.eq.$uid').order('created_at', ascending: false));

  Future<List<Map<String, dynamic>>> survivors() async =>
      List<Map<String, dynamic>>.from(await db.from('survivor_ranking').select().order('position'));

  Future<List<Map<String, dynamic>>> factionRanking() async =>
      List<Map<String, dynamic>>.from(await db.from('faction_ranking').select().order('total_reputation', ascending: false));

  Future<Map<String, dynamic>> profileStats() async =>
      Map<String, dynamic>.from(await db.rpc('profile_stats'));

  Stream<List<Map<String, dynamic>>> watchAlerts() => db.from('horde_alerts')
      .stream(primaryKey: ['id']).order('created_at', ascending: false)
      .map((rows) => rows.where((r) => DateTime.parse(r['expires_at']).isAfter(DateTime.now())).toList());

  Stream<List<Map<String, dynamic>>> watchTrades() => db.from('trades')
      .stream(primaryKey: ['id']).order('created_at', ascending: false)
      .map((rows) => rows.where((r) => r['recipient_id'] == uid || r['author_id'] == uid).toList());
}

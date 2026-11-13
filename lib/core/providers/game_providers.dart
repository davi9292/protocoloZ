import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/game_repository.dart';

final profileProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).myProfile());
final inventoryProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).inventory());
final expeditionTypesProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).expeditionTypes());
final activeExpeditionProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).activeExpedition());
final sheltersProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).shelters());
final alertsProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).alerts());
final tradesProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).trades());
final survivorsProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).survivors());
final factionRankingProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).factionRanking());
final profileStatsProvider = FutureProvider((ref) => ref.watch(gameRepositoryProvider).profileStats());

final realtimeAlertsProvider = StreamProvider((ref) => ref.watch(gameRepositoryProvider).watchAlerts());
final realtimeTradesProvider = StreamProvider((ref) => ref.watch(gameRepositoryProvider).watchTrades());

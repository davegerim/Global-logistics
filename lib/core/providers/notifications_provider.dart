import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(backendApiProvider);
  return api.notificationsUnreadCount();
});

final latestNotificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(backendApiProvider);
  return api.notificationsLatest();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';

final consignorActiveProvider = FutureProvider<dynamic>((ref) async {
  final api = ref.watch(backendApiProvider);
  return api.shipmentsConsignorActive();
});
